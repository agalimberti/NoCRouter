`timescale 1ns / 1ps

import noc_params::*;

module tb_switch_allocator #(
);
    /*SWITCH ALLOCATOR*/

    logic rst, clk;

    logic [PORT_NUM-1:0][VC_NUM-1:0] on_off_cmd;

    logic [PORT_NUM-1:0] valid_flit_o;

    /*INPUT BLOCK & CROSSBAR MOCK*/

    port_t [VC_NUM-1:0] out_port [PORT_NUM-1:0];

    logic [VC_SIZE-1:0] downstream_vc [PORT_NUM-1:0][VC_NUM-1:0];
    
    logic switch_request [PORT_NUM-1:0][VC_NUM-1:0];
    
    logic valid_sel [PORT_NUM-1:0];
    
    logic [VC_SIZE-1:0] vc_sel [PORT_NUM-1:0];
    
    logic [PORT_SIZE-1:0] input_vc_sel [PORT_NUM-1:0];

    /*INTERFACES INSTANTIATION*/
        
    input_block2switch_allocator inb_if();

    switch_allocator2crossbar xbar_if();
    
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

    /*DUT INSTANTIATION*/
    
    switch_allocator #(
    )
    switch_allocator (
        .rst(rst),
        .clk(clk),
        .on_off_i(on_off_cmd),
        .ib_if(inb_if.switch_allocator),
        .xbar_if(xbar_if.switch_allocator),
        .valid_flit_o(valid_flit_o)
     );
    /*MOCK INSTANTIATION*/
    
    ib_xb_mock ib_xb_mock(
        .xbar_if(xbar_if.crossbar),
        .inb_if(inb_if.input_block),
        .out_port_i(out_port),
        .downstream_vc_i(downstream_vc),
        .switch_request_i(switch_request)
    );

    initial 
    begin
        dump_output();
        initialize();
        clear_reset();
        test();
        #15 $finish;
    end 

    always #5 clk = ~clk ;

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_switch_allocator);
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
            curr_highest_priority_vc[i] = 1'b0;
            curr_highest_priority_ip[i] = 1'b0;
        end
    endtask
    
    /*The switch allocator is called to execute a number of basic tasks*/
    task test();
        repeat(10) @(posedge clk)
        begin
            valid_flit_o = {PORT_NUM{$random}};
            for(int i = 0; i < PORT_NUM; i++)
            begin
                on_off_cmd[i] = {VC_NUM{$random}};
                out_port[i] = {VC_NUM{ports[$urandom_range(4,0)]}};
                for (int j = 0; j < VC_NUM; j++)
                begin
                    switch_request[i][j] = $random;
                    downstream_vc[i][j] = {VC_NUM{$random}};
                end
            end
            test_check();
        end
    endtask

    task test_check();
        for(int i = 0; i < PORT_NUM ; i = i + 1)
        begin
            valid_sel[i] = 1'b0;
            valid_flit_o[i] = 1'b0;
            vc_sel[i] = {VC_SIZE{1'b0}};
            input_vc_sel[i] = {PORT_SIZE{1'b0}};
            request_cmd[i]={VC_NUM{1'b0}};
        end
        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                if(switch_request[up_port][up_vc] & on_off_cmd[out_port[up_port][up_vc]][downstream_vc[up_port][up_vc]])
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

        /*SWITCH ALLOCATION*/
        for(int up_port = 0; up_port < PORT_NUM; up_port = up_port + 1)
        begin
            for(int up_vc = 0; up_vc < VC_NUM; up_vc = up_vc + 1)
            begin
                if(grant_o_gen[up_port][up_vc])
                begin
                    vc_sel[up_port] = up_vc;
                    valid_sel[up_port] = 1'b1;
                    valid_flit_o[out_port[up_port][up_vc]] = 1'b1;
                    input_vc_sel[out_port[up_port][up_vc]] = up_port;
                end
            end
        end
    endtask

endmodule 


module ib_xb_mock #()(
    switch_allocator2crossbar.crossbar xbar_if,
    output logic [PORT_SIZE-1:0] input_vc_sel_o [PORT_NUM-1:0],
    input_block2switch_allocator.input_block inb_if,
    input port_t [VC_NUM-1:0] out_port_i [PORT_NUM-1:0],
    input logic [VC_SIZE-1:0] downstream_vc_i [PORT_NUM-1:0][VC_NUM-1:0],
    input logic switch_request_i [PORT_NUM-1:0][VC_NUM-1:0],
    output logic[VC_SIZE-1:0] vc_sel_o [PORT_NUM-1:0],
    output logic valid_sel_o [PORT_NUM-1:0]
);

    always_comb
    begin
        vc_sel_o = inb_if.vc_sel;
        valid_sel_o = inb_if.valid_sel;
        inb_if.out_port = out_port_i;
        inb_if.downstream_vc = downstream_vc_i;
        inb_if.switch_request = switch_request_i;
        input_vc_sel_o = xbar_if.input_vc_sel;
    end
    
endmodule
