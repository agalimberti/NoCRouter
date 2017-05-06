`timescale 1ns / 1ps

module tb_separable_input_first_allocator #(
    parameter AGENTS_NUM = 3,
    parameter RESOURCES_NUM = 3
);
    
    logic clk, rst;

    logic [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] requests_cmd;

    wire [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] grants;

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        test();
        #5 $finish;
    end

    always #5 clk = ~clk;

    separable_input_first_allocator #(
        .AGENTS_NUM(AGENTS_NUM),
        .RESOURCES_NUM(RESOURCES_NUM)
    )
    separable_input_first_allocator (
        .clk(clk),
        .rst(rst),
        .requests_i(requests_cmd),
        .grants_o(grants)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_separable_input_first_allocator);
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
        begin
            for(int i=0; i<AGENTS_NUM; i++)
            begin
                requests_cmd[i] <= {RESOURCES_NUM{$random}};
            end
        end
    endtask
    
endmodule