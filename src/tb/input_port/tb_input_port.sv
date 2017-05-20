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
    flit_t flit_queue[VC_NUM][$];
    flit_t flit_read;
    int num_op, timer, total_time;
    int pkt_size[VC_NUM], flit_num[VC_NUM], flit_to_read[VC_NUM], flit_to_read_next[VC_NUM], multiple_head[VC_NUM], head_count[VC_NUM];
    logic [VC_NUM-1:0] insert_not_compl, va_done, head_done;
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

        /*
        The parameters requested from the test task are the following ones:
        test(vc_num, vc_neww, pkt_size, wait_time, va_time, sa_time)
        */
        
        // Standard 4 flits packet
        
        vc_num = {VC_SIZE{$random}};
        vc_new = {VC_SIZE{$random}};
        multiple_head[vc_num] = 0;
        pkt_size[vc_num] = 4;
        test(vc_num, vc_new, pkt_size[vc_num], 0, 2, 2);
        
        // Standard packet, 4 flits, with delay between them
        test(vc_num, vc_new, pkt_size[vc_num], 2, 2, 1);
        
        // No BODY flits packet
        vc_num = {VC_SIZE{$random}};
        vc_new = {VC_SIZE{$random}};
        pkt_size[vc_num] = 2;
        test(vc_num, vc_new, pkt_size[vc_num], 0, 1, 0);

        // Long packet (exceeds buffer length)
        test(vc_num, vc_new, 16, 0, 1, 0);
        
        // Packet with multiple HEAD flits
        multiple_head[vc_num] = 3;
        test(vc_num, vc_new, 6, 0, 1, 0);
        
        // Single flit packet
        multiple_head[vc_num] = 0;
        test(vc_num, vc_new, 1, 0, 1, 1);
        
        // vcs test
        // TODO
        
        // BODY & TAIL flits without HEAD flit
        multiple_head[vc_num] = 0;
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
        for(int i=0; i < VC_NUM; i++)
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
    task write_flit(input logic [VC_SIZE-1:0] vc, input logic [VC_SIZE-1:0] vc_new);
        begin
            valid_flit_cmd  <= 1;
            data_cmd        <= flit_written;
        end
        num_op++;
        push_flit(vc, vc_new);
    endtask

    /*
    Push the actual flit into the queue, with the new vc, only under specific conditions.
    In particular, the push operation is done if the HEAD flit hasn't been inserted yet or
    the flit to insert is not an HEAD one (head_count==0).
    */
    task push_flit(input logic [VC_SIZE-1:0] vc, input logic [VC_SIZE-1:0] vc_new);
       
        flit_written.vc_id = vc_new;
        if( ~head_done[vc] | head_count[vc] == 0)
        begin
            $display("push %d", $time);
            flit_queue[vc].push_back(flit_written);
            flit_to_read_next[vc]++;
        end
    endtask

    /*
    Checks the correspondance between the flit extracted from the queue and the one in data_o. 
    The check is done only whether the given vc is not empty or there are still some flits that have to be read.
    If the check goes wrong an error message is displayed and the testbench ends.
    */
    task check_flits(input logic [VC_SIZE-1:0] vc);
        //$display("*** %d, %d", is_empty_o[vc], flit_to_read);
        if( (~(is_empty_o[vc])) | flit_to_read[vc] > 0)
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

    /*
    This task try to insert into the module a BODY and a TAIL
    flit without the usual leading HEAD flit. 
    A simple check is done in order to check the proper behavior of the dut.
    */ 
    task noHead();
        @(posedge clk)
        begin
            valid_sel_cmd <= 0;
            create_flit(BODY, 0);
            write_flit(0, 0);
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
            write_flit(0, 0);
        end
        @(posedge clk)
        begin
            valid_flit_cmd <= 0;
            if(~is_empty_o[0])
                $finish;
        end
    endtask

    /*
    This is the main task of the testbench: after an initial phase of initialization, it repeatedly calls the 3 subtasks
    until there is no flits to read or the insertion of all the flits of a packet has not been completed.
    
    Parameters
        curr_vc: is the vc identifier in which the packet will be inserted
        vc_new: is the identifier of the vc that would be assigned from the VA
        wait_time: is the number of cycles between the write of two following flits
        va_time: is the time at which the va signals are asserted (considered with respect to the time of the insertion of the first flit)
        sa_time: is the time at which the sa signals are asserted (read note below)
    
    IMPORTANT: sa_time is considered in cycles after va_time.
    (E.g.: sa_time=0 means that the sa will be executed the next cycle after the va)
    */
    task test(input logic [VC_SIZE-1:0] curr_vc, input logic [VC_SIZE-1:0] vc_new, input integer size, 
                input integer wait_time, input integer va_time, input integer sa_time);
        
        head_count[curr_vc] = multiple_head[curr_vc];
        init_test();

        $display("Packet size: %d", size);
        while(flit_to_read[curr_vc] > 0 | insert_not_compl[curr_vc] == 1) @(posedge clk)
        begin
            $display("Time %d, total time:%d, to read %d, timer %d",$time,total_time, flit_to_read[curr_vc], timer);
            insertFlit(curr_vc, size, wait_time);
            commandIP(curr_vc, va_time, sa_time);
            readFlit(curr_vc);
            total_time++;
            flit_to_read[curr_vc] = flit_to_read_next[curr_vc];
            $display("Time %d, total time:%d, to read %d, timer  %d",$time,total_time, flit_to_read[curr_vc], timer);
        end
        
        @(posedge clk)
        begin
            valid_sel_cmd   <= 0;
            va_done         <= 0;
        end
    endtask
    
    /*
    This task is responsible of calling the proper writing task according to some connditions.
    As input it takes the actual vc identifier, the size of the packe and the wait_time (task test(..) for its description).
    */
    task insertFlit(input logic [VC_SIZE-1:0] vc, input integer size, input integer wait_time);
    //$display("head cnt %d", head_count);
    if(size == 1)
    begin
        flit_num[vc]++;
        if(flit_num[vc] == 1)
        begin
            create_flit(HEADTAIL, vc);
            write_flit(vc, vc_new);
            insert_not_compl[vc] <= 0;
        end
        else    
            //@(posedge clk)
                valid_flit_cmd <= 0;
    end
    else
    begin
        if(timer == 0 & insert_not_compl[vc])
        begin
            flit_num[vc]++;
                                
            if(flit_num[vc] == 1 | head_count[vc] > 0)
                begin
                    create_flit(HEAD, vc);
                    write_flit(vc, vc_new);
                    head_count[vc]--;
                    head_done[vc] = 1;
                end
            else
            begin
                head_count[vc] = 0;
                if (flit_num[vc] == size)
                begin
                    create_flit(TAIL, vc);
                    write_flit(vc, vc_new);
                    insert_not_compl[vc] <= 0; // Deassert completion flag
                end
            
                else
                begin
                    create_flit(BODY, vc);
                    write_flit(vc, vc_new);
                end
            end
            timer = wait_time; // reset timer
        end
        else
        begin
            valid_flit_cmd <= 0;
            if(timer > 0)
                timer--;
        end
    end
    endtask

    /*
    This task, if there are flits to be read and the va hasn't been done yet, update some control variables and then pops a flit
    out of the queue and calls the check task (on the next fallingg edge of the clk). 
    */
    task readFlit(input logic [VC_SIZE-1:0] vc);
        if(flit_to_read[vc] > 0 & va_done[vc])
        begin
            num_op++;
            flit_to_read_next[vc]--;
            begin
                flit_read = flit_queue[vc].pop_front();
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

    /*
    In this task, the command for the VA and the SA are asserted at specific cycles, tracked with the total_time, sa_time and va_time variables.
    In particular, the va_time indicates the cycles at which the va will be executed (number of cycles wrt the initial flit write); 
    while the sa_time indicates the cycle for the sa execution: its value gives the number of cycles to wait after the va_time.
    */  
    task commandIP(input logic [VC_SIZE-1:0] vc, input integer va_time, input integer sa_time);
        
        vc_valid_cmd <= 0;
        
        if(total_time == va_time) //VA phase
        begin
            va_done[vc]             <= 1;
            vc_valid_cmd[vc]    <= 1;
            vc_new_cmd[vc]      <= vc_new;
        end
        else if(total_time > va_time+sa_time) //SA phase
        begin
            valid_sel_cmd       <= 1;
            vc_sel_cmd          <= vc;
        end
    endtask
    
    /*
    This task initializes all variables that are necessary for each test before it starts.
    */
    task init_test();
        automatic int i;

        total_time  = 0;
        timer       = 0;

        for(i = 0; i < VC_NUM; i++)
        begin
            head_done[i]        = 0;
            flit_num[i]         = 0;
            flit_to_read[i]     = 0;
            flit_to_read_next[i]= 0;
            insert_not_compl[i] = 1;
        end
    endtask

endmodule