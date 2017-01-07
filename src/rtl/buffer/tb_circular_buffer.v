module tb_circular_buffer #(parameter BUFFER_SIZE=8, parameter FLIT_SIZE=8);

integer i;

reg clk,rst;
reg tb_read_cmd;
reg tb_write_cmd;

reg[FLIT_SIZE-1:0] tb_data_i;
wire[FLIT_SIZE-1:0] tb_data_o;
wire tb_is_full_o;
wire tb_is_empty_o;

initial
begin

	$dumpfile("out.vcd");
	$dumpvars(0, tb_circular_buffer);
	
	// Dynamic dumping of the memory cells of the DUT
	for (i = 0; i < BUFFER_SIZE; i = i + 1) 
		$dumpvars(0, tb_circular_buffer.circular_buffer.memory[i]);

	// Initialize input signals of the DUT
	clk <= 0;
	rst =  1;
	tb_read_cmd		= 0;
	tb_write_cmd	= 0;
	tb_data_i		= 0;

	// Clear rst
	repeat(5) @(posedge clk);
		rst<=0;

	// writes up to buffer saturation
	repeat(12) 
	begin
		@(posedge clk);
		tb_read_cmd		<= 0;	
		tb_write_cmd	<= tb_is_full_o ? 0 : 1;
		tb_data_i		<= {FLIT_SIZE{$random}};

	end

    //writes try with full buffer
    repeat(2) 
    begin
        @(posedge clk);
        tb_read_cmd	<= 0;
        tb_write_cmd	<= 1;
        tb_data_i		<= {FLIT_SIZE{$random}};
    end

	repeat(2) 
	begin 
	   @(posedge clk);
	   tb_read_cmd		<= 0;
      tb_write_cmd	<= 0;
	end 

	// reads until empty buffer
	repeat(12) 
	begin
		@(posedge clk);
		tb_read_cmd		<= tb_is_empty_o ? 0 : 1;	
		tb_write_cmd	<= 0;
		tb_data_i		<= {FLIT_SIZE{$random}};
	end

    //reads try with empty buffer
    repeat(2)
    begin 
        @(posedge clk);
        tb_read_cmd	<= 1;
        tb_write_cmd	<= 0;
        tb_data_i		<= {FLIT_SIZE{$random}};
    end
    
	repeat(2)
	begin 
       @(posedge clk);
       tb_read_cmd	<= 0;
       tb_write_cmd	<= 0;
    end 

	//random, possibly simultaneous, reads/writes
	repeat(15) 
	begin
		@(posedge clk);
		tb_read_cmd		<= tb_is_empty_o ? 0 : $random;	
		tb_write_cmd	<= tb_is_full_o ? 0 : $random;
		tb_data_i		<= {FLIT_SIZE{$random}};
	end

	#20 $finish;

end

// Clock update
always #5 clk =~clk;

// DUT
circular_buffer #(.BUFFER_SIZE(BUFFER_SIZE), .FLIT_SIZE(FLIT_SIZE))
	circular_buffer(
		.clk(clk),
		.rst(rst),
		.data_i(tb_data_i),
		.write_i(tb_write_cmd),
		.read_i(tb_read_cmd),
		.data_o(tb_data_o),
		.is_empty_o(tb_is_empty_o),
		.is_full_o(tb_is_full_o)
	);

endmodule

