import noc_params::*;

/*
This is a first simplified version of the route computation unit module,
all the integer nets and variables have to be substituted
by more appropriate ones (see head flit scheme)
*/
module rc_unit #(
    parameter X_CURRENT = 0,
    parameter Y_CURRENT = 0
)(
    input int x_dest,
    input int y_dest,
    output port_t out_port
);

    int x_offset;
    int y_offset;

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
        end
    end

endmodule