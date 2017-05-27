`timescale 1ns / 1ps

module tb_separable_input_first_allocator #(
    parameter AGENTS_NUM = 3,
    parameter RESOURCES_NUM = 3
);
    localparam [31:0] AGENTS_PTR_SIZE = $clog2(AGENTS_NUM);
    
    logic clk, rst;
    
    logic [RESOURCES_NUM-1:0][AGENTS_PTR_SIZE-1:0] curr_highest_priority_in, next_highest_priority_in;
    
    logic [AGENTS_NUM-1:0][AGENTS_PTR_SIZE-1:0] curr_highest_priority_out, next_highest_priority_out;   
    
    logic [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] requests_cmd ;
    
    logic [RESOURCES_NUM-1:0][AGENTS_NUM-1:0] grants_in_trasp, grants_out;
    
    logic [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] grants_in, grants_out_trasp; 

    wire [AGENTS_NUM-1:0][RESOURCES_NUM-1:0] grants; 
    

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        test();
        $display("[ALLOCATOR PASSED]");
        #5 $finish;
        
    end

    always #5 clk = ~clk;

    separable_input_first_allocator #(
        .AGENTS_NUM(AGENTS_NUM),
        .RESOURCES_NUM(RESOURCES_NUM)
    )
    separable_input_first_allocator (
        .clk(clk),
        .rst(rst),
        .requests_i(requests_cmd),
        .grants_o(grants)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_separable_input_first_allocator);
    endtask

    task initialize();
        clk <= 0;
        rst  = 1;
        for(int i=0; i < RESOURCES_NUM; i++)
        begin
            curr_highest_priority_in[i] <= 0;
            grants_in[i] <= 0;
        end
        for(int i=0; i < AGENTS_NUM ; i++)
        begin
            curr_highest_priority_out[i] <= 0;
            grants_out[i] <= 0;
        end
    endtask

    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask
    
    task test();
        repeat(10) @(posedge clk)//each agent requests some resources
        begin
            for(int j=0; j < AGENTS_NUM; j = j + 1)
            begin
                requests_cmd[j] <= {RESOURCES_NUM{$random}};
                check_in_grant(j); 
            end
            trasp_matrix_in();    
            for(int j=0; j<RESOURCES_NUM; j++)
                check_out_grant(j);
            trasp_matrix_out();
            check_matrices();
        end
    endtask
    
    task check_in_grant(input int k);
        grants_in[k]  =  {RESOURCES_NUM{1'b0}};
        next_highest_priority_in[k] = curr_highest_priority_in[k];
        for(int i = 0; i < RESOURCES_NUM; i = i + 1)
        begin
            if(requests_cmd[k][(curr_highest_priority_in[k] + i) % RESOURCES_NUM])
            begin
                grants_in[k][(curr_highest_priority_in[k] + i) % RESOURCES_NUM] = 1'b1; 
                next_highest_priority_in[k] = (curr_highest_priority_in[k] + i + 1) % RESOURCES_NUM;
                break;
            end
        end
        curr_highest_priority_in[k] = next_highest_priority_in[k];            
    endtask
    
    task check_out_grant(input int k);
        grants_out[k]  =  {RESOURCES_NUM{1'b0}};
        next_highest_priority_out[k] = curr_highest_priority_out[k];
        for(int i = 0; i < AGENTS_NUM; i = i + 1)
        begin
            if(grants_in_trasp[k][(curr_highest_priority_out[k] + i) % AGENTS_NUM])
            begin
                grants_out[k][(curr_highest_priority_out[k] + i) % AGENTS_NUM] = 1'b1;
                next_highest_priority_out[k] = (curr_highest_priority_out[k] + i + 1) % AGENTS_NUM;
                break;
            end
        end
        curr_highest_priority_out[k] = next_highest_priority_out[k];
    endtask
    
    task check_matrices();
        for(int g = 0; g < AGENTS_NUM; g = g + 1)
        begin
            for(int h = 0; h < RESOURCES_NUM; h = h + 1)
            begin
            if(grants[g][h]!==grants_out_trasp[g][h])
                begin
                    $display("[ARBITER FAILED] %d,%d  out: %d controllo: %d", g, h, grants[g][h],grants_out_trasp[g][h]);
                    #5 $finish;
                end
            end
        end
    endtask
    
    task trasp_matrix_in();
        for(int i = 0; i < AGENTS_NUM ; i++)
        begin
            for(int j = 0; j < RESOURCES_NUM; j++)
            begin
                grants_in_trasp[j][i] = grants_in[i][j]; 
            end
        end
    endtask
    
    task trasp_matrix_out();
        for(int i = 0; i < RESOURCES_NUM ; i++)
        begin
            for(int j = 0; j < AGENTS_NUM; j++)
            begin
                grants_out_trasp[j][i] = grants_out[i][j];
            end
        end
    endtask
endmodule