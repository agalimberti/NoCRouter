`timescale 1ns / 1ps

import noc_params::*;

module tb_circular_buffer #(
    parameter BUFFER_SIZE=8
);

    integer i;

    logic clk,rst;
    logic read_i;
    logic write_i;

    flit_t data_i;
    flit_t data_o;
    wire is_full_o;
    wire is_empty_o;

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        write_until_saturate();
        write_while_full();
        read_and_write_while_full();
        no_op();
        read_until_empty();
        read_while_empty();
        no_op();
        random_reads_writes();
        #20 $finish;
    end

    always #5 clk = ~clk;

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
        )
    circular_buffer (
        .*
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
  		  random_head_flit();
    endtask

    task clear_reset();
        repeat(5) @(posedge clk);
            rst <= 0;
    endtask

    task write_until_saturate();
        repeat(12)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= is_full_o ? 0 : 1;
            random_head_flit();
        end
    endtask

    task write_while_full();
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= 1;
            random_head_flit();          
        end
    endtask;

    task read_and_write_while_full();
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 1;
            write_i <= 1;
            random_head_flit();
        end
    endtask

    task no_op();
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= 0;
        end
    endtask

    task read_until_empty();
        repeat(12)
        begin
            @(posedge clk);
            read_i  <= is_empty_o ? 0 : 1;
            write_i <= 0;
           random_head_flit();
        end
    endtask

    task read_while_empty();
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 1;
            write_i <= 0;
           random_head_flit();
        end
    endtask

    task random_reads_writes();
        repeat(15)
        begin
            @(posedge clk);
            read_i  <= is_empty_o ? 0 : $random;
            write_i <= is_full_o ? 0 : $random;
           random_head_flit();
        end
    endtask
    
    task random_head_flit();
        data_i.flit_label <= HEAD;
        data_i.data.head_data.vc_id <= {VC_SIZE{$random}};
        data_i.data.head_data.x_dest <= {DEST_ADDR_SIZE{$random}};
    	data_i.data.head_data.y_dest <= {DEST_ADDR_SIZE{$random}}; 
  		data_i.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{$random}}; 
   endtask;

endmodule