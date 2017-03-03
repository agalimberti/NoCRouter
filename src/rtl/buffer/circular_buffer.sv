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
        begin: read_not_empty
            read_ptr_next = increase_ptr(read_ptr);
            write_ptr_next = write_ptr;
            is_full_next = 0;
            update_empty_on_read();
        end
        //write only (if buffer not full)
        else if(~read_i & write_i & ~is_full_o)
        begin: write_not_full
            read_ptr_next = read_ptr;
            write_ptr_next = increase_ptr(write_ptr);
            update_full_on_write();
            is_empty_next = 0;
        end
        //concurrently read and write (if buffer not empty)
        else if(read_i & write_i & ~is_empty_o)
        begin: read_write_not_empty
            read_ptr_next = increase_ptr(read_ptr);
            write_ptr_next = increase_ptr(write_ptr);
            is_full_next = is_full_o;
            is_empty_next = is_empty_o;
        end
        //default behavior (keep previous state)
        else
        begin: do_nothing
            read_ptr_next = read_ptr;
            write_ptr_next = write_ptr;
            is_full_next = is_full_o;
            is_empty_next = is_empty_o;
        end
    end

    function logic [POINTER_SIZE-1:0] increase_ptr (logic [POINTER_SIZE-1:0] ptr)
        if(ptr == BUFFER_SIZE-1)
            increased_ptr = 0;
        else
            increased_ptr = ptr+1;
    endfunction

    function void update_empty_on_read ()
        if(read_ptr_next == write_ptr)
            is_empty_next = 1;
        else
            is_empty_next = 0;
    endfunction

    function void update_full_on_write ()
        if(write_ptr_next == read_ptr)
            is_full_next = 1;
        else
            is_full_next = 0;
    endfunction

endmodule