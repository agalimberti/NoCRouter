`timescale 1ns / 1ps

module tb_circular_buffer #(
    parameter BUFFER_SIZE=8, 
    parameter FLIT_SIZE=8
);
    
    integer i;
    
    logic clk,rst;
    logic read_i;
    logic write_i;
    
    logic [FLIT_SIZE-1:0] data_i;
    wire [FLIT_SIZE-1:0] data_o;
    wire is_full_o;
    wire is_empty_o;
    
    initial
    begin
    
        $dumpfile("out.vcd");
        $dumpvars(0, tb_circular_buffer);
        
        // Dynamic dumping of the memory cells of the DUT
        for (i = 0; i < BUFFER_SIZE; i = i + 1)
            $dumpvars(0, tb_circular_buffer.circular_buffer.memory[i]);
        
        // Initialize input signals of the DUT
        clk     <= 0;
        rst     = 1;
        read_i  = 0;
        write_i = 0;
        data_i  = 0;
        
        // Clear rst
        repeat(5) @(posedge clk);
            rst<=0;
        
        // writes up to buffer saturation
        repeat(12)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= is_full_o ? 0 : 1;
            data_i  <= {FLIT_SIZE{$random}};
        
        end
        
        //writes try with full buffer
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= 1;
            data_i  <= {FLIT_SIZE{$random}};
        end
        
        //simultaneous read/write with full buffer
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 1;
            write_i <= 1;
            data_i  <= {FLIT_SIZE{$random}};
        end
        
        //no operations
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= 0;
        end
        
        // reads until empty buffer
        repeat(12)
        begin
            @(posedge clk);
            read_i  <= is_empty_o ? 0 : 1;
            write_i <= 0;
            data_i  <= {FLIT_SIZE{$random}};
        end
        
        //reads try with empty buffer
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 1;
            write_i <= 0;
            data_i  <= {FLIT_SIZE{$random}};
        end
        
        //no operations
        repeat(2)
        begin
            @(posedge clk);
            read_i  <= 0;
            write_i <= 0;
        end
        
        //random, possibly simultaneous, reads/writes
        repeat(15)
        begin
            @(posedge clk);
            read_i  <= is_empty_o ? 0 : $random;
            write_i <= is_full_o ? 0 : $random;
            data_i  <= {FLIT_SIZE{$random}};
        end
        
        #20 $finish;
    
    end //end initial block
    
    // Clock update
    always #5 clk =~clk;
    
    // DUT
    circular_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .FLIT_SIZE(FLIT_SIZE)
         )
    circular_buffer (
        .* 
    );
endmodule