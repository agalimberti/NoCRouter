`timescale 1ns / 1ps

module tb_crossbar #(
    parameter INPUT_NUM = 4,
    parameter OUTPUT_NUM = 4,
    parameter FLIT_SIZE = 4   
);
    
    localparam [31:0] SEL_SIZE = $clog2(INPUT_NUM); 

    logic [FLIT_SIZE-1:0] tb_data_i [INPUT_NUM-1:0];
    logic [SEL_SIZE-1:0] tb_sel_i [OUTPUT_NUM-1:0];
    wire [FLIT_SIZE-1:0] tb_data_o [OUTPUT_NUM-1:0];
	
	initial
	begin
	
		$dumpfile("out.vcd");
		$dumpvars(0, tb_crossbar);
	
	    repeat(20)
	    begin
		#5
        for(int i=0;i<INPUT_NUM;i++)
            tb_data_i[i] = {FLIT_SIZE{$random}};
        for(int i=0;i<OUTPUT_NUM;i++)
            tb_sel_i[i] = {SEL_SIZE{$random}};
        end
		
		
		#5 $finish;
	
	end
	
	// DUT	
	crossbar #(
        .INPUT_NUM(INPUT_NUM),
        .OUTPUT_NUM(OUTPUT_NUM),
        .FLIT_SIZE(FLIT_SIZE)
        )
    crossbar ( 
        .data_i(tb_data_i), 
        .sel_i(tb_sel_i),
        .data_o(tb_data_o)
    ); 

endmodule