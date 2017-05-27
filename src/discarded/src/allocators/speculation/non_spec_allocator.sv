import noc_params::*;

module non_spec_allocator #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2
)(
    input rst,
    input clk,
    input [PORT_NUM-1:0][VC_NUM-1:0] on_off_i,
    input port_t [VC_NUM-1:0] out_port_i [PORT_NUM-1:0],
    input [VC_SIZE-1:0] downstream_vc_i [PORT_NUM-1:0][VC_NUM-1:0],
    input non_spec_request_i [PORT_NUM-1:0][VC_NUM-1:0],     //buffer in SA
    output logic [PORT_NUM-1:0][PORT_NUM-1:0] grants_o,
    output logic [VC_NUM-1:0] granted_vc_o [PORT_NUM-1:0]
);

    /*
    WARNING: it's exactly the same as the classical
    non-speculative Switch Allocator, but without the
    computation of the outputs to the Input Block
    and Crossbar from the computed grants matrix
    */

    logic [VC_NUM-1:0] input_port_req [PORT_NUM-1:0];

    logic [PORT_NUM-1:0][PORT_NUM-1:0] requests_cmd;

    /*
    For each input port, a corresponding VC_NUM-input Round-Robin
    Arbiter selects a winner among all active VCs;
    */
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
                .grants_o(granted_vc_o[port_arb])
            );
        end
    endgenerate

    /*
    At each output port, a PORT_NUM-input PORT_NUM-output
    Separable Input-First Allocator selects a winner among all
    input ports which have a VC requesting for that output port.
    */
    separable_input_first_allocator #(
        .AGENTS_NUM(PORT_NUM),
        .RESOURCES_NUM(PORT_NUM)
    )
    separable_input_first_allocator (
        .rst(rst),
        .clk(clk),
        .requests_i(requests_cmd),
        .grants_o(grants_o)
    );

    /*
    Combinational logic:
    - at each input port, requests are made to the corresponding
      RR Arbiter for each VC which is asking for the Switch
      allocation and whose previously assigned downstream VC
      is able to receive a flit from the flow control POV;
    - at each input port, the desired output port is requested
      to the SIF Allocator for the VC winning arbitration
      at the previous stage.
    */
    always_comb
    begin
        for(int port = 0; port < PORT_NUM ; port = port + 1)
        begin
            input_port_req[port] = {VC_NUM{1'b0}};
            requests_cmd[port]={PORT_NUM{1'b0}};
        end

        for(int port = 0; port < PORT_NUM; port = port + 1)
        begin
            for(int vc = 0; vc < VC_NUM; vc = vc + 1)
            begin
                if(non_spec_request_i[port][vc] & on_off_i[out_port_i[port][vc]][downstream_vc_i[port][vc]])
                begin
                    input_port_req[port][vc] = 1'b1;
                end
            end
        end

        for(int port = 0; port < PORT_NUM; port = port + 1)
        begin
            for(int vc = 0; vc < VC_NUM; vc = vc + 1)
            begin
                if(granted_vc_o[port][vc])
                begin
                    requests_cmd[port][out_port_i[port][vc]] = 1'b1;
                end
            end
        end

    end

endmodule