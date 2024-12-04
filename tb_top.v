`timescale 1ns / 1ps

module tb_top;

    // Parameters
    parameter SIZE = 32;
    parameter SIZE_OP = 6;
    parameter CONTROL_SIZE = 18;
    parameter IF_ID_SIZE = 32;
    parameter ID_EX_SIZE = 129;
    parameter EX_MEM_SIZE = 77;
    parameter MEM_WB_SIZE = 71;
    parameter ADDR_WIDTH = 32;
    parameter MAX_INSTRUCTION = 64;
    parameter NUM_REGISTERS = 32;
    parameter MEM_SIZE = 64;

    // Signals
    reg i_rst;
    reg i_clk;
    wire i_uart_rx;
    wire o_uart_tx;
    wire uart_rx_done;
    wire uart_tx_start;
    wire uart_tx_full;
    wire uart_rx_empty;
    wire [7:0] uart_rx_data;
    wire [7:0] uart_tx_data;

    // Signals for the second UART module (PC simulation)
    wire pc_uart_tx;
    wire pc_uart_rx_done;
    wire pc_uart_tx_start;
    wire pc_uart_tx_full;
    wire pc_uart_rx_empty;
    wire [7:0] pc_uart_rx_data;
    reg [7:0] pc_uart_tx_data;
    reg pc_uart_tx_start_reg;
    reg pc_uart_rx_done_reg;
    reg [31:0]regs[31:0];


    // Instantiate the MIPS module
    mips #(
        .SIZE(SIZE),
        .SIZE_OP(SIZE_OP),
        .CONTROL_SIZE(CONTROL_SIZE),
        //.IF_ID_SIZE(IF_ID_SIZE),
        //.ID_EX_SIZE(ID_EX_SIZE),
        //.EX_MEM_SIZE(EX_MEM_SIZE),
        //.MEM_WB_SIZE(MEM_WB_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MAX_INSTRUCTION(MAX_INSTRUCTION),
        .NUM_REGISTERS(NUM_REGISTERS),
        .MEM_SIZE(MEM_SIZE)
    ) uut (
        .i_rst(i_rst),
        .i_stall(1'b0),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .i_clk(i_clk)
        //.rx_done_tick(uart_rx_done),
        //.tx_done_tick(uart_tx_start)
    );

    // Instantiate the UART module (PC simulation)
    uart #(
        .DBIT(8),
        .SB_TICK(16),
        .DVSR(651),   // 9600 baud rate with 10MHz clock
        .DVSR_BIT(10),
        .FIFO_W(4)
    ) uart_inst (
        .clk(i_clk),
        .reset(i_rst),
        .rd_uart(pc_uart_rx_done_reg),
        .wr_uart(pc_uart_tx_start_reg),
        .rx(o_uart_tx),
        .w_data(pc_uart_tx_data),
        .tx_full(pc_uart_tx_full),
        .rx_empty(pc_uart_rx_empty),
        .tx(pc_uart_tx),
        .r_data(pc_uart_rx_data)
    );

    // Connect the UART modules
    assign i_uart_rx = pc_uart_tx;

    // Clock generation
    always #5 i_clk = ~i_clk;

    // Testbench procedure
    initial begin
        // Initialize signals
        i_clk = 0;
        i_rst = 1;
        pc_uart_tx_start_reg = 0;
        pc_uart_rx_done_reg = 0;

        // Reset the system
        #10 i_rst = 0;

        // Set continuous mode
        send_uart_command(8'h08); // Command to set continuous mode
        // Load a short test program
        send_uart_command(8'h07); // Command to start loading program
        send_uart_command(8'd11); // Cantidad de instrucciones a cargar
        // Send the instructions
        send_uart_data(32'b00111100000000010000000000000001, 32); // LUI R1, 1
        send_uart_data(32'b00111100000000110000000000000011, 32); // LUI R3, 3
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP 
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP
        send_uart_data(32'b10100100001000010000000000000001, 32); // SH, R1 -> MEM[1]
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP
        send_uart_data(32'b10000100001001010000000000000001, 32); // LH, R5 <- MEM[1]
        send_uart_data(32'b00000000101000110011100000100001, 32); // R7 = R5 + R3 => Anda
        send_uart_data(32'b00111100000010110000000000000011, 32); // NOP
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP 

        send_uart_command(8'h11); // Command to set step-by-step mode
        wait_for_ready(); // Wait for 'R'
     
        //send_uart_command(8'h0E); 

        //send_uart_command(8'h07); // Command to start program        
        send_uart_command(8'h0D); // Command to start program
        
        #10000000;
        send_uart_command(8'h0B);
        send_uart_command(8'h02);
        receive_data_from_uart(4);
        wait_for_ready();
        
        //send_uart_command(8'h09); // Command to set step-by-step mode


        // Request registers and latches
        //send_uart_command(8'h01); // Command to request registers

        // Set step-by-step mode
        //send_uart_command(8'h09); // Command to set step-by-step mode
        //wait_for_ready(); // Wait for 'R'

        send_uart_command(8'h02); // Command to request IF/ID latch
        receive_data_from_uart(4); // Receive 4 bytes of data

        wait_for_ready(); // Wait for 'R'

        send_uart_command(8'h03); // Command to request ID/EX latch
        receive_data_from_uart(17); // Receive 17 bytes of data
        wait_for_ready(); // Wait for 'R'
        
        send_uart_command(8'h04); // Command to request mem ex latch
        receive_data_from_uart(10); // Receive 17 bytes of data
        wait_for_ready;

        send_uart_command(8'h05); // Command to request MEM/WB latch
        receive_data_from_uart(9); // Receive 9 bytes of data
        wait_for_ready(); // Wait for 'R'

        send_uart_command(8'h0a); // Command to step

        send_uart_command(8'h02); // Command to request IF/ID latch
        receive_data_from_uart(5); // Receive 4 bytes of data

        send_uart_command(8'h03); // Command to request ID/EX latch
        receive_data_from_uart(17); // Receive 17 bytes of data
        wait_for_ready(); // Wait for 'R'
        
        send_uart_command(8'h04); // Command to request ID/EX latch
        receive_data_from_uart(10); // Receive 17 bytes of data
        wait_for_ready;

        send_uart_command(8'h05); // Command to request MEM/WB latch
        receive_data_from_uart(9); // Receive 9 bytes of data
        wait_for_ready(); // Wait for 'R'


        // Finish simulation
        #10000 $finish;
    end

    task receive_registers;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                @(negedge pc_uart_rx_done);
                regs[i] = pc_uart_rx_data;
            end
            $display("Registers:");
            for (i = 0; i < 32; i = i + 1) begin
                $display("R%d: %d", i, regs[i]);
            end
        end
    endtask

    task receive_data_from_uart;
        input integer num_bytes;
        integer i;
        reg [7:0] data [0:31];
        begin
            for (i = 0; i < num_bytes; i = i + 1) begin
                @(negedge pc_uart_rx_done);
                data[i] = pc_uart_rx_data;
            end
            $display("Data received:");
            for (i = 0; i < num_bytes; i = i + 1) begin
                $write("%h ", data[i]);
            end
            $display("");
        end
    endtask

    // Task to send UART command
    task send_uart_command(input [7:0] command);
        begin
            @(negedge i_clk);
            pc_uart_tx_data = command;
            pc_uart_tx_start_reg = 1;
            @(negedge pc_uart_tx_full);
            pc_uart_tx_start_reg = 0;
        end
    endtask

    // Task to send UART data
    task send_uart_data(input [31:0] data, input integer data_size);
        integer i;
        begin
            for (i = 0; i < data_size/8; i = i + 1) begin
                send_uart_command(data[8*i +: 8]);
            end
        end
    endtask

    // Function to wait for 'R' indicating ready
    task wait_for_ready;
        begin
            @(posedge pc_uart_rx_done);
            while (pc_uart_rx_data != "R") begin
                @(posedge pc_uart_rx_done);
            end
        end
    endtask

    // Control the read signal for the PC UART
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pc_uart_rx_done_reg <= 0;
        end else begin
            if (!pc_uart_rx_empty) begin
                pc_uart_rx_done_reg <= 1;
            end else begin
                pc_uart_rx_done_reg <= 0;
            end
        end
    end

    assign pc_uart_tx_start = pc_uart_tx_start_reg;

endmodule