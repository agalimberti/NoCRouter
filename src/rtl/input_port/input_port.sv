import noc_params::*;

module input_port #(
        parameter BUFFER_SIZE = 8
    )(  input clk, input rst, 
        input_port2crossbar if_crossbar, 
        input_port2switch_allocator if_sa
    );

    input_buffer
        #(.BUFFER_SIZE(BUFFER_SIZE)) 
        ib0(
            .*
        );
    
    rc_unit
        #(.X_CURRENT(0),
          .Y_CURRENT(0))
        rc(
            // TODO
        );
        
    always_ff @(posedge clk)  
    begin
        //Simultaneous RC and BW
        
        //if(data_i.flit_label == HEAD)
            //Assert validity bit to RC unit
            
        //Assert read signal 
    end

endmodule