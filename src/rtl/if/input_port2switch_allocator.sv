import noc_params::*;

interface input_port2switch_allocator;

    port_t out_port;
    logic [VC_SIZE-1 : 0] vc_sel;

    modport input_port (
        output out_port,
        input vc_sel
    );

    modport switch_allocator (
        input out_port,
        output vc_sel
    );

endinterface