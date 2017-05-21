import noc_params::*;

interface input_block2vc_allocator;

    logic [VC_SIZE-1:0] vc_new [PORT_NUM-1:0] [VC_NUM-1:0];
    logic [VC_NUM-1:0] vc_valid [PORT_NUM-1:0];
    logic [VC_NUM-1:0] vc_request [PORT_NUM-1:0];
    port_t [VC_NUM-1:0] out_port [PORT_NUM-1:0];

    modport input_block (
        input vc_new,
        input vc_valid,
        output vc_request,
        output out_port
    );

    modport vc_allocator (
        output vc_new,
        output vc_valid,
        input vc_request,
        input out_port
    );

endinterface