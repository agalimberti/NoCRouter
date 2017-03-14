import noc_params::*;

interface rc_unit2input_port;

    logic [DEST_ADDR_SIZE-1 : 0] x_dest;
    logic [DEST_ADDR_SIZE-1 : 0] y_dest;
    port_t out_port;
    
    modport rc_unit(
        input x_dest,
        input y_dest,
        output out_port
    );
    
    modport input_port(
        output x_dest,
        output y_dest,
        input out_port
    );  
endinterface


interface input_port2crossbar;
    
    flit_t flit;
    
    modport ip(
        output flit
    );
    
    modport xbar(
        input flit
    );
endinterface


module router(input clk, rst);

    rc_unit2input_port rc0_2_ip0;

    input_port
        #(.BUFFER_SIZE(8))
        ip0(
            .clk(clk),
            .rst(rst),
            .rc(rc0_2_ip0.ip)
        );
        
    rc_unit 
        #(.X_CURRENT(0),
          .Y_CURRENT(0))
        rc0(
            .ip(rc0_2_ip0.rc)
        );
    
    crossbar xbar;
    input_port2crossbar ip0_2_xbar;
    
    

endmodule