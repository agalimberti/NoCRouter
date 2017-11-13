`timescale 1ns / 1ps

import noc_params::*;

module tb_input_buffer #(
    parameter BUFFER_SIZE = 8
);

    int i;
    int num_operation;

    logic clk, rst;
    logic read_i;
    logic write_i;
    logic [VC_SIZE-1:0] vc_new_i;
    logic vc_valid_i;

    logic req_check, req_check_next;
    logic alloc_check, alloc_check_next;
    
    port_t out_port_i;
    port_t out_port_o;

    flit_t flit_queue[$];
    flit_t flit_written;
    flit_t flit_read;
    flit_novc_t data_i;
    flit_t data_o;

    wire is_full_o;
    wire is_empty_o;
    wire on_off_o;
    wire vc_request_o;
    wire vc_allocatable_o;

    input_buffer #(
        .BUFFER_SIZE(BUFFER_SIZE)
    )
    input_buffer (
        .data_i(data_i),
        .read_i(read_i),
        .write_i(write_i),
        .vc_new_i(vc_new_i),
        .vc_valid_i(vc_valid_i),
        .out_port_i(out_port_i),
        .rst(rst),
        .clk(clk),
        .data_o(data_o),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o),
        .out_port_o(out_port_o),
        .on_off_o(on_off_o),
        .vc_request_o(vc_request_o),
        .vc_allocatable_o(vc_allocatable_o)
    );

    /*
    The testbench inserts 2 packets in the buffer
    each packet has different current_vc and next_vc values
    to test that the vc_id changes correctly
    */
    initial
    begin
        dump_output();
        initialize();
        clear_reset();
        insert_packet(NORTH, 0, 1);
        read_packet();
        insert_packet(WEST, 1, 0);
        read_packet();
        #20 $finish;
    end

    always #5 clk = ~clk;

    always_ff @(posedge clk, posedge rst)
    begin
        if(rst)
        begin
            req_check   <= 0;
            alloc_check <= 0;
        end
        else
        begin
            req_check   <= req_check_next;
            alloc_check <= alloc_check_next;
            
            if(req_check != vc_request_o)
            begin
                $display("ERROR: vc_request_o %d", $time);
                $finish;   
            end
            
            if(alloc_check != vc_allocatable_o)
            begin
                $display("ERROR: vc_allocatable_o %d", $time);
                $finish;   
            end  
        end
            
    end
    
    always_comb
    begin
        req_check_next      = req_check;
        alloc_check_next    = alloc_check;  
             
        if(data_i.flit_label == HEAD & is_empty_o)
            req_check_next = 1;
        if(vc_valid_i == 1)
            req_check_next = 0;
            
        if(data_o.flit_label == TAIL)
            alloc_check_next = 1;
        if(alloc_check & is_empty_o)
            alloc_check_next = 0;
    end
    
    task read_flit();
        /*
        checks whether the buffer is empty or not and
        if are at least at 2 cycles from the first write
        */
        if(i == 0)
            return;
        else
        begin
            flit_read=flit_queue.pop_front();
            @(posedge clk)
                write_i <= 0;
                read_i  <= 1;
                i = i - 1;
                num_operation = num_operation + 1;
            @(negedge clk)
                check_flits();
        end
    endtask

    task write_flit(input logic [VC_SIZE-1:0] next_vc);
        /*
        Checks whether the buffer is full or not.
        If not, a flit is inserted both in the buffer and in the queue.
        The flit that has been inserted in the buffer has the current_vc
        while the one inserted in the queue has the new vc value.
        */
        if(i == BUFFER_SIZE - 1)
            return;
        else
        begin
            read_i  <= 0;
            write_i <= 1;
            data_i.flit_label <= flit_written.flit_label;
            data_i.data <= flit_written.data;
            push_flit(next_vc);
            i = i + 1;
            num_operation = num_operation + 1;
        end
        @(posedge clk)
        read_i  <= 0;
        write_i <= 0;
    endtask

    task dump_output();
        $dumpfile("out.vcd");
        $dumpvars(0, tb_input_buffer);
    endtask

    task initialize();
        clk     <= 0;
        rst     = 1;
        read_i  = 0;
        write_i = 0;
        i = 0;
        num_operation = 0;
    endtask

    task clear_reset();
        repeat(2) @(posedge clk);
            rst <= 0;
    endtask
    /*
        The packet is created and then inserted in the buffer with the
        specified values of input port, current_vc and next_vc.
        At half of the write of the packet the buffer is emptied,
        to check the correct behaviour of the buffer.
    */
    task insert_packet(input port_t p, input logic [VC_SIZE-1:0] curr_vc, input logic [VC_SIZE-1:0] next_vc);
        create_flit(HEAD, curr_vc);
        out_port_i <= p;
        @(posedge clk)
        begin
            write_flit(next_vc);
        end
        create_flit(BODY, curr_vc);
        @(posedge clk)
        begin
            vc_valid_i  <= 1;
            vc_new_i    <= next_vc;
            write_flit(next_vc);
        end
        repeat(2) @(posedge clk)
            read_flit();
        create_flit(BODY, curr_vc);
        @(posedge clk)
        begin
            vc_valid_i  <= 0;
            write_flit(next_vc);
        end
        create_flit(TAIL, curr_vc);
        @(posedge clk)
        begin
            write_flit(next_vc);
        end
        @(posedge clk)
            write_i <= 0;
    endtask

    task create_flit(input flit_label_t lab, input logic [VC_SIZE-1:0] curr_vc);
        flit_written.flit_label <= lab;
        flit_written.vc_id <= curr_vc;
        if(lab == HEAD)
        begin
            flit_written.data.head_data.x_dest  <= {DEST_ADDR_SIZE_X{num_operation}};
            flit_written.data.head_data.y_dest  <= {DEST_ADDR_SIZE_Y{num_operation}};
            flit_written.data.head_data.head_pl <= {HEAD_PAYLOAD_SIZE{num_operation}};
        end
        else
        begin
            flit_written.data.bt_pl <= {FLIT_DATA_SIZE{num_operation}};
        end
    endtask
    /*
    Checks the correspondance between the flit extracted 
    from the queue and the one in data_o.
    If the check goes wrong an error message is displayed
    and the testbench ends.
    */
    task check_flits();
        if(~(flit_read == data_o))
        begin
            $display("[READ] FAILED");
            #40 $finish;
        end
        else
            $display("[READ] PASSED");
    endtask

    task push_flit(input logic [VC_SIZE-1:0] vc);
        flit_written.vc_id = vc;
        flit_queue.push_back(flit_written);
    endtask

    task read_packet();
        repeat(5)
        begin
            read_flit();
        end
    endtask

endmodule