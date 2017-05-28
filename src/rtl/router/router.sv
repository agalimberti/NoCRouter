import noc_params::*;

module router #(
    parameter BUFFER_SIZE = 8,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
)(
    input clk,
    input rst,
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
    output logic [VC_NUM-1:0] error_o [PORT_NUM-1:0]
);

    //connections from upstream
    flit_t data_out [PORT_NUM-1:0];
    logic  [PORT_NUM-1:0] is_valid_out;
    logic  [PORT_NUM-1:0] [VC_NUM-1:0] is_on_off_in;
    logic  [PORT_NUM-1:0] [VC_NUM-1:0] is_allocatable_in;

    //connections from downstream
    flit_t data_in [PORT_NUM-1:0];
    logic  is_valid_in [PORT_NUM-1:0];
    logic  [VC_NUM-1:0] is_on_off_out [PORT_NUM-1:0];
    logic  [VC_NUM-1:0] is_allocatable_out [PORT_NUM-1:0];

    always_comb
    begin
        router_if_local_up.data = data_out[LOCAL];
        router_if_north_up.data = data_out[NORTH];
        router_if_south_up.data = data_out[SOUTH];
        router_if_west_up.data  = data_out[WEST];
        router_if_east_up.data  = data_out[EAST];

        router_if_local_up.is_valid = is_valid_out[LOCAL];
        router_if_north_up.is_valid = is_valid_out[NORTH];
        router_if_south_up.is_valid = is_valid_out[SOUTH];
        router_if_west_up.is_valid  = is_valid_out[WEST];
        router_if_east_up.is_valid  = is_valid_out[EAST];

        is_on_off_in[LOCAL] = router_if_local_up.is_on_off;
        is_on_off_in[NORTH] = router_if_north_up.is_on_off;
        is_on_off_in[SOUTH] = router_if_south_up.is_on_off;
        is_on_off_in[WEST]  = router_if_west_up.is_on_off;
        is_on_off_in[EAST]  = router_if_east_up.is_on_off;

        is_allocatable_in[LOCAL] = router_if_local_up.is_allocatable;
        is_allocatable_in[NORTH] = router_if_north_up.is_allocatable;
        is_allocatable_in[SOUTH] = router_if_south_up.is_allocatable;
        is_allocatable_in[WEST]  = router_if_west_up.is_allocatable;
        is_allocatable_in[EAST]  = router_if_east_up.is_allocatable;

        data_in[LOCAL] = router_if_local_down.data;
        data_in[NORTH] = router_if_north_down.data;
        data_in[SOUTH] = router_if_south_down.data;
        data_in[WEST]  = router_if_west_down.data;
        data_in[EAST]  = router_if_east_down.data;

        is_valid_in[LOCAL] = router_if_local_down.is_valid;
        is_valid_in[NORTH] = router_if_north_down.is_valid;
        is_valid_in[SOUTH] = router_if_south_down.is_valid;
        is_valid_in[WEST]  = router_if_west_down.is_valid;
        is_valid_in[EAST]  = router_if_east_down.is_valid;

        router_if_local_down.is_on_off = is_on_off_out[LOCAL];
        router_if_north_down.is_on_off = is_on_off_out[NORTH];
        router_if_south_down.is_on_off = is_on_off_out[SOUTH];
        router_if_west_down.is_on_off  = is_on_off_out[WEST];
        router_if_east_down.is_on_off  = is_on_off_out[EAST];

        router_if_local_down.is_allocatable = is_allocatable_out[LOCAL];
        router_if_north_down.is_allocatable = is_allocatable_out[NORTH];
        router_if_south_down.is_allocatable = is_allocatable_out[SOUTH];
        router_if_west_down.is_allocatable  = is_allocatable_out[WEST];
        router_if_east_down.is_allocatable  = is_allocatable_out[EAST];

    end

    input_block2crossbar ib2xbar_if();
    input_block2switch_allocator ib2sa_if();
    input_block2vc_allocator ib2va_if();
    switch_allocator2crossbar sa2xbar_if();

    input_block #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT)
    )
    input_block (
        .rst(rst),
        .clk(clk),
        .data_i(data_in),
        .valid_flit_i(is_valid_in),
        .crossbar_if(ib2xbar_if),
        .sa_if(ib2sa_if),
        .va_if(ib2va_if),
        .on_off_o(is_on_off_out),
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
        .on_off_i(is_on_off_in),
        .ib_if(ib2sa_if),
        .xbar_if(sa2xbar_if),
        .valid_flit_o(is_valid_out)
    );
    
    vc_allocator #(
    )
    vc_allocator (
        .rst(rst),
        .clk(clk),
        .idle_downstream_vc_i(is_allocatable_in),
        .ib_if(ib2va_if)
    );

endmodule