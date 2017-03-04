`timescale 1ns / 1ps

import port_type_package::*;

module tb_rc_unit #(
    parameter X_CURRENT = 2,
    parameter Y_CURRENT = 2
);

    int x_dest;
    int y_dest;
    port_type out_port;

	initial
    begin
        dump_output();
        all_destinations_5x5_mesh();
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

    task all_destinations_5x5_mesh();
        x_dest = 0;
        y_dest = 0;
        repeat(5)
        begin
            repeat(4)
            begin
                #5 ++x_dest;
            end
            #5 x_dest = 0;
            ++y_dest;
        end
        y_dest = 0;
    endtask

endmodule