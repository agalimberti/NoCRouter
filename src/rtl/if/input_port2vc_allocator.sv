import noc_params::*;

interface input_port2vc_allocator;

    /*
    Some connections may be missing, for now it only models 
    the virtual channel allocator's input to the input port
    */

    logic [VC_NUM-1:0] [VC_SIZE-1:0] vc_new;
    logic [VC_NUM-1:0] vc_valid;

    modport input_port (
        input vc_new,
        input vc_valid
    );

    modport vc_allocator (
        output vc_new,
        output vc_valid
    );

endinterface