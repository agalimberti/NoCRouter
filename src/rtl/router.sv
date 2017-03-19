import noc_params::*;

module router(input clk, input rst, router2router if_router);

    input_port2crossbar ip0_2_xbar;

    input_port
        #(.BUFFER_SIZE(8))
        ip0(
            .clk(clk),
            .rst(rst),
        );
     
    crossbar xbar;
    
endmodule
