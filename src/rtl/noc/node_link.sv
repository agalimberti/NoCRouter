import noc_params::*;

module node_link (
    router2router.upstream router_if_up,
    router2router.downstream router_if_down,
    //upstream connections
    input flit_t data_i,
    input is_valid_i,
    output logic [VC_NUM-1:0] is_on_off_o,
    output logic [VC_NUM-1:0] is_allocatable_o,
    //downstream connections
    output flit_t data_o,
    output logic is_valid_o,
    input [VC_NUM-1:0] is_on_off_i,
    input [VC_NUM-1:0] is_allocatable_i
);

    always_comb
    begin
        router_if_up.data = data_i;
        router_if_up.is_valid = is_valid_i;
        is_on_off_o = router_if_up.is_on_off;
        is_allocatable_o = router_if_up.is_allocatable;
        data_o = router_if_down.data;
        is_valid_o = router_if_down.is_valid;
        router_if_down.is_on_off = is_on_off_i;
        router_if_down.is_allocatable = is_allocatable_i;
    end

endmodule