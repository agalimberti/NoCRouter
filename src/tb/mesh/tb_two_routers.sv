 `timescale 1ns / 1ps

import noc_params::*; 

module tb_two_routers;

   localparam ROUTER_NUM = 2; // 0 = upstream, 1 = downstream
   localparam BUFFER_SIZE = 8;

   // Testbench signals
   flit_t flit_written[PORT_NUM];
   flit_t packet_queue[PORT_NUM][$];
   flit_t flit_read[PORT_NUM];
   
   int x_curr, y_curr, num_op, timer;
   int pkt_size[$], flit_num[$], flit_to_read[$], flit_to_read_next[$], multiple_head[$], wait_time[$],x_dest[$], y_dest[$], packet_id[$];
   int x_dest_addr[4], y_dest_addr[4];
   logic [PORT_SIZE-1:0] test_port_num[$];
   logic [PORT_NUM-1:0] insert_not_compl, head_done;
   logic [VC_SIZE-1:0] vc_num [$];
   logic clk;
   logic rst;

   wire [VC_NUM-1:0] error_o [ROUTER_NUM-1:0][PORT_NUM-1:0];

   //connections from upstream
   flit_t u_data_out [PORT_NUM-1:0];
   flit_t d_data_out [PORT_NUM-1:0];
   logic [PORT_NUM-1:0] u_valid_flit_out, d_valid_flit_out;
   logic [PORT_NUM-1:0] [VC_NUM-1:0] u_on_off_in, d_on_off_in;
   logic [PORT_NUM-1:0] [VC_NUM-1:0] u_is_allocatable_in, d_is_allocatable_in;

   //connections from downstream
   flit_t u_data_in [PORT_NUM-1:0];
   flit_t d_data_in [PORT_NUM-1:0];
   logic u_valid_flit_in [PORT_NUM-1:0];
   logic d_valid_flit_in [PORT_NUM-1:0];
   logic [VC_NUM-1:0] u_on_off_out [PORT_NUM-1:0];
   logic [VC_NUM-1:0] d_on_off_out [PORT_NUM-1:0];
   logic [VC_NUM-1:0] u_is_allocatable_out [PORT_NUM-1:0];
   logic [VC_NUM-1:0] d_is_allocatable_out [PORT_NUM-1:0];

   //DUT Interfaces Instantiation
   router2router routers_link();

   router2router u_local_down();
   router2router u_north_down();
   router2router u_south_down();
   router2router u_west_down();
   router2router u_east_down();

   router2router d_local_up();
   router2router d_north_up();
   router2router d_south_up();
   router2router d_west_up();
   router2router d_east_up();
   
   //(useless but necessary interfaces)
   router2router u_local_up();
   router2router u_north_up();
   router2router u_south_up();
   router2router u_west_up();
   router2router d_local_down();
   router2router d_north_down();
   router2router d_south_down();
   router2router d_east_down();
   router2router um_local_down();
   router2router um_north_down();
   router2router um_south_down();
   router2router um_west_down();
   router2router um_east_down();
   router2router dm_local_up();
   router2router dm_north_up();
   router2router dm_south_up();
   router2router dm_west_up();
   router2router dm_east_up();


   //DUT Instantiation
   router #(
       .BUFFER_SIZE(BUFFER_SIZE),
       .X_CURRENT(1),
       .Y_CURRENT(1)
   )
   upstream_router (
       .clk(clk),
       .rst(rst),
       .error_o(error_o[0]),
       //router2router.upstream 
       .router_if_east_up(routers_link),
       //router2router.downstream
       .router_if_local_down(u_local_down),
       .router_if_north_down(u_north_down),
       .router_if_south_down(u_south_down),
       .router_if_west_down(u_west_down),
       .router_if_east_down(u_east_down),
       //mock if
       .router_if_local_up(u_local_up),
       .router_if_north_up(u_north_up),
       .router_if_south_up(u_south_up),
       .router_if_west_up(u_west_up)
    );

   router #(
       .BUFFER_SIZE(BUFFER_SIZE),
       .X_CURRENT(2),
       .Y_CURRENT(1)
   )
   downstream_router (
       .clk(clk),
       .rst(rst),
       .error_o(error_o[1]),
       //router2router.upstream 
       .router_if_local_up(d_local_up),
       .router_if_north_up(d_north_up),
       .router_if_south_up(d_south_up),
       .router_if_west_up(d_west_up),
       .router_if_east_up(d_east_up),
       //router2router.downstream
       .router_if_west_down(routers_link),
       //mock if
       .router_if_local_down(d_local_down),
       .router_if_north_down(d_north_down),
       .router_if_south_down(d_south_down),
       .router_if_east_down(d_east_down)
   );
   
   router_mock upstream_mock (
       .router_if_local_up(u_local_down),
       .router_if_north_up(u_north_down),
       .router_if_south_up(u_south_down),
       .router_if_west_up(u_west_down),
       .router_if_east_up(u_east_down),
       .router_if_local_down(um_local_down),
       .router_if_north_down(um_north_down),
       .router_if_south_down(um_south_down),
       .router_if_west_down(um_west_down),
       .router_if_east_down(um_east_down),
       .data_out(u_data_out),
       .is_valid_out(u_valid_flit_out),
       .is_on_off_in(u_on_off_in),
       .is_allocatable_in(u_is_allocatable_in),
       .data_in(u_data_in),
       .is_valid_in(u_valid_flit_in),
       .is_on_off_out(u_on_off_out),
       .is_allocatable_out(u_is_allocatable_out)
   );
   
   router_mock downstream_mock (
       .router_if_local_down(d_local_up),
       .router_if_north_down(d_north_up),
       .router_if_south_down(d_south_up),
       .router_if_west_down(d_west_up),
       .router_if_east_down(d_east_up),
       .router_if_local_up(dm_local_up),
       .router_if_north_up(dm_north_up),
       .router_if_south_up(dm_south_up),
       .router_if_west_up(dm_west_up),
       .router_if_east_up(dm_east_up),
       .data_out(d_data_out),
       .is_valid_out(d_valid_flit_out),
       .is_on_off_in(d_on_off_in),
       .is_allocatable_in(d_is_allocatable_in),
       .data_in(d_data_in),
       .is_valid_in(d_valid_flit_in),
       .is_on_off_out(d_on_off_out),
       .is_allocatable_out(d_is_allocatable_out)
   );

   initial
   begin
       dump_output();
       initialize();
       clear_reset();
       
       /*
       WARNING: always check the settings for x and y positions
       of the router, passed as parameter in dut instantiation
       */
       x_curr = upstream_router.X_CURRENT;
       y_curr = upstream_router.Y_CURRENT;

       main_test();

       $display("[All tests PASSED]");
       #20 $finish;
   end
       // Clock update
   always #5 clk = ~clk;

   // Output dump
   task dump_output();
       $dumpfile("out.vcd");
       $dumpvars(0, tb_two_routers);
   endtask

   // Initialize signals
   task initialize();
       clk     <= 0;
       rst     = 1;
   endtask
   
   // De-assert the reset signal
   task clear_reset();
       @(posedge clk);
           rst <= 0;
   endtask
   
   /*
   Create a flit to be written in both DUT and packet queue, with the given flit label and packet number in 
   the port identifier passed as port_id parameter.
   The flit to be written is created accordingly to its label, that is, HEAD and HEADTAIL flits are different
   with respect to BODY and TAIL ones.
   The last parameters, id and pkt_id, respectively refer to the identifier of the test case and the id of the packet 
   that will be inserted.
   */
   task automatic create_flit(input flit_label_t lab, input logic [PORT_SIZE-1:0] port_id, input integer id, input int pkt_id);
       flit_written[port_id].flit_label = lab;
       flit_written[port_id].vc_id      = vc_num[id];
       if(lab == HEAD | lab == HEADTAIL)
           begin
               flit_written[port_id].data.head_data.x_dest  = x_dest[id];
               flit_written[port_id].data.head_data.y_dest  = y_dest[id];
               flit_written[port_id].data.head_data.head_pl = pkt_id;
           end
       else
               flit_written[port_id].data.bt_pl = pkt_id;
   endtask
   
   /*
   Write flit into the DUT module in the proper port, given by the port identifier as input;
   while writing a flit into a port, the relative valid flag is set to 1.
   The last parameters, id and pkt_id, respectively refer to the identifier of the test case and the id of the packet 
   that will be inserted.
   Finally, the push task is called.
   */
   task automatic write_flit(input logic [PORT_SIZE-1:0] port_id, input integer pkt_id, input integer id);
       begin
           u_valid_flit_in[port_id]  <= 1;
           u_data_in[port_id]        <= flit_written[port_id];
       end
       num_op++;
       push_flit(port_id, pkt_id, id);
   endtask
   
   /*
   Push the actual flit into the proper queue only under specific conditions.
   In particular, the push operation is done if the HEAD flit hasn't been inserted yet or
   the flit to insert is not an HEAD one (i.e. multiple_head==0).
   The two last parameters, id and pkt_id, respectively refer to the identifier of the test case and the id of the packet 
   that will be inserted.
   */
   task automatic push_flit(input logic [PORT_SIZE-1:0] port_id, input integer pkt_id, input integer id);
       if( ~head_done[port_id] | int'(multiple_head[id]) == 0)
       begin
           $display("push %d, dest %d, pktid %d", $time, computeOutport(x_dest[port_id], y_dest[port_id]), pkt_id);
           packet_queue[pkt_id].push_back(flit_written[port_id]);
           $display("Pushed flit, queue size %d", packet_queue[pkt_id].size());
           flit_to_read_next[pkt_id]++;
       end
   endtask
   
   /*
   This is the main task of the testbench: after a preliminary phase of initialization, it repeatedly calls the 3 subtasks
   until there are no flits to read and the insertion of the flits of all the packets has not been completed (these two conditions
   are checked by means of a function).
   */
   task test();
       $display("\n*** NEW TEST * %d ***", $time);
       initTest();
       while(checkEndConditions()) @(posedge clk)
       begin    
           $display("*");        
           insertFlit();
           checkFlits();
           updateFlitToRead();
       end
   endtask
   
   /*
   This function updates the flit_to_read variable of all the ports in the test case vector.
   */
   function void updateFlitToRead();
       automatic int i;
       
       for(i=0; i<test_port_num.size(); i++)
           flit_to_read[packet_id[i]] = flit_to_read_next[packet_id[i]];   
   endfunction
   
   /*
   This task checks whether there are flits still to read from the queues and that the insertion of all packets into the ports has not yet completed.
   The checks is done for all ports indicated in the test_port_num list. 
   */
   function bit unsigned checkEndConditions();
       automatic int i, pid;
   
       for(i = 0; i < test_port_num.size(); i++)
       begin
           if(packet_queue[i].size()>0 | insert_not_compl[test_port_num[i]])
               return 1;
       end
       return 0;
   endfunction
   
   /*
   This task is responsible of understanding the type of the next flit that will be inserted
   and calling the proper writing task according to some conditions.
   */
   task insertFlit();
       automatic int i,j, pkt_id, p_size;
       automatic logic [PORT_SIZE-1:0] port_id;
   
       for(i=0; i<test_port_num.size(); i++)
       begin
           for(j=0; j<PORT_SIZE; j++)
           begin
               port_id[j] = test_port_num[i][j];
           end
           
           pkt_id = int'(packet_id[i]);
           p_size = pkt_size[i];
           
           $display("* i %d, port id %d, pkt id %d, pkt size %d", i, port_id, pkt_id, p_size);

           if(p_size == 1)
           begin
               flit_num[port_id]++;
               if(int'(flit_num[port_id]) == 1)
               begin
                   create_flit(HEADTAIL, port_id, i, pkt_id);
                   write_flit(port_id, pkt_id, i);
                   insert_not_compl[port_id] <= 0;
               end
               else    
                   u_valid_flit_in[port_id] <= 0;
           end
           else //end single flit part
           begin
               if(timer == 0 & insert_not_compl[port_id] & u_on_off_out[port_id][vc_num[i]])
               begin
                   flit_num[port_id]++;
                                       
                   if(int'(flit_num[port_id]) == 1 | int'(multiple_head[i]) > 0)
                       begin
                           create_flit(HEAD, port_id, i, pkt_id);
                           write_flit(port_id, pkt_id, i);
                           multiple_head[i]--;
                           head_done[port_id] = 1;
                       end
                   else
                   begin
                       multiple_head[i] = 0;
                       if (int'(flit_num[port_id]) == p_size)
                       begin
                           create_flit(TAIL, port_id, i, pkt_id);
                           write_flit(port_id, pkt_id, i);
                           insert_not_compl[port_id] <= 0; // Deassert completion flag
                       end
                       else
                       begin
                           create_flit(BODY, port_id, i, pkt_id);
                           write_flit(port_id, pkt_id, i);
                       end
                   end
                   timer = wait_time[port_id]; // reset timer
               end
               else
               begin
                   u_valid_flit_in[port_id] <= 0;
                   if(timer > 0)
                       timer--;
               end
           end // end multiple flit part
       end //end for
   endtask
   
   /*
   This task just updates the counters that control the flits insertion and then pops out of the proper queue the next flit to be read. 
   The pkt_id refers to the identifier of the packet which is going to be read from the router and it is used to properly choose the where to 
   read from and where to put the read flit.
   */
   task automatic readFlit(input int pkt_id);
       automatic int pid;
//       $display("Read simtime %d, portnum %d, toread %d destport %d",$time, port_id,flit_to_read[port_id], dest_port_id);
       begin
           num_op++;
           flit_to_read_next[pkt_id]--;
           flit_read[pkt_id] = packet_queue[pkt_id].pop_front();
       end
   endtask
   
   /*
   Checks the correspondance between the flit extracted from the queue and the one in data_o; this check is done for all the port where
   the flit in output is valid. 
   If the check goes wrong an error message is displayed and the testbench ends.
   */
   task checkFlits();
       automatic  int i, pkt_id;
       automatic logic [PORT_SIZE-1:0] port_id;
       
       @(negedge clk)
//        $display("Check %d, port_num %d, toread %d, valid_flit_out %b",$time, port_num, flit_to_read[port_num],valid_flit_out[computeOutport(x_dest, y_dest)]); 
       begin 
           for(i=0; i<PORT_NUM; i++)
           begin
               if(d_valid_flit_out[i])
               begin
                   if(d_data_out[i].flit_label == HEAD || d_data_out[i].flit_label == HEADTAIL)
                       pkt_id = d_data_out[i].data.head_data.head_pl;
                   else
                       pkt_id = d_data_out[i].data.bt_pl;
                       
                   readFlit(pkt_id);
                   
                   if(~checkFlitFields(flit_read[port_id],d_data_out[port_id]))
                   begin
                       $display("[READ] FAILED %d", $time);
                       #10 $finish;
                   end
                   else
                       $display("[READ] PASSED %d", $time);
                end // end if
           end // end for
       end
   endtask 
   
   /*
   The function checks whether the label and the content of the two given flits are equal or not.
   Notice that the check doesn't consider the vc identifier, which is computed by the internal SA module.
   The objective in this case is only to verify that the packet exiting from the router maintains the same destionation
   address and data payload.
   */
   function bit checkFlitFields(flit_t flit_read, flit_t flit_out);
       if(flit_read.flit_label === flit_out.flit_label & 
           flit_read.data === flit_out.data)
           return 1;
       return 0;
   endfunction
   
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
   
   /*
   This task initializes to proper value all variables that are necessary for each test before it starts.
   */
   task initTest();
       automatic int i,j;
       timer       = 0;
       
       // Values reset
       for(i=0;i<PORT_NUM;i++)
       begin
           u_valid_flit_in[i]    = 0;
           head_done[i]        = 0;
           flit_num[i]         = 0;
           flit_to_read[i]     = 0;
           flit_to_read_next[i]= 0;
           insert_not_compl[i] = 0;
           
           for(j=0; j<VC_NUM; j++)
           begin
               d_is_allocatable_in[i][j] = 1;    // means that downstream router is always available
               d_on_off_in[i][j] = 1;            // always do "read" operation from the router  
               u_is_allocatable_in[i][j] = 1;    
               u_on_off_in[i][j] = 1;         
           end
       end
       
       // Assert flag for each port in the test port list
       for(i=0; i<test_port_num.size(); i++)    
           insert_not_compl[test_port_num[i]] = 1;
   endtask

    /*
    * This task is used to set all the requested parameters and to effectively 
    * call the task that does the test.
    * The test is repeated for all input and output ports combinations  
    * except the pair of ports that are used to connect together the two routers. 
    */
    task main_test();
        automatic int i,j;
        
        // Setting values of test parameters
        packet_id = {0};
        vc_num = {0};
        multiple_head = {0};
        pkt_size = {4};
        wait_time = {0};
        vc_num = {0};

        // Precomputed destination addresses to properly check all the
        // output ports of the downstream router.
        // In order: North, East, South and Local
        x_dest_addr = {2,3,2,2};
        y_dest_addr = {0,1,2,1};
        
        // Test #1-16: for every pair of input port of the first router
        // and output port of the second, a simple insertion test is executed 
        for(i=0; i<(PORT_NUM-1); i++)
        begin
            //setting current test port number
            test_port_num = {i};
            
            for(j=0; j<(PORT_NUM-1); j++)
            begin
                //update destination address
                x_dest[0] = x_dest_addr[j];
                y_dest[0] = y_dest_addr[j];
            
                //recall test task
                $display("Test %d",i);
                test();
            end
        end
   endtask
   
endmodule

/*
   ROUTERS MOCK MODULE
*/
module router_mock (
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