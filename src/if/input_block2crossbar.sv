import noc_params::*;

interface input_block2crossbar;

    flit_t flit [PORT_NUM-1:0];

    modport input_block (
        output flit
    );

    modport crossbar (
        input flit
    );

endinterface