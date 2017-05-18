import noc_params::*;

interface router2router;

    flit_t data;
    logic valid_flit;
    logic [VC_NUM-1:0] on_off;
    logic [VC_NUM-1:0] is_allocatable;

    modport upstream (
        output data,
        output valid_flit,
        input on_off,
        input is_allocatable
    );

    modport downstream (
        input data,
        input valid_flit,
        output on_off,
        output is_allocatable
    );

endinterface