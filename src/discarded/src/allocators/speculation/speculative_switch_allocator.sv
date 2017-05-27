import noc_params::*;

module speculative_switch_allocator #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2
)(
    input rst,
    input clk,
    input [PORT_NUM-1:0][VC_NUM-1:0] on_off_i,
    input_block2switch_allocator.switch_allocator ib_if,
    vc_allocator2speculative_switch_allocator.speculative_switch_allocator va_if,
    switch_allocator2crossbar.switch_allocator xbar_if,
    output logic valid_flit_o [PORT_NUM-1:0]
);

    logic [PORT_NUM-1:0][PORT_NUM-1:0] non_spec_grants;
    logic [PORT_NUM-1:0][PORT_NUM-1:0] spec_grants;

    logic [VC_NUM-1:0] non_spec_granted_vc [PORT_NUM-1:0];
    logic [VC_NUM-1:0] spec_granted_vc [PORT_NUM-1:0];

    non_spec_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    non_spec_allocator (
        .rst(rst),
        .clk(clk),
        .on_off_i(on_off_i),
        .out_port_i(ib_if.out_port),
        .downstream_vc_i(ib_if.downstream_vc),
        .non_spec_request_i(ib_if.switch_request),
        .grants_o(non_spec_grants),
        .granted_vc_o(non_spec_granted_vc)
    );
    
    spec_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    spec_allocator (
        .rst(rst),
        .clk(clk),
        .out_port_i(ib_if.out_port),
        .spec_request_i(ib_if.vc_request),
        .grants_o(spec_grants),
        .granted_vc_o(spec_granted_vc)        
    );

    /*
    Combinational block:
    merge the two grants matrices obtained by the speculative
    and non-speculative allocators in order to obtain one
    final grants matrix, from which to compute:
    - the signals which control the Crossbar traversal,
    - the flit output by each Input Port,
    - the validity bit directed to the downstream Router
    */
    always_comb
    begin
        for(int port = 0; port < PORT_NUM ; port = port + 1)
        begin
            ib_if.valid_sel[port] = 1'b0;
            valid_flit_o[port] = 1'b0;
            ib_if.vc_sel[port] = {VC_SIZE{1'b0}};
            xbar_if.input_vc_sel[port] = {PORT_SIZE{1'b0}};
        end
        
        for(int in = 0; in < PORT_NUM; in = in + 1)
        begin
            for(int out = 0; out < PORT_NUM; out = out + 1)
            begin
                if(non_spec_grants[in][out] | (spec_grants[in][out] & ~is_non_spec_allocated(in, out)))
                begin
                    for(int vc = 0; vc < VC_NUM; vc = vc + 1)
                    begin
                        if(non_spec_granted_vc[in][vc])
                        begin
                            ib_if.vc_sel[in] = vc;
                            ib_if.valid_sel[in] = 1'b1;
                            valid_flit_o[out] = 1'b1;
                            xbar_if.input_vc_sel[out] = (PORT_SIZE)'(in);
                            break;
                        end
                    end
                    if(valid_flit_o[out] == 1'b0)   //i.e., the grant is speculative
                    begin
                        for(int vc = 0; vc < VC_NUM; vc = vc + 1)
                        begin
                            if(spec_granted_vc[in][vc] &  va_if.vc_valid[in][vc])
                            begin
                                ib_if.vc_sel[in] = vc;
                                ib_if.valid_sel[in] = 1'b1;
                                valid_flit_o[out] = 1'b1;
                                xbar_if.input_vc_sel[out] = (PORT_SIZE)'(in);
                                break;
                            end
                        end
                    end
                end
            end
        end
      
    end

    function logic is_non_spec_allocated (input int row, input int column);
        is_non_spec_allocated = 1'b0;
        for(int c = 0; c < PORT_NUM; c = c + 1)
        begin
            if(non_spec_grants[row][c])
            begin
                is_non_spec_allocated = 1'b1;
                break;
            end
        end
        for(int r = 0; r < PORT_NUM; r = r + 1)
        begin
            if(non_spec_grants[r][column])
            begin
                is_non_spec_allocated = 1'b1;
                break;
            end
        end
    endfunction

endmodule