`timescale 1ns / 1ps

import noc_params::*;

module tb_input_port #(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
);

    //TESTBENCH 
    flit_t flit_written;
    flit_t flit_queue[$];
    flit_t flit_read;
    int num_op, body_num, pkt_num;
    logic [VC_SIZE-1:0] vc_num, vc_new;
    
    //INPUT PORT
    flit_t data_cmd;
    logic valid_flit_cmd;
    logic rst;
    logic clk;
    logic [VC_SIZE-1 : 0] vc_sel_cmd;
    logic [VC_SIZE-1:0] vc_new_cmd [VC_NUM-1:0];
    logic [VC_NUM-1:0] vc_valid_cmd;
    logic valid_sel_cmd;
    flit_t flit_o;
    logic [VC_NUM-1:0] on_off_o;
    logic [VC_NUM-1:0] vc_allocatable_o;
    logic [VC_NUM-1:0] vc_request_o;
    port_t [VC_NUM-1:0] out_port_o;

    //DUT INSTANTIATION
    input_port #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH),
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT)
    )
    input_port (
       .data_i(data_cmd),
       .valid_flit_i(valid_flit_cmd),
       .rst(rst),
       .clk(clk),
       .vc_sel_i(vc_sel_cmd),
       .vc_new_i(vc_new_cmd),
       .vc_valid_i(vc_valid_cmd),
       .valid_sel_i(valid_sel_cmd),
       .flit_o(flit_o),
       .on_off_o(on_off_o),
       .vc_allocatable_o(vc_allocatable_o),
       .vc_request_o(vc_request_o),
       .out_port_o(out_port_o)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        
        num_op = 0;
        for(pkt_num=0, vc_num=0; pkt_num<2; pkt_num++,vc_num++)
        begin
            $display("%d", vc_num);
            vc_new = {VC_SIZE{$random}};
            insert_packet(vc_num, vc_new);  
            read_packet(vc_num);
        end
          
        #20 $finish;
    end
    
    always #5 clk = ~clk;

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_input_port);     
    endtask
    
    task initialize();
        clk             <= 0;
        rst             = 1;
        valid_flit_cmd  = 0;
        vc_sel_cmd      = 0;
        vc_valid_cmd    = 0;
        valid_sel_cmd   = 0;
        for(int i=0; i<VC_NUM; i++)
            vc_new_cmd[i] = 0;
    endtask
    
    task create_flit(input flit_label_t lab, input logic [VC_SIZE-1:0] curr_vc);
            flit_written.flit_label <= lab;
            flit_written.vc_id      <= curr_vc;
            if(lab == HEAD)
                begin
                    flit_written.data.head_data.x_dest  <= {DEST_ADDR_SIZE_X{num_op}};
                    flit_written.data.head_data.y_dest  <= {DEST_ADDR_SIZE_Y{num_op}}; 
                    flit_written.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{num_op}}; 
                end
            else
                    flit_written.data.bt_pl <= {FLIT_DATA_SIZE{flit_queue.size()}};
    endtask
    
    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask
    
    task write_flit(input logic [VC_SIZE-1:0] vc_new);
            begin
                vc_valid_cmd    <= 0;
                valid_flit_cmd  <= 1;
                data_cmd        <= flit_written;
            end
            num_op++;
            push_flit(vc_new);
    endtask
        
    task push_flit(input logic [VC_SIZE-1:0] vc_new);
        $display("%d", $time);
        flit_written.vc_id = vc_new;
        flit_queue.push_back(flit_written);
    endtask
        
    task insert_packet(input logic [VC_SIZE-1:0] curr_vc, input logic [VC_SIZE-1:0] vc_new);
        
        @(posedge clk)
            create_flit(HEAD, curr_vc);
            valid_sel_cmd <= 0;
        @(posedge clk) 
        begin
            write_flit(vc_new);
        end 
             
        for(body_num=0; body_num<2; body_num++)
        begin
            create_flit(BODY, curr_vc);   
            @(posedge clk)
            begin 
                write_flit(vc_new);
                if(body_num == 0)
                begin
                    vc_valid_cmd[curr_vc]   <= 1;
                    vc_new_cmd[curr_vc]     <= vc_new;
                end
                else 
                    vc_valid_cmd[curr_vc]   <= 0;
            end
        end
        
        create_flit(TAIL, curr_vc);
        @(posedge clk)
        begin 
            write_flit(vc_new);
        end
    endtask
    
    task read_packet(input logic [VC_SIZE-1:0] vc);
        repeat(4)
        begin
            read_flit(vc);
        end
    endtask
    
    task read_flit(input logic [VC_SIZE-1:0] vc);
        num_op++;
        begin
            flit_read = flit_queue.pop_front();
            @(posedge clk)
            begin
                valid_flit_cmd  <= 0;
                valid_sel_cmd   <= 1;
                vc_sel_cmd      <= vc;           
            end
            @(negedge clk)
                check_flits();
        end
    endtask 

    /*
    Checks the correspondance between the flit extracted 
    from the queue and the one in data_o.
    If the check goes wrong an error message is displayed
    and the testbench ends.
    */
    task check_flits();
        if(~(flit_read === flit_o))
        begin
            $display("[READ] FAILED %d", $time);
            #10 $finish;
        end
        else
            $display("[READ] PASSED %d", $time);
    endtask
endmodule