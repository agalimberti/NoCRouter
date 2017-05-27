import noc_params::*;

interface vc_allocator2speculative_switch_allocator;

    logic [VC_NUM-1:0] vc_valid [PORT_NUM-1:0];

    modport vc_allocator (
        output vc_valid
    );

    modport speculative_switch_allocator (
        input vc_valid
    );

endinterface