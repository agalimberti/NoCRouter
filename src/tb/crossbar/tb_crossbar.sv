`timescale 1ns / 1ps

import noc_params::*;

module tb_crossbar;

    int j, k;

    flit_t flit_x;
    flit_t data_i [PORT_NUM-1:0];
    flit_t data_o [PORT_NUM-1:0];

    logic [PORT_SIZE-1:0] sel_cmd [PORT_NUM-1:0];

    initial
    begin
        dump_output();
        test();
        #5 $finish;
    end
    
    input_block2crossbar ib2xbar();
    switch_allocator2crossbar sa2xbar();
    
    mock_in mock_in (
        .data_i(data_i),
        .sel_cmd(sel_cmd),
        .ib_if(ib2xbar),
        .sa_if(sa2xbar)
    );

    crossbar crossbar (
        .ib_if(ib2xbar),
        .sa_if(sa2xbar),
        .data_o(data_o)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_crossbar);
    endtask

    task test();
        j = 0;
        k = 0;
        fill_flit_x();
        repeat(PORT_NUM)
        begin
            repeat(PORT_NUM)
            begin
                reset_data_i();
                for(int i = 0; i < PORT_NUM; i = i + 1)
                    sel_cmd[i] = corresp_output(i);
                #5
                if(~check_flits())
                begin
                   $display("[CROSSBAR] Failed");
                   return;
                end
                #5
                j = j + 1;
            end
            k = k + 1;
            j = 0;
        end
        $display("[CROSSBAR] Passed");
    endtask

    task reset_data_i();
        for(int i = 0; i < PORT_NUM; i = i + 1)
            data_i[i] <= flit_x;
        fill_data_i();
    endtask

    task fill_data_i();
        data_i[j].flit_label <= HEAD;
        data_i[j].vc_id <= 1;
        data_i[j].data <= {FLIT_DATA_SIZE{1'b1}};
    endtask

    task fill_flit_x();
        flit_x.flit_label <= HEAD;
        flit_x.vc_id <= {VC_SIZE{1'bx}};
        flit_x.data <= {FLIT_DATA_SIZE{1'bx}};
    endtask

    function logic check_flits();
        for(int i = 0; i < PORT_NUM; i = i + 1)
        begin
            if(data_i[corresp_output(i)] === data_o[i])
                check_flits = 1;
            else
            begin
                check_flits = 0;
                break;
            end
        end
    endfunction

    function int corresp_output(input int a);
        corresp_output = (a + k) % PORT_NUM;
    endfunction

endmodule

module mock_in 
(   
    input flit_t data_i [PORT_NUM-1:0], 
    logic [PORT_SIZE-1:0] sel_cmd [PORT_NUM-1:0], 
    input_block2crossbar.input_block ib_if, 
    switch_allocator2crossbar.switch_allocator sa_if
);
    assign ib_if.flit = data_i;
    assign sa_if.input_vc_sel = sel_cmd;

endmodule