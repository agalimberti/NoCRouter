`timescale 1ns / 1ps

import noc_params::*;

module tb_input_port #(
    parameter BUFFER_SIZE = 8,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
);

    //TESTBENCH
    flit_t flit_written;
    flit_t flit_queue[VC_NUM][$];
    flit_t flit_read;
    
    int num_op, timer, total_time;
    int pkt_size[VC_NUM], flit_num[VC_NUM], flit_to_read[VC_NUM], flit_to_read_next[VC_NUM], multiple_head[VC_NUM], 
        wait_time[VC_NUM], va_time[VC_NUM], sa_time[VC_NUM];
    
    logic [VC_NUM-1:0] insert_not_compl, va_done, head_done;
    logic [VC_SIZE-1:0] vc_num, vc_num_next, test_vc_num;
    logic [VC_SIZE-1:0] vc_new [VC_NUM-1:0];
    
    //Enum defining test modes
    typedef enum {SINGLE,MULTI} test_mode_t;
    test_mode_t test_mode;
    
    //INPUT PORT
    flit_t data_cmd;
    logic valid_flit_cmd;
    logic rst;
    logic clk;
    logic [VC_SIZE-1 : 0] sa_sel_vc_cmd;
    logic [VC_SIZE-1:0] va_new_vc_cmd [VC_NUM-1:0];
    logic [VC_NUM-1:0] va_valid_cmd;
    logic sa_valid_cmd;

    flit_t flit_o;
    wire [VC_NUM-1:0] is_on_off_o;
    wire [VC_NUM-1:0] is_allocatable_vc_o;
    wire [VC_NUM-1:0] va_request_o;
    logic sa_request_o [VC_NUM-1:0];
    logic [VC_SIZE-1:0] sa_downstream_vc_o [VC_NUM-1:0];
    port_t [VC_NUM-1:0] out_port_o;
    wire [VC_NUM-1:0] is_full_o;
    wire [VC_NUM-1:0] is_empty_o;
    wire [VC_NUM-1:0] error_o;

    //DUT INSTANTIATION
    input_port #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT)
    )
    input_port (
       .data_i(data_cmd),
       .valid_flit_i(valid_flit_cmd),
       .rst(rst),
       .clk(clk),
       .sa_sel_vc_i(sa_sel_vc_cmd),
       .va_new_vc_i(va_new_vc_cmd),
       .va_valid_i(va_valid_cmd),
       .sa_valid_i(sa_valid_cmd),
       .xb_flit_o(flit_o),
       .is_on_off_o(is_on_off_o),
       .is_allocatable_vc_o(is_allocatable_vc_o),
       .va_request_o(va_request_o),
       .sa_request_o(sa_request_o),
       .sa_downstream_vc_o(sa_downstream_vc_o),
       .out_port_o(out_port_o),
       .is_full_o(is_full_o),
       .is_empty_o(is_empty_o),
       .error_o(error_o)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();

        /*
        The parameters requested from the test task are the following ones:
            test(vc_id)
        */
        
        /*
        Standard 4 flits packet
        */
        test_mode = SINGLE;
        test_vc_num = {VC_SIZE{$random}};
        vc_new[test_vc_num] = {VC_SIZE{$random}};
        multiple_head[test_vc_num] = 0;
        pkt_size[test_vc_num] = 4;
        wait_time[test_vc_num] = 0;
        va_time[test_vc_num] = 2;
        sa_time[test_vc_num] = 0;
        test(test_vc_num);
        
        /*
        Standard packet, 4 flits, with delay between them
        */
        test_mode = SINGLE;
        vc_new[test_vc_num] = {VC_SIZE{$random}};
        test_mode = SINGLE;
        wait_time[test_vc_num] = 2;
        va_time[test_vc_num] = 2;
        sa_time[test_vc_num] = 1;
        test(test_vc_num);
        
        /*
        No BODY flits packet
        */
        test_mode = SINGLE;
        test_vc_num = {VC_SIZE{$random}};
        vc_new[test_vc_num] = {VC_SIZE{$random}};
        pkt_size[test_vc_num] = 2;
        wait_time[test_vc_num] = 0;
        va_time[test_vc_num] = 1;
        sa_time[test_vc_num] = 0;
        test(test_vc_num);

        /*
        Long packet (exceeds buffer length)
        */
        test_mode = SINGLE;
        vc_new[test_vc_num] = {VC_SIZE{$random}};
        pkt_size[test_vc_num] = 16;
        wait_time[test_vc_num] = 0;
        va_time[test_vc_num] = 1;
        sa_time[test_vc_num] = 0;
        test(test_vc_num);
        
        /*
        Packet with multiple HEAD flits
        */
        test_mode = SINGLE;
        multiple_head[test_vc_num] = 3;
        pkt_size[test_vc_num] = 6;
        wait_time[test_vc_num] = 0;
        va_time[test_vc_num] = 1;
        sa_time[test_vc_num] = 0;
        test(test_vc_num);
        
        /*
        Single flit packet
        */
        test_mode = SINGLE;
        multiple_head[test_vc_num] = 0;
        pkt_size[test_vc_num] = 1;
        wait_time[test_vc_num] = 0;
        va_time[test_vc_num] = 1;
        sa_time[test_vc_num] = 1;
        test(test_vc_num);
        
        /*
        Multiple VCs test
        NOTE: improper values assigned to SA and/or VA times could cause
        a failure in tb execution. 
        */
        test_mode = MULTI;
        multiple_head = {0,0};
        pkt_size = {4,5};
        wait_time = {0,0};
        va_time = {2,3};
        sa_time = {0,0};
        vc_new = {1'b0,1'b1};
        test(0); 
                
        /*
        BODY & TAIL flits without HEAD flit
        */
        test_mode = SINGLE;
        multiple_head[test_vc_num] = 0;
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
        sa_sel_vc_cmd   = 0;
        va_valid_cmd    = 0;
        sa_valid_cmd    = 0;
        for(int i = 0; i < VC_NUM; i++)
            va_new_vc_cmd[i] = 0;
    endtask

    // Create a flit to be written in both DUT and queue
    task create_flit(input flit_label_t lab);
        flit_written.flit_label = lab;
        flit_written.vc_id      = vc_num;
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
    task write_flit();
        begin
            valid_flit_cmd  <= 1;
            data_cmd        <= flit_written;
        end
        num_op++;
        push_flit();
    endtask

    /*
    Push the actual flit into the queue, with the new vc, only under specific conditions.
    In particular, the push operation is done if the HEAD flit hasn't been inserted yet or
    the flit to insert is not an HEAD one (multiple_head==0).
    */
    task push_flit();
        flit_written.vc_id = vc_new[vc_num];
        if( ~head_done[vc_num] | multiple_head[vc_num] == 0)
        begin
            $display("push %d", $time);
            flit_queue[vc_num].push_back(flit_written);
            flit_to_read_next[vc_num]++;
        end
    endtask

    /*
    Checks the correspondance between the flit extracted from the queue and the one in data_o. 
    The check is done only whether the given vc is not empty or there are still some flits that have to be read.
    If the check goes wrong an error message is displayed and the testbench ends.
    */
    task checkFlits();
        @(negedge clk)
        $display("Check %d, vcnum %d, empty %d, toread %d",$time, vc_num,is_empty_o[vc_num], flit_to_read[vc_num]); 
        begin 
            if( ((~(is_empty_o[vc_num])) | flit_to_read[vc_num] > 0) & va_done[vc_num] & sa_valid_cmd)
            begin
                if(~(flit_read === flit_o))
                begin
                    $display("[READ] FAILED %d", $time);
                    #10 $finish;
                end
                else
                    $display("[READ] PASSED %d", $time);
            end 
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
            sa_valid_cmd <= 0;
            create_flit(BODY);
            write_flit();
        end
        @(posedge clk)
        begin
            valid_flit_cmd <= 0;
            if(~(is_empty_o[0]))
                $finish;
        end
        @(posedge clk)
        begin
            sa_valid_cmd <= 0;
            create_flit(TAIL);
            write_flit();
        end
        @(posedge clk)
        begin
            valid_flit_cmd <= 0;
            if(~is_empty_o[0])
                $finish;
        end
    endtask

    /*
    This is the main task of the testbench: after an initial phase of initialization, it repeatedly calls the 4 subtasks
    until there is no flits to read or the insertion of all the flits of a packet has not been completed (these two conditions
    are checked by means of a separate task).
    
    Parameters
        curr_vc: is the vc identifier in which the packet will be inserted. It is relevant only the test mode in SINGLE. 
    */
    task test(input logic [VC_SIZE-1:0] curr_vc);
        
        vc_num = curr_vc;
        initTest();

        $display("Packet size: %d", pkt_size[vc_num]);
        while(checkEndConditions()) @(posedge clk)
        begin
            $display("Time %d,vc_num: %d total time:%d, to read %d, timer %d",$time, vc_num, total_time, flit_to_read[vc_num], timer);
            
            insertFlit();
            commandIP();
            readFlit();
            
            if(test_mode == MULTI)
                vcChange();
            
            flit_to_read[vc_num] = flit_to_read_next[vc_num];
            total_time++;
            $display("Time %d,vc_num: %d total time:%d, to read %d, timer %d",$time, vc_num, total_time, flit_to_read[vc_num], timer);
        end
        
        @(posedge clk)
        begin
            sa_valid_cmd    <= 0;
            va_done         <= 0;
        end
    endtask
    
    /*
    This task checks whether there are flits still to be read and that the insertion of a packet into the buffer has not yet completed.
    The checks is done for all VCs. 
    */
    function bit unsigned checkEndConditions();
        automatic int i;
    
        for(i = 0; i < VC_NUM; i++)
        begin
            if(flit_to_read[i] > 0 | insert_not_compl[i] == 1)
                return 1;
        end
        return 0;
    endfunction
    
    /*
    This task is responsible of calling the proper writing task according to some conditions.
    */
    task insertFlit();
    //$display("head cnt %d", multiple_head[vc_num]);
    if(pkt_size[vc_num] == 1)
    begin
        flit_num[vc_num]++;
        if(flit_num[vc_num] == 1)
        begin
            create_flit(HEADTAIL);
            write_flit();
            insert_not_compl[vc_num] <= 0;
        end
        else    
            valid_flit_cmd <= 0;
    end
    else
    begin
        if(timer == 0 & insert_not_compl[vc_num])
        begin
            flit_num[vc_num]++;
                                
            if(flit_num[vc_num] == 1 | multiple_head[vc_num] > 0)
                begin
                    create_flit(HEAD);
                    write_flit();
                    multiple_head[vc_num]--;
                    head_done[vc_num] = 1;
                end
            else
            begin
                multiple_head[vc_num] = 0;
                if (flit_num[vc_num] == pkt_size[vc_num])
                begin
                    create_flit(TAIL);
                    write_flit();
                    insert_not_compl[vc_num] <= 0; // Deassert completion flag
                end
            
                else
                begin
                    create_flit(BODY);
                    write_flit();
                end
            end
            timer = wait_time[vc_num]; // reset timer
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
    This task, if there are flits to be read and the va hasn't been done yet, updates some control variables and then pops a flit
    out of the queue and calls the check task (on the next falling edge of the clock). 
    */
    task readFlit();
        $display("Read simtime %d, ttime %d, vcnum %d toread %d vadone %d",$time, total_time, vc_num,flit_to_read[vc_num] , va_done[vc_num]);
        if(flit_to_read[vc_num] > 0 & va_done[vc_num] & total_time>va_time[vc_num]+sa_time[vc_num])
        begin
            num_op++;
            flit_to_read_next[vc_num]--;
            begin
                flit_read = flit_queue[vc_num].pop_front();
                begin
                    //sa_valid_cmd   <= 1;
                    //sa_sel_vc_cmd  <= vc_num;
                end
            end
            
            checkFlits();
        end
    endtask

    /*
    In this task, the command for the VA and the SA are asserted at specific cycles, tracked with the total_time, sa_time and va_time variables.
    In particular, the va_time indicates the cycles at which the va will be executed (number of cycles wrt the initial flit write); 
    while the sa_time indicates the cycle for the sa execution: its value gives the number of cycles to wait after the va_time.
    
    IMPORTANT: sa_time is considered in cycles after va_time.
    (E.g.: sa_time=0 means that the sa will be executed the next cycle after the va)
    */  
    task commandIP();
        
        va_valid_cmd <= 0;
        
        if(total_time == va_time[vc_num]) //VA phase
        begin
            va_done[vc_num]         <= 1;
            va_valid_cmd[vc_num]    <= 1;
            va_new_vc_cmd[vc_num]   <= vc_new[vc_num];
        end
        else if(total_time > va_time[vc_num]+sa_time[vc_num]) //SA phase
        begin
            if(flit_to_read_next[vc_num] > 0)
                sa_valid_cmd    <= 1;
            else 
                sa_valid_cmd    <= 0;
                
            sa_sel_vc_cmd      <= vc_num; 
        end
        
        //if(vc_num != sa_sel_vc_cmd)
          //  sa_valid_cmd <= 0;

    endtask
    
    /*
    This task initializes to proper value all variables that are necessary for each test before it starts.
    */
    task initTest();
        automatic int i;

        total_time  = 0;
        timer       = 0;

        for(i = 0; i < VC_NUM; i++)
        begin
            va_done[i]          = 0;
            head_done[i]        = 0;
            flit_num[i]         = 0;
            flit_to_read[i]     = 0;
            flit_to_read_next[i]= 0;
            insert_not_compl[i] = 0;
        end
        
        if(test_mode == MULTI)
        begin
            vc_num = 0;
            vc_num_next = 0;
            insert_not_compl = {1'b1,1'b1};
        end
        else
            insert_not_compl[vc_num]= 1;
                    
    endtask
    
    /*
    Update the vc identifier
    */
    task vcChange();
        vc_num_next++;
        vc_num <= vc_num_next;
    endtask
    
endmodule