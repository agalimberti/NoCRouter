`timescale 1ns / 1ps

import noc_params::*;

module tb_input_buffer#(
    parameter BUFFER_SIZE=8
);

    int i;
    
    logic clk, rst;
    logic read_i;
    logic write_i;
    logic [VC_SIZE-1:0] vc_new_i;
    logic vc_valid_i;
    
    port_t out_port_i;
    port_t out_port_o;
    
    flit_t flit_queue[$];
    flit_t flit_written;
    flit_t flit_read;
    flit_t data_i;
    flit_t data_o;
    
    wire is_full_o;
    wire is_empty_o;
    
    input_buffer #(
            .BUFFER_SIZE(BUFFER_SIZE)
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
            .out_port_o(out_port_o)
        );
    
    initial
    begin
        dump_output();
        initialize();
        clear_reset(); 
               
        insert_packet(NORTH);
        read_packet();
        
        //insert_packet(WEST);
        //read_packet();
        
        #20 $finish;
    end
    
    always #5 clk = ~clk;
    
    task read_flit();
        
        flit_read=flit_queue.pop_front();
        @(posedge clk)
            write_i <= 0;
            read_i  <= 1;
        @(posedge clk)
        begin
            //$display("%d", $time);
            read_i  <= 0;
            write_i <= 0;
            if(1)
            begin
                if(~(flit_read == data_o))
                    #40 $finish;
                    //$display("-%d", $time); 
            end
        end
        
    endtask
    
    task write_flit();
        read_i  <= 0;
        write_i <= 1;
        data_i  <= flit_written;
        push_flit();
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
        
        create_flit(HEAD);
        @(posedge clk) 
        begin
            write_flit();
            out_port_i  <= p;
        end
        
//        repeat($urandom_range(3,0)) 
//            read_flit();
            
        create_flit(BODY);
        @(posedge clk)
        begin 
            write_flit();
            vc_valid_i  <= 1;
            vc_new_i    <= 1'b1;   
        end
        
//        repeat($urandom_range(3,0)) @(posedge clk)
//            read_flit();
            
        create_flit(BODY);
        @(posedge clk)
        begin
            vc_valid_i  <= 0;
            write_flit();
        end
        
//        repeat($urandom_range(3,0)) @(posedge clk)
//            read_flit();
           
        create_flit(TAIL);   
        @(posedge clk) 
        begin
            write_flit();
        end
        
        @(posedge clk) 
            write_i <= 0;
             
    endtask
    
    task create_flit(input flit_label_t lab);
        flit_written.flit_label <= lab;
        flit_written.vc_id      <= 1'b1;
        if(lab == HEAD)
            begin
                flit_written.data.head_data.x_dest  <= {DEST_ADDR_SIZE_X{flit_queue.size()}};
                flit_written.data.head_data.y_dest  <= {DEST_ADDR_SIZE_Y{flit_queue.size()}}; 
                flit_written.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{flit_queue.size()}}; 
            end
        else
                flit_written.data.bt_pl <= {FLIT_DATA_SIZE{flit_queue.size()}};
    endtask
    
    task push_flit();
            flit_queue.push_back(flit_written);
            $display("%d", flit_queue.size());
    endtask
    
    task read_packet();
        repeat(5) 
        begin
            read_flit();
        end
    endtask
    
endmodule