module round_robin_arbiter #(
    parameter AGENTS_NUM = 4
)(
    input rst,
    input clk,
    input [AGENTS_NUM-1:0] requests_i,
    output logic [AGENTS_NUM-1:0] grants_o
);

    localparam [31:0] AGENTS_PTR_SIZE = $clog2(AGENTS_NUM);

    logic [AGENTS_PTR_SIZE-1:0] highest_priority, highest_priority_next;

    always_ff@(posedge clk, posedge rst)
    begin
        if(rst)
            highest_priority <= 0;
        else
            highest_priority <= highest_priority_next;
    end

    always_comb
    begin
        grants_o = {AGENTS_NUM{1'b0}};
        highest_priority_next = highest_priority;
        for(int i = 0; i < AGENTS_NUM; i = i + 1)
        begin
            if(requests_i[(highest_priority + i) % AGENTS_NUM])
            begin
                grants_o[(highest_priority + i) % AGENTS_NUM] = 1'b1;
                highest_priority_next = (highest_priority + i + 1) % AGENTS_NUM;
                break;
            end
        end
    end

endmodule