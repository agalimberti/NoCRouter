`timescale 1ns / 1ps

import noc_params::*;

module tb_vc_allocator #(
);
    /*VC ALLOCATOR*/

    logic rst, clk;

    logic [PORT_NUM-1:0][VC_NUM-1:0] idle_downstream_vc_i;

    /*INPUT BLOCK MOCK*/

    port_t [VC_NUM-1:0] out_port [PORT_NUM-1:0];
    
    logic [VC_NUM-1:0] vc_request [PORT_NUM-1:0];

    /*INTERFACES INSTANTIATION*/
        
    input_block2vc_allocator ib_if();

    logic [VC_SIZE-1:0] vc_new_generated [PORT_NUM-1:0] [VC_NUM-1:0];
    
    logic [VC_NUM-1:0] vc_valid_generated [PORT_NUM-1:0];
    
    port_t [PORT_NUM-1:0] ports = {LOCAL, NORTH, SOUTH, WEST, EAST};

    /*SEPARABLE INPUT FIRST ALLOCATOR*/

    localparam [31:0] AGENTS_PTR_SIZE_IN = $clog2(VC_NUM);

    localparam [31:0] AGENTS_PTR_SIZE_OUT = $clog2(PORT_NUM);

    logic [PORT_NUM-1:0][VC_NUM-1:0] request_cmd;

    logic [PORT_NUM-1:0][AGENTS_PTR_SIZE_IN-1:0] curr_highest_priority_vc, next_highest_priority_vc;
    
    logic [PORT_NUM-1:0][AGENTS_PTR_SIZE_OUT-1:0] curr_highest_priority_ip, next_highest_priority_ip;   
    
    logic [PORT_NUM-1:0][VC_NUM-1:0] vc_grant_gen;
    
    logic [PORT_NUM-1:0][PORT_NUM-1:0] ip_grant_gen; 

    logic [PORT_NUM-1:0][PORT_NUM-1:0] out_request_gen;

    logic [PORT_NUM-1:0][VC_NUM-1:0] grant_o_gen;

    /*RESOURCES AVAILABILITY VECTOR*/
    
    logic [PORT_NUM-1:0][VC_NUM-1:0] available_vc_curr, available_vc_prox;

    /*DUT INSTANTIATION*/
    
    vc_allocator #(
    )
    vc_allocator (
            .rst(rst),
            .clk(clk),
            .idle_downstream_vc_i(idle_downstream_vc_i),
            .ib_if(ib_if.vc_allocator)
     );
    /*MOCK INSTANTIATION*/
    
    ib_mock ib_mock(
            .ib_if(ib_if.input_block),
            .out_port_i(out_port),
            .vc_request_i(vc_request)
    );
         
    /*
    The testbench performs four different test:
    1) Simulation of the basic tasks that the allocator has to perform, all the requests are cumulative
    2) Simulation of a corner case: all the upstream vcs request the same port.
    3) Simulation of a corner case: after all the request have been granted the downstream vc is not in idle, so all the resources have been 
     exhausted, after that all the downstream vcs return in idle and the resources recover.
    4) Simulation of a corner case: a reset is performed during the execution of the module and then normal tasks are executed.
    */

    initial 
    begin
        dump_output();
        initialize();
        clear_reset();
        test_cumulative_requests();
        test_same_port_requests();
        test_exhaust_vc_and_return_availability();
        test_reset();
        $display("[ALLOCATOR] PASSED");
        #15 $finish;
    end 

    always #5 clk = ~clk ;

    task dump_output();
            $dumpfile("out.vcd");
            $dumpvars(0, tb_vc_allocator);
    endtask

    task clear_reset();
        begin
            @(posedge clk);
            rst <= 0;
        end
    endtask

    task initialize();
        clk <= 0;
        rst  = 1;
        for(int i = 0; i < PORT_NUM; i++)
            begin
                available_vc_curr[i]  = {VC_NUM{1'b1}};
                curr_highest_priority_vc[i] = 1'b0;
                vc_grant_gen[i] = {VC_NUM{1'b0}};
                curr_highest_priority_ip[i] = 1'b0;
                vc_request[i] = {VC_NUM{1'b0}};
            end
    endtask

    task reset();
        rst  = 1;
        for(int i = 0; i < PORT_NUM; i++)
            begin
                available_vc_curr[i]  = {VC_NUM{1'b1}};
                curr_highest_priority_vc[i] = 1'b0;
                vc_grant_gen[i] = {VC_NUM{1'b0}};
                curr_highest_priority_ip[i] = 1'b0;
                vc_request[i] = {VC_NUM{1'b0}};
                vc_valid_generated[i] = {VC_NUM{1'b0}};
            end
    endtask
    
    /*First test the vc allocator is called to execute a number of basic tasks*/
    task test_cumulative_requests();
        repeat(10) @(posedge clk)
        begin
            for(int i = 0; i < PORT_NUM; i++)
            begin
                idle_downstream_vc_i[i] = {VC_NUM{$random}};
                out_port[i] = {VC_NUM{ports[$urandom_range(4,0)]}};
                vc_request[i] = {VC_NUM{$random}};
            end
            test_check();
        end
    endtask
    /*
    Second test: all the upstream vcs request the same port
    */
    task test_same_port_requests();
        for(int j = 0; j < PORT_NUM; j++)
        begin
            @(posedge clk)
            for(int i = 0; i < PORT_NUM; i++)
            begin
                idle_downstream_vc_i[i] = {VC_NUM{1'b1}};
                out_port[i] = {VC_NUM{ports[j]}};
                vc_request[i]= {VC_NUM{1'b1}};
            end
            test_check();
        end
    endtask
    /*
    Third test all the downstream vc are not in idle (5clk) and then they return in idle again
    */
    task test_exhaust_vc_and_return_availability();
        for(int j = 0; j < PORT_NUM; j++)
        begin
            @(posedge clk)
            for(int i = 0; i < PORT_NUM; i++)
            begin
                idle_downstream_vc_i[i] = {VC_NUM{1'b0}};
                out_port[i] = {VC_NUM{ports[$urandom_range(4,0)]}};
                vc_request[i] = {VC_NUM{1'b1}};
            end
            test_check();
        end
        
        for(int j = 0; j < PORT_NUM; j++)
        begin
            @(posedge clk)
            for(int i = 0; i < PORT_NUM; i++)
            begin
                idle_downstream_vc_i[i] = {VC_NUM{1'b1}};
                out_port[i] = {VC_NUM{ports[$urandom_range(4,0)]}};
                vc_request[i] = {VC_NUM{1'b1}};
            end
            test_check();
        end
    endtask
    /*
    Fourth and last test a reset is performed before the operations
    */
    task test_reset();
        @(posedge clk, posedge rst)
            reset();   
        clear_reset();
        repeat(10) @(posedge clk)
        begin
            for(int i = 0; i < PORT_NUM; i++)
            begin
                idle_downstream_vc_i[i] = {VC_NUM{$random}};
                out_port[i] = {VC_NUM{ports[$urandom_range(4,0)]}};
                vc_request[i] = {VC_NUM{$random}};
            end
            test_check();
        end
    endtask

    task test_check();
        available_vc_prox = available_vc_curr;
        for(int port = 0; port < PORT_NUM; port = port + 1)
        begin
            request_cmd[port] = {VC_NUM{1'b0}};
            vc_valid_generated[port] = {VC_NUM{1'b0}};
        end
        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                vc_new_generated[up_port][up_vc] = {VC_SIZE{1'bx}};
            end
        end
        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                if(vc_request[up_port][up_vc] & available_vc_curr[out_port[up_port][up_vc]])
                begin
                    request_cmd[up_port][up_vc] = 1'b1;
                end
            end
        end
        /*INPUT FIRST ALLOCATION*/
        for(int k = 0; k < PORT_NUM; k = k + 1)
        begin
            vc_grant_gen[k]  =  {VC_NUM{1'b0}};
            next_highest_priority_vc[k] = curr_highest_priority_vc[k];
            for(int i = 0; i < VC_NUM; i = i + 1)
            begin
                if(request_cmd[k][(curr_highest_priority_vc[k] + i) % VC_NUM])
                begin
                    vc_grant_gen[k][(curr_highest_priority_vc[k] + i) % VC_NUM] = 1'b1; 
                    next_highest_priority_vc[k] = (curr_highest_priority_vc[k] + i + 1) % VC_NUM;
                    break;
                end
            end
            curr_highest_priority_vc[k] = next_highest_priority_vc[k];
        end
        out_request_gen = {PORT_NUM*PORT_NUM{1'b0}};
        for(int i = 0; i < PORT_NUM; i = i + 1)
        begin
            for(int j = 0; j < VC_NUM; j = j + 1)
            begin
                if(vc_grant_gen[i][j])
                begin
                    out_request_gen[out_port[i][j]][i] = 1'b1;
                    break;
                end
            end
        end
        for(int k = 0; k < PORT_NUM; k = k + 1)
        begin
            ip_grant_gen[k]  =  {PORT_NUM{1'b0}};
            next_highest_priority_ip[k] = curr_highest_priority_ip[k];
            for(int i = 0; i < PORT_NUM; i = i + 1)
            begin
                if(out_request_gen[k][(curr_highest_priority_ip[k] + i) % PORT_NUM])
                begin
                    ip_grant_gen[k][(curr_highest_priority_ip[k] + i) % PORT_NUM] = 1'b1;
                    next_highest_priority_ip[k] = (curr_highest_priority_ip[k] + i + 1) % PORT_NUM;
                    break;
                end
            end
            curr_highest_priority_ip[k] = next_highest_priority_ip[k];
        end
        grant_o_gen= {PORT_NUM*VC_NUM{1'b0}};
        for(int i = 0; i < PORT_NUM; i = i + 1)
        begin
            for(int j = 0; j < PORT_NUM; j = j + 1)
            begin
                for(int k = 0; k < VC_NUM; k = k + 1)
                begin
                    if(ip_grant_gen[i][j] & vc_grant_gen[j][k])
                    begin
                        grant_o_gen[j][k] = 1'b1;
                        break;
                    end
                end
            end
        end

        /*VC ALLOCATION*/

        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                if(grant_o_gen[up_port][up_vc])
                begin
                    vc_new_generated[up_port][up_vc] = assign_downstream_vc(out_port[up_port][up_vc]);
                    vc_valid_generated[up_port][up_vc] = 1'b1;
                    available_vc_prox[out_port[up_port][up_vc]][vc_new_generated[up_port][up_vc]] = 1'b0;
                end
            end
        end

        for(int down_port = 0; down_port < PORT_NUM; down_port = down_port + 1)
        begin
            for(int down_vc = 0; down_vc < VC_NUM; down_vc = down_vc + 1)
            begin
                if(~available_vc_curr[down_port][down_vc] & idle_downstream_vc_i[down_port][down_vc])
                begin
                    available_vc_prox[down_port][down_vc] = 1'b1;
                end
            end
        end
        available_vc_curr = available_vc_prox;
        check();
    endtask

    task check();
        @(negedge clk)
        for(int j = 0; j < VC_SIZE; j++)
        begin
            for(int i = 0; i < PORT_NUM; i++)
            begin
                for(int k = 0; k < VC_NUM; k++)
                begin
                    if(vc_new_generated[j][i][k]!==ib_mock.vc_new_o[j][i][k])
                    begin
                        $display("[ALLOCATOR] FAILED time: %d", $time);
                        #5 $finish;
                    end
                end
            end   
        end

        for(int j = 0; j < VC_NUM; j++)
        begin
            for(int i = 0; i < PORT_NUM; i++)
            begin
                if(vc_valid_generated[j][i]!==ib_mock.vc_valid_o[j][i])
                begin
                $display("[ALLOCATOR] FAILED time: %d", $time);
                #5 $finish;
                end
            end
        end
    endtask
    
    
    function logic [VC_SIZE-1:0] assign_downstream_vc (input port_t port);
        assign_downstream_vc = {VC_SIZE{1'bx}};
        for(int vc = 0; vc < VC_NUM; vc = vc + 1)
        begin
            if(available_vc_curr[port][vc])
            begin
                assign_downstream_vc = vc;
                break;
            end
        end
    endfunction


endmodule



module ib_mock #()(
    input_block2vc_allocator.input_block ib_if,
    input port_t [VC_NUM-1:0] out_port_i [PORT_NUM-1:0],
    input logic [VC_NUM-1:0] vc_request_i [PORT_NUM-1:0],
    output logic [VC_SIZE-1:0] vc_new_o [PORT_NUM-1:0] [VC_NUM-1:0],
    output logic [VC_NUM-1:0] vc_valid_o [PORT_NUM-1:0]
);

    always_comb
    begin
        vc_new_o = ib_if.vc_new;
        vc_valid_o = ib_if.vc_valid;
        ib_if.out_port = out_port_i;
        ib_if.vc_request = vc_request_i;
    end
    
endmodule