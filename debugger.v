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
    output reg [ADDR_WIDTH-1:0] o_debug_addr, // Dirección de depuración
    output reg [ADDR_WIDTH-1:0] o_write_addr, // Dirección de escritura
    output reg o_inst_write_enable,
    output reg [SIZE-1:0] o_write_data, // datos de escritura
    output wire uart_tx_start,
    output wire uart_tx_full,
    output wire uart_rx_empty
);

    // UART signals
    reg uart_tx_start_reg;
    reg uart_rx_done_reg;
    reg original_mode; // Para almacenar el modo original antes de la escritura
    reg [7:0] uart_rx_data_reg;
    reg [7:0] uart_tx_data_reg;
    reg [31:0] instruction_buffer; // Buffer para acumular los bytes de la instrucción
    integer instruction_count; // Cantidad de instrucciones a recibir
    integer instruction_counter; // Contador de instrucciones recibidas
    integer byte_counter; // Contador de bytes recibidos
    wire [7:0] uart_rx_data;
    wire [7:0] uart_tx_data;
    wire uart_rx_done; 

    // State machine states
    localparam IDLE = 0;
    localparam SEND_REGISTERS = 1;
    localparam SEND_IF_ID = 2;
    localparam SEND_ID_EX = 3;
    localparam SEND_EX_MEM = 4;
    localparam SEND_MEM_WB = 5;
    localparam SEND_MEMORY_0 = 6;
    localparam SEND_MEMORY_1 = 7;
    localparam SEND_MEMORY_2 = 8;
    localparam SEND_MEMORY_3 = 9;
    localparam LOAD_PROGRAM = 10;
    localparam WAIT_EXECUTE = 11;
    localparam STEP_CLOCK = 12;
    localparam WAIT_STEP = 13;
    localparam RECEIVE_ADDRESS = 14;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS = 15;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_IF_ID = 16;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_ID_EX = 17;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM = 18;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB = 19;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_0 = 20;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_1 = 21;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_2 = 22;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_3 = 23;
    localparam WAIT_RX_DONE_DOWN_IDLE = 24;
    localparam WAIT_RX_DONE_DOWN_SEND_REGISTERS = 25;
    localparam WAIT_RX_DONE_DOWN_SEND_IF_ID = 26;
    localparam WAIT_RX_DONE_DOWN_SEND_ID_EX = 27;
    localparam WAIT_RX_DONE_DOWN_SEND_EX_MEM = 28;
    localparam WAIT_RX_DONE_DOWN_SEND_MEM_WB = 29;
    localparam WAIT_RX_DONE_DOWN_SEND_MEMORY = 30;
    localparam WAIT_RX_DONE_DOWN_LOAD_PROGRAM = 31;
    localparam WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS = 32;
    localparam WAIT_RX_DONE_DOWN_WAIT_EXECUTE = 33;

    reg [5:0] state, next_state;
    integer i;

    // UART modules
    wire tick;
    baudrate_generator #(
        .COUNT(326)
    ) baud_gen (
        .clk(i_clk),
        .reset(i_reset),
        .tick(tick)
    );

    uart_tx #(
        .N(8),
        .COUNT_TICKS(16)
    ) uart_tx_inst (
        .clk(i_clk),
        .reset(i_reset),
        .tx_start(uart_tx_start_data),
        .tick(tick),
        .data_in(uart_tx_data),
        .tx_done(uart_tx_full),
        .tx(o_uart_tx)
    );

    uart_rx #(
        .N(8),
        .COUNT_TICKS(16)
    ) uart_rx_inst (
        .clk(i_clk),
        .reset(i_reset),
        .tick(tick),
        .rx(i_uart_rx),
        .data_out(uart_rx_data),
        .valid(uart_rx_done),
        .state_leds(),
        .started()
    );

    always @(posedge uart_rx_done) begin
        uart_rx_data_reg <= uart_rx_data;
        uart_rx_done_reg <= 1;
    end

    // State machine
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state <= IDLE;
            uart_rx_done_reg <= 0;
            uart_tx_data_reg <= 0;
            byte_counter <= 0;
            instruction_buffer <= 0;
            instruction_count <= 0;
            instruction_counter <= 0;
            o_write_addr <= 0;
            o_write_data <= 0;
            o_inst_write_enable <= 0;
            uart_tx_start_reg <= 0;
        end else begin
            state <= next_state;
            if (uart_rx_done) begin
                uart_rx_data_reg <= uart_rx_data;
                uart_rx_done_reg <= 1;
            end else begin
                uart_rx_done_reg <= 0;
            end
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                uart_tx_start_reg = 0;
                if (uart_rx_done_reg) begin
                    case (uart_rx_data_reg)
                        8'h01: next_state = WAIT_RX_DONE_DOWN_SEND_REGISTERS;
                        8'h02: next_state = WAIT_RX_DONE_DOWN_SEND_IF_ID;
                        8'h03: next_state = WAIT_RX_DONE_DOWN_SEND_ID_EX;
                        8'h04: next_state = WAIT_RX_DONE_DOWN_SEND_EX_MEM;
                        8'h05: next_state = WAIT_RX_DONE_DOWN_SEND_MEM_WB;
                        8'h06: next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY;
                        8'h07: begin
                            original_mode = o_mode; // Guardar el modo original
                            o_mode = 0; // Cambiar a modo continuo
                            next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                        end
                        8'h08: begin
                            o_mode = 0; // Modo continuo
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h09: begin
                            o_mode = 1; // Modo paso a paso
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h0A: next_state = WAIT_RX_DONE_DOWN_IDLE; // Comando para avanzar un ciclo de reloj
                        8'h0B: next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS; // Comando para leer memoria de datos
                        8'h0C: begin // Comando para finalizar la carga de instrucciones
                            o_inst_write_enable = 0;
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h0D: begin // Comando para iniciar después de la escritura
                            o_inst_write_enable = 0;
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h0E: next_state = WAIT_RX_DONE_DOWN_WAIT_EXECUTE; // Comando para esperar ejecución
                        default: next_state = WAIT_RX_DONE_DOWN_IDLE;
                    endcase
                end
            end
            SEND_REGISTERS: begin
                // Send registers through UART
                for (i = 0; i < SIZE*NUM_REGISTERS; i = i + 8) begin
                    uart_tx_data_reg = i_registers_debug[i +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS;
                end
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_IF_ID: begin
                // Send IF/ID latch through UART
                for (i = 0; i < IF_ID_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_IF_ID[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_IF_ID;
                end
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_IF_ID) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_IF_ID;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_ID_EX: begin
                // Send ID/EX latch through UART
                for (i = 0; i < ID_EX_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_ID_EX[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_ID_EX;
                end
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_ID_EX) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_ID_EX;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_EX_MEM: begin
                // Send EX/MEM latch through UART
                for (i = 0; i < EX_MEM_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_EX_MEM[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM;
                end
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_MEM_WB: begin
                // Send MEM/WB latch through UART
                for (i = 0; i < MEM_WB_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_MEM_WB[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB;
                end
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_MEMORY_0: begin
                // Send memory data through UART
                uart_tx_data_reg = i_debug_data[7:0];
                uart_tx_start_reg = 1;
                next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_0;
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_0) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_0;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_MEMORY_1: begin
                uart_tx_data_reg = i_debug_data[15:8];
                uart_tx_start_reg = 1;
                next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_1;
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_1) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_1;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_MEMORY_2: begin
                uart_tx_data_reg = i_debug_data[23:16];
                uart_tx_start_reg = 1;
                next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_2;
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_2) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_2;
                end else begin
                    next_state = IDLE;
                end
            end
            SEND_MEMORY_3: begin
                uart_tx_data_reg = i_debug_data[31:24];
                uart_tx_start_reg = 1;
                next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_3;
                if (next_state == WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_3) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_3;
                end else begin
                    next_state = IDLE;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS: begin
                if (uart_tx_full) begin
                    next_state = SEND_REGISTERS;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_IF_ID: begin
                if (uart_tx_full) begin
                    next_state = SEND_IF_ID;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_IF_ID;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_ID_EX: begin
                if (uart_tx_full) begin
                    next_state = SEND_ID_EX;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_ID_EX;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM: begin
                if (uart_tx_full) begin
                    next_state = SEND_EX_MEM;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB: begin
                if (uart_tx_full) begin
                    next_state = SEND_MEM_WB;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_0: begin
                if (uart_tx_full) begin
                    next_state = SEND_MEMORY_1;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_0;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_1: begin
                if (uart_tx_full) begin
                    next_state = SEND_MEMORY_2;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_1;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_2: begin
                if (uart_tx_full) begin
                    next_state = SEND_MEMORY_3;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_2;
                end
            end
            WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_3: begin
                if (uart_tx_full) begin
                    next_state = IDLE;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY_3;
                end
            end
            LOAD_PROGRAM: begin
                if (uart_rx_done_reg) begin
                    if (byte_counter == 0) begin
                        instruction_count = uart_rx_data_reg; // Recibir la cantidad de instrucciones
                        byte_counter = byte_counter + 1;
                    end else begin
                        case (byte_counter)
                            1: instruction_buffer[7:0] = uart_rx_data_reg;
                            2: instruction_buffer[15:8] = uart_rx_data_reg;
                            3: instruction_buffer[23:16] = uart_rx_data_reg;
                            4: instruction_buffer[31:24] = uart_rx_data_reg;
                            default: instruction_buffer = instruction_buffer;
                        endcase
                        byte_counter = byte_counter + 1;
                        if (byte_counter == 5) begin // Si se han recibido 4 bytes de la instrucción
                            o_inst_write_enable = 1;
                            // Invertir la endianess de instruction_buffer antes de cargarlo en o_write_data
                            o_write_data = instruction_buffer;
                            byte_counter = 1; // Reiniciar el contador para la siguiente instrucción
                            instruction_counter = instruction_counter + 1;
                            if (instruction_counter < instruction_count) begin
                                o_write_addr = o_write_addr + 1; // Incrementar la dirección de escritura para la siguiente instrucción
                            end
                        end
                        if (instruction_counter == instruction_count) begin // Si se han recibido todas las instrucciones
                            o_inst_write_enable = 0;
                            o_mode = original_mode; // Restaurar el modo original
                            o_write_addr = 0;
                            next_state = WAIT_EXECUTE;
                        end else begin
                            next_state = LOAD_PROGRAM;
                        end
                    end
                    if(next_state == WAIT_EXECUTE) begin
                        next_state = WAIT_EXECUTE;
                    end else begin
                        next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                    end
                end
            end
            RECEIVE_ADDRESS: begin
                if (uart_rx_done_reg) begin
                    o_debug_addr = uart_rx_data_reg[ADDR_WIDTH-1:0]; // Actualizar dirección de depuración
                    next_state = SEND_MEMORY_0;
                    if (next_state == SEND_MEMORY_0) begin
                        next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            WAIT_EXECUTE: begin
                if (uart_rx_done_reg) begin
                    case (uart_rx_data_reg)
                        8'h08: o_mode = 0; // Modo continuo
                        8'h09: o_mode = 1; // Modo paso a paso
                        8'h11: next_state = IDLE; // Comando para comenzar a ejecutar el pipeline
                        default: next_state = WAIT_EXECUTE;
                    endcase
                    if (next_state == WAIT_EXECUTE) begin
                        next_state = WAIT_RX_DONE_DOWN_WAIT_EXECUTE;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            WAIT_STEP: begin
                if (!uart_rx_empty && uart_rx_data_reg == 8'h0A) begin
                    next_state = STEP_CLOCK;
                end
            end
            STEP_CLOCK: begin
                next_state = WAIT_STEP;
            end
        WAIT_RX_DONE_DOWN_IDLE: begin
            if (!uart_rx_done) begin
                next_state = IDLE;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_IDLE;
            end
        end
        WAIT_RX_DONE_DOWN_SEND_REGISTERS: begin
            if (!uart_rx_done) begin
                next_state = SEND_REGISTERS;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_SEND_REGISTERS;
            end
        end
        WAIT_RX_DONE_DOWN_SEND_IF_ID: begin
            if (!uart_rx_done) begin
                next_state = SEND_IF_ID;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_SEND_IF_ID;
            end
        end
        WAIT_RX_DONE_DOWN_SEND_ID_EX: begin
            if (!uart_rx_done) begin
                next_state = SEND_ID_EX;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_SEND_ID_EX;
            end
        end
        WAIT_RX_DONE_DOWN_SEND_EX_MEM: begin
            if (!uart_rx_done) begin
                next_state = SEND_EX_MEM;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_SEND_EX_MEM;
            end
        end
        WAIT_RX_DONE_DOWN_SEND_MEM_WB: begin
            if (!uart_rx_done) begin
                next_state = SEND_MEM_WB;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_SEND_MEM_WB;
            end
        end
        WAIT_RX_DONE_DOWN_SEND_MEMORY: begin
            if (!uart_rx_done) begin
                next_state = SEND_MEMORY_0;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY;
            end
        end
        WAIT_RX_DONE_DOWN_LOAD_PROGRAM: begin
            if (!uart_rx_done) begin
                next_state = LOAD_PROGRAM;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
            end
        end
        WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS: begin
            if (!uart_rx_done) begin
                next_state = RECEIVE_ADDRESS;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS;
            end
        end
        WAIT_RX_DONE_DOWN_WAIT_EXECUTE: begin
            if (!uart_rx_done) begin
                next_state = WAIT_EXECUTE;
            end else begin
                next_state = WAIT_RX_DONE_DOWN_WAIT_EXECUTE;
            end
        end
            default: next_state = IDLE;
        endcase
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

    assign uart_tx_start = uart_tx_start_reg;
    assign uart_tx_data = uart_tx_data_reg;

endmodule