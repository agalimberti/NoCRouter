import noc_params::*;

module vc_allocator_for_spec #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2
)(
    input rst,
    input clk,
    input [VC_TOTAL-1:0] idle_downstream_vc_i,
    input_block2vc_allocator.vc_allocator ib_if,
    vc_allocator2speculative_switch_allocator.vc_allocator ssa_if
);

    logic [VC_TOTAL-1:0][VC_TOTAL-1:0] requests_cmd;
    logic [VC_TOTAL-1:0][VC_TOTAL-1:0] grants;

    logic [VC_TOTAL-1:0] available_vc, available_vc_next;

    separable_input_first_allocator #(
        .AGENTS_NUM(VC_TOTAL),
        .RESOURCES_NUM(VC_TOTAL)
    )
    separable_input_first_allocator (
        .rst(rst),
        .clk(clk),
        .requests_i(requests_cmd),
        .grants_o(grants)
    );

    //added this line for the speculation !!!
    assign ssa_if.vc_valid = ib_if.vc_valid;

    /*
    Sequential logic:
    - reset on the rising edge of the rst input;
    - update the availability of downstream Virtual Channels.
    */
    always_ff@(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            available_vc        <= {VC_TOTAL{1'b1}};
        end
        else
        begin
            available_vc        <= available_vc_next;
        end
    end

    /*
    Combinational logic:
    - the requests matrix for the Separable Input-First Allocator
      is computed, by setting its values to 1 if and only if
        * the upstream VC requires allocation,
          i.e., it currently is in VA state, and
        * the downstream VC is currently available and it
          belongs to the input port which has already been
          computed as the next hop for the upstream VC;
    - compute the outputs from the grants matrix obtained from
      the Separable Input-First allocator and update the next
      value for the availability of downstream Virtual Channels
      if they have just been allocated;
    - update the next value for the availability of downstream
      Virtual Channels after their eventual deallocations.
    */
    always_comb
    begin
        available_vc_next = available_vc;
        for(int port = 0; port < PORT_NUM; port = port + 1)
        begin
            ib_if.vc_valid[port] = {VC_NUM{1'b0}};
        end
        requests_cmd = {VC_TOTAL*VC_TOTAL{1'b0}};
        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                ib_if.vc_new[up_port][up_vc] = {VC_SIZE{1'bx}};
            end
        end

        for(int up_vc = 0; up_vc < VC_TOTAL; up_vc = up_vc + 1)
        begin
            for(int down_vc = 0; down_vc < VC_TOTAL; down_vc = down_vc + 1)
            begin
                if(ib_if.vc_request[up_vc / VC_NUM][up_vc % VC_NUM] & available_vc[down_vc] &
                    (down_vc / VC_NUM) == ib_if.out_port [up_vc / VC_NUM][up_vc % VC_NUM])
                begin
                    requests_cmd[up_vc][down_vc] = 1'b1;
                end
            end
        end

        for(int up_vc = 0; up_vc < VC_TOTAL; up_vc = up_vc + 1)
        begin
            for(int down_vc = 0; down_vc < VC_TOTAL; down_vc = down_vc + 1)
            begin
                if(grants[up_vc][down_vc])
                begin
                    ib_if.vc_new[up_vc / VC_NUM][up_vc % VC_NUM] = (VC_SIZE)'(down_vc % VC_NUM);
                    ib_if.vc_valid[up_vc / VC_NUM][up_vc % VC_NUM] = 1'b1;
                    available_vc_next[down_vc] = 1'b0;
                end
            end
        end

        for(int down_vc = 0; down_vc < VC_TOTAL; down_vc = down_vc + 1)
        begin
            if(~available_vc[down_vc] & idle_downstream_vc_i[down_vc])
            begin
                available_vc_next[down_vc] = 1'b1;
            end
        end
    end

endmodule