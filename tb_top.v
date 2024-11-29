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
    wire pc_uart_rx;
    wire pc_uart_tx;
    wire pc_uart_rx_done;
    wire pc_uart_tx_start;
    wire pc_uart_tx_full;
    wire pc_uart_rx_empty;
    wire [7:0] pc_uart_rx_data;
    reg [7:0] pc_uart_tx_data;
    reg pc_uart_tx_start_reg;
    reg pc_uart_rx_done_reg;

    // Instantiate the MIPS module
    mips #(
        .SIZE(SIZE),
        .SIZE_OP(SIZE_OP),
        .CONTROL_SIZE(CONTROL_SIZE),
        .IF_ID_SIZE(IF_ID_SIZE),
        .ID_EX_SIZE(ID_EX_SIZE),
        .EX_MEM_SIZE(EX_MEM_SIZE),
        .MEM_WB_SIZE(MEM_WB_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MAX_INSTRUCTION(MAX_INSTRUCTION),
        .NUM_REGISTERS(NUM_REGISTERS),
        .MEM_SIZE(MEM_SIZE)
    ) uut (
        .i_rst(i_rst),
        .i_stall(1'b0),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .i_clk(i_clk),
        .rx_done_tick(uart_rx_done),
        .tx_done_tick(uart_tx_start)
    );

    // Instantiate the second UART module (PC simulation)
    wire tick;

    reg [31:0]regs[31:0];
    reg done = 0;
    baudrate_generator #(
        .COUNT(326)
    ) baud_gen (
        .clk(i_clk),
        .reset(i_rst),
        .tick(tick)
    );

    uart_tx #(
        .N(8),
        .COUNT_TICKS(16)
    ) uart_tx_inst (
        .clk(i_clk),
        .reset(i_rst),
        .tx_start(pc_uart_tx_start_reg),
        .tick(tick),
        .data_in(pc_uart_tx_data),
        .tx_done(pc_uart_tx_full),
        .tx(pc_uart_tx)
    );

    uart_rx #(
        .N(8),
        .COUNT_TICKS(16)
    ) uart_rx_inst (
        .clk(i_clk),
        .reset(i_rst),
        .tick(tick),
        .rx(o_uart_tx),
        .data_out(pc_uart_rx_data),
        .valid(pc_uart_rx_done),
        .state_leds(),
        .started()
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
        send_uart_command(8'd15); // Cantidad de instrucciones a cargar

        // Send the instructions
        send_uart_data(32'b00111100000000010000000000000011,32); //R1 = 3
        send_uart_data(32'b00111100000000100000000000000001,32); //R2 = 1
        send_uart_data(32'b00111100000000110000000000001001,32); //R3 = 9
        send_uart_data(32'b00111100000001000000000000000111,32); //R4 = 7
        send_uart_data(32'b00111100000001010000000000000011,32); //R5 = 3
        send_uart_data(32'b00111100000001100000000001100101,32); //R6 = 101
        send_uart_data(32'b00111100000001110000000000011001,32); //R7 = 25
        send_uart_data(32'b00000000001000100001100000100011,32); //R3 = R1 - R2 -> 2
        send_uart_data(32'b00000000011001000010100000100001,32); //R5 = R3 + R4 -> 9
        send_uart_data(32'b00000000011001100011100000100001,32); //R7 = R3 + R6 -> 103
        send_uart_data(32'b00000000011001000010100000100001,32); //R15 = R3 + R5
        send_uart_data(32'b00111100000011110000000010010100,32); //R15 = 300
        send_uart_data(32'b00111100000000010000000000000011,32); //R1 = 3
        send_uart_data(32'b00111100000000010000000000000011,32); //R1 = 3
        send_uart_data(32'b00111100000000010000000000000011,32); //R1 = 3

        
        // Set step-by-step mode
        //send_uart_command(8'h09); // Command to set step-by-step mode
        
        send_uart_command(8'h11); // Command to set step-by-step mode


        send_uart_command(8'h0D); // Command to start program

        // Request registers and latches
        //send_uart_command(8'h01); // Command to request registers

        #100000;
//
        send_uart_command(8'h02); // Command to request IF/ID latch
//
        //#100000;
        //send_uart_command(8'h03); // Command to request ID/EX latch
//
        //#100000;
        //send_uart_command(8'h04); // Command to request EX/MEM latch
//
        //#100000;
        //send_uart_command(8'h05); // Command to request MEM/WB latch
//
        //#100000;
//
        //// Advance one step
        //send_uart_command(8'h0A); // Command to advance one step
//
        //send_uart_command(8'h08); // Command to request registers
        //// Request registers and latches again
        //send_uart_command(8'h01); // Command to request registers
        //send_uart_command(8'h02); // Command to request IF/ID latch
        //send_uart_command(8'h03); // Command to request ID/EX latch
        //send_uart_command(8'h04); // Command to request EX/MEM latch
        //send_uart_command(8'h05); // Command to request MEM/WB latch
//
        //// Repeat until the end of the program
        //repeat (3) begin
        //    send_uart_command(8'h0A); // Command to advance one step
        //    send_uart_command(8'h01); // Command to request registers
        //    send_uart_command(8'h02); // Command to request IF/ID latch
        //    send_uart_command(8'h03); // Command to request ID/EX latch
        //    send_uart_command(8'h04); // Command to request EX/MEM latch
        //    send_uart_command(8'h05); // Command to request MEM/WB latch
        //end

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