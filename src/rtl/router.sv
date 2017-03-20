import noc_params::*;

module router(
    input clk, 
    input rst, 
    router2router router_if
);

    input_port2crossbar ip0_2_xbar;
    
    input_port
        #(.BUFFER_SIZE(8))
        ip0(
            .*,
            .crossbar_if(ip0_2_xbar)
        );
    
endmodule
