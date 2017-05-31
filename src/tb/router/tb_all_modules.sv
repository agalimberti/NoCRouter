`timescale 1ns / 1ps

import noc_params::*;

module tb_all_modules;

    // Testbench
    flit_t flit_written;
    flit_t flit_queue[PORT_NUM][$];
    flit_t flit_read;
    
    int num_op, timer, total_time, x_dest, y_dest;
    int pkt_size[PORT_NUM], flit_num[PORT_NUM], flit_to_read[PORT_NUM], flit_to_read_next[PORT_NUM], multiple_head[PORT_NUM], 
        wait_time[PORT_NUM];
    
    logic [PORT_NUM-1:0] insert_not_compl, head_done;
    logic [PORT_SIZE-1:0] port_num, test_port_num;
    logic [VC_SIZE-1:0] vc_num, vc_num_next;

    logic clk;
    logic rst;
    logic [VC_NUM-1:0] error_o [PORT_NUM-1:0];

    //connections from upstream
    flit_t data_out [PORT_NUM-1:0];
    logic [PORT_NUM-1:0] valid_flit_out;
    logic [PORT_NUM-1:0] [VC_NUM-1:0] on_off_in;
    logic [PORT_NUM-1:0] [VC_NUM-1:0] is_allocatable_in;

    //connections from downstream
    flit_t data_in [PORT_NUM-1:0];
    logic valid_flit_in [PORT_NUM-1:0];
    logic [VC_NUM-1:0] on_off_out [PORT_NUM-1:0];
    logic [VC_NUM-1:0] is_allocatable_out [PORT_NUM-1:0];

    //DUT Instantiation
    input_block2crossbar ib2xbar_if();
    input_block2switch_allocator ib2sa_if();
    input_block2vc_allocator ib2va_if();
    switch_allocator2crossbar sa2xbar_if();

    input_block #(
        .PORT_NUM(5),
        .BUFFER_SIZE(8),
        .X_CURRENT(MESH_SIZE_X/2),
        .Y_CURRENT(MESH_SIZE_Y/2)
    )
    input_block (
        .rst(rst),
        .clk(clk),
        .data_i(data_in),
        .valid_flit_i(valid_flit_in),
        .crossbar_if(ib2xbar_if),
        .sa_if(ib2sa_if),
        .va_if(ib2va_if),
        .on_off_o(on_off_out),
        .vc_allocatable_o(is_allocatable_out),
        .error_o(error_o)
    );

    crossbar #(
    )
    crossbar (
        .ib_if(ib2xbar_if),
        .sa_if(sa2xbar_if),
        .data_o(data_out)
    );

    switch_allocator #(
    )
    switch_allocator (
        .rst(rst),
        .clk(clk),
        .on_off_i(on_off_in),
        .ib_if(ib2sa_if),
        .xbar_if(sa2xbar_if),
        .valid_flit_o(valid_flit_out)
    );
    
    vc_allocator #(
    )
    vc_allocator (
        .rst(rst),
        .clk(clk),
        .idle_downstream_vc_i(is_allocatable_in),
        .ib_if(ib2va_if)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();

        /*
        Standard 4 flits packet
        */
        x_dest = 2;
        y_dest = 2;
        test_port_num = 1;
        vc_num = 0;
        multiple_head[test_port_num] = 0;
        pkt_size[test_port_num] = 4;
        wait_time[test_port_num] = 0;
        test(test_port_num);
        
        #50 $finish;
    end

    // Clock update
    always #5 clk = ~clk;

    // Output dump
    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_all_modules);
    endtask

    // Initialize signals
    task initialize();
        clk             <= 0;
        rst             = 1;
    endtask
    
    // De-assert the reset signal
    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask
    
    // Create a flit to be written in both DUT and queue
    task create_flit(input flit_label_t lab);
        flit_written.flit_label = lab;
        flit_written.vc_id      = vc_num;
        if(lab == HEAD)
            begin
                flit_written.data.head_data.x_dest  = x_dest;
                flit_written.data.head_data.y_dest  = y_dest;
                flit_written.data.head_data.head_pl = {HEAD_PAYLOAD_SIZE{num_op}};
            end
        else
                flit_written.data.bt_pl = {FLIT_DATA_SIZE{num_op}};
    endtask
    
    // Write flit into the DUT module
    task write_flit();
        begin
            valid_flit_in[port_num]  <= 1;
            data_in[port_num]        <= flit_written;
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
        flit_written.vc_id = vc_num;
        if( ~head_done[port_num] | multiple_head[port_num] == 0)
        begin
            $display("push %d", $time);
            flit_queue[port_num].push_back(flit_written);
            flit_to_read_next[port_num]++;

        end
    endtask
    
    /*
    This is the main task of the testbench: after an initial phase of initialization, it repeatedly calls the 4 subtasks
    until there is no flits to read or the insertion of all the flits of a packet has not been completed (these two conditions
    are checked by means of a separate task).
    
    Parameters
        curr_port: is the vc identifier in which the packet will be inserted. It is relevant only the test mode in SINGLE. 
    */
    task test(input logic [VC_SIZE-1:0] curr_port);
        
        port_num = curr_port;
        initTest();

        $display("Packet size: %d", pkt_size[port_num]);
        repeat(20) @(posedge clk)
        begin
            $display("Time %d,port_num: %d total time:%d, to read %d, timer %d",$time, port_num, total_time, flit_to_read[port_num], timer);
            
            insertFlit();
            checkFlits();
            
            flit_to_read[port_num] = flit_to_read_next[port_num];
            total_time++;
            $display("Time %d,port_num: %d total time:%d, to read %d, timer %d",$time, port_num, total_time, flit_to_read_next[port_num], timer);
        end

    endtask
    
    /*
    This task checks whether there are flits still to be read and that the insertion of a packet into the buffer has not yet completed.
    The checks is done for all VCs. 
    */
    function bit unsigned checkEndConditions();
        automatic int i;
    
        for(i = 0; i < PORT_NUM; i++)
        begin
            if( flit_to_read[i] > 0 | insert_not_compl[i] == 1)
                return 1;
        end
        return 0;
    endfunction
    
    /*
    This task is responsible of calling the proper writing task according to some conditions.
    */
    task insertFlit();
    //$display("head cnt %d", multiple_head[vc_num]);
    if(pkt_size[port_num] == 1)
    begin
        flit_num[port_num]++;
        if(flit_num[port_num] == 1)
        begin
            create_flit(HEADTAIL);
            write_flit();
            insert_not_compl[port_num] <= 0;
        end
        else    
            valid_flit_in[port_num] <= 0;
    end
    else
    begin
        if(timer == 0 & insert_not_compl[port_num])
        begin
            flit_num[port_num]++;
                                
            if(flit_num[port_num] == 1 | multiple_head[port_num] > 0)
                begin
                    create_flit(HEAD);
                    write_flit();
                    multiple_head[port_num]--;
                    head_done[port_num] = 1;
                end
            else
            begin
                multiple_head[port_num] = 0;
                if (flit_num[port_num] == pkt_size[port_num])
                begin
                    create_flit(TAIL);
                    write_flit();
                    insert_not_compl[port_num] <= 0; // Deassert completion flag
                end
            
                else
                begin
                    create_flit(BODY);
                    write_flit();
                end
            end
            timer = wait_time[port_num]; // reset timer
        end
        else
        begin
            valid_flit_in[port_num] <= 0;
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
        $display("Read simtime %d, ttime %d, vcnum %d toread %d",$time, total_time, port_num,flit_to_read[port_num]);
        //if(flit_to_read[vc_num] > 0 & va_done[vc_num] & total_time>va_time[vc_num]+sa_time[vc_num])
        begin
            num_op++;
            flit_to_read_next[port_num]--;
            flit_read = flit_queue[port_num].pop_front();
            
            //checkFlits();
        end
    endtask
    
    /*
    Checks the correspondance between the flit extracted from the queue and the one in data_o. 
    The check is done only whether the given vc is not empty or there are still some flits that have to be read.
    If the check goes wrong an error message is displayed and the testbench ends.
    */
    
    task checkFlits();
        @(negedge clk)
        //$display("Check %d, vcnum %d, empty %d, toread %d",$time, vc_num,is_empty_o[port_num], flit_to_read[port_num]); 
        begin 
            if(valid_flit_out[port_num])
            begin
                readFlit();
                if(~(flit_read === data_out[port_num]))
                begin
                    $display("[READ] FAILED %d", $time);
                    //#10 $finish;
                end
                else
                    $display("[READ] PASSED %d", $time);
            end 
        end
    endtask 
    
    /*
    This task initializes to proper value all variables that are necessary for each test before it starts.
    */
    task initTest();
        automatic int i,j;
        total_time  = 0;
        timer       = 0;
        
        for(i=0;i<PORT_NUM;i++)
        begin
            valid_flit_in[i] = 0;
            head_done[i]        = 0;
            flit_num[i]         = 0;
            flit_to_read[i]     = 0;
            flit_to_read_next[i]= 0;
            insert_not_compl[i] = 0;
            for(j=0; j<VC_NUM; j++)
            begin
                is_allocatable_in[i][j] = 0;
                on_off_in[i][j] = 1;
            end
        end
            
        insert_not_compl[port_num] = 1;
    endtask

endmodule