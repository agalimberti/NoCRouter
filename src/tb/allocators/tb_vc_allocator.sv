`timescale 1ns / 1ps

import noc_params::*;
module tb_vc_allocator #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2
);
    
    /*VC ALLOCATOR*/
    logic rst, clk;

    logic [VC_TOTAL-1:0] idle_downstream_vc_i;
    
    logic [VC_TOTAL-1:0] vc_to_allocate_i;
    
    port_t [VC_TOTAL-1:0] out_port_i;
    
    logic [VC_SIZE-1:0] vc_new_o [VC_TOTAL-1:0];
    
    logic [VC_TOTAL-1:0] vc_valid_o;
    
    port_t [PORT_NUM-1:0] ports = {LOCAL, NORTH, SOUTH, WEST, EAST};
    
    /*DUT INSTANTIATION*/
    
    vc_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    vc_allocator (
        .rst(rst),
        .clk(clk),
        .idle_downstream_vc_i(idle_downstream_vc_i),
        .vc_to_allocate_i(vc_to_allocate_i),
        .out_port_i(out_port_i),
        .vc_new_o(vc_new_o),
        .vc_valid_o(vc_valid_o)
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
            $dumpvars(0, tb_vc_allocator);
    endtask

    task clear_reset();
        @(posedge clk);
        rst <= 0;
    endtask

    task initialize();
            clk <= 0;
            rst  = 1;
    endtask

    task test();
    repeat(10) @(posedge clk)
    begin
        idle_downstream_vc_i <= {PORT_NUM{$random}};
        for(int i = 0; i <= VC_TOTAL; i++)
            out_port_i[i] <= ports[$urandom_range(4,0)];
        vc_to_allocate_i <= {PORT_NUM{$random}}; 
    end
    endtask

endmodule
