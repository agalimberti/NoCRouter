import noc_params::*;

module input_buffer #(
    parameter BUFFER_SIZE = 8
)(
    input flit_t data_i,
    input read_i,
    input write_i,
    input [VC_SIZE-1:0] vc_new_i,
    input vc_valid_i,
    input port_t out_port_i,
    input rst,
    input clk,
    output flit_t data_o,
    output logic is_full_o,
    output logic is_empty_o,
    output port_t out_port_o
);

    enum logic [1:0] {IDLE, VA, SA} ss, ss_next;

    logic [VC_SIZE-1:0] downstream_vc, downstream_vc_next;

    flit_t read_flit;

    port_t out_port_next;

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
    )
    circular_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .rst(rst),
        .clk(clk),
        .data_o(read_flit),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o)
    );

    always_ff@(posedge clk, rst)
    begin
        if(rst)
        begin
            ss              <= IDLE;
            out_port_o      <= LOCAL;
            downstream_vc   <= 0;
        end
        else
        begin
            ss              <= ss_next;
            out_port_o      <= out_port_next;
            downstream_vc   <= downstream_vc_next;
        end
    end

    always_comb
    begin
        data_o.flit_label = read_flit.flit_label;
		data_o.vc_id = downstream_vc;
		data_o.data = read_flit.data;

        ss_next = ss;
        out_port_next = out_port_o;
        downstream_vc_next = downstream_vc;
        
        unique case(ss)
            IDLE:
            begin
                if(data_i.flit_label == HEAD & write_i & is_empty_o)   //and the buffer is currently empty?
                begin
                    ss_next = VA;
                    out_port_next = out_port_i;
                end
            end

            VA:
            begin
                if(vc_valid_i)
                begin
                    ss_next = SA;
                    downstream_vc_next = vc_new_i;
                end
            end

            SA:
            begin
                if(is_empty_o) //better, if the last read flit is the Tail one and now the buffer is then empty (or one flit only?)?
                    ss_next = IDLE;
            end
        endcase
    end

endmodule