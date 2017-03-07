`timescale 1ns / 1ps

import noc_params::*;

int i;

module tb_crossbar #(
    parameter INPUT_NUM = 4,
    parameter OUTPUT_NUM = 4
);

    localparam [31:0] SEL_SIZE = $clog2(INPUT_NUM);

    flit_t data_i [INPUT_NUM-1:0];
    logic [SEL_SIZE-1:0] sel_i [OUTPUT_NUM-1:0];
    flit_t data_o [OUTPUT_NUM-1:0];

	initial
	begin
        dump_output();
        random_test();
		#5 $finish;
	end

	crossbar #(
        .INPUT_NUM(INPUT_NUM),
        .OUTPUT_NUM(OUTPUT_NUM)
        )
    crossbar (
        .*
    );

    task dump_output();
        $dumpfile("out.vcd");
		$dumpvars(0, tb_crossbar);
    endtask

    task random_test();
	    repeat(20)
	    begin
    		#5
            for(i=0;i<INPUT_NUM;i++)
                random_head_flit();
            for(int i=0;i<OUTPUT_NUM;i++)
                sel_i[i] = {SEL_SIZE{$random}};
        end
    endtask
        
    task random_head_flit();
        data_i[i].flit_label <= HEAD;
        data_i[i].data.head_data.vc_id <= {VC_SIZE{$random}};
        data_i[i].data.head_data.x_dest <= {DEST_ADDR_SIZE{$random}};
        data_i[i].data.head_data.y_dest <= {DEST_ADDR_SIZE{$random}}; 
        data_i[i].data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{$random}}; 
   endtask;

endmodule