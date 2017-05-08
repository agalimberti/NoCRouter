import noc_params::*;

interface input_port2vc_allocator;

    /*
    Some connections may be missing, for now it only models 
    the virtual channel allocator's input to the input port
    */

    logic [VC_SIZE-1:0] vc_new [VC_NUM-1:0];
    logic [VC_NUM-1:0] vc_valid;
    logic [VC_NUM-1:0] vc_request;
    port_t [VC_NUM-1:0] out_port;

    modport input_port (
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