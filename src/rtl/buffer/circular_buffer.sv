module circular_buffer #(
    parameter BUFFER_SIZE = 8,
    parameter FLIT_SIZE = 8
)(
    input [FLIT_SIZE-1:0] data_i,
    input read_i,
    input write_i,
    input rst,
    input clk,
    output [FLIT_SIZE-1:0] data_o,
    output logic is_full_o,
    output logic is_empty_o
);

    //pointer size
    localparam [31:0] POINTER_SIZE = $clog2(BUFFER_SIZE);

    //buffer memory
    logic [FLIT_SIZE-1:0] memory [BUFFER_SIZE-1:0];

    //read and write pointers
    logic [POINTER_SIZE-1:0] read_ptr;
    logic [POINTER_SIZE-1:0] write_ptr;

    //next state values
    logic [POINTER_SIZE-1:0] read_ptr_next;
    logic [POINTER_SIZE-1:0] write_ptr_next;
    logic is_full_next;
    logic is_empty_next;

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
        //read only (if buffer not empty)
        unique if(read_i & ~write_i & ~is_empty_o)
        begin
            //increment read pointer
            if(read_ptr == BUFFER_SIZE-1)
                read_ptr_next = 0; 
            else
                read_ptr_next = read_ptr+1;
            //no update to write pointer
            write_ptr_next = write_ptr;
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
            //no update to read pointer
            read_ptr_next = read_ptr;
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
        //concurrently read and write (if buffer not empty)
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
            is_full_next = is_full_o;
            is_empty_next = is_empty_o;
        end
        //default behavior (keep previous state)
        else
        begin
            read_ptr_next = read_ptr;
            write_ptr_next = write_ptr;
            is_full_next = is_full_o;
            is_empty_next = is_empty_o;
        end
    end
endmodule