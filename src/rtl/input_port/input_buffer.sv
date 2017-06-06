import noc_params::*;

module input_buffer #(
    parameter BUFFER_SIZE = 8
)(
    input flit_novc_t data_i,
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
    output port_t out_port_o,
    output logic vc_request_o,
    output logic switch_request_o,
    output logic vc_allocatable_o,
    output logic [VC_SIZE-1:0] downstream_vc_o,
    output logic error_o
);

    enum logic [1:0] {IDLE, VA, SA} ss, ss_next;

    logic [VC_SIZE-1:0] downstream_vc_next;

    logic read_cmd, write_cmd;
    logic end_packet, end_packet_next;
    logic vc_allocatable_next;
    logic error_next;

    flit_novc_t read_flit;

    port_t out_port_next;

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
    )
    circular_buffer (
        .data_i(data_i),
        .read_i(read_cmd),
        .write_i(write_cmd),
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
    always_ff @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            ss                  <= IDLE;
            out_port_o          <= LOCAL;
            downstream_vc_o     <= 0;
            end_packet          <= 0;
            vc_allocatable_o    <= 0;
            error_o             <= 0;
        end
        else
        begin
            ss                  <= ss_next;
            out_port_o          <= out_port_next;
            downstream_vc_o     <= downstream_vc_next;
            end_packet          <= end_packet_next;
            vc_allocatable_o    <= vc_allocatable_next;
            error_o             <= error_next;
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
		data_o.vc_id = downstream_vc_o;
		data_o.data = read_flit.data;

        ss_next = ss;
        out_port_next = out_port_o;
        downstream_vc_next = downstream_vc_o;

        read_cmd = 0;
        write_cmd = 0;

        end_packet_next = end_packet;
        error_next = 0;

        vc_request_o = 0;
        switch_request_o = 0;
        vc_allocatable_next = 0;

        unique case(ss)
            IDLE:
            begin
                if((data_i.flit_label == HEAD | data_i.flit_label == HEADTAIL) & write_i & is_empty_o)
                begin
                    ss_next = VA;
                    out_port_next = out_port_i;
                    write_cmd = 1;
                end

                if(vc_valid_i | read_i | ((data_i.flit_label == BODY | data_i.flit_label == TAIL) & write_i) | ~is_empty_o)
                begin
                    error_next = 1;
                end
                if(write_i & data_i.flit_label == HEADTAIL)
                begin
                    end_packet_next = 1;
                end
            end

            VA:
            begin
                if(vc_valid_i)
                begin
                    ss_next = SA;
                    downstream_vc_next = vc_new_i;
                end

                vc_request_o = 1;
                if(write_i & (data_i.flit_label == BODY | data_i.flit_label == TAIL) & ~end_packet)
                begin
                    write_cmd = 1;
                end

                if((write_i & (end_packet | data_i.flit_label == HEAD | data_i.flit_label == HEADTAIL)) | read_i)
                begin
                    error_next = 1;
                end
                if(write_i & data_i.flit_label == TAIL)
                begin
                    end_packet_next = 1;
                end
            end

            SA:
            begin
                if(read_i & (data_o.flit_label == TAIL | data_o.flit_label == HEADTAIL))
                begin
                    ss_next = IDLE;
                    vc_allocatable_next = 1;
                    end_packet_next = 0;
                end

                if(~is_empty_o)
                begin
                    switch_request_o = 1;
                end
                    
                read_cmd = read_i;
                if(write_i & (data_i.flit_label == BODY | data_i.flit_label == TAIL) & ~end_packet)
                begin
                    write_cmd = 1;
                end

                if((write_i & (end_packet | data_i.flit_label == HEAD | data_i.flit_label == HEADTAIL)) | vc_valid_i)
                begin
                    error_next = 1;
                end
                if(write_i & data_i.flit_label == TAIL)
                begin
                    end_packet_next = 1;
                end
            end

            default:
            begin
                ss_next = IDLE;
                vc_allocatable_next = 1;
                error_next = 1;
                end_packet_next = 0;
            end

        endcase
    end

endmodule