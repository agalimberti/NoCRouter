import noc_params::*;

module input_buffer #(
    parameter BUFFER_SIZE = 8
)(
    input flit_t data_i,
    output flit_t data_o,
    input rst,
    input clk
);

    logic read_cmd, write_cmd;
    wire buf_full, buf_empty;

    circular_buffer  #(
            .BUFFER_SIZE(BUFFER_SIZE)
            )
        circular_buffer (
            .read_i(read_cmd),
            .write_i(write_cmd),
            .is_full_o(buf_full),
            .is_empty_o(buf_empty),
            .*
        );
    
    //FSM
    logic [1:0] ss, ss_next;
    localparam IDLE=2'b00, VA=2'b01, SA=2'b10;
    
    //Status update
    always_ff @(posedge clk, rst)
    begin
        if(rst)
            ss <= IDLE;
        else
            ss <= ss_next;
    end
    
    //Combinational logic for next state
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
                    if(buf_empty)
                        ss_next = IDLE;
                end
        endcase
    end
endmodule