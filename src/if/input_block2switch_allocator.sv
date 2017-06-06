import noc_params::*;

interface input_block2switch_allocator;

    port_t [VC_NUM-1:0] out_port [PORT_NUM-1:0];
    logic [VC_SIZE-1:0] vc_sel [PORT_NUM-1:0];
    logic valid_sel [PORT_NUM-1:0];
    logic [VC_SIZE-1:0] downstream_vc [PORT_NUM-1:0][VC_NUM-1:0];
    logic switch_request [PORT_NUM-1:0][VC_NUM-1:0];    //from Input Buffer, asserted when in SA state
    
    modport input_block (
        input vc_sel,
        input valid_sel,
        output out_port,
        output downstream_vc,
        output switch_request
    );

    modport switch_allocator (
        output vc_sel,
        output valid_sel,
        input out_port,
        input downstream_vc,
        input switch_request
    );

endinterface