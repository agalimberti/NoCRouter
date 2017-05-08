import noc_params::*;

module switch_allocator #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2
)(
    input rst,
    input clk,
    /*
    TODO: change the module ports to implement the IB2SA interface,
    and make on_off_i compatible with the port coming out
    of the input_block module of the downstream router
    */
    input on_off_i [PORT_NUM-1:0][VC_NUM-1:0],
    input [VC_SIZE-1:0] downstream_vc_i [PORT_NUM-1:0][VC_NUM-1:0],
    input port_t out_port_i [PORT_NUM-1:0][VC_NUM-1:0],
    input switch_request_i [PORT_NUM-1:0][VC_NUM-1:0],  //TODO: from Input Buffer, asserted when in SA state
    output logic [VC_SIZE-1:0] vc_sel_o [PORT_NUM-1:0],
    output logic valid_sel_o [PORT_NUM-1:0],
    output logic [PORT_SIZE-1:0] crossbar_sel_o [PORT_NUM-1:0]  // TODO: interface with the Crossbar module missing
);

    localparam PORT_SIZE = $clog2(PORT_NUM);    //TODO: remove after using interface to Crossbar

    logic [VC_NUM-1:0] input_port_req [PORT_NUM-1:0];
    logic [VC_NUM-1:0] granted_vc [PORT_NUM-1:0];
    logic [PORT_NUM-1:0][PORT_NUM-1:0] requests_cmd;
    logic [PORT_NUM-1:0][PORT_NUM-1:0] grants;

    genvar port_arb;
    generate
        for(port_arb=0; port_arb<PORT_NUM; port_arb++)
        begin: generate_input_port_arbiters
            round_robin_arbiter #(
                .AGENTS_NUM(VC_NUM)
            )
            round_robin_arbiter (
                .rst(rst),
                .clk(clk),
                .requests_i(input_port_req[port_arb]),
                .grants_o(granted_vc[port_arb])
            );
        end
    endgenerate

    separable_input_first_allocator #(
        .AGENTS_NUM(PORT_NUM),
        .RESOURCES_NUM(PORT_NUM)
    )
    separable_input_first_allocator (
        .rst(rst),
        .clk(clk),
        .requests_i(requests_cmd),
        .grants_o(grants)
    );

    always_comb
    begin
        for(int port = 0; port < PORT_NUM ; port = port + 1)
        begin
            valid_sel_o[port] = 1'b0;
            vc_sel_o[port] = {VC_SIZE{1'b0}};
            crossbar_sel_o[port] = {PORT_SIZE{1'b0}};
            input_port_req[port] = {VC_NUM{1'b0}};
            requests_cmd[port]={PORT_NUM{1'b0}};
        end

        for(int port = 0; port < PORT_NUM; port = port + 1)
        begin
            for(int vc = 0; vc < VC_NUM; vc = vc + 1)
            begin
                if(switch_request_i[port][vc] & on_off_i[out_port_i[port][vc]][downstream_vc_i[port][vc]])
                begin
                    input_port_req[port][vc] = 1'b1;
                end
            end
        end

        for(int port = 0; port < PORT_NUM; port = port + 1)
        begin
            for(int vc = 0; vc < VC_NUM; vc = vc + 1)
            begin
                if(granted_vc[port][vc])
                begin
                    requests_cmd[port][out_port_i[port][vc]] = 1'b1;
                end
            end
        end

        for(int in = 0; in < PORT_NUM; in = in + 1)
        begin
            for(int out = 0; out < PORT_NUM; out = out + 1)
            begin
                if(grants[in][out])
                begin
                    for(int vc = 0; vc < VC_NUM; vc = vc + 1)
                    begin
                        if(granted_vc[in][vc])
                        begin
                            vc_sel_o[out] = downstream_vc_i[in][vc];
                        end
                    end
                    valid_sel_o[out] = 1'b1;
                    crossbar_sel_o[out] = (PORT_SIZE)'(in);
                end
            end
        end
    end

endmodule