module debugger #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS),
    parameter SIZE_OP = 6,
    parameter MEM_SIZE = 64, // Tamaño de la memoria en bytes
    parameter ADDR_WIDTH = $clog2(MEM_SIZE),
    parameter IF_ID_SIZE = 32,
    parameter ID_EX_SIZE = 129,
    parameter EX_MEM_SIZE = 77,
    parameter MEM_WB_SIZE = 71
)(
    input wire i_clk,
    input wire i_reset,
    input wire i_uart_rx,
    output wire o_uart_tx,
    input wire [SIZE*NUM_REGISTERS-1:0] i_registers_debug,
    input wire [IF_ID_SIZE-1:0] i_IF_ID,
    input wire [ID_EX_SIZE-1:0] i_ID_EX,
    input wire [EX_MEM_SIZE-1:0] i_EX_MEM,
    input wire [MEM_WB_SIZE-1:0] i_MEM_WB,
    input wire [SIZE-1:0] i_debug_data, // Datos de depuración de la memoria de datos
    output reg o_mode, // Modo de depuración: 0 = continuo, 1 = paso a paso
    output wire o_debug_clk,
    input wire [SIZE-1:0] i_pc, // Contador de programa
    input wire [SIZE-1:0] i_max_pc, // Valor máximo del contador de programa
    output reg [SIZE-1:0] o_debug_addr, // Dirección de depuración para la memoria de datos
    output reg o_inst_write_enable, // habilitación de escritura
    output reg [ADDR_WIDTH-1:0] o_write_addr, // dirección de escritura
    output reg [SIZE-1:0] o_write_data // datos de escritura
);

    // UART signals
    wire [7:0] uart_rx_data;
    wire uart_rx_done;
    reg [7:0] uart_tx_data;
    reg uart_tx_start;
    wire uart_tx_full;
    wire uart_rx_empty;

    uart #(
        .DATA_LEN(8),
        .SB_TICK(16),
        .COUNTER_MOD(651),
        .COUNTER_BITS(10),
        .PTR_LEN(4)
    ) uart_inst (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_readUart(uart_rx_done),
        .i_writeUart(uart_tx_start),
        .i_uartRx(i_uart_rx),
        .i_dataToWrite(uart_tx_data),
        .o_txFull(uart_tx_full),
        .o_rxEmpty(uart_rx_empty),
        .o_uartTx(o_uart_tx),
        .o_dataToRead(uart_rx_data)
    );

    // State machine for debugger
    localparam IDLE = 3'b000,
               SEND_REGISTERS = 3'b001,
               SEND_IF_ID = 3'b010,
               SEND_ID_EX = 3'b011,
               SEND_EX_MEM = 3'b100,
               SEND_MEM_WB = 3'b101,
               SEND_MEMORY = 3'b110,
               LOAD_PROGRAM = 3'b111,
               WAIT_STEP = 3'b000, // Ajustado a 3 bits
               STEP_CLOCK = 3'b001; // Ajustado a 3 bits

    reg [2:0] state, next_state;

    // Declaraciones de variables
    integer i;

    // Command handling
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state <= IDLE;
            o_mode <= 0; // Modo continuo por defecto
            o_inst_write_enable <= 0;
        end else begin
            state <= next_state;
        end
    end

    always @* begin
        next_state = state;
        uart_tx_start = 0;
        o_inst_write_enable = 0;
        case (state)
            IDLE: begin
                if (!uart_rx_empty) begin
                    case (uart_rx_data)
                        8'h01: next_state = SEND_REGISTERS;
                        8'h02: next_state = SEND_IF_ID;
                        8'h03: next_state = SEND_ID_EX;
                        8'h04: next_state = SEND_EX_MEM;
                        8'h05: next_state = SEND_MEM_WB;
                        8'h06: next_state = SEND_MEMORY;
                        8'h07: next_state = LOAD_PROGRAM;
                        8'h08: o_mode = 0; // Modo continuo
                        8'h09: o_mode = 1; // Modo paso a paso
                        8'h0A: next_state = STEP_CLOCK; // Comando para avanzar un ciclo de reloj
                        8'h0B: begin // Comando para leer memoria de datos
                            next_state = SEND_MEMORY;
                            o_debug_addr = uart_rx_data[ADDR_WIDTH-1:0]; // Actualizar dirección de depuración
                        end
                        default: next_state = IDLE;
                    endcase
                end
            end
            SEND_REGISTERS: begin
                // Send registers through UART
                for (i = 0; i < SIZE*NUM_REGISTERS; i = i + 8) begin
                    uart_tx_data = i_registers_debug[i +: 8];
                    uart_tx_start = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_IF_ID: begin
                // Send IF/ID latch through UART
                for (i = 0; i < IF_ID_SIZE; i = i + 8) begin
                    uart_tx_data = i_IF_ID[i*8 +: 8];
                    uart_tx_start = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_ID_EX: begin
                // Send ID/EX latch through UART
                for (i = 0; i < ID_EX_SIZE; i = i + 8) begin
                    uart_tx_data = i_ID_EX[i*8 +: 8];
                    uart_tx_start = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_EX_MEM: begin
                // Send EX/MEM latch through UART
                for (i = 0; i < EX_MEM_SIZE; i = i + 8) begin
                    uart_tx_data = i_EX_MEM[i*8 +: 8];
                    uart_tx_start = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_MEM_WB: begin
                // Send MEM/WB latch through UART
                for (i = 0; i < MEM_WB_SIZE; i = i + 8) begin
                    uart_tx_data = i_MEM_WB[i*8 +: 8];
                    uart_tx_start = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_MEMORY: begin
                // Send memory data through UART
                uart_tx_data = i_debug_data[7:0];
                uart_tx_start = 1;
                @(negedge uart_tx_full);
                uart_tx_data = i_debug_data[15:8];
                uart_tx_start = 1;
                @(negedge uart_tx_full);
                uart_tx_data = i_debug_data[23:16];
                uart_tx_start = 1;
                @(negedge uart_tx_full);
                uart_tx_data = i_debug_data[31:24];
                uart_tx_start = 1;
                @(negedge uart_tx_full);
                next_state = IDLE;
            end
            LOAD_PROGRAM: begin
                // Load program into instruction memory
                for (i = 0; i < MEM_SIZE; i = i + 1) begin
                    @(negedge uart_rx_empty);
                    o_inst_write_enable = 1;
                    o_write_addr = i;
                    o_write_data = {uart_rx_data, uart_rx_data, uart_rx_data, uart_rx_data};
                end
                next_state = IDLE;
            end
            WAIT_STEP: begin
                if (!uart_rx_empty && uart_rx_data == 8'h0A) begin
                    next_state = STEP_CLOCK;
                end
            end
            STEP_CLOCK: begin
                next_state = WAIT_STEP;
            end
        endcase
    end

    // UART transmit logic
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            uart_tx_start <= 0;
        end else if (uart_tx_full) begin
            uart_tx_start <= 0;
        end else if (state == SEND_REGISTERS || state == SEND_IF_ID || state == SEND_ID_EX || state == SEND_EX_MEM || state == SEND_MEM_WB || state == SEND_MEMORY) begin
            uart_tx_start <= 1;
        end
    end

    // Clock generation for step mode and continuous mode
    reg step_clk;
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            step_clk <= 0;
        end else if (state == STEP_CLOCK) begin
            step_clk <= 1;
        end else begin
            step_clk <= 0;
        end
    end

    assign o_debug_clk = (o_mode) ? step_clk : i_clk;

endmodule