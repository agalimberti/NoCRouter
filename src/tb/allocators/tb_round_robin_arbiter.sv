`timescale 1ns / 1ps

module tb_round_robin_arbiter #(
    parameter AGENTS_NUM = 4
);
    
    logic clk, rst;

    logic [AGENTS_NUM-1:0] requests_cmd;

    wire [AGENTS_NUM-1:0] grants;

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        test();
        #5 $finish;
    end

    always #5 clk = ~clk;

    round_robin_arbiter #(
        .AGENTS_NUM(AGENTS_NUM)
    )
    round_robin_arbiter (
        .clk(clk),
        .rst(rst),
        .requests_i(requests_cmd),
        .grants_o(grants)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_round_robin_arbiter);
    endtask

    task initialize();
        clk <= 0;
        rst  = 1;
    endtask

    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask
    
    task test();
        repeat(10) @(posedge clk)
            requests_cmd <= {AGENTS_NUM{$random}};
    endtask
    
endmodule