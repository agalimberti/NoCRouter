import noc_params::*;

module router #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2,
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
)(
    input clk,
    input rst,
    //TODO: must be made somehow bidirectional
    router2router router_if_north,
    router2router router_if_south,
    router2router router_if_west,
    router2router router_if_east,
    router2node router_if_local
);

    input_block2crossbar ib2xbar_if();
    input_block2switch_allocator ib2sa_if();
    input_block2vc_allocator ib2va_if();
    switch_allocator2crossbar sa2xbar_if();

    input_block #(
        .PORT_NUM(PORT_NUM),
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH),
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT)
    )
    input_block (
        .rst(rst),
        .clk(clk),
        .data_i(),
        .valid_flit_i(),
        .crossbar_if(ib2xbar_if),
        .sa_if(ib2sa_if),
        .va_if(ib2va_if),
        .on_off_o(),
        .vc_allocatable_o()
    );

    crossbar #(
    )
    crossbar (
        .ib_if(ib2xbar_if),
        .sa_if(sa2xbar_if),
        .data_o()
    );

    vc_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    vc_allocator (
        .rst(rst),
        .clk(clk),
        .ib_if(ib2va_if)
    );

    switch_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    switch_allocator (
        .rst(rst),
        .clk(clk),
        .on_off_i(),
        .ib_if(ib2sa_if),
        .xbar_if(sa2xbar_if)
    );

endmodule
