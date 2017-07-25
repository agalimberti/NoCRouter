import noc_params::*;

module separable_input_first_allocator #(
    parameter VC_NUM = 2
)(
    input rst,
    input clk,
    input [PORT_NUM-1:0][VC_NUM-1:0] request_i,
    input port_t [VC_NUM-1:0] out_port_i [PORT_NUM-1:0],
    output logic [PORT_NUM-1:0][VC_NUM-1:0] grant_o
);

    logic [PORT_NUM-1:0][PORT_NUM-1:0] out_request;
    logic [PORT_NUM-1:0][PORT_NUM-1:0] ip_grant;
    logic [PORT_NUM-1:0][VC_NUM-1:0] vc_grant;

    /*
    First stage:
    At each Input Port, Round-Robin arbitration is performed between the
    Virtual Channels requesting for the allocation of any Output Port.
    */
    genvar in_arb;
    generate
        for(in_arb=0; in_arb<PORT_NUM; in_arb++)
        begin: generate_input_round_robin_arbiters
            round_robin_arbiter #(
                .AGENTS_NUM(VC_NUM)
            )
            round_robin_arbiter (
                .rst(rst),
                .clk(clk),
                .requests_i(request_i[in_arb]),
                .grants_o(vc_grant[in_arb])
            );
        end
    endgenerate

    /*
    Second stage:
    At each Output Port, Round-Robin arbitration is performed
    between the Input Ports requesting for its allocation.
    */
    genvar out_arb;
    generate
        for(out_arb=0; out_arb<PORT_NUM; out_arb++)
        begin: generate_output_round_robin_arbiters
            round_robin_arbiter #(
                .AGENTS_NUM(PORT_NUM)
            )
            round_robin_arbiter (
                .rst(rst),
                .clk(clk),
                .requests_i(out_request[out_arb]),
                .grants_o(ip_grant[out_arb])
            );
        end
    endgenerate

    /*
    Combinational logic:
    - compute the request vectors for the second stage arbiters from
      the grants of the first order arbiters; i.e., the Input Ports
      will request the Output Port associated to the Virtual Channel
      winning the first stage arbitration (if there was anyone requesting);
    - compute the output grant matrix from the results of both the first
      and second stage arbiters; i.e., to the VCs winning first stage
      arbitration from Input Ports winning second stage arbitration
      will correspond a 1 in the output grant matrix.
    */
    always_comb
    begin
        out_request = {PORT_NUM*PORT_NUM{1'b0}};
        grant_o= {PORT_NUM*VC_NUM{1'b0}};

        for(int in_port = 0; in_port < PORT_NUM; in_port = in_port + 1)
        begin
            for(int in_vc = 0; in_vc < VC_NUM; in_vc = in_vc + 1)
            begin
                if(vc_grant[in_port][in_vc])
                begin
                    out_request[out_port_i[in_port][in_vc]][in_port] = 1'b1;
                    break;
                end
            end
        end

        for(int out_port = 0; out_port < PORT_NUM; out_port = out_port + 1)
        begin
            for(int in_port = 0; in_port < PORT_NUM; in_port = in_port + 1)
            begin
                for(int in_vc = 0; in_vc < VC_NUM; in_vc = in_vc + 1)
                begin
                    if(ip_grant[out_port][in_port] & vc_grant[in_port][in_vc])
                    begin
                        grant_o[in_port][in_vc] = 1'b1;
                        break;
                    end
                end
            end
        end

    end

endmodule