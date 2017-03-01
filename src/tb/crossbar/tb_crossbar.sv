`timescale 1ns / 1ps

module tb_crossbar #(
    parameter INPUT_NUM = 4,
    parameter OUTPUT_NUM = 4,
    parameter FLIT_SIZE = 4
);

    localparam [31:0] SEL_SIZE = $clog2(INPUT_NUM);

    logic [FLIT_SIZE-1:0] data_i [INPUT_NUM-1:0];
    logic [SEL_SIZE-1:0] sel_i [OUTPUT_NUM-1:0];
    wire [FLIT_SIZE-1:0] data_o [OUTPUT_NUM-1:0];

	initial
	begin
        dump_output();
        random_test();
		#5 $finish;
	end

	// DUT
	crossbar #(
        .INPUT_NUM(INPUT_NUM),
        .OUTPUT_NUM(OUTPUT_NUM),
        .FLIT_SIZE(FLIT_SIZE)
        )
    crossbar (
        .*
    );

    //tasks
    task dump_output();
        $dumpfile("out.vcd");
		$dumpvars(0, tb_crossbar);
    endtask

    task random_test();
	    repeat(20)
	    begin
		#5
        for(int i=0;i<INPUT_NUM;i++)
            data_i[i] = {FLIT_SIZE{$random}};
        for(int i=0;i<OUTPUT_NUM;i++)
            sel_i[i] = {SEL_SIZE{$random}};
        end
    endtask

endmodule