`timescale 1ns / 1ps

import noc_params::*;

module tb_crossbar #(
    parameter INPUT_NUM = 4,
    parameter OUTPUT_NUM = 4
);

    localparam [31:0] SEL_SIZE = $clog2(INPUT_NUM);
    int i, j;
    flit_t flit_test;
    flit_t flit_x;
    flit_t data_i [INPUT_NUM-1:0];
    logic [SEL_SIZE-1:0] sel_i [OUTPUT_NUM-1:0];
    flit_t data_o [OUTPUT_NUM-1:0];

    initial
    begin
        dump_output();
        fill_flit_x();
        #5
        reset_data_i();
        test();
        #5 $finish;
    end

    crossbar #(
        .INPUT_NUM(INPUT_NUM),
        .OUTPUT_NUM(OUTPUT_NUM)
        )
    crossbar (
        .data_i(data_i),
        .sel_i(sel_i),
        .data_o(data_o)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_crossbar);
    endtask

    task test();
        j = 0;
        repeat(OUTPUT_NUM) 
        begin
            #5
            for(int i=0;i<OUTPUT_NUM;i++)
                sel_i[i] = i;
            #5
            if(~check_flits())
            begin
               $display("[CROSSBAR] Failed");
               return; 
            end
            j = j + 1;
            reset_data_i();
        end    	   
        $display("[CROSSBAR] Passed");
    endtask
        
    task reset_data_i();
        for( i = 0; i < INPUT_NUM; i = i + 1)
            data_i[i] <= flit_x;
        fill_data_i();
    endtask 
    
    task fill_data_i();
        data_i[j].flit_label <= HEAD;
        data_i[j].vc_id <= 1;
        data_i[j].data.head_data.x_dest <= 1;
        data_i[j].data.head_data.y_dest <= 1; 
        data_i[j].data.head_data.head_pl <= 1;
    endtask
    
    task fill_flit_x();
        flit_x.flit_label <= HEAD;
        flit_x.vc_id <= 10;
        flit_x.data.head_data.x_dest <= 10;
        flit_x.data.head_data.y_dest <= 10; 
        flit_x.data.head_data.head_pl <= 10; 
    endtask
    
    function logic check_flits();
        for( i = 0; i < INPUT_NUM; i = i + 1)
            if(data_i[i].flit_label == data_o[sel_i[i]].flit_label & 
                    data_i[i].vc_id == data_o[sel_i[i]].vc_id &
                    data_i[i].data.head_data.x_dest == data_o[sel_i[i]].data.head_data.x_dest &
                    data_i[i].data.head_data.y_dest == data_o[sel_i[i]].data.head_data.y_dest &
                    data_i[i].data.head_data.head_pl == data_o[sel_i[i]].data.head_data.head_pl)
                check_flits = 1;
            else
                check_flits = 0;    
    endfunction

endmodule