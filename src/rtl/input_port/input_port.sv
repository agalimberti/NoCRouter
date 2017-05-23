import noc_params::*;

module input_port #(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2,
    bit SPECULATION = 0
)(
    input flit_t data_i,
    input valid_flit_i,
    input rst,
    input clk,
    input [VC_SIZE-1:0] vc_sel_i,
    input [VC_SIZE-1:0] vc_new_i [VC_NUM-1:0],
    input [VC_NUM-1:0] vc_valid_i,
    input valid_sel_i,
    output flit_t flit_o,
    output logic [VC_NUM-1:0] on_off_o,
    output logic [VC_NUM-1:0] vc_allocatable_o,
    output logic [VC_NUM-1:0] vc_request_o,
    output logic switch_request_o [VC_NUM-1:0],
    output logic [VC_SIZE-1:0] downstream_vc_o [VC_NUM-1:0],
    output port_t [VC_NUM-1:0] out_port_o,
    output logic [VC_NUM-1:0] is_full_o,
    output logic [VC_NUM-1:0] is_empty_o,
    output logic [VC_NUM-1:0] error_o
);

    flit_novc_t data_cmd;
    flit_t [VC_NUM-1:0] data_out;

    port_t out_port_cmd;

    logic [VC_NUM-1:0] read_cmd;
    logic [VC_NUM-1:0] write_cmd;

    genvar vc;
    generate
        for(vc=0; vc<VC_NUM; vc++)
        begin: generate_virtual_channels
            input_buffer #(
                .BUFFER_SIZE(BUFFER_SIZE),
                .PIPELINE_DEPTH(PIPELINE_DEPTH),
                .SPECULATION(SPECULATION)
            )
            input_buffer (
                .data_i(data_cmd),
                .read_i(read_cmd[vc]),
                .write_i(write_cmd[vc]),
                .vc_new_i(vc_new_i[vc]),
                .vc_valid_i(vc_valid_i[vc]),
                .out_port_i(out_port_cmd),
                .rst(rst),
                .clk(clk),
                .data_o(data_out[vc]),
                .is_full_o(is_full_o[vc]),
                .is_empty_o(is_empty_o[vc]),
                .on_off_o(on_off_o[vc]),
                .out_port_o(out_port_o[vc]),
                .vc_request_o(vc_request_o[vc]),
                .switch_request_o(switch_request_o[vc]),
                .vc_allocatable_o(vc_allocatable_o[vc]),
                .downstream_vc_o(downstream_vc_o[vc]),
                .error_o(error_o[vc])
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
        .x_dest_i(data_i.data.head_data.x_dest),
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
        data_cmd.flit_label = data_i.flit_label;
        data_cmd.data = data_i.data;
        
        write_cmd = {VC_NUM{1'b0}};
        if(valid_flit_i)
            write_cmd[data_i.vc_id] = 1;

        read_cmd = {VC_NUM{1'b0}};
        if(valid_sel_i)
            read_cmd[vc_sel_i] = 1;
        flit_o = data_out[vc_sel_i];
    end

endmodule