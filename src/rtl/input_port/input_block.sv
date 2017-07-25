import noc_params::*;

module input_block #(
    parameter PORT_NUM = 5,
    parameter BUFFER_SIZE = 8,
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
    output logic [VC_NUM-1:0] vc_allocatable_o [PORT_NUM-1:0],
    output logic [VC_NUM-1:0] error_o [PORT_NUM-1:0]
);
    
    logic [VC_NUM-1:0] is_full [PORT_NUM-1:0];
    logic [VC_NUM-1:0] is_empty [PORT_NUM-1:0];

    port_t [VC_NUM-1:0] out_port [PORT_NUM-1:0];

    assign va_if.out_port = out_port;
    assign sa_if.out_port = out_port;

    /*
    The Input Block module contains all the PORT_NUM
    Input Ports composing the Router, making it easier
    to connect all of them through one single interface
    per each other module, i.e., the Crossbar, the
    Virtual Channel Allocator and the Switch Allocator.
    */
    genvar ip;
    generate
        for(ip=0; ip<PORT_NUM; ip++)
        begin: generate_input_ports
            input_port #(
                .BUFFER_SIZE(BUFFER_SIZE),
                .X_CURRENT(X_CURRENT),
                .Y_CURRENT(Y_CURRENT)
            )
            input_port (
                .data_i(data_i[ip]),
                .valid_flit_i(valid_flit_i[ip]),
                .rst(rst),
                .clk(clk),
                .sa_sel_vc_i(sa_if.vc_sel[ip]),
                .va_new_vc_i(va_if.vc_new[ip]),
                .va_valid_i(va_if.vc_valid[ip]),
                .sa_valid_i(sa_if.valid_sel[ip]),
                .xb_flit_o(crossbar_if.flit[ip]),
                .is_on_off_o(on_off_o[ip]),
                .is_allocatable_vc_o(vc_allocatable_o[ip]),
                .va_request_o(va_if.vc_request[ip]),
                .sa_request_o(sa_if.switch_request[ip]),
                .sa_downstream_vc_o(sa_if.downstream_vc[ip]),
                .out_port_o(out_port[ip]),
                .is_full_o(is_full[ip]),
                .is_empty_o(is_empty[ip]),
                .error_o(error_o[ip])
            );
        end
    endgenerate

endmodule