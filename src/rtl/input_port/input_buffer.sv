import noc_params::*;

module input_buffer #(
    parameter BUFFER_SIZE = 8
)(
    input flit_t data_i,
    input read_i,
    input write_i,
    input rst,
    input clk,
    output flit_t data_o,
    output logic is_full_o,
    output logic is_empty_o
);

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
        )
    circular_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .rst(rst),
        .clk(clk),
        .data_o(data_o),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o)
    );
    
    
    // TODO
    // FSM
    logic [1:0] ss, ss_next;
    localparam IDLE=2'b00, VA=2'b01, SA=2'b10;
    
    // Status update
    always_ff @(posedge clk, rst)
    begin
        if(rst)
            ss <= IDLE;
        else
            ss <= ss_next;
    end
    
    // Combinational logic for next state
    always_comb
    begin
        ss = ss_next;
        
        case (ss)
            IDLE:
                begin
                    if(flit_i.flit_label == HEAD)
                        ss_next = VA;
                end
            VA:
                begin
                    ss_next = SA;
                end
            SA:
                begin
                    if(is_empty_o)
                        ss_next = IDLE;
                end
        endcase
    end
endmodule