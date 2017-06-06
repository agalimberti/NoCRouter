module separable_input_first_allocator #(
    parameter AGENTS_NUM = 4,
    parameter RESOURCES_NUM = 6
)(
    input rst,
    input clk,
    input [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] requests_i,
    output logic [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] grants_o
);

    logic [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] first_stage_grants;
    logic [RESOURCES_NUM-1:0][AGENTS_NUM-1:0] rev_first_stage_grants, rev_grants;

    /*
    First stage:
    for each agent, arbitrate its requests for all the resources such that it
    is granted access to at most one of the requested resources
    */
    genvar in_arb;
    generate
        for(in_arb=0; in_arb<AGENTS_NUM; in_arb++)
        begin: generate_input_round_robin_arbiters
            round_robin_arbiter #(
                .AGENTS_NUM(RESOURCES_NUM)
            )
            round_robin_arbiter (
                .rst(rst),
                .clk(clk),
                .requests_i(requests_i[in_arb]),
                .grants_o(first_stage_grants[in_arb])
            );
        end
    endgenerate

    /*
    Second stage:
    for each available resource which has been requested in the first stage,
    arbitrate the requests such that at most one agent is granted its access
    */
    genvar out_arb;
    generate
        for(out_arb=0; out_arb<RESOURCES_NUM; out_arb++)
        begin: generate_output_round_robin_arbiters
            round_robin_arbiter #(
                .AGENTS_NUM(AGENTS_NUM)
            )
            round_robin_arbiter (
                .rst(rst),
                .clk(clk),
                .requests_i(rev_first_stage_grants[out_arb]),
                .grants_o(rev_grants[out_arb])
            );
        end
    endgenerate

    /*
    Combinational logic:
    the grant matrix computed by the First Stage is overturned to
    be given in input to the Second Stage, while the grant matrix
    computed by the Second Stage is similarly overturned to be
    given as the output of the Allocator module.
    */
    always_comb
    begin
        for(int up = 0; up < AGENTS_NUM; up = up + 1)
        begin
            for (int down = 0; down < RESOURCES_NUM; down = down + 1)
            begin
                rev_first_stage_grants[down][up] = first_stage_grants[up][down];
                grants_o[up][down] = rev_grants[down][up];
            end
        end
    end

endmodule