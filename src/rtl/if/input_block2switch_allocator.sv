import noc_params::*;

interface input_block2switch_allocator;

    port_t [VC_NUM-1 : 0] out_port [PORT_NUM-1:0];
    logic [VC_SIZE-1 : 0] vc_sel [PORT_NUM-1:0];
    logic valid_sel [PORT_NUM-1:0];

    modport input_block (
        output out_port,
        input vc_sel,
        input valid_sel
    );

    modport switch_allocator (
        input out_port,
        output vc_sel,
        output valid_sel
    );

endinterface