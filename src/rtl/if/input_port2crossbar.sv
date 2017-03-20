import noc_params::*;

interface input_port2crossbar;

    flit_t flit;

    modport input_port (
        output flit
    );

    modport crossbar (
        input flit
    );

endinterface