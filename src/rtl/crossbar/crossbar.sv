import noc_params::*;

module crossbar #(
)(
    input_block2crossbar.crossbar ib_if,
    switch_allocator2crossbar.crossbar sa_if,
    output flit_t data_o [PORT_NUM-1:0]
);

    /*
    Combinational logic:
    on each output, propagate the corresponding input
    according to the current selection
    */
    always_comb
    begin
        for(int ip = 0; ip < PORT_NUM; ip = ip + 1)
        begin
            data_o[ip] = ib_if.flit[sa_if.input_vc_sel[ip]];
        end
    end

endmodule