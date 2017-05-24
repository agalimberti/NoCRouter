`timescale 1ns / 1ps

module tb_round_robin_arbiter #(
    parameter AGENTS_NUM = 4
);
    localparam [31:0] AGENTS_PTR_SIZE = $clog2(AGENTS_NUM);
    
    logic clk, rst;

    logic [AGENTS_NUM-1:0] requests_cmd;
    
    logic [AGENTS_PTR_SIZE-1:0] curr_highest_priority, next_highest_priority;
    
    logic first_test, starvation[AGENTS_NUM-1:0];

    wire [AGENTS_NUM-1:0] grants;
    
    int num_of_grants, agent_granted, count[AGENTS_NUM-1:0];

    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        test();
        $display("[ARBITER PASSED]");
        #5 $finish;
    end

    always #5 clk = ~clk;

    round_robin_arbiter #(
        .AGENTS_NUM(AGENTS_NUM)
    )
    round_robin_arbiter (
        .clk(clk),
        .rst(rst),
        .requests_i(requests_cmd),
        .grants_o(grants)
    );

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_round_robin_arbiter);
    endtask

    task initialize();
        clk <= 0;
        rst  = 1;
        curr_highest_priority <= 0;
        first_test = 1'b1;
        for(int i = 0; i < AGENTS_NUM; i++)
        begin
            count[i]=0;
            starvation[i]=1'b0;
        end
    endtask

    task clear_reset();
        @(posedge clk);
            rst <= 0;
     endtask
    
    /*
    We should test that:
    1) Only the agents that actually issued a request in the first place can actually receive a grant
    2) In case of conflict only one agent receive a grant
    3) Optional: if more than 1 agent request to access a shared resource, one of them will receive a grant
    */
    task test();
        @(posedge clk);
        repeat(10) 
        begin
            @(posedge clk)
            requests_cmd <= {AGENTS_NUM{$random}};
            check_grant();
        end
    endtask
    /*
    In order to check the correct behaviour of the round robin arbiter
    we need to be sure that the grants have been asserted only to the agents
    that requested them, also we need to check that in case of conflict only
    one agent has received the grant, and it is the one with highest priority
    of those in conflict
    */
    task check_grant();
        num_of_grants = 0;
        next_highest_priority = curr_highest_priority;
        for(int i = 0; i < AGENTS_NUM; i = i + 1)
        begin
            if(grants[i])
            begin
                num_of_grants = num_of_grants + 1;
            end
            if(requests_cmd[(curr_highest_priority + i) % AGENTS_NUM] & grants[(curr_highest_priority + i) % AGENTS_NUM])
            begin
                next_highest_priority = (curr_highest_priority + i + 1) % AGENTS_NUM;
                agent_granted = (curr_highest_priority + i) % AGENTS_NUM;
            end
        end
        for(int i = 0; i < AGENTS_NUM; i = i + 1)
        begin
            if(requests_cmd[(curr_highest_priority + i) % AGENTS_NUM] & ~grants[(curr_highest_priority + i) % AGENTS_NUM])
                count[(curr_highest_priority + i) % AGENTS_NUM]=count[(curr_highest_priority + i) % AGENTS_NUM]+1;
            else count[(curr_highest_priority + i) % AGENTS_NUM]=0;
        end
        for(int i = 0; i < AGENTS_NUM; i = i + 1)
        begin
            if(count[i]>10)
                starvation[i]=1'b1;
        end
        if(first_test)
        begin
            first_test = 1'b0;
            return;
        end
        if(num_of_grants > 1 || ~requests_cmd[agent_granted] || !grants[agent_granted])
        begin
            $display("[ARBITER FAILED] %d", $time);
            #10 $finish;
        end
        curr_highest_priority = next_highest_priority;           
    endtask
    
endmodule