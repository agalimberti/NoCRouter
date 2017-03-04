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

    localparam [31:0] POINTER_SIZE = $clog2(BUFFER_SIZE);

    logic [FLIT_SIZE-1:0] memory [BUFFER_SIZE-1:0];

    logic [POINTER_SIZE-1:0] read_ptr;
    logic [POINTER_SIZE-1:0] write_ptr;

    logic [POINTER_SIZE-1:0] read_ptr_next;
    logic [POINTER_SIZE-1:0] write_ptr_next;
    logic is_full_next;
    logic is_empty_next;

    /*
    The memory slot pointed by the read_ptr is output at the data_o pin
    */
    assign data_o = memory [read_ptr];

    /*
    Sequential logic:
    - reset on the rising edge of the rst input;
    - when the write_i input is asserted on the rising edge of the clock,
      new data is added to the buffer if the buffer is not full
      or a simultaneous read is performed (i.e., the read_i input is asserted).
    */
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

    /*
    Combinatorial logic:
    - the following operations are accepted:
        * read while the buffer is not empty
        * write while the buffer is not full
        * simultaneously read and write while the buffer is not empty
      and, accordingly to the requested operation:
        * full and empty flags are eventually updated
        * read and write pointers are eventually incremented
    - otherwise, the buffer next status doesn't change
    */
    always_comb
    begin
        unique if(read_i & ~write_i & ~is_empty_o)
        begin: read_not_empty
            read_ptr_next = increase_ptr(read_ptr);
            write_ptr_next = write_ptr;
            is_full_next = 0;
            update_empty_on_read();
        end
        else if(~read_i & write_i & ~is_full_o)
        begin: write_not_full
            read_ptr_next = read_ptr;
            write_ptr_next = increase_ptr(write_ptr);
            update_full_on_write();
            is_empty_next = 0;
        end
        else if(read_i & write_i & ~is_empty_o)
        begin: read_write_not_empty
            read_ptr_next = increase_ptr(read_ptr);
            write_ptr_next = increase_ptr(write_ptr);
            is_full_next = is_full_o;
            is_empty_next = is_empty_o;
        end
        else
        begin: do_nothing
            read_ptr_next = read_ptr;
            write_ptr_next = write_ptr;
            is_full_next = is_full_o;
            is_empty_next = is_empty_o;
        end
    end

    function logic [POINTER_SIZE-1:0] increase_ptr (input logic [POINTER_SIZE-1:0] ptr);
        if(ptr == BUFFER_SIZE-1)
            increase_ptr = 0;
        else
            increase_ptr = ptr+1;
    endfunction

    function void update_empty_on_read ();
        if(read_ptr_next == write_ptr)
            is_empty_next = 1;
        else
            is_empty_next = 0;
    endfunction

    function void update_full_on_write ();
        if(write_ptr_next == read_ptr)
            is_full_next = 1;
        else
            is_full_next = 0;
    endfunction

endmodule