import noc_params::*;

module input_buffer #(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5
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
    output logic on_off_o,
    output port_t out_port_o
);

    enum logic [1:0] {IDLE, VA, SA} ss, ss_next;

    logic [VC_SIZE-1:0] downstream_vc, downstream_vc_next;

    flit_t read_flit;

    port_t out_port_next;

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH)
    )
    circular_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .rst(rst),
        .clk(clk),
        .data_o(read_flit),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o),
        .on_off_o(on_off_o)
    );

    /*
    Sequential logic:
    - on the rising edge of the reset input signal, reset the state of the
      finite state machine, the next hop destination and the downstream virtual
      channel identifier;
    - on the rising edge of the clock input signal, update the state,
      the next hop destination and the downstream virtual channel identifier.
    */
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

    /*
    Combinational logic:
    - in Idle state, when the input flit is an Head one, the write command is
      asserted and the buffer is empty, then the next hop destination received
      in input and associated to the flit is stored, and the next state is set
      to be Virtual Channel Allocation;
    - in Virtual Channel Allocation state, when the virtual channel for the
      downstream router is valid, i.e., the corresponding validity signal is
      asserted, then the virtual channel identifier is stored and the next
      state is set to be Switch Allocation;
    - in Switch Allocation state, when the last flit to read is the Tail one
      and the read command is asserted, then the next state is set to be Idle.
    */
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
                if(data_i.flit_label == HEAD & write_i & is_empty_o)
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
                if(data_o.flit_label == TAIL & read_i)
                    ss_next = IDLE;
            end
        endcase
    end

endmodule