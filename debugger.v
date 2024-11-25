module debugger #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS),
    parameter SIZE_OP = 6,
    parameter MEM_SIZE = 1024,
    parameter NUM_LATCHES = 10 // Número de latches intermedios
)(
    input wire clk,
    input wire reset,
    input wire uart_rx,
    output wire uart_tx,
    input wire [SIZE-1:0] registers [NUM_REGISTERS-1:0],
    input wire [SIZE-1:0] latches [NUM_LATCHES-1:0],
    input wire [SIZE-1:0] data_memory [MEM_SIZE-1:0],
    output reg [SIZE-1:0] instruction_memory [MEM_SIZE-1:0],
    output reg mode_continuous,
    output reg mode_step,
    output wire debug_clk
);

    // UART signals
    wire [7:0] uart_rx_data;
    wire uart_rx_done;
    reg [7:0] uart_tx_data;
    reg uart_tx_start;
    wire uart_tx_done;

    // UART module instance
    uart #(
        .DBIT(8),
        .SB_TICK(16),
        .DVSR(651),
        .DVSR_BIT(10),
        .FIFO_W(4)
    ) uart_inst (
        .clk(clk),
        .reset(reset),
        .rd_uart(uart_rx_done),
        .wr_uart(uart_tx_start),
        .rx(uart_rx),
        .w_data(uart_tx_data),
        .tx_full(),
        .rx_empty(),
        .tx(uart_tx),
        .r_data(uart_rx_data)
    );

    // State machine for debugger
    typedef enum reg [2:0] {
        IDLE,
        SEND_REGISTERS,
        SEND_LATCHES,
        SEND_MEMORY,
        LOAD_PROGRAM,
        WAIT_STEP,
        STEP_CLOCK
    } state_t;

    state_t state, next_state;

    // Command handling
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            mode_continuous <= 0;
            mode_step <= 0;
        end else begin
            state <= next_state;
        end
    end

    always @* begin
        next_state = state;
        uart_tx_start = 0;
        case (state)
            IDLE: begin
                if (uart_rx_done) begin
                    case (uart_rx_data)
                        8'h01: next_state = SEND_REGISTERS;
                        8'h02: next_state = SEND_LATCHES;
                        8'h03: next_state = SEND_MEMORY;
                        8'h04: next_state = LOAD_PROGRAM;
                        8'h05: mode_continuous = 1;
                        8'h06: mode_step = 1;
                        8'h07: next_state = STEP_CLOCK; // Comando para avanzar un ciclo de reloj
                        default: next_state = IDLE;
                    endcase
                end
            end
            SEND_REGISTERS: begin
                // Send registers through UART
                for (int i = 0; i < NUM_REGISTERS; i = i + 1) begin
                    uart_tx_data = registers[i][7:0];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = registers[i][15:8];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = registers[i][23:16];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = registers[i][31:24];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                end
                next_state = IDLE;
            end
            SEND_LATCHES: begin
                // Send latches through UART
                for (int i = 0; i < NUM_LATCHES; i = i + 1) begin
                    uart_tx_data = latches[i][7:0];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = latches[i][15:8];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = latches[i][23:16];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = latches[i][31:24];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                end
                next_state = IDLE;
            end
            SEND_MEMORY: begin
                // Send memory through UART
                for (int i = 0; i < MEM_SIZE; i = i + 1) begin
                    uart_tx_data = data_memory[i][7:0];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = data_memory[i][15:8];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = data_memory[i][23:16];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                    uart_tx_data = data_memory[i][31:24];
                    uart_tx_start = 1;
                    @(posedge uart_tx_done);
                end
                next_state = IDLE;
            end
            LOAD_PROGRAM: begin
                // Load program into instruction memory
                for (int i = 0; i < MEM_SIZE; i = i + 1) begin
                    @(posedge uart_rx_done);
                    instruction_memory[i][7:0] = uart_rx_data;
                    @(posedge uart_rx_done);
                    instruction_memory[i][15:8] = uart_rx_data;
                    @(posedge uart_rx_done);
                    instruction_memory[i][23:16] = uart_rx_data;
                    @(posedge uart_rx_done);
                    instruction_memory[i][31:24] = uart_rx_data;
                end
                next_state = IDLE;
            end
            WAIT_STEP: begin
                if (uart_rx_done && uart_rx_data == 8'h07) begin
                    next_state = STEP_CLOCK;
                end
            end
            STEP_CLOCK: begin
                next_state = WAIT_STEP;
            end
        endcase
    end

    // UART transmit logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            uart_tx_start <= 0;
        end else if (uart_tx_done) begin
            uart_tx_start <= 0;
        end else if (state == SEND_REGISTERS || state == SEND_LATCHES || state == SEND_MEMORY) begin
            uart_tx_start <= 1;
        end
    end

    // Clock generation for step mode
    reg step_clk;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            step_clk <= 0;
        end else if (state == STEP_CLOCK) begin
            step_clk <= 1;
        end else begin
            step_clk <= 0;
        end
    end

    assign debug_clk = (mode_continuous) ? clk : step_clk;

endmodule