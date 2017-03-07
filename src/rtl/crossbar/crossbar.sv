import noc_params::*;

module crossbar #(
    parameter INPUT_NUM=2,
    parameter OUTPUT_NUM=2
)(
    input flit_t data_i [INPUT_NUM-1:0],
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
        for(int j=0; j<OUTPUT_NUM; j++)
        begin
            data_o[j] = data_i[sel_i[j]];
        end
    end

endmodule
