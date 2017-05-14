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
    int num_op, pkt_size, wait_time, flit_num, timer, flit_to_read, flit_to_read_next, total_time;
    logic insert_not_compl, va_done;
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
    wire [VC_NUM-1:0] on_off_o;
    wire [VC_NUM-1:0] vc_allocatable_o;
    wire [VC_NUM-1:0] vc_request_o;
    port_t [VC_NUM-1:0] out_port_o;
    wire [VC_NUM-1:0] is_full_o;
    wire [VC_NUM-1:0] is_empty_o;

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
       .out_port_o(out_port_o),
       .is_full_o(is_full_o),
       .is_empty_o(is_empty_o)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();

        // Standard 4 flits pkt
        pkt_size = 4;
        vc_num = {VC_SIZE{$random}};
        vc_new = {VC_SIZE{$random}};
        test(vc_num, vc_new, pkt_size, 0, 2);
        
        // Standard packet, 4 flits, with delay between them
        test(vc_num, vc_new, pkt_size, 2, 2);
        
        // No body flits pkt
        pkt_size = 2;
        vc_num = {VC_SIZE{$random}};
        vc_new = {VC_SIZE{$random}};
        test(vc_num, vc_new, pkt_size, 0, 1);

        // Long pkt (exceeds buffer length)

        // Double head flit

        // BODY & TAIL flits without HEAD flit
        noHead();

        #10 $finish;
    end

    // Clock update
    always #5 clk = ~clk;

    // Output dump
    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_input_port);
    endtask

    // Initialize signals
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

    // Create a flit to be written in both DUT and queue
    task create_flit(input flit_label_t lab, input logic [VC_SIZE-1:0] curr_vc);
            flit_written.flit_label = lab;
            flit_written.vc_id      = curr_vc;
            if(lab == HEAD)
                begin
                    flit_written.data.head_data.x_dest  = {DEST_ADDR_SIZE_X{num_op}};
                    flit_written.data.head_data.y_dest  = {DEST_ADDR_SIZE_Y{num_op}};
                    flit_written.data.head_data.head_pl = {HEAD_PAYLOAD_SIZE{num_op}};
                end
            else
                    flit_written.data.bt_pl = {FLIT_DATA_SIZE{num_op}};
    endtask

    // De-assert the reset signal
    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask

    // Write flit into the DUT module
    task write_flit(input logic [VC_SIZE-1:0] vc_new);
        begin
            //vc_valid_cmd    <= 0;
            valid_flit_cmd  <= 1;
            data_cmd        <= flit_written;
        end
        num_op++;
        push_flit(vc_new);
    endtask

    // Push the actual flit, with the new vc, into the buffer
    task push_flit(input logic [VC_SIZE-1:0] vc_new);
        $display("push %d", $time);
        flit_written.vc_id = vc_new;
        flit_queue.push_back(flit_written);
    endtask

    /*
    Checks the correspondance between the flit extracted
    from the queue and the one in data_o.
    If the check goes wrong an error message is displayed
    and the testbench ends.
    */
    task check_flits(input logic [VC_SIZE-1:0] vc);
        if(~(is_empty_o[vc]) | flit_to_read > 0)
        begin
            if(~(flit_read === flit_o))
            begin
                $display("[READ] FAILED %d", $time);
                #10 $finish;
            end
            else
                $display("[READ] PASSED %d", $time);
        end
    endtask

    task noHead();
        @(posedge clk)
        begin
            valid_sel_cmd <= 0;
            create_flit(BODY, 0);
            write_flit(0);
        end
        @(posedge clk)
        begin
            valid_flit_cmd <= 0;
            if(~(is_empty_o[0]))
                $finish;
        end
        @(posedge clk)
        begin
            valid_sel_cmd <= 0;
            create_flit(TAIL, 0);
            write_flit(0);
        end
        @(posedge clk)
        begin
            valid_flit_cmd <= 0;
            if(~is_empty_o[0])
                $finish;
        end
    endtask

    task test(input logic [VC_SIZE-1:0] curr_vc, input logic [VC_SIZE-1:0] vc_new, input integer pkt_size, input integer wait_time, input integer va_time);
        flit_num = 0;
        timer = 0;
        flit_to_read = 0;
        insert_not_compl = 1;
        total_time = 0;

        while(flit_to_read > 0 | insert_not_compl == 1) @(posedge clk)
        begin
            $display("%d, total time:%d, to read %d, timer %d",$time,total_time, flit_to_read, timer);
            insertFlit(curr_vc,wait_time);
            commandIP(curr_vc, va_time);
            readFlit(curr_vc);
            total_time++;
            flit_to_read = flit_to_read_next;
            $display("%d, total time:%d, to read %d, timer  %d",$time,total_time, flit_to_read, timer);
        end
        @(posedge clk)
        begin
            valid_sel_cmd   <= 0;
            va_done         <= 0;
        end
    endtask

    task insertFlit(input logic [VC_SIZE-1:0] vc, input integer wait_time);
    if(pkt_size == 1)
        begin
        /*  
            create_flit(HEAD_TAIL, curr_vc);
            @(posedge clk)
                begin
                    write_flit(vc_new);
                end
        */
        end
    else
        begin
            if(timer == 0 & insert_not_compl)
                begin
                    flit_num++;
                    flit_to_read_next++;
                    
                    if(flit_num == 1)
                        begin
                            create_flit(HEAD, vc);
                            write_flit(vc_new);
                        end
                    else if (flit_num == pkt_size)
                        begin
                            create_flit(TAIL, vc);
                            write_flit(vc_new);
                            insert_not_compl = 0; // Deassert completion flag
                        end
                    else
                        begin
                            create_flit(BODY, vc);
                            write_flit(vc_new);
                        end
                    timer = wait_time; // reset timer
                end
            else
                begin
                    valid_flit_cmd <= 0;
                    timer--;
                end
        end
    endtask

    task readFlit(input logic [VC_SIZE-1:0] vc);
        if(flit_to_read > 0 & va_done)
        begin
            num_op++;
            flit_to_read_next--;
            begin
                flit_read = flit_queue.pop_front();
                begin
                    valid_sel_cmd   <= 1;
                    vc_sel_cmd      <= vc;
                end
                @(negedge clk)
                begin
                    check_flits(vc);
                end
            end
        end
    endtask

    task commandIP(input logic [VC_SIZE-1:0] vc, input integer va_time);
        if(total_time == va_time) //VA phase
        begin
            va_done             <= 1;
            vc_valid_cmd[vc]    <= 1;
            vc_new_cmd[vc]      <= vc_new;
        end
        else if(total_time > 1) //SA phase
        begin
            vc_valid_cmd[vc]    <= 0; //VA already done
            valid_sel_cmd       <= 1;
            vc_sel_cmd          <= vc;
        end
    endtask

endmodule