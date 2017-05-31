import noc_params::*;

`timescale 1ns / 1ps

module tb_separable_input_first_allocator #(
    parameter VC_NUM = 2
);
    /*INPUT SIGNALS*/
    
    logic clk, rst;

    logic [PORT_NUM-1:0][VC_NUM-1:0] requests_cmd;
    
    port_t [VC_NUM-1:0] out_port_cmd [PORT_NUM-1:0];

    /*INTERNAL VALUES*/ 

    localparam [31:0] AGENTS_PTR_SIZE_IN = $clog2(VC_NUM);

    localparam [31:0] AGENTS_PTR_SIZE_OUT = $clog2(PORT_NUM);
    
    logic [PORT_NUM-1:0][AGENTS_PTR_SIZE_IN-1:0] curr_highest_priority_vc, next_highest_priority_vc;
    
    logic [PORT_NUM-1:0][AGENTS_PTR_SIZE_OUT-1:0] curr_highest_priority_ip, next_highest_priority_ip;   
    
    logic [PORT_NUM-1:0][VC_NUM-1:0] vc_grant_gen;
    
    logic [PORT_NUM-1:0][PORT_NUM-1:0] ip_grant_gen; 

    logic [PORT_NUM-1:0][PORT_NUM-1:0] out_request_gen;

    logic [PORT_NUM-1:0][VC_NUM-1:0] grant_o_gen;

    wire [PORT_NUM-1:0][VC_NUM-1:0] grants;

    port_t [PORT_NUM-1:0] ports = {LOCAL, NORTH, SOUTH, WEST, EAST};
    

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        test();
        $display("[ALLOCATOR PASSED]");
        #5 $finish;
        
    end

    always #5 clk = ~clk;

    separable_input_first_allocator #(
        .VC_NUM(VC_NUM)
    )
    separable_input_first_allocator (
        .clk(clk),
        .rst(rst),
        .request_i(requests_cmd),
        .out_port_i(out_port_cmd),
        .grant_o(grants)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_separable_input_first_allocator);
    endtask

    task initialize();
        clk <= 0;
        rst  = 1;
        for(int i=0; i < PORT_NUM; i++)
        begin
            curr_highest_priority_vc[i] = 1'b0;
            vc_grant_gen[i] = {VC_NUM{1'b0}};
            curr_highest_priority_ip[i] = 1'b0;
        end
        ip_grant_gen = {PORT_NUM*PORT_NUM{1'b0}};
        out_request_gen = {PORT_NUM*PORT_NUM{1'b0}};
        grant_o_gen = {PORT_NUM*VC_NUM{1'b0}};
    endtask

    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask
    
    task test();
        repeat(10) @(posedge clk)
        begin
            for(int j=0; j < PORT_NUM; j = j + 1)
            begin
                requests_cmd[j] = {VC_NUM{$random}};
                gen_vc_grant(j);
            end
            for(int j=0; j < PORT_NUM; j = j + 1)
            begin 
                out_port_cmd[j] = {PORT_NUM{ports[$urandom_range(4,0)]}};
                gen_out_request();
            end
            for(int j=0; j < PORT_NUM; j = j + 1)
                gen_ip_grant(j); 
            gen_grant_o();
            check_matrices();
        end
    endtask
    
    task gen_vc_grant(input int k);
        vc_grant_gen[k]  =  {VC_NUM{1'b0}};
        next_highest_priority_vc[k] = curr_highest_priority_vc[k];
        for(int i = 0; i < VC_NUM; i = i + 1)
        begin
            if(requests_cmd[k][(curr_highest_priority_vc[k] + i) % VC_NUM])
            begin
                vc_grant_gen[k][(curr_highest_priority_vc[k] + i) % VC_NUM] = 1'b1; 
                next_highest_priority_vc[k] = (curr_highest_priority_vc[k] + i + 1) % VC_NUM;
                break;
            end
        end
        curr_highest_priority_vc[k] = next_highest_priority_vc[k];            
    endtask
    
    task gen_ip_grant(input int k);
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
    endtask

    task gen_out_request();
        out_request_gen = {PORT_NUM*PORT_NUM{1'b0}};
        for(int i = 0; i < PORT_NUM; i = i + 1)
            begin
                for(int j = 0; j < VC_NUM; j = j + 1)
                begin
                    if(vc_grant_gen[i][j])
                    begin
                        out_request_gen[out_port_cmd[i][j]][i] = 1'b1;
                        break;
                    end
                end
            end
    endtask

    task gen_grant_o();
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
    endtask
    
    task check_matrices();
        @(negedge clk)
        for(int g = 0; g < PORT_NUM; g = g + 1)
        begin
            for(int h = 0; h < VC_NUM; h = h + 1)
            begin
            if(grants[g][h]!==grant_o_gen[g][h])
                begin
                    $display("[ARBITER FAILED] %d,%d  out: %d generated: %d", g, h, grants[g][h],grant_o_gen[g][h]);
                    #5 $finish;
                end
            end
        end
    endtask
endmodule
