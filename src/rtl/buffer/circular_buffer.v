module circular_buffer #(parameter SIZE=8)(
	input data_i,
	input read_i,
	input write_i,
	input rst,
	input clk,
	output data_o,
	output reg full_o,
	output reg empty_o
);							//TODO buffer cells aren't just single bits, but XX bits (XX: size of a flit)

	//function calculating base 2 logarithm
	function integer clogb2;					//IS IT STILL SYNTHESIZABLE WITH A FUNCTION???
	input [31:0] value;							//Yet, it is ONLY applied to a PARAMETER to put the result in a LOCALPARAM
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

	assign data_o = memory [read_ptr];

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
			if(read_i & ~write_i & ~empty_o)				//READ ONLY
			begin
				if(read_ptr == SIZE-1)
				begin
					read_ptr <= 0; 
				end
				else
				begin
					read_ptr <= read_ptr+1;
				end
				if(read_ptr == write_ptr-1)
				begin
					empty_o <= 1;
				end
				else 
				begin
					empty_o <= 0;
				end
			end
			else if(~read_i & write_i & ~full_o)			//WRITE ONLY
			begin
				if(write_ptr == SIZE-1)
				begin
					write_ptr <= 0;
				end
				else
				begin
					write_ptr <= write_ptr+1;
					memory[write_ptr] <= data_i;
				end
				if(write_ptr == read_ptr-1)
				begin
					empty_o <= 1;
				end
				else 
				begin
					empty_o <= 0;
				end
			end
			else if(read_i & write_i)
			begin
				//read and write in the same clock cycle NOT YET IMPLEMENTED
			end
		end
	end
endmodule