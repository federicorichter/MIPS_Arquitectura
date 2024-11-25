module tb_top;
    reg clk, rst, i_stall;
    wire uart_tx, uart_rx;
    reg [31:0] program [0:14]; // Programa a cargar en la memoria de instrucciones
    integer i;

    // Señales para el UART de la PC
    reg pc_uart_tx_start;
    reg [7:0] pc_uart_tx_data;
    wire pc_uart_tx_done;
    wire pc_uart_rx_done;
    wire [7:0] pc_uart_rx_data;

    // Señales de tick para UART
    wire rx_done_tick;
    wire tx_done_tick;

    initial begin
        // Inicializar el reloj
        clk = 0;
        forever #10 clk = ~clk;  // Periodo de 20 ns, frecuencia de 50 MHz
    end

    initial begin
        // Inicializar señales
        rst = 1;
        i_stall = 0;
        pc_uart_tx_start = 0;

        // Programa a cargar en la memoria de instrucciones
        program[0] = 32'b00111100000000010000000000000011; // R1 = 3
        program[1] = 32'b00111100000000100000000000000001; // R2 = 1
        program[2] = 32'b00111100000000110000000000001001; // R3 = 9
        program[3] = 32'b00111100000001000000000000000111; // R4 = 7
        program[4] = 32'b00111100000001010000000000000011; // R5 = 3
        program[5] = 32'b00111100000001100000000001100101; // R6 = 101
        program[6] = 32'b00111100000001110000000000011001; // R7 = 25 
        program[7] = 32'b00000000001000100001100000100011; // R3 = R1 - R2 -> 2
        program[8] = 32'b00000000011001000010100000100001; // R5 = R3 + R4 -> 9
        program[9] = 32'b00000000011001100011100000100001; // R7 = R3 + R6 -> 103
        program[10] = 32'b00000000011001000010100000100001; // R15 = R3 + R5
        program[11] = 32'b0; // R1 = 3
        program[12] = 32'b00111100000000010000000000000011; // R1 = 3
        program[13] = 32'b00111100000000010000000000000011; // R1 = 3
        program[14] = 32'b00111100000000010000000000000011; // R1 = 3

        // Resetear el sistema
        #50;
        rst = 0;

        // Cargar el programa en la memoria de instrucciones a través del debugger
        for (i = 0; i < 15; i = i + 1) begin
            pc_uart_tx_data = program[i][7:0];
            pc_uart_tx_start = 1;
            #20;
            pc_uart_tx_start = 0;
            wait(pc_uart_tx_done);
            #20;
            pc_uart_tx_data = program[i][15:8];
            pc_uart_tx_start = 1;
            #20;
            pc_uart_tx_start = 0;
            wait(pc_uart_tx_done);
            #20;
            pc_uart_tx_data = program[i][23:16];
            pc_uart_tx_start = 1;
            #20;
            pc_uart_tx_start = 0;
            wait(pc_uart_tx_done);
            #20;
            pc_uart_tx_data = program[i][31:24];
            pc_uart_tx_start = 1;
            #20;
            pc_uart_tx_start = 0;
            wait(pc_uart_tx_done);
            #20;
        end

        // Cambiar el modo del debugger a continuo
        pc_uart_tx_data = 8'h08;
        pc_uart_tx_start = 1;
        #20;
        pc_uart_tx_start = 0;
        wait(pc_uart_tx_done);
        #20;

        // Esperar un tiempo para que el programa se ejecute en modo continuo
        #1200;

        // Resetear el sistema y cambiar el modo del debugger a paso a paso
        rst = 1;
        #50;
        rst = 0;
        pc_uart_tx_data = 8'h09;
        pc_uart_tx_start = 1;
        #20;
        pc_uart_tx_start = 0;
        wait(pc_uart_tx_done);
        #20;

        // Simular el avance paso a paso
        for (i = 0; i < 10; i = i + 1) begin
            pc_uart_tx_data = 8'h0A;
            pc_uart_tx_start = 1;
            #20;
            pc_uart_tx_start = 0;
            wait(pc_uart_tx_done);
            #20;
        end

        // Finalizar la simulación
        #1200;
        $finish;
    end

    mips #(
        .SIZE(32),
        .SIZE_OP(6),
        .CONTROL_SIZE(18),
        .IF_ID_SIZE(32),
        .ID_EX_SIZE(129),
        .EX_MEM_SIZE(77),
        .MEM_WB_SIZE(71),
        .ADDR_WIDTH(32),
        .MAX_INSTRUCTION(64),
        .MEM_SIZE(64)
    ) 
    uut(
        .i_clk(clk),
        .i_rst(rst),
        .i_stall(i_stall),
        .i_uart_rx(uart_rx),
        .o_uart_tx(uart_tx),
        .rx_done_tick(rx_done_tick), // Conectar señal de tick de recepción
        .tx_done_tick(tx_done_tick)  // Conectar señal de tick de transmisión
    );

    uart #(
        .DATA_LEN(8),
        .SB_TICK(16),
        .COUNTER_MOD(651),
        .COUNTER_BITS(10),
        .PTR_LEN(4)
    ) uart_inst (
        .i_clk(clk),
        .i_reset(rst),
        .i_readUart(pc_uart_tx_start),
        .i_writeUart(pc_uart_tx_start),
        .i_uartRx(uart_rx),
        .i_dataToWrite(pc_uart_tx_data),
        .o_txFull(),
        .o_rxEmpty(),
        .o_uartTx(uart_tx),
        .o_dataToRead(pc_uart_rx_data)
    );

endmodule