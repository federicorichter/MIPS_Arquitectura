`timescale 1ns / 1ps

module tb_top;

    // Parameters
    parameter SIZE = 32;
    parameter SIZE_OP = 6;
    parameter CONTROL_SIZE = 18;
    parameter SIZE_REG_DIR = 5;
    parameter IF_ID_SIZE = 64;
    parameter ID_EX_SIZE = 129;
    parameter EX_MEM_SIZE = 78;
    parameter MEM_WB_SIZE = 72;
    parameter MAX_INSTRUCTION = 64; // Define MAX_INSTRUCTION
    parameter NUM_REGISTERS = 32;
    parameter MEM_SIZE = 64; // Define MEM_SIZE
    parameter ADDR_WIDTH = $clog2(MEM_SIZE);

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
    wire [5:0] state_out;
    wire [4:0] byte_counter_out;
    wire [4:0] instruction_counter_out;

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
        .i_clk(i_clk),
        .state_out(state_out),
        // .instruction_count_out(instruction_count_out),
        .byte_counter_out(byte_counter_out),
        .instruction_counter_out(instruction_counter_out),
        .uart_rx_done_reg_out(uart_rx_done_reg_out)
        //.uart_rx_data_out(uart_rx_data_out)
        //.rx_done_tick(uart_rx_done),
        //.tx_done_tick(uart_tx_start)
    );

    // Instantiate the second UART module (PC simulation)
    wire tick;

    reg [31:0]regs[31:0];
    reg done = 0;
    baudrate_generator #(
        .COUNT(131)
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
    always #25 i_clk = ~i_clk;

    // Testbench procedure
    initial begin
        // Initialize signals
        i_clk = 0;
        i_rst = 1;
        pc_uart_tx_start_reg = 0;
        pc_uart_rx_done_reg = 0;

        // Reset the system
        #1000 i_rst = 0;

        // Set continuous mode
        send_uart_command(8'h09); // Command to set continuous mode
        // Load a short test program
        send_uart_command(8'h07); // Command to start loading program
        send_uart_command(8'd10); // Cantidad de instrucciones a cargar
        // Send the instructions
        /*send_uart_data(32'b00111100000000010000000000000011, 32); // R1 = 3
        send_uart_data(32'b00111100000000100000000000000001, 32); // R2 = 1
        send_uart_data(32'b00111100000000110000000000001001, 32); // R3 = 9
        send_uart_data(32'b00111100000001000000000000000111, 32); // R4 = 7
        send_uart_data(32'b00111100000001010000000000000011, 32); // R5 = 3
        send_uart_data(32'b00111100000001100000000001100101, 32); // R6 = 101
        send_uart_data(32'b00111100000001110000000000011001, 32); // R7 = 25
        send_uart_data(32'b00000000001000100001100000100011, 32); // R3 = R1 - R2 -> 2
        send_uart_data(32'b00000000011001000010100000100001, 32); // R5 = R3 + R4 -> 9
        send_uart_data(32'b00000000011001100011100000100001, 32); // R7 = R3 + R6 -> 103
        send_uart_data(32'b00000000011001000010100000100001, 32); // R15 = R3 + R5
        send_uart_data(32'b00111100000011110000000010010100, 32); // R15 = 300
        send_uart_data(32'b00111100000000010000000000000011, 32); // R1 = 3
        send_uart_data(32'b00111100000000010000000000000011, 32); // R1 = 3
        send_uart_data(32'b00111100000000010000000000000011, 32); // R1 = 3*/

        /*send_uart_data(32'b00111100000000010000000000001000,32); // LUI R1, 8 => parece q anda
        send_uart_data(32'b00111100000000110000000000000110,32); // LUI R3, 6
        send_uart_data(32'b00111100000000110000000000000110,32); // LUI R3, 6
        send_uart_data(32'b00111100000000110000000000000110,32); // LUI R3, 6 
        send_uart_data(32'b00000000001000000100100000001001,32); // JALR, R1, R9
        send_uart_data(32'b00111100000000110000000000000011,32); // LUI R3, 3
        send_uart_data(32'b00111100000000110000000000001111,32); // LUI R3, 15
        send_uart_data(32'b00111100000000110000000000001101,32); // LUI R3, 13 -> Salta aca
        send_uart_data(32'b00111100000000110000000000000101,32); // LUI R3, 5 
        send_uart_data(32'b00111100000000110000000000000100,32); // LUI R3, 4
        send_uart_data(32'b00111100000000110000000000000110, 32); // LUI R3, 6*/

        /*send_uart_data(32'b00111100000000010000000000000001, 32); // LUI R1, 1
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
        send_uart_data(32'b00111100000010110000000000000001, 32); // NOP */
        
        //send_uart_data(32'b0, 32);
        /*send_uart_data(32'b00100000000000010000000000001111, 32); // ADDI R1, R0, 15
        send_uart_data(32'b10100000000000010000000000000000, 32); // SB R1, 0(0)
        send_uart_data(32'b00100000001000100000000000000111, 32); // ADDI R2, R1, 7
        send_uart_data(32'b10100000000000100000000000001000, 32); // SB R2, 8(0)
        send_uart_data(32'b10000000000000110000000000001000, 32); // LB R3, 8(0)
        send_uart_data(32'b00110000011001000000000000001011, 32); // ANDI R4, R3, 11
        send_uart_data(32'b00100000100000010000000100010000, 32); // ADDI R4, R4, 272
        send_uart_data(32'b0, 32); // Primer set de prueba -> Funciona con reg */

        /*send_uart_data(32'b00100000000010100000000000001111, 32); // ADDI R10, R0, 15
        send_uart_data(32'b00100000000101000000000000001111, 32); // ADDI R20, R0, 15
        send_uart_data(32'b00010001010101000000000000000011, 32); // BNEQ R10, R20, 3
        send_uart_data(32'b0, 32); // ADDI R20, R0, 15
        send_uart_data(32'b00100000000001000000000000101000, 32); // ADDI R4, R0, 40
        send_uart_data(32'b00100000000001010000000000110010, 32); // ADDI R5, R0, 50
        send_uart_data(32'b00100000000001100000000000110010, 32); // ADDI R6, R0, 50
        send_uart_data(32'b00100000000000010000000000001010, 32); // ADDI R1, R0, 10  -> Salta aca
        send_uart_data(32'b00100000000000100000000000010100, 32); // ADDI R2, R0, 20
        send_uart_data(32'b00100000000000110000000000011110, 32); // ADDI R3, R0, 30 //rarisimo pero funciona con regs */ 

        send_uart_data(32'b00100000000000010000000000000110, 32); // ADDI R1, R0, 6
        send_uart_data(32'b00000000001000000101000000001001, 32); // JALR R10, R1
        send_uart_data(32'b0, 32);                                // NOP
        send_uart_data(32'b00100000000001000000000000000111, 32); // ADDI R4, R0, 40
        send_uart_data(32'b00100000000001010000000000000111, 32); // ADDI R5, R0, 40
        send_uart_data(32'b00100000000001100000000000000111, 32); // ADDI R6, R0, 40
        send_uart_data(32'b00100000000000010000000000001010, 32); // ADDI R1, R0, 10 -> Deberia saltar aca
        send_uart_data(32'b00100000000000100000000000000101, 32); // ADDI R2, R0, 5
        send_uart_data(32'b00100000000000110000000000000111, 32); // ADDI R3, R0, 7
        send_uart_data(32'b00000001010000000000000000001000, 32); // JR R10 funciona(? usando reg 

        /*send_uart_data(32'b00001000000000000000000000000101, 32); // J 5
        send_uart_data(32'b0, 32);                                // NOP
        send_uart_data(32'b00100000000001000000000000101000, 32); // ADDI R4, R0, 40
        send_uart_data(32'b00100000000001010000000000101000, 32); // ADDI R5, R0, 40
        send_uart_data(32'b00100000000001100000000000101000, 32); // ADDI R6, R0, 40 
        send_uart_data(32'b00100000000000010000000000001010, 32); // ADDI R1, R0, 10 -> Deberia saltar aca
        send_uart_data(32'b00100000000000100000000000000101, 32); // ADDI R2, R0, 5
        send_uart_data(32'b00100000000000110000000000000111, 32); // ADDI R3, R0, 7 -> anda */

        /*send_uart_data(32'b00001100000000000000000000000101, 32); // J 5
        send_uart_data(32'b0, 32);                                // NOP
        send_uart_data(32'b00100000000001000000000000101000, 32); // ADDI R4, R0, 40
        send_uart_data(32'b00100000000001010000000000101000, 32); // ADDI R5, R0, 40
        send_uart_data(32'b00100000000001100000000000101000, 32); // ADDI R6, R0, 40 
        send_uart_data(32'b00100000000000010000000000001010, 32); // ADDI R1, R0, 10 -> Deberia saltar aca
        send_uart_data(32'b00100000000000100000000000000101, 32); // ADDI R2, R0, 5
        send_uart_data(32'b00100000000000110000000000000111, 32); // ADDI R3, R0, 7 
        send_uart_data(32'b00000011111000000000000000001000, 32);  // JR R31 */

        //send_uart_command(8'h0E); 

        //send_uart_command(8'h07); // Command to start program 
        wait_for_ready();

        send_uart_command(8'h0D); // Command to start program
        send_uart_command(8'h08); // Command to set continuous mode

                
        //send_uart_command(8'h0B);
        //send_uart_command(8'h02);
        //receive_data_from_uart(4);
        //wait_for_ready();
        //
        ////send_uart_command(8'h09); // Command to set step-by-step mode
//
//
        //// Request registers and latches
        ////send_uart_command(8'h01); // Command to request registers
//
        //// Set step-by-step mode
        ////send_uart_command(8'h09); // Command to set step-by-step mode
        ////wait_for_ready(); // Wait for 'R'
//
        //send_uart_command(8'h02); // Command to request IF/ID latch
        //receive_data_from_uart(8); // Receive 4 bytes of data
//
        //wait_for_ready(); // Wait for 'R'
//
        //send_uart_command(8'h03); // Command to request ID/EX latch
        //receive_data_from_uart(17); // Receive 17 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h04); // Command to request mem ex latch
        //receive_data_from_uart(10); // Receive 17 bytes of data
        //wait_for_ready;
//
        //send_uart_command(8'h05); // Command to request MEM/WB latch
        //receive_data_from_uart(9); // Receive 9 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h01);
        //receive_data_from_uart(128); // Receive 9 bytes of data
        //wait_for_ready(); // Wait for 'R'
//
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
        //send_uart_command(8'h0A); // Command to step program
//
        //send_uart_command(8'h02); // Command to request IF/ID latch
        //receive_data_from_uart(8); // Receive 4 bytes of data
//
        //wait_for_ready(); // Wait for 'R'
//
        //send_uart_command(8'h03); // Command to request ID/EX latch
        //receive_data_from_uart(17); // Receive 17 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h04); // Command to request mem ex latch
        //receive_data_from_uart(10); // Receive 17 bytes of data
        //wait_for_ready;
//
        //send_uart_command(8'h05); // Command to request MEM/WB latch
        //receive_data_from_uart(9); // Receive 9 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h01);
        //receive_data_from_uart(128); // Receive 9 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h08); // Command to contiunous
        
        #70000000000;


        //send_uart_command(8'h02); // Command to request IF/ID latch
        //receive_data_from_uart(8); // Receive 4 bytes of data
//
        //wait_for_ready(); // Wait for 'R'
//
        //send_uart_command(8'h03); // Command to request ID/EX latch
        //receive_data_from_uart(17); // Receive 17 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h04); // Command to request mem ex latch
        //receive_data_from_uart(10); // Receive 17 bytes of data
        //wait_for_ready;
//
        //send_uart_command(8'h05); // Command to request MEM/WB latch
        //receive_data_from_uart(9); // Receive 9 bytes of data
        //wait_for_ready(); // Wait for 'R'
        //
        //send_uart_command(8'h01);
        //receive_data_from_uart(128); // Receive 9 bytes of data
        //wait_for_ready(); // Wait for 'R'



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