import noc_params::*;

module input_port #(
    parameter BUFFER_SIZE = 8
    )(input clk, rst, rc_unit2input_port rc, flit_t data_i);

    input_buffer
        #(.BUFFER_SIZE(BUFFER_SIZE)) 
        ib0(
            .*
        );
        
    always_ff @(posedge clk)  
    begin
        //Simultaneous RC and BW
        
        //if(data_i.flit_label == HEAD)
            //Assert validity bit to RC unit
            
        //Assert read signal 
    end

endmodule