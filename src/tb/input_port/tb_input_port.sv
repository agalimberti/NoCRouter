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
    logic [VC_NUM-1:0] on_off_o;

    //CROSSBAR MOCK
    flit_t flit_o;

    //SWITCH ALLOCATOR MOCK
    port_t [VC_NUM-1 : 0] out_port_o;
    logic [VC_SIZE-1 : 0] vc_sel_cmd;
    logic valid_sel_cmd;

    //VIRTUAL CHANNEL ALLOCATOR MOCK
    logic [VC_NUM-1:0] [VC_SIZE-1:0] vc_new_cmd;
    logic [VC_NUM-1:0] vc_valid_cmd;

    //INTERFACES INSTANTIATION
    input_port2crossbar ip2xbar_if();
    input_port2switch_allocator ip2sa_if();
    input_port2vc_allocator ip2va_if();

    //DUT INSTANTIATION
    input_port #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH)
    )
    input_port (
        .data_i(data_cmd),
        .valid_flit_i(valid_flit_cmd),
        .rst(rst),
        .clk(clk),
        .crossbar_if(ip2xbar_if.input_port),
        .sa_if(ip2sa_if.input_port),
        .va_if(ip2va_if.input_port),
        .on_off_o(on_off_o)
    );

    //MOCK MODULES INSTANTIATION
    xbar_mock xbar_mock (
        .ip_if(ip2xbar_if.crossbar),
        .flit_o(flit_o)
    );

    sa_mock sa_mock (
        .ip_if(ip2sa_if.switch_allocator),
        .out_port_o(out_port_o),
        .vc_sel_i(vc_sel_cmd),
        .valid_sel_i(valid_sel_cmd)
    );

    va_mock va_mock (
        .ip_if(ip2va_if.vc_allocator),
        .vc_new_i(vc_new_cmd),
        .vc_valid_i(vc_valid_cmd)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        
        num_op = 0;
        for(pkt_num=0, vc_num=0; pkt_num<2; pkt_num++,vc_num++)
        begin
//            vc_new = 0;
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
        valid_sel_cmd   = 0;
        vc_sel_cmd      = 0;
        vc_valid_cmd    = 0;
        vc_new_cmd      = 0;
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

module xbar_mock #()(
    input_port2crossbar.crossbar ip_if,
    output flit_t flit_o
);

    always_comb
    begin
        flit_o = ip_if.flit;
    end

endmodule

module sa_mock #()(
    input_port2switch_allocator.switch_allocator ip_if,
    output port_t [VC_NUM-1 : 0] out_port_o,
    input [VC_SIZE-1 : 0] vc_sel_i,
    input valid_sel_i
);

    always_comb
    begin
        ip_if.vc_sel    = vc_sel_i;
        ip_if.valid_sel = valid_sel_i;
        out_port_o      = ip_if.out_port;
    end

endmodule

module va_mock #()(
    input_port2vc_allocator.vc_allocator ip_if,
    input [VC_NUM-1:0] [VC_SIZE-1:0] vc_new_i,
    input [VC_NUM-1:0] vc_valid_i
);

    always_comb
    begin
        ip_if.vc_new    = vc_new_i;
        ip_if.vc_valid  = vc_valid_i;
    end

endmodule