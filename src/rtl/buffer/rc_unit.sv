import noc_params::*;

module rc_unit #(
    parameter X_CURRENT = 0,
    parameter Y_CURRENT = 0
)(
    input logic [DEST_ADDR_SIZE-1 : 0] x_dest,
    input logic [DEST_ADDR_SIZE-1 : 0] y_dest,
    output port_t out_port
);

    logic signed [DEST_ADDR_SIZE-1 : 0] x_offset;
    logic signed [DEST_ADDR_SIZE-1 : 0] y_offset;

    /*
    Combinational logic:
    - the route computation follows a DOR (Dimension-Order Routing) algorithm,
      with the nodes of the Network-on-Chip arranged in a 2D mesh structure,
      hence with 5 inputs and 5 outputs per node (except for boundary routers),
      i.e., both for input and output:
        * left, right, up and down links to the adjacent nodes
        * one link to the end node
    - the 2D Mesh coordinates scheme is mapped as following:
        * X increasing from Left to Right
        * Y increasing from  Up  to Down
    */
    always_comb
    begin
        x_offset = x_dest - X_CURRENT;
        y_offset = y_dest - Y_CURRENT;

        unique if (x_offset < 0)
        begin
            out_port = LEFT;
        end
        else if (x_offset > 0)
        begin
            out_port = RIGHT;
        end
        else if (x_offset == 0 & y_offset < 0)
        begin
            out_port = UP;
        end
        else if (x_offset == 0 & y_offset > 0)
        begin
            out_port = DOWN;
        end
        else
        begin
            out_port = CENTER;
            /*
            branch taken also if the inputs are non-specified (x),
            hence the need for the usage of a validity bit
            */
        end
    end

endmodule