import noc_params::*;

module crossbar #(
    parameter INPUT_NUM = PORT_NUM,
    parameter OUTPUT_NUM = PORT_NUM
)(
    input_block2crossbar.crossbar input_block_if,
    input [SEL_SIZE-1:0] sel_i [OUTPUT_NUM-1:0],
    output flit_t data_o [OUTPUT_NUM-1:0]
);

    localparam [31:0] SEL_SIZE = $clog2(INPUT_NUM);

    /*
    Combinational logic:
    on each output, propagate the corresponding input
    according to the current selection
    */
    always_comb
    begin
        for(int ip = 0; ip < OUTPUT_NUM; ip = ip + 1)
        begin
            data_o[j] = input_block_if.flit[sel_i[ip]];
        end
    end

endmodule
