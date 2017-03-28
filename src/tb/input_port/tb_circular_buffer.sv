`timescale 1ns / 1ps

import noc_params::*;

module tb_circular_buffer #(
    parameter BUFFER_SIZE=8
);

    integer i;
    integer random_test = 8;
    
    logic clk,rst;
    logic read_i;
    logic write_i;

    flit_t flit_queue[$];
    flit_t flit_written;
    flit_t flit_read;
    flit_t flit_x;
    flit_t data_i;
    flit_t data_o;
    wire is_full_o;
    wire is_empty_o;

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        repeat(random_test)
            write();
        repeat(random_test)
            read();
        #20 $finish;
    end

    always #5 clk = ~clk;

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
        )
    circular_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .rst(rst),
        .clk(clk),
        .data_o(data_o),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_circular_buffer);
        
        for (i = 0; i < BUFFER_SIZE; i = i + 1)
            $dumpvars(0, tb_circular_buffer.circular_buffer.memory[i]);
    endtask

    task initialize();
        clk     <= 0;
        rst     = 1;
        read_i  = 0;
        write_i = 0;
    endtask

    task clear_reset();
        repeat(5) @(posedge clk);
            rst <= 0;
    endtask
    
    //the read task first pops out a flit at the front of the flit_queue
    //then it reads a flit from the buffer and compares the two
    task read();
        flit_read = flit_queue.pop_front;
        @(posedge clk);
        write_i <= 0;
        read_i <= is_empty_o ? 0 : 1;
        if(~check_flits & i!=8)
            $display("[READ] FAILED");
        else $display("[READ] PASSED");
        i = 0;
    endtask
    

    //the write task first inserts a flit in the flit_queue
    //then the same flit is written into the buffer
    task write();
        insert_in_queue();
        @(posedge clk);
        write_i <= is_full_o ? 0 : 1;
        read_i <=0;
        data_i <= flit_written;
        if(is_empty_o & flit_queue.size() > 2)
            $display("[WRITE] FAILED");
        else $display("[WRITE] PASSED");
    endtask

    task insert_in_queue();
         flit_written.flit_label <= HEAD;
        flit_written.vc_id <= {VC_SIZE{flit_queue.size()}};
        flit_written.data.head_data.x_dest <= {DEST_ADDR_SIZE_X{flit_queue.size()}};
        flit_written.data.head_data.y_dest <= {DEST_ADDR_SIZE_Y{flit_queue.size()}}; 
          flit_written.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{flit_queue.size()}};
          flit_queue.push_back(flit_written);
    endtask

    function logic check_flits();
        if(flit_read.flit_label == data_o.flit_label &
           flit_read.vc_id == data_o.vc_id &
           flit_read.data.head_data.x_dest == data_o.data.head_data.x_dest &
           flit_read.data.head_data.y_dest == data_o.data.head_data.y_dest &
           flit_read.data.head_data.head_pl == data_o.data.head_data.head_pl)
            check_flits = 1;
        else
            check_flits = 0;   
    endfunction 
    
endmodule