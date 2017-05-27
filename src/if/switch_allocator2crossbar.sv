import noc_params::*;

interface switch_allocator2crossbar;

    logic [PORT_SIZE-1:0] input_vc_sel [PORT_NUM-1:0];

    modport switch_allocator (
        output input_vc_sel
    );

    modport crossbar (
        input input_vc_sel
    );

endinterface