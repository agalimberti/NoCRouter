`timescale 1ns / 1ps

import noc_params::*;

module tb_rc_unit #(
    parameter X_CURRENT = MESH_SIZE / 2,
    parameter Y_CURRENT = MESH_SIZE / 2
);

    logic [DEST_ADDR_SIZE-1 : 0] x_dest_i;
    logic [DEST_ADDR_SIZE-1 : 0] y_dest_i;
    port_t out_port_o;

	initial
    begin
        dump_output();
        compute_all_destinations_mesh();
        #5 $finish;
    end

    rc_unit #(
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT)
    )
    rc_unit (
        .*
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_rc_unit);
    endtask

    task compute_all_destinations_mesh();
        #5 x_dest_i = 0;
        y_dest_i = 0;
        repeat(MESH_SIZE)
        begin
            repeat(MESH_SIZE - 1)
            begin
                #5 x_dest_i ++;
            end
            #5 x_dest_i = 0;
            y_dest_i ++;
        end
        y_dest_i = 0;
    endtask

endmodule