import noc_params::*;

module vc_allocator #(
    parameter VC_TOTAL = 10,    //computing it as localparam from the other two breaks the synthesis
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2
)(
    input rst,
    input clk,
    /*
    -   some input from the upstream input ports:
        * flag if VA allocation is requested,
          i.e., the VC is in VA state
        * output port computed from the RC unit

        and downstream input ports:
        * return to availability of the VC, when it goes back to IDLE state

    -   some output to the upstream input ports
    */
    //these IOs MUST later be changed to use INTERFACES!
    input [VC_TOTAL-1:0] vc_to_allocate_i,
    input port_t [VC_TOTAL-1:0] out_port_i,
    input [VC_TOTAL-1:0] idle_downstream_vc_i,
    output logic [VC_SIZE-1:0] vc_new_o [VC_TOTAL-1:0],  //switched indexes also in IP2VA interface
    output logic [VC_TOTAL-1:0] vc_valid_o
);

/*
IMPORTANT: interfaces must be adjusted to
support multiple input ports per VC Allocator
*/

    logic [VC_TOTAL-1:0][VC_TOTAL-1:0] requests_cmd;
    logic [VC_TOTAL-1:0][VC_TOTAL-1:0] grants;

    logic [VC_TOTAL-1:0] available_vc, available_vc_next; //resources availability vector

    logic [VC_SIZE-1:0] vc_new_next [VC_TOTAL-1:0]; //don't change to packed, otherwise it breaks

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

    /*
    Sequential logic:
    - reset on the rising edge of the rst input;
    - update the availability of downstream Virtual Channels.
    */
    always_ff@(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            for(int vc = 0; vc < VC_TOTAL; vc = vc + 1)
            begin
                vc_new_o[vc]    <= 0;
            end
            available_vc        <= {VC_TOTAL{1'b1}};

        end
        else
        begin
            vc_new_o            <= vc_new_next;
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
        vc_new_next = vc_new_o;
        vc_valid_o = {VC_TOTAL{1'b0}};
        requests_cmd = {VC_TOTAL*VC_TOTAL{1'b0}};

        for(int up_vc = 0; up_vc < VC_TOTAL; up_vc = up_vc + 1)
        begin
            for(int down_vc = 0; down_vc < VC_TOTAL; down_vc = down_vc + 1)
            begin
                if(vc_to_allocate_i[up_vc] & available_vc[down_vc] & (down_vc / VC_NUM) == out_port_i[up_vc])
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
                    vc_new_next[up_vc] = (VC_SIZE)'(down_vc % VC_NUM);
                    vc_valid_o[up_vc] = 1'b1;
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