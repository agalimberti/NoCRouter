`timescale 1ns / 1ps

import noc_params::*; 

module tb_router;

    // Testbench
    flit_t flit_written[PORT_NUM];
    flit_t flit_queue[PORT_NUM][$];
    flit_t flit_read[PORT_NUM];
    
    int x_curr, y_curr;
    int num_op, timer, total_time, x_dest, y_dest;
    int pkt_size[PORT_NUM], flit_num[PORT_NUM], flit_to_read[PORT_NUM], flit_to_read_next[PORT_NUM], multiple_head[PORT_NUM], wait_time[PORT_NUM];
    
    logic [PORT_NUM-1:0] insert_not_compl, head_done;
    logic [PORT_SIZE-1:0] port_num, test_port_num;
    logic [VC_SIZE-1:0] vc_num, vc_num_next;

    logic clk;
    logic rst;
    wire [VC_NUM-1:0] error_o [PORT_NUM-1:0];

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
    router2router local_up();
    router2router north_up();
    router2router south_up();
    router2router west_up();
    router2router east_up();
    router2router local_down();
    router2router north_down();
    router2router south_down();
    router2router west_down();
    router2router east_down();

    router #(
        .BUFFER_SIZE(8),
        .X_CURRENT(MESH_SIZE_X/2),
        .Y_CURRENT(MESH_SIZE_Y/2)
    )
    router (
        .clk(clk),
        .rst(rst),
        //router2router.upstream 
        .router_if_local_up(local_up),
        .router_if_north_up(north_up),
        .router_if_south_up(south_up),
        .router_if_west_up(west_up),
        .router_if_east_up(east_up),
        //router2router.downstream
        .router_if_local_down(local_down),
        .router_if_north_down(north_down),
        .router_if_south_down(south_down),
        .router_if_west_down(west_down),
        .router_if_east_down(east_down),
        .error_o(error_o)
    );

    routers_mock routers_mock (
        .router_if_local_up(local_down),
        .router_if_north_up(north_down),
        .router_if_south_up(south_down),
        .router_if_west_up(west_down),
        .router_if_east_up(east_down),
        .router_if_local_down(local_up),
        .router_if_north_down(north_up),
        .router_if_south_down(south_up),
        .router_if_west_down(west_up),
        .router_if_east_down(east_up),
        .data_out(data_out),
        .is_valid_out(valid_flit_out),
        .is_on_off_in(on_off_in),
        .is_allocatable_in(is_allocatable_in),
        .data_in(data_in),
        .is_valid_in(valid_flit_in),
        .is_on_off_out(on_off_out),
        .is_allocatable_out(is_allocatable_out)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        
        /*
        Always check the settings for x and y positions
        of the router
        */
        x_curr = 2;
        y_curr = 2;
        
        /*
        Standard 4 flits packet
        */
        x_dest = 2;
        y_dest = 2;
        test_port_num = 0;
        vc_num = 0;
        multiple_head[test_port_num] = 0;
        pkt_size[test_port_num] = 4;
        wait_time[test_port_num] = 3;
        test(test_port_num);
        
        //repeat(3) @(posedge clk);
        
        test(test_port_num);
        
        #30 $finish;
    end

    // Clock update
    always #5 clk = ~clk;

    // Output dump
    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_router);
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
        flit_written[port_num].flit_label = lab;
        flit_written[port_num].vc_id      = vc_num;
        if(lab == HEAD)
            begin
                flit_written[port_num].data.head_data.x_dest  = x_dest;
                flit_written[port_num].data.head_data.y_dest  = y_dest;
                flit_written[port_num].data.head_data.head_pl = {HEAD_PAYLOAD_SIZE{num_op}};
            end
        else
                flit_written[port_num].data.bt_pl = {FLIT_DATA_SIZE{num_op}};
    endtask
    
    // Write flit into the DUT module
    task write_flit();
        begin
            valid_flit_in[port_num]  <= 1;
            data_in[port_num]        <= flit_written[port_num];
        end
        num_op++;
        push_flit();
    endtask
    
    /*
    Push the actual flit into the proper queue only under specific conditions.
    In particular, the push operation is done if the HEAD flit hasn't been inserted yet or
    the flit to insert is not an HEAD one (multiple_head==0).
    */
    task push_flit();
        if( ~head_done[port_num] | multiple_head[port_num] == 0)
        begin
            $display("push %d , dest %d", $time, computeOutport(x_dest, y_dest));
            flit_queue[computeOutport(x_dest, y_dest)].push_back(flit_written[port_num]);
            flit_to_read_next[port_num]++;
        end
    endtask
    
    /*
    This is the main task of the testbench: after an initial phase of initialization, it repeatedly calls the 4 subtasks
    until there is no flits to read or the insertion of all the flits of a packet has not been completed (these two conditions
    are checked by means of a separate task).
    
    Parameters
        curr_port: is the port identifier in which the packet will be inserted.
    */
    task test(input logic [VC_SIZE-1:0] curr_port);
        
        port_num = curr_port;
        initTest();

        $display("Packet size: %d", pkt_size[port_num]);
        while(checkEndConditions()) @(posedge clk)
        begin
            $display("Time %d, port_num: %d total time:%d, to read %d, timer %d",$time, port_num, total_time, flit_to_read[port_num], timer);
            
            insertFlit();
            total_time++;
            checkFlits();
            flit_to_read[port_num] = flit_to_read_next[port_num];
            
            $display("Time %d, port_num: %d total time:%d, to read %d, timer %d",$time, port_num, total_time, flit_to_read_next[port_num], timer);
        end

    endtask
    
    /*
    This task checks whether there are flits still to read from the queues and that the insertion of all packets into the ports has not yet completed.
    The checks is done for all ports of the router. 
    */
    function bit unsigned checkEndConditions();
        automatic int i;
    
        for(i = 0; i < PORT_NUM; i++)
        begin
            if(flit_queue[i].size()>0 | insert_not_compl[i])
                return 1;
        end
        return 0;
    endfunction
    
    /*
    This task is responsible of calling the proper writing task according to some conditions.
    */
    task insertFlit();
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
    This task just updates the counters that control the flits insertion and 
    then pops out of the proper queue the next flit to be read
    */
    task readFlit();
        $display("Read simtime %d, ttime %d, portnum %d, toread %d",$time, total_time, port_num,flit_to_read[port_num]);
        begin
            num_op++;
            flit_to_read_next[port_num]--;
            flit_read[computeOutport(x_dest, y_dest)] = flit_queue[computeOutport(x_dest, y_dest)].pop_front();
        end
    endtask
    
    /*
    Checks the correspondance between the flit extracted from the queue and the one in data_o; this check is done for all the port where
    the flit in output is valid. 
    If the check goes wrong an error message is displayed and the testbench ends.
    */
    
    task checkFlits();
        automatic  int i;
        
        @(negedge clk)
        $display("Check %d, port_num %d, toread %d, valid_flit_out %b",$time, port_num, flit_to_read[port_num],valid_flit_out[computeOutport(x_dest, y_dest)]); 
        begin 
            for(i=0; i<PORT_NUM; i++)
            begin
                if(valid_flit_out[i])
                begin
                    readFlit();
                    if(~(flit_read[i] === data_out[i]))
                    begin
                        $display("[READ] FAILED %d", $time);
                        //#10 $finish;
                    end
                    else
                        $display("[READ] PASSED %d", $time);
                end 
            end //end for
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
            valid_flit_in[i]    = 0;
            head_done[i]        = 0;
            flit_num[i]         = 0;
            flit_to_read[i]     = 0;
            flit_to_read_next[i]= 0;
            insert_not_compl[i] = 0;
            for(j=0; j<VC_NUM; j++)
            begin
                is_allocatable_in[i][j] = 1; // means that downstream router is always available
                on_off_in[i][j] = 1;
            end
        end
            
        insert_not_compl[port_num] = 1;
    endtask
    
    /*
    Compute the outport for the current packet according to
    the position of the router into the mesh and the destionation positions.
    */
    function int computeOutport(input int xdest, input int ydest);
        automatic int x_off, y_off, res;
        x_off = xdest - x_curr;
        y_off = ydest - y_curr;
        
        if(x_off < 0)
            res = 3; //WEST
        else if (x_off > 0)
            res = 4; //EAST
        else if (y_off < 0)
            res = 1; //NORTH
        else if (y_off > 0)
            res = 2; //SOUTH
        else // x_off=0 and y_off=0
            res = 0; //LOCAL
        return res;
    endfunction

endmodule

/*
    ROUTERS MOCK MODULE
*/
module routers_mock #()(
    router2router.upstream router_if_local_up,
    router2router.upstream router_if_north_up,
    router2router.upstream router_if_south_up,
    router2router.upstream router_if_west_up,
    router2router.upstream router_if_east_up,
    router2router.downstream router_if_local_down,
    router2router.downstream router_if_north_down,
    router2router.downstream router_if_south_down,
    router2router.downstream router_if_west_down,
    router2router.downstream router_if_east_down,

    //ports to propagate to downstream interfaces
    output flit_t data_out [PORT_NUM-1:0],
    output logic [PORT_NUM-1:0] is_valid_out,
    input logic [PORT_NUM-1:0] [VC_NUM-1:0] is_on_off_in,
    input logic [PORT_NUM-1:0] [VC_NUM-1:0] is_allocatable_in,

    //ports to propagate to upstream interfaces
    input flit_t data_in [PORT_NUM-1:0],
    input logic is_valid_in [PORT_NUM-1:0],
    output logic [VC_NUM-1:0] is_on_off_out [PORT_NUM-1:0],
    output logic [VC_NUM-1:0] is_allocatable_out [PORT_NUM-1:0]
);

    always_comb
    begin
       
        router_if_local_up.data = data_in[LOCAL];
        router_if_north_up.data = data_in[NORTH];
        router_if_south_up.data = data_in[SOUTH];
        router_if_west_up.data  = data_in[WEST];
        router_if_east_up.data  = data_in[EAST];
        
        router_if_local_up.is_valid = is_valid_in[LOCAL];
        router_if_north_up.is_valid = is_valid_in[NORTH];
        router_if_south_up.is_valid = is_valid_in[SOUTH];
        router_if_west_up.is_valid  = is_valid_in[WEST];
        router_if_east_up.is_valid  = is_valid_in[EAST];
        
        is_on_off_out[LOCAL] = router_if_local_up.is_on_off;
        is_on_off_out[NORTH] = router_if_north_up.is_on_off;
        is_on_off_out[SOUTH] = router_if_south_up.is_on_off;
        is_on_off_out[WEST]  = router_if_west_up.is_on_off;
        is_on_off_out[EAST]  = router_if_east_up.is_on_off;
        
        is_allocatable_out[LOCAL] = router_if_local_up.is_allocatable;
        is_allocatable_out[NORTH] = router_if_north_up.is_allocatable;
        is_allocatable_out[SOUTH] = router_if_south_up.is_allocatable;
        is_allocatable_out[WEST]  = router_if_west_up.is_allocatable;
        is_allocatable_out[EAST]  = router_if_east_up.is_allocatable;
        
        data_out[LOCAL] = router_if_local_down.data;
        data_out[NORTH] = router_if_north_down.data;
        data_out[SOUTH] = router_if_south_down.data;
        data_out[WEST]  = router_if_west_down.data;
        data_out[EAST]  = router_if_east_down.data;
        
        is_valid_out[LOCAL] = router_if_local_down.is_valid;
        is_valid_out[NORTH] = router_if_north_down.is_valid;
        is_valid_out[SOUTH] = router_if_south_down.is_valid;
        is_valid_out[WEST]  = router_if_west_down.is_valid;
        is_valid_out[EAST]  = router_if_east_down.is_valid;
                
        router_if_local_down.is_on_off = is_on_off_in[LOCAL];
        router_if_north_down.is_on_off = is_on_off_in[NORTH];
        router_if_south_down.is_on_off = is_on_off_in[SOUTH];
        router_if_west_down.is_on_off  = is_on_off_in[WEST];
        router_if_east_down.is_on_off  = is_on_off_in[EAST];
        
        router_if_local_down.is_allocatable = is_allocatable_in[LOCAL];
        router_if_north_down.is_allocatable = is_allocatable_in[NORTH];
        router_if_south_down.is_allocatable = is_allocatable_in[SOUTH];
        router_if_west_down.is_allocatable  = is_allocatable_in[WEST];
        router_if_east_down.is_allocatable  = is_allocatable_in[EAST];
        
    end 
endmodule