import noc_params::*;

module input_port #(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
)(
    input flit_t data_i,
    input valid_flit_i,
    input rst,
    input clk,
    input_port2crossbar.input_port crossbar_if,
    input_port2switch_allocator.input_port sa_if,
    input_port2vc_allocator.input_port va_if,
    output logic [VC_NUM-1:0] on_off_o
);

    flit_t [VC_NUM-1:0] data;

    port_t out_port_cmd;

    logic [VC_NUM-1:0] read_cmd;
    logic [VC_NUM-1:0] write_cmd;
    logic [VC_NUM-1:0] is_full;
    logic [VC_NUM-1:0] is_empty;

    genvar vc;
    generate
        for(vc=0; vc<VC_NUM; vc++)
        begin: generate_virtual_channels
            input_buffer #(
                .BUFFER_SIZE(BUFFER_SIZE),
                .PIPELINE_DEPTH(PIPELINE_DEPTH)
            )
            input_buffer (
                .data_i(data_i),
                .read_i(read_cmd[vc]),
                .write_i(write_cmd[vc]),
                .vc_new_i(va_if.vc_new[vc]),
                .vc_valid_i(va_if.vc_valid[vc]),
                .out_port_i(out_port_cmd),
                .rst(rst),
                .clk(clk),
                .data_o(data[vc]),
                .is_full_o(is_full[vc]),
                .is_empty_o(is_empty[vc]),
                .on_off_o(on_off_o[vc]),
                .out_port_o(sa_if.out_port[vc])
            );
        end
    endgenerate

    rc_unit #(
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT),
        .DEST_ADDR_SIZE_X(DEST_ADDR_SIZE_X),
        .DEST_ADDR_SIZE_Y(DEST_ADDR_SIZE_Y)
    )
    rc_unit (
        .x_dest_i(data_i.data.head_data.x_dest),    //does it work with non-head flit in input?
        .y_dest_i(data_i.data.head_data.y_dest),
        .out_port_o(out_port_cmd)
    );

    /*
    Combinational logic:
    - if the input flit is valid, assert the write command of the corresponding
      virtual channel buffer where the flit has to be stored;
    - assert the read command of the virtual channel buffer selected by the
      interfaced switch allocator and propagate at the crossbar interface the
      corresponding flit.
    */
    always_comb
    begin
        write_cmd = {VC_NUM{0}};
        if(valid_flit_i)
            write_cmd[data_i.vc_id] = 1;

        read_cmd = {VC_NUM{0}};
        crossbar_if.flit = data[sa_if.vc_sel];
        read_cmd[sa_if.vc_sel] = 1;
    end

endmodule