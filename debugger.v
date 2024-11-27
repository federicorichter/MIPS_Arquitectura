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
    output wire uart_rx_done,
    output wire uart_tx_start,
    output wire uart_tx_full,
    output wire uart_rx_empty,
    output wire [7:0] uart_rx_data,
    output wire [7:0] uart_tx_data
);

    // UART signals
    reg [7:0] uart_tx_data_reg;
    reg uart_tx_start_reg;
    reg uart_rx_done_reg;

    // State machine states
    localparam IDLE = 0;
    localparam SEND_REGISTERS = 1;
    localparam SEND_IF_ID = 2;
    localparam SEND_ID_EX = 3;
    localparam SEND_EX_MEM = 4;
    localparam SEND_MEM_WB = 5;
    localparam SEND_MEMORY = 6;
    localparam LOAD_PROGRAM = 7;
    localparam STEP_CLOCK = 8;
    localparam WAIT_STEP = 9;

    reg [3:0] state, next_state;
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
        .tx_start(uart_tx_start_reg),
        .tick(tick),
        .data_in(uart_tx_data_reg),
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

    // State machine
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        uart_tx_start_reg = 0;
        uart_rx_done_reg = 0;
        o_mode = 0;
        case (state)
            IDLE: begin
                if (uart_rx_done) begin
                    uart_rx_done_reg = 1;
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
                        8'h0C: begin // Comando para finalizar la carga de instrucciones
                            o_inst_write_enable = 0;
                            next_state = IDLE;
                        end
                        8'h0D: begin // Comando para iniciar después de la escritura
                            o_inst_write_enable = 1;
                            next_state = IDLE;
                        end
                        default: next_state = IDLE;
                    endcase
                end
            end
            SEND_REGISTERS: begin
                // Send registers through UART
                for (i = 0; i < SIZE*NUM_REGISTERS; i = i + 8) begin
                    uart_tx_data_reg = i_registers_debug[i +: 8];
                    uart_tx_start_reg = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_IF_ID: begin
                // Send IF/ID latch through UART
                for (i = 0; i < IF_ID_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_IF_ID[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_ID_EX: begin
                // Send ID/EX latch through UART
                for (i = 0; i < ID_EX_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_ID_EX[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_EX_MEM: begin
                // Send EX/MEM latch through UART
                for (i = 0; i < EX_MEM_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_EX_MEM[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_MEM_WB: begin
                // Send MEM/WB latch through UART
                for (i = 0; i < MEM_WB_SIZE; i = i + 8) begin
                    uart_tx_data_reg = i_MEM_WB[i*8 +: 8];
                    uart_tx_start_reg = 1;
                    @(negedge uart_tx_full);
                end
                next_state = IDLE;
            end
            SEND_MEMORY: begin
                // Send memory data through UART
                uart_tx_data_reg = i_debug_data[7:0];
                uart_tx_start_reg = 1;
                @(negedge uart_tx_full);
                uart_tx_data_reg = i_debug_data[15:8];
                uart_tx_start_reg = 1;
                @(negedge uart_tx_full);
                uart_tx_data_reg = i_debug_data[23:16];
                uart_tx_start_reg = 1;
                @(negedge uart_tx_full);
                uart_tx_data_reg = i_debug_data[31:24];
                uart_tx_start_reg = 1;
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
    assign uart_rx_done = uart_rx_done_reg;

endmodule