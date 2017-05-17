import noc_params::*;

module rc_unit #(
    parameter X_CURRENT = 0,
    parameter Y_CURRENT = 0,
    parameter DEST_ADDR_SIZE_X = 4,
    parameter DEST_ADDR_SIZE_Y = 4
)(
    input logic [DEST_ADDR_SIZE_X-1 : 0] x_dest_i,
    input logic [DEST_ADDR_SIZE_Y-1 : 0] y_dest_i,
    output port_t out_port_o
);

    wire signed [DEST_ADDR_SIZE_X-1 : 0] x_offset;
    wire signed [DEST_ADDR_SIZE_Y-1 : 0] y_offset;

    assign x_offset = x_dest_i - X_CURRENT;
    assign y_offset = y_dest_i - Y_CURRENT;

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
        unique if (x_offset < 0)
        begin
            out_port_o = WEST;
        end
        else if (x_offset > 0)
        begin
            out_port_o = EAST;
        end
        else if (x_offset == 0 & y_offset < 0)
        begin
            out_port_o = NORTH;
        end
        else if (x_offset == 0 & y_offset > 0)
        begin
            out_port_o = SOUTH;
        end
        else
        begin
            out_port_o = LOCAL;
        end
    end

endmodule