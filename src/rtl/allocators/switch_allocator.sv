import noc_params::*;

module switch_allocator #(
)(
    input rst,
    input clk,
    input [PORT_NUM-1:0][VC_NUM-1:0] on_off_i,
    input_block2switch_allocator.switch_allocator ib_if,
    switch_allocator2crossbar.switch_allocator xbar_if,
    output logic [PORT_NUM-1:0] valid_flit_o
);

    logic [PORT_NUM-1:0][VC_NUM-1:0] request_cmd;
    logic [PORT_NUM-1:0][VC_NUM-1:0] grant;

    separable_input_first_allocator #(
        .VC_NUM(VC_NUM)
    )
    separable_input_first_allocator (
        .rst(rst),
        .clk(clk),
        .request_i(request_cmd),
        .out_port_i(ib_if.out_port),
        .grant_o(grant)
    );

    /*
    Combinational logic:
    - compute the request matrix for the internal Separable Input-First
      Allocator, by setting to 1 the upstream Virtual Channels which are
      requesting for the allocation of a downstream Virtual Channel and
      whose associated downstream Virtual Channel is available from
      the on/off flow control point of view;
    - compute the outputs of the module from the grants matrix obtained
      from the Separable Input-First allocator.
    */
    always_comb
    begin
        for(int port = 0; port < PORT_NUM ; port = port + 1)
        begin
            ib_if.valid_sel[port] = 1'b0;
            valid_flit_o[port] = 1'b0;
            ib_if.vc_sel[port] = {VC_SIZE{1'b0}};
            xbar_if.input_vc_sel[port] = {PORT_SIZE{1'b0}};
            request_cmd[port]={VC_NUM{1'b0}};
        end

        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                if(ib_if.switch_request[up_port][up_vc] & on_off_i[ib_if.out_port[up_port][up_vc]][ib_if.downstream_vc[up_port][up_vc]])
                begin
                    request_cmd[up_port][up_vc] = 1'b1;
                end
            end
        end

        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                if(grant[up_port][up_vc])
                begin
                    ib_if.vc_sel[up_port] = up_vc;
                    ib_if.valid_sel[up_port] = 1'b1;
                    valid_flit_o[ib_if.out_port[up_port][up_vc]] = 1'b1;
                    xbar_if.input_vc_sel[ib_if.out_port[up_port][up_vc]] = up_port;
                end
            end
        end
        
    end

endmodule