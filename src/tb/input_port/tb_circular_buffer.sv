`timescale 1ns / 1ps

import noc_params::*;

module tb_circular_buffer #(
    parameter BUFFER_SIZE = 8
);

    int i,j;
    int num_operation;
    
    logic clk,rst;
    logic read_i;
    logic write_i;

    flit_novc_t flit_queue[$];
    flit_novc_t flit_written;
    flit_novc_t flit_read;
    flit_novc_t flit_x;
    flit_novc_t data_i;
    flit_novc_t data_o;

    wire is_full_o;
    wire is_empty_o;
    wire on_off_o;

    initial begin
        dump_output();
        initialize();
        clear_reset();
        fork
        begin
            repeat(20)
                random_operation();
        end
        join      
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
        .is_empty_o(is_empty_o),
        .on_off_o(on_off_o)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_circular_buffer);
        
        for (i = 0; i < BUFFER_SIZE; i = i + 1)
            $dumpvars(0, tb_circular_buffer.circular_buffer.memory[i]);
        i = 0;
    endtask

    task initialize();
        clk     <= 0;
        rst     = 1;
        read_i  = 0;
        write_i = 0;
        num_operation = 0;
    endtask

    task clear_reset();
        repeat(5) @(posedge clk);
            rst <= 0;
    endtask
    
    /*
    the read task first pops out a flit at the front of the flit queue
    then it reads a flit from the buffer and compares the two
    */
    task read();
        if(i == 0)
            return;
        else
        begin
            flit_read=flit_queue.pop_front();
            @(posedge clk);
            write_i <= 0;
            read_i <= 1;
            data_i <= flit_x;
            i = i - 1;
            num_operation = num_operation + 1;
            @(negedge clk);
            if(~check_flits)
                $display("[READ] FAILED");
            else
                $display("[READ] PASSED");
        end
    endtask

    /*
    the write task first inserts a flit in the flit queue
    then the same flit is written into the buffer
    */
    task write();
        if(i == BUFFER_SIZE - 1)
            return;
        else
        begin
            create_flit();
            @(posedge clk);
            write_i <= 1;
            read_i <= 0;
            data_i <= flit_written;
            flit_queue.push_back(flit_written);
            if(is_empty_o & flit_queue.size() > 2)
                $display("[WRITE] FAILED");
            else
                $display("[WRITE] PASSED");
            i = i + 1;
            num_operation = num_operation + 1;
        end
    endtask

    /*
    The read write combines the two operations above
    */
    task read_write();
        begin
            if(i == 0)
                return;
            else
            begin
                flit_read=flit_queue.pop_front();
                create_flit();
                @(posedge clk);
                write_i <= 1;
                read_i <= 1;
                data_i <= flit_written;
                flit_queue.push_back(flit_written);
                num_operation = num_operation + 1;
                @(negedge clk);
                if(check_flits & ~is_empty_o)
                    $display("[READ AND WRITE] PASSED");
                else
                    $display("[READ AND WRITE] FAILED");
            end
        end
    endtask
    
    task random_operation();
        j = $urandom_range(8,0);
        if(j >= 6)
            read_write();
        else if (j <= 2)
            write();
        else
            read();
    endtask

    task create_flit();
        flit_written.flit_label <= HEAD;
        flit_written.data.head_data.x_dest <= {DEST_ADDR_SIZE_X{num_operation}};
        flit_written.data.head_data.y_dest <= {DEST_ADDR_SIZE_Y{num_operation}}; 
        flit_written.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{num_operation}};
    endtask

    function logic check_flits();
        if(flit_read == data_o)
            check_flits = 1;
        else
            check_flits = 0;   
    endfunction 
    
endmodule