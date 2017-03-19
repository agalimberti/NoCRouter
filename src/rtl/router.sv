import noc_params::*;

module router(input clk, input rst, router2router if_router);



interface input_port2crossbar;
    
    flit_t flit;
    
    modport ip(
        output flit
    );
    
    modport xbar(
        input flit
    );
endinterface




    input_port
        #(.BUFFER_SIZE(8))
        ip0(
            .clk(clk),
            .rst(rst),
        );
    crossbar xbar;
    input_port2crossbar ip0_2_xbar;
    
    

endmodule