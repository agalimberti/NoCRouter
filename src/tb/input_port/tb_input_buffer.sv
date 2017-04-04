`timescale 1ns / 1ps

import noc_params::*;

module tb_input_buffer#(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5
);

    int i;
    
    logic clk, rst;
    logic read_i;
    logic write_i;
    logic [VC_SIZE-1:0] vc_new_i;
    logic vc_valid_i;
    logic on_off_o;
    
    port_t out_port_i;
    port_t out_port_o;
    
    flit_t flit_queue[$];
    flit_t flit_written;
    flit_t flit_x;
    flit_t data_i;
    flit_t data_o;
    
    wire is_full_o;
    wire is_empty_o;
    
    input_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH)
    )
    input_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .vc_new_i(vc_new_i),
        .vc_valid_i(vc_valid_i),
        .out_port_i(out_port_i),
        .rst(rst),
        .clk(clk),
        .data_o(data_o),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o),
        .out_port_o(out_port_o),
        .on_off_o(on_off_o)
    );
    
    initial
    begin
        dump_output();
        initialize();
        clear_reset(); 
               
        insert_packet(NORTH);
       
        repeat(5) @(posedge clk)
        begin
            read_flit();
        end
        
        insert_packet(WEST);
        
        repeat(5) @(posedge clk)
            begin
                read_flit();
            end 
        
        #20 $finish;
    end
    
    always #5 clk = ~clk;
    
    task read_flit();
        read_i  <= 1;
        write_i <= 0;
    endtask
    
    task write_flit();
        read_i  <= 0;
        write_i <= 1;
    endtask
    
    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_input_buffer);     
    endtask
    
    task initialize();
        clk     <= 0;
        rst     = 1;
        read_i  = 0;
        write_i = 0;
    endtask
    
    task clear_reset();
        repeat(2) @(posedge clk);
            rst <= 0;
    endtask
    
    task insert_packet(input port_t p);
        
        @(posedge clk) 
        begin
            insert_flit(HEAD);
            out_port_i  <= p;
            push_flit();
        end
            
        @(posedge clk)
        begin 
            vc_valid_i  <= 1;
            vc_new_i    <= 0;
            insert_flit(BODY);
            push_flit();
        end
          
        @(posedge clk)
        begin
            insert_flit(BODY);
            push_flit(); 
        end
          
        @(posedge clk) 
        begin
            insert_flit(TAIL);
            push_flit();
        end
    endtask
    
    task insert_flit(input flit_label_t lab);
        write_flit();
        data_i.flit_label <= lab;
        data_i.vc_id <= {VC_SIZE{flit_queue.size()}};
        data_i.data.head_data.x_dest <= {DEST_ADDR_SIZE_X{flit_queue.size()}};
        data_i.data.head_data.y_dest <= {DEST_ADDR_SIZE_Y{flit_queue.size()}}; 
        data_i.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{flit_queue.size()}};            
    endtask
    
    task push_flit();
            flit_queue.push_back(data_i);
        endtask
        
endmodule