module circular_buffer #(parameter SIZE=8)(
	input data_i,
	input read_i,
	input write_i,
	input rst,
	input clk,
	output data_o,
	output reg full_o,
	output reg empty_o
);							
//TODO buffer cells aren't just single bits, but XX bits (XX: size of a flit)

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

	//size of the pointer (as a number of bits) is the base 2 logarithm of the SIZE parameter
	localparam [32:0] POINTER_SIZE= clogb2(SIZE);

	reg [SIZE-1:0] memory;

	reg [POINTER_SIZE-1:0] read_ptr;
	reg [POINTER_SIZE-1:0] write_ptr;

	//next state values
	reg [POINTER_SIZE-1:0] read_ptr_next;
	reg [POINTER_SIZE-1:0] write_ptr_next;
	reg full_o_next;
	reg empty_o_next;

	//data output
	assign data_o = memory [read_ptr];

	//sequential logic
	always@(posedge clk or posedge rst)
	begin
		if (rst)
		begin
			read_ptr <= 0;
			write_ptr <= 0;
			full_o <= 0;
			empty_o <= 1;
		end
		else
		begin
			read_ptr <= read_ptr_next;
			write_ptr <= write_ptr_next;
			full_o <= full_o_next;
			empty_o <= empty_o_next;
			if((~read_i & write_i & ~full_o) | (read_i & write_i))
			begin
				memory[write_ptr] <= data_i;
			end
		end
	end

	//combinatorial logic
	always@(*)
	begin
		write_ptr_next = write_ptr;
		read_ptr_next = read_ptr;
		full_o_next = full_o;
		empty_o_next = empty_o;
		//read only (if buffer not empty)
		if(read_i & ~write_i & ~empty_o)
		begin
			//increment read pointer
			if(read_ptr == SIZE-1)
			begin
				read_ptr_next = 0; 
			end
			else
			begin
				read_ptr_next = read_ptr+1;
			end
			//update empty buffer flag
			if(read_ptr_next == write_ptr)
			begin
				empty_o_next = 1;
			end
			else 
			begin
				empty_o_next = 0;
			end
		end
		//write only (if buffer not full)
		else if(~read_i & write_i & ~full_o)
		begin
			//increment write pointer
			if(write_ptr == SIZE-1)
			begin
				write_ptr_next = 0;
			end
			else
			begin
				write_ptr_next = write_ptr+1;
			end
			//update full buffer flag
			if(write_ptr_next == read_ptr)
			begin
				full_o_next = 1;
			end
			else 
			begin
				full_o_next = 0;
			end
		end
		//both read and write
		else if(read_i & write_i)
		begin
			//read
			if(read_ptr == SIZE-1)
			begin
				read_ptr_next = 0; 
			end
			else
			begin
				read_ptr_next = read_ptr+1;
			end
			//write
			if(write_ptr == SIZE-1)
			begin
				write_ptr_next = 0;
			end
			else
			begin
				write_ptr_next = write_ptr+1;
			end
			/*
			no update to full and empty buffer flags,
			because they don't change, as the two 
			pointers move at the same time
			*/
		end
	end
endmodule