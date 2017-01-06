module circular_buffer #(parameter BUFFER_SIZE=8, parameter FLIT_SIZE=8)(
	input [FLIT_SIZE-1:0] data_i,
	input read_i,
	input write_i,
	input rst,
	input clk,
	output [FLIT_SIZE-1:0] data_o,
	output reg is_full_o,
	output reg is_empty_o
);							

	//function calculating base 2 logarithm
	function integer clogb2;
	input [31:0] value;
	integer i;
	begin
		clogb2 = 0;
		for(i = 0; 2**i < value; i = i + 1)
			clogb2 = i + 1;
	end
	endfunction

	//size of the pointers (as a number of bits) is the base 2 logarithm of the SIZE parameter
	localparam [32:0] POINTER_SIZE= clogb2(BUFFER_SIZE);

	//buffer memory
	reg [FLIT_SIZE-1:0] memory [BUFFER_SIZE-1:0];

	//read and write pointers
	reg [POINTER_SIZE-1:0] read_ptr;
	reg [POINTER_SIZE-1:0] write_ptr;

	//next state values
	reg [POINTER_SIZE-1:0] read_ptr_next;
	reg [POINTER_SIZE-1:0] write_ptr_next;
	reg is_full_next;
	reg is_empty_next;

	//data output
	assign data_o = memory [read_ptr];

	always_ff@(posedge clk or posedge rst)
	begin
		if (rst)
		begin
			read_ptr <= 0;
			write_ptr <= 0;
			is_full_o <= 0;
			is_empty_o <= 1;
		end
		else
		begin
			read_ptr <= read_ptr_next;
			write_ptr <= write_ptr_next;
			is_full_o <= is_full_next;
			is_empty_o <= is_empty_next;
			if((~read_i & write_i & ~is_full_o) | (read_i & write_i))
				memory[write_ptr] <= data_i;
		end
	end

	always_comb
	begin
		//default behavior (keep previous state)
		write_ptr_next = write_ptr;
		read_ptr_next = read_ptr;
		is_full_next = is_full_o;
		is_empty_next = is_empty_o;
		//read only (if buffer not empty)
		unique if(read_i & ~write_i & ~is_empty_o)
		begin
			//increment read pointer
			if(read_ptr == BUFFER_SIZE-1)
				read_ptr_next = 0; 
			else
				read_ptr_next = read_ptr+1;
			//update full buffer flag
			is_full_next = 0;
			//update empty buffer flag
			if(read_ptr_next == write_ptr)
				is_empty_next = 1;
			else 
				is_empty_next = 0;
		end
		//write only (if buffer not full)
		else if(~read_i & write_i & ~is_full_o)
		begin
			//increment write pointer
			if(write_ptr == BUFFER_SIZE-1)
				write_ptr_next = 0;
			else
				write_ptr_next = write_ptr+1;
			//update full buffer flag
			if(write_ptr_next == read_ptr)
				is_full_next = 1;
			else 
				is_full_next = 0;
			//update empty buffer flag
			is_empty_next = 0;
		end
		//concurrently read and write
		else if(read_i & write_i & ~is_empty_o)
		begin
			//increment read pointer
			if(read_ptr == BUFFER_SIZE-1)
				read_ptr_next = 0; 
			else
				read_ptr_next = read_ptr+1;
			//increment write pointer
			if(write_ptr == BUFFER_SIZE-1)
				write_ptr_next = 0;
			else
				write_ptr_next = write_ptr+1;
			//no update to full and empty buffer flags
		end
	end
endmodule