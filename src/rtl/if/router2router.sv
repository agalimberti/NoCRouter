import noc_params::*;

interface router2router;

    flit_t flit;
    logic valid;

    modport upstream (
        output flit,
        output valid
    );

    modport downstream (
        input flit,
        input valid
    );

endinterface