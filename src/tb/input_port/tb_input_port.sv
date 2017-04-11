`timescale 1ns / 1ps

import noc_params::*;

module tb_input_port #(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5
);

    //INPUT PORT
    flit_t data_cmd;
    logic valid_flit_cmd;
    logic rst;
    logic clk;
    logic read_i, write_i;
    logic [VC_NUM-1:0] on_off_o;

    //CROSSBAR MOCK
    flit_t flit_o;

    //SWITCH ALLOCATOR MOCK
    port_t [VC_NUM-1 : 0] out_port_o;
    logic [VC_SIZE-1 : 0] vc_sel_cmd;

    //VIRTUAL CHANNEL ALLOCATOR MOCK
    logic [VC_NUM-1:0] [VC_SIZE-1:0] vc_new_cmd;
    logic [VC_NUM-1:0] vc_valid_cmd;

    //INTERFACES INSTANTIATION
    input_port2crossbar ip2xbar_if();
    input_port2switch_allocator ip2sa_if();
    input_port2vc_allocator ip2va_if();

    input_port #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH)
    )
    input_port (
        .data_i(data_cmd),
        .valid_flit_i(valid_flit_cmd),
        .rst(rst),
        .clk(clk),
        .crossbar_if(ip2xbar_if.input_port),
        .sa_if(ip2sa_if.input_port),
        .va_if(ip2va_if.input_port),
        .on_off_o(on_off_o)
    );

    xbar_mock xbar_mock (
        .ip_if(ip2xbar_if.crossbar),
        .flit_o(flit_o)
    );

    sa_mock sa_mock (
        .ip_if(ip2sa_if.switch_allocator),
        .out_port_o(out_port_o),
        .vc_sel_i(vc_sel_cmd)

    );

    va_mock va_mock (
        .ip_if(ip2va_if.vc_allocator),
        .vc_new_i(vc_new_cmd),
        .vc_valid_i(vc_valid_cmd)
    );

    initial
    begin
        dump_output();
        initialize();
        clear_reset();     
        //perform some tests
        #20 $finish;
    end
    
    always #5 clk = ~clk;

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_input_port);     
    endtask
    
    task initialize();
        clk             <= 0;
        rst             = 1;
        read_i          = 0;
        write_i         = 0;
        /* also to be reset
        data_cmd        = ;
        valid_flit_cmd  = ;
        vc_sel_cmd      = ;
        vc_new_cmd      = ;
        vc_valid_cmd    = ;
        */
    endtask
    
    task clear_reset();
        repeat(2) @(posedge clk);
            rst <= 0;
    endtask

endmodule

module xbar_mock #()(
    input_port2crossbar.crossbar ip_if,
    output flit_t flit_o
);

    always_comb
    begin
        flit_o = ip_if.flit;
    end

endmodule

module sa_mock #()(
    input_port2switch_allocator.switch_allocator ip_if,
    output port_t [VC_NUM-1 : 0] out_port_o,
    input [VC_SIZE-1 : 0] vc_sel_i
);

    always_comb
    begin
        ip_if.vc_sel    = vc_sel_i;
        out_port_o      = ip_if.out_port;
    end

endmodule

module va_mock #()(
    input_port2vc_allocator.vc_allocator ip_if,
    input [VC_NUM-1:0] [VC_SIZE-1:0] vc_new_i,
    input [VC_NUM-1:0] vc_valid_i
);

    always_comb
    begin
        ip_if.vc_new    = vc_new_i;
        ip_if.vc_valid  = vc_valid_i;
    end

endmodule