`timescale 1ns / 1ps

import noc_params::*;

module tb_circular_buffer #(
    parameter BUFFER_SIZE=8
);

    integer i;
    integer j = 0;
    
    logic clk,rst;
    logic read_i;
    logic write_i;

    flit_t flit_vector[BUFFER_SIZE-1:0];
    flit_t flit_new;
    flit_t flit_x;
    flit_t data_i;
    flit_t data_o;
    wire is_full_o;
    wire is_empty_o;

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        write_until_saturate();
        write_while_full();
        read_and_write_while_full();
        refill_vector();
        read_until_empty();
        read_while_empty();
        #20 $finish;
    end

    always #5 clk = ~clk;

    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
        )
    circular_buffer (
        .*
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_circular_buffer);
        
        for (i = 0; i < BUFFER_SIZE; i = i + 1)
            $dumpvars(0, tb_circular_buffer.circular_buffer.memory[i]);
    endtask

    task initialize();
        clk     <= 0;
        rst     = 1;
        read_i  = 0;
        write_i = 0;
  		fill_vector_and_new();
    endtask

    task clear_reset();
        repeat(5) @(posedge clk);
            rst <= 0;
    endtask

    task write_until_saturate();
        for( i = 0; i < BUFFER_SIZE; i = i + 1)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= is_full_o ? 0 : 1;
            data_i <= flit_vector[i];
            if(~is_empty_o & i > 1)
                $display("[Write] Passed");
            else if(is_empty_o & i > 1)
                $display("[Write] Not Passed");
        end
        for( i = 0; i < 2; i = i + 1 )
        begin
        	@(posedge clk);
        	if(~is_empty_o)
            	$display("[Write] Passed");
        	else if(is_empty_o)
        		$display("[Write] Failed");
       	end
    endtask
    
    task write_while_full();
    	@(posedge clk);
        read_i  <= 0;
        write_i <= 1;
        data_i <= flit_x;
        if(is_full_o & i > 1)
        	$display("[Write Saturate] Passed");
  		else
    	    $display("[Write Saturate] Failed");
   	endtask;
	
    task read_and_write_while_full();
        @(posedge clk);
        read_i  <= 1;
        write_i <= 1;
        data_i <= flit_new;
        check_flits();
        j = 1;
        for( i = 0; i < 2; i = i + 1 )
            @(posedge clk);
        if(is_full_o)
        	$display("[Read and Write while Full] Passed");
        else 
            $display("[Read and Write while Full] Failed");
    endtask
	
	task read_until_empty();
        for(i = 0; i < BUFFER_SIZE; i = i + 1) 
        begin
            @(posedge clk);
            read_i  <= is_empty_o ? 0 : 1;
            write_i <= 0;
            if(i < BUFFER_SIZE - 1)
           		check_flits();
           	j = j + 1;
        end
        for( i = 0; i < 2; i = i + 1 )
        	@(posedge clk);
        if(is_empty_o)
        	$display("[Read until empty] Passed");
        else 
        	$display("[Read until empty] Failed");
    endtask

    task read_while_empty();
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 1;
            write_i <= 0;
        end
        for( i = 0; i < 2; i = i + 1 )
        	@(posedge clk);
        if(is_empty_o)
        	$display("[Read while empty] Passed");
        else 
          	$display("[Read while empty] Failed");
    endtask

    task fill_vector_and_new();
    	for( i = 0; i < BUFFER_SIZE; i = i + 1)
    	begin
            flit_vector[i].flit_label <= HEAD;
            flit_vector[i].data.head_data.vc_id <= {VC_SIZE{i}};
            flit_vector[i].data.head_data.x_dest <= {DEST_ADDR_SIZE{i}};
    	    flit_vector[i].data.head_data.y_dest <= {DEST_ADDR_SIZE{i}}; 
  	    	flit_vector[i].data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{i}};
  	    end
  	    	flit_new.flit_label <= HEAD;
  	        flit_new.data.head_data.vc_id <= {VC_SIZE{BUFFER_SIZE}};
  	        flit_new.data.head_data.x_dest <= {DEST_ADDR_SIZE{BUFFER_SIZE}};
  	       	flit_new.data.head_data.y_dest <= {DEST_ADDR_SIZE{BUFFER_SIZE}}; 
  	      	flit_new.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{BUFFER_SIZE}};
    endtask;
    
    task refill_vector();
    	for( i = 0; i < BUFFER_SIZE; i = i + 1)
		begin
            flit_vector[i].flit_label <= HEAD;
            flit_vector[i].data.head_data.vc_id <= {VC_SIZE{i + 1}};
            flit_vector[i].data.head_data.x_dest <= {DEST_ADDR_SIZE{i + 1}};
        	flit_vector[i].data.head_data.y_dest <= {DEST_ADDR_SIZE{i + 1}}; 
      	   	flit_vector[i].data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{i + 1}};
      	end
    endtask 

    task check_flits();
    	if(flit_vector[j].flit_label == data_o.flit_label &
    	   flit_vector[j].data.head_data.vc_id == data_o.data.head_data.vc_id &
    	   flit_vector[j].data.head_data.x_dest == data_o.data.head_data.x_dest &
    	   flit_vector[j].data.head_data.y_dest == data_o.data.head_data.y_dest &
    	   flit_vector[j].data.head_data.head_pl == data_o.data.head_data.head_pl)
    		$display("[Read] Passed");
    	else
    		$display("[Read] Failed");    
    endtask 
    
endmodule