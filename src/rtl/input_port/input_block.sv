import noc_params::*;

module input_block #(
    parameter PORT_NUM = 5,
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
)(
    input flit_t data_i [PORT_NUM-1:0],
    input valid_flit_i [PORT_NUM-1:0],
    input rst,
    input clk,
    input_block2crossbar.input_block crossbar_if,
    input_block2switch_allocator.input_block sa_if,
    input_block2vc_allocator.input_block va_if,
    output logic [VC_NUM-1:0] on_off_o [PORT_NUM-1:0],
    output logic [VC_NUM-1:0] vc_allocatable_o[ PORT_NUM-1:0]
);

    port_t [VC_NUM-1:0] out_port [PORT_NUM-1:0];

    assign va_if.out_port = out_port;
    assign sa_if.out_port = out_port;

    logic [VC_NUM-1:0] vc_request [PORT_NUM-1:0];

    assign va_if.vc_request = vc_request;
    assign sa_if.vc_request = vc_request;    

    genvar ip;
    generate
        for(ip=0; ip<PORT_NUM; ip++)
        begin: generate_input_ports
            input_port #(
                .BUFFER_SIZE(BUFFER_SIZE),
                .PIPELINE_DEPTH(PIPELINE_DEPTH),
                .X_CURRENT(X_CURRENT),
                .Y_CURRENT(Y_CURRENT)
            )
            input_port (
                .data_i(data_i[ip]),
                .valid_flit_i(valid_flit_i[ip]),
                .rst(rst),
                .clk(clk),
                .vc_sel_i(sa_if.vc_sel[ip]),
                .vc_new_i(va_if.vc_new[ip]),
                .vc_valid_i(va_if.vc_valid[ip]),
                .valid_sel_i(sa_if.valid_sel[ip]),
                .flit_o(crossbar_if.flit[ip]),
                .on_off_o(on_off_o[ip]),
                .vc_allocatable_o(vc_allocatable_o[ip]),
                .vc_request_o(vc_request[ip]),
                .switch_request_o(sa_if.switch_request[ip]),
                .downstream_vc_o(sa_if.downstream_vc[ip]),
                .out_port_o(out_port[ip])
            );
        end
    endgenerate

endmodule