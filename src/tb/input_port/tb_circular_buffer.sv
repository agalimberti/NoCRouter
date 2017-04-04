`timescale 1ns / 1ps

import noc_params::*;

module tb_circular_buffer #(
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5
);

    integer i;
    integer j = 0;
    
    logic clk,rst;
    logic read_i;
    logic write_i;
    logic on_off_o;

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
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH)
    )
    circular_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .rst(rst),
        .clk(clk),
        .data_o(data_o),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o),
        .on_off_o(on_off_o)
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
            if(is_empty_o & i > 1)
            begin
                $display("[BUFFER WRITE] Failed");
                return;
            end
        end
        for( i = 0; i < 2; i = i + 1 )
        begin
        	@(posedge clk);
        	if(is_empty_o)
        	begin
        		$display("[BUFFER WRITE] Failed");
        		return;
        	end
       	end
       	if(is_full_o)
       		$display("[BUFFER WRITE UNTIL SATURATE] Passed");
       	else
       	  	begin
       		$display("[BUFFER WRITE UNTIL SATURATE] Failed");
       	    return;
       	end
    endtask
    
    task write_while_full();
    	@(posedge clk);
        read_i  <= 0;
        write_i <= 1;
        data_i <= flit_x;
        if(is_full_o & i > 1)
        	$display("[BUFFER WRITE WHILE FULL] Passed");
  		else
  		begin
    	    $display("[BUFFER WRITE WHILE FULL] Failed");
    	    return;
    	end
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
        	$display("[BUFFER READ AND WRITE WHILE FULL] Passed");
        else
        begin
            $display("[BUFFER READ AND WRITE WHILE FULL] Failed");
            return;
        end 
    endtask
	
	task read_until_empty();
        for(i = 0; i < BUFFER_SIZE; i = i + 1) 
        begin
            @(posedge clk);
            read_i  <= is_empty_o ? 0 : 1;
            write_i <= 0;
            if(i < BUFFER_SIZE - 1)
            begin
            	if(~check_flits())
            	begin 
            		$display("[BUFFER READ] Failed");
            		return;
            	end
            end
           		
           	j = j + 1;
        end
        for( i = 0; i < 2; i = i + 1 )
        	@(posedge clk);
        if(is_empty_o)
        	$display("[BUFFER READ UNTIL EMPTY] Passed");
        else
       	begin 
        	$display("[BUFFER READ UNTIL EMPTY] Failed");
        	return;
        end
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
        	$display("[BUFFER READ WHILE EMPTY] Passed");
        else
        begin 
          	$display("[BUFFER READ WHILE EMPTY] Failed");
          	return;
       	end
    endtask

    task fill_vector_and_new();
    	for( i = 0; i < BUFFER_SIZE; i = i + 1)
    	begin
            flit_vector[i].flit_label <= HEAD;
            flit_vector[i].vc_id <= {VC_SIZE{i}};
            flit_vector[i].data.head_data.x_dest <= {DEST_ADDR_SIZE_X{i}};
    	    flit_vector[i].data.head_data.y_dest <= {DEST_ADDR_SIZE_Y{i}}; 
  	    	flit_vector[i].data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{i}};
  	    end
  	    	flit_new.flit_label <= HEAD;
  	        flit_new.vc_id <= {VC_SIZE{BUFFER_SIZE}};
  	        flit_new.data.head_data.x_dest <= {DEST_ADDR_SIZE_X{BUFFER_SIZE}};
  	       	flit_new.data.head_data.y_dest <= {DEST_ADDR_SIZE_Y{BUFFER_SIZE}}; 
  	      	flit_new.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{BUFFER_SIZE}};
    endtask;
    
    task refill_vector();
    	for( i = 0; i < BUFFER_SIZE; i = i + 1)
		begin
            flit_vector[i].flit_label <= HEAD;
            flit_vector[i].vc_id <= {VC_SIZE{i + 1}};
            flit_vector[i].data.head_data.x_dest <= {DEST_ADDR_SIZE_X{i + 1}};
        	flit_vector[i].data.head_data.y_dest <= {DEST_ADDR_SIZE_Y{i + 1}}; 
      	   	flit_vector[i].data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{i + 1}};
      	end
    endtask 

    function logic check_flits();
    	if(flit_vector[j].flit_label == data_o.flit_label &
    	   flit_vector[j].vc_id == data_o.vc_id &
    	   flit_vector[j].data.head_data.x_dest == data_o.data.head_data.x_dest &
    	   flit_vector[j].data.head_data.y_dest == data_o.data.head_data.y_dest &
    	   flit_vector[j].data.head_data.head_pl == data_o.data.head_data.head_pl)
    	    check_flits = 1;
    	else
    		check_flits = 0;   
    endfunction 
    
endmodule