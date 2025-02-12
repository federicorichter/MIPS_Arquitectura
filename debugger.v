module debugger #(
    parameter SIZE = 32,                       // Ancho de datos
    parameter NUM_REGISTERS = 32,              // Número de registros
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS), // Ancho de la dirección del registro
    parameter SIZE_OP = 6,                       // Tamaño del código de operación
    parameter MEM_SIZE = 64,                     // Tamaño de la memoria en bytes
    parameter ADDR_WIDTH = $clog2(MEM_SIZE),     // Ancho de la dirección para la memoria
    parameter IF_ID_SIZE = 64,                   // Tamaño del registro de la pipeline IF/ID
    parameter ID_EX_SIZE = 129,                  // Tamaño del registro de la pipeline ID/EX
    parameter EX_MEM_SIZE = 77,                  // Tamaño del registro de la pipeline EX/MEM
    parameter MEM_WB_SIZE = 71,                  // Tamaño del registro de la pipeline MEM/WB
    parameter STEP_CYCLES = 3                    // Número de ciclos de reloj por paso en modo paso a paso
)(
    input wire i_clk,                           // Reloj del sistema
    input wire i_reset,                         // Señal de reset
    input wire i_uart_rx,                       // Datos de recepción UART
    output wire o_uart_tx,                      // Datos de transmisión UART
    input wire [(SIZE*NUM_REGISTERS)-1:0] i_registers_debug, // Valores de los registros para depuración
    input wire [IF_ID_SIZE-1:0] i_IF_ID,        // Contenido del registro de la pipeline IF/ID
    input wire [ID_EX_SIZE-1:0] i_ID_EX,        // Contenido del registro de la pipeline ID/EX
    input wire [EX_MEM_SIZE-1:0] i_EX_MEM,      // Contenido del registro de la pipeline EX/MEM
    input wire [MEM_WB_SIZE-1:0] i_MEM_WB,      // Contenido del registro de la pipeline MEM/WB
    input wire [SIZE-1:0] i_debug_data,         // Contenido de la memoria de datos para depuración
    input wire [SIZE-1:0] i_pc,                 // Valor del contador de programa
    input wire [SIZE*MEM_SIZE-1:0] i_debug_instructions, // Contenido de la memoria de instrucciones para depuración
    output reg o_mode,                          // Modo de depuración: 0 = continuo, 1 = paso a paso
    output reg o_debug_clk,                    // Señal de reloj para depuración (puede ser el reloj del sistema o el reloj de paso)
    output reg [ADDR_WIDTH-1:0] o_debug_addr,   // Dirección para la depuración de la memoria de datos
    output reg [ADDR_WIDTH-1:0] o_write_addr_reg, // Dirección para la escritura de la memoria de instrucciones
    output reg o_inst_write_enable_reg,         // Señal de habilitación para la escritura de la memoria de instrucciones
    output reg [SIZE-1:0] o_write_data_reg,      // Datos para la escritura de la memoria de instrucciones
    output wire uart_tx_start,                  // Señal de inicio de transmisión UART
    output wire uart_tx_full,                   // Señal de transmisión UART completa
    output reg o_clk_mem_read,                  // Habilitación de reloj para la lectura de la memoria de datos
    output reg [5:0] state_out,                 // Estado actual de la máquina de estados del depurador
    output reg [7:0] uart_rx_data_out,          // Datos UART recibidos
    output reg [4:0] instruction_counter_out,   // Contador de instrucciones de salida
    output reg [4:0] instruction_count_out,     // Conteo de instrucciones de salida
    output reg [2:0] byte_counter_out,          // Contador de bytes de salida
    output reg uart_rx_done_reg_out,            // Flag de finalización de recepción UART de salida
    output reg [4:0] i_pc_out,
    output reg o_prog_reset                     // Salida para la señal de reset del programa
);

    // Señales UART
    reg uart_tx_start_reg = 0;                // Registro de inicio de transmisión UART
    reg uart_rx_done_reg;                     // Registro de finalización de recepción UART
    reg original_mode;                        // Almacena el modo original antes de la escritura
    reg [7:0] uart_rx_data_reg = 0;            // Registro de datos de recepción UART
    reg [7:0] uart_tx_data_reg = 0;            // Registro de datos de transmisión UART
    reg [31:0] instruction_buffer = 0;         // Buffer para acumular bytes de instrucción
    reg [1023:0] padded_registers;
    reg [IF_ID_SIZE-1:0] padded_if_id;
    reg [135:0] padded_id_ex;
    reg [79:0] padded_ex_mem;
    reg [71:0] padded_mem_wb;
    reg [31:0] instruction_count = 0;         // Número de instrucciones a recibir
    reg [31:0] instruction_counter = 0;         // Contador para las instrucciones recibidas
    integer byte_counter = 1;                   // Contador para los bytes recibidos
    wire [7:0] uart_rx_data;                   // Datos UART recibidos
    wire [7:0] uart_tx_data;                   // Datos UART a transmitir
    wire uart_rx_done;                        // Señal de finalización de recepción UART
    reg [IF_ID_SIZE-1:0] i_IF_ID_REG;
    reg send_idle_ack_flag;
    reg [ADDR_WIDTH-1:0] o_write_addr = 0;       // Dirección para la escritura de la memoria de instrucciones
    reg [SIZE-1:0] o_write_data = 0;            // Datos para la escritura de la memoria de instrucciones
    reg o_inst_write_enable = 0;              // Señal de habilitación para la escritura de la memoria de instrucciones
    reg step_clk;
    reg step_complete;
    reg [31:0] step_counter;
    reg step_active;
    reg one_pulse_low;

    // Estados de la máquina de estados
    localparam IDLE = 0;                           // Estado inicial
    localparam SEND_REGISTERS = 1;                  // Enviar valores de los registros
    localparam SEND_IF_ID = 2;                     // Enviar registro IF/ID
    localparam SEND_ID_EX = 3;                     // Enviar registro ID/EX
    localparam SEND_EX_MEM = 4;                    // Enviar registro EX/MEM
    localparam SEND_MEM_WB = 5;                   // Enviar registro MEM/WB
    localparam SEND_MEMORY = 6;                    // Enviar memoria de datos
    localparam SEND_MEMORY_1 = 7;
    localparam SEND_MEMORY_2 = 8;
    localparam SEND_MEMORY_3 = 9;
    localparam LOAD_PROGRAM = 10;                   // Cargar programa en la memoria de instrucciones
    localparam WAIT_EXECUTE = 11;                   // Esperar a que la ejecución se complete
    localparam STEP_CLOCK = 12;                     // Generar un solo ciclo de reloj en modo paso a paso
    localparam WAIT_STEP = 13;                      // Esperar a que el paso se complete
    localparam RECEIVE_ADDRESS = 14;               // Recibir dirección para la lectura de la memoria de datos
    localparam WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS = 15;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_IF_ID = 16;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_ID_EX = 17;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM = 18;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB = 19;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEMORY = 20;
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
    localparam SEND_IDLE_ACK = 34;                  // Enviar 'R' para confirmar el estado IDLE
    localparam WAIT_UART_TX_FULL_DOWN_IDLE_ACK = 35; // Esperar a que se transmita 'R'
    localparam WAIT_NO_TX_FULL = 36;
    localparam WAIT_TX_DOWN_IDLE_ACK = 37;
    localparam RECEIVE_STOP_PC = 38;                // Recibir el valor del PC de parada
    localparam WAIT_RX_DOWN_STOP_PC = 39;
    localparam RECEIVE_INSTRUCTION_COUNT = 40;
    localparam WAIT_RX_DONE_DOWN_RECEIVE_INSTRUCTION_COUNT = 41;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_1 = 42;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_2 = 43;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_3 = 44;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_4 = 45;
    localparam PROGRAM_RESET = 46;
    localparam SEND_DEBUG_INSTRUCTIONS = 48;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_DEBUG_INSTRUCTIONS = 49;
    localparam SEND_PC = 50;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_PC = 51;

    reg [5:0] state, next_state;                // Estado actual y siguiente de la máquina de estados
    reg [31:0] i;
    reg [31:0] send_registers_counter = 0;     // Contador para enviar los valores de los registros
    reg [31:0] send_if_id_counter = 0;
    reg [31:0] send_id_ex_counter = 0;
    reg [31:0] send_ex_mem_counter = 0;
    reg [31:0] send_mem_wb_counter = 0;
    reg [31:0] send_memory_counter = 0;         // Contador para enviar la memoria de datos
    reg [31:0] next_send_registers_counter = 0;
    reg [31:0] next_send_if_id_counter = 0;
    reg [31:0] next_send_id_ex_counter = 0;
    reg [31:0] next_send_ex_mem_counter = 0;
    reg [31:0] next_send_mem_wb_counter = 0;
    reg [31:0] next_send_memory_counter = 0;
    reg [31:0] next_instruction_counter = 0;
    reg [31:0] next_instruction_count = 0;
    integer next_byte_counter = 0;
    reg [ADDR_WIDTH-1:0] next_write_addr;
    reg [SIZE-1:0] stop_pc = 0;                 // Valor del PC en el que se detendrá la ejecución
    reg done_inst_write = 0;
    reg ctr_rx_done = 0;
    reg [3:0] reset_counter;
    reg reset_active;
    reg [31:0] send_debug_instructions_counter = 0;
    reg [31:0] next_send_debug_instructions_counter = 0;
    reg next_prog_reset;
    reg [3:0] next_reset_counter;

    // Módulos UART
    wire tick;                                  // Tick de reloj para UART
    baudrate_generator #(
        .COUNT(261)                             // Conteo del generador de velocidad de baudios
    ) baud_gen (
        .clk(i_clk),                           // Reloj del sistema
        .reset(i_reset),                         // Señal de reset
        .tick(tick)                             // Tick de salida
    );

    uart_tx #(
        .N(8),                                  // Ancho de datos
        .COUNT_TICKS(16)                        // Número de ticks por bit
    ) uart_tx_inst (
        .clk(i_clk),                           // Reloj del sistema
        .reset(i_reset),                         // Señal de reset
        .tx_start(uart_tx_start),               // Señal de inicio de transmisión
        .tick(tick),                             // Tick de reloj
        .data_in(uart_tx_data_reg),            // Datos a transmitir
        .tx_done(uart_tx_full),                 // Señal de transmisión completa
        .tx(o_uart_tx)                          // Datos de transmisión UART
    );

    uart_rx #(
        .N(8),                                  // Ancho de datos
        .COUNT_TICKS(16)                        // Número de ticks por bit
    ) uart_rx_inst (
        .clk(i_clk),                           // Reloj del sistema
        .reset(i_reset),                         // Señal de reset
        .tick(tick),                             // Tick de reloj
        .rx(i_uart_rx),                         // Datos de recepción UART
        .data_out(uart_rx_data),                // Datos recibidos
        .valid(uart_rx_done),                   // Señal de datos válidos
        .state_leds(),
        .started()
    );

    always @(*) begin
        o_write_addr_reg = o_write_addr;
        o_inst_write_enable_reg = o_inst_write_enable;
        o_write_data_reg = o_write_data;
    end

    reg [1:0] rx_state;
    localparam RX_IDLE = 0;
    localparam RX_RECEIVING = 1;
    localparam RX_DONE = 2;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            rx_state <= RX_IDLE;
            uart_rx_done_reg <= 0;
            uart_rx_data_reg <= 0;
        end else begin
            case (rx_state)
                RX_IDLE: begin
                    if (uart_rx_done) begin
                        rx_state <= RX_RECEIVING;
                        uart_rx_data_reg <= uart_rx_data;
                        uart_rx_done_reg <= 1;
                    end
                end
                RX_RECEIVING: begin
                    uart_rx_done_reg <= 0;
                    rx_state <= RX_DONE;
                end
                RX_DONE: begin
                    if (!uart_rx_done) begin
                        rx_state <= RX_IDLE;
                    end
                end
            endcase
        end
    end

    // Actualizar contadores y dirección de escritura
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            send_registers_counter <= 0;
            send_if_id_counter <= 0;
            send_id_ex_counter <= 0;
            send_ex_mem_counter <= 0;
            send_mem_wb_counter <= 0;
            send_memory_counter <= 0;
            instruction_counter <= 0;
            send_debug_instructions_counter <= 0;
            o_write_addr <= 0;
        end else begin
            send_registers_counter <= next_send_registers_counter;
            send_if_id_counter <= next_send_if_id_counter;
            send_id_ex_counter <= next_send_id_ex_counter;
            send_ex_mem_counter <= next_send_ex_mem_counter;
            send_mem_wb_counter <= next_send_mem_wb_counter;
            send_memory_counter <= next_send_memory_counter;
            instruction_counter <= next_instruction_counter;
            instruction_count <= next_instruction_count;
            send_debug_instructions_counter <= next_send_debug_instructions_counter;
            o_write_addr <= next_write_addr;
            byte_counter <= next_byte_counter;
            byte_counter_out <= byte_counter[2:0]; // Cargar los 5 bits menos significativos
            instruction_count_out <= instruction_count[4:0]; // Cargar los 5 bits menos significativos
            instruction_counter_out <= instruction_counter[4:0]; // Cargar los 5 bits menos significativos
        end
    end

    // Lógica de la máquina de estados
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state <= IDLE;
            state_out <= IDLE;
            reset_counter <= 0;
            reset_active <= 0;
            o_prog_reset <= 0;
            o_debug_clk <= 0;
            one_pulse_low <= 0;
        end else begin
            state <= next_state;
            state_out <= state;
            reset_counter <= next_reset_counter;
            o_prog_reset <= next_prog_reset;

            if (o_mode == 0) begin
                o_debug_clk <= 0;
                one_pulse_low <= 0;
            end else if (state == STEP_CLOCK) begin
                o_debug_clk <= 1;
                one_pulse_low <= 1;
            end else if (one_pulse_low) begin
                o_debug_clk <= 0;
                one_pulse_low <= 0;
            end
        end
    end

    // Lógica del siguiente estado
    always @(*) begin
        next_state = state;                       // Por defecto: permanecer en el mismo estado
        next_send_registers_counter = send_registers_counter;
        next_send_if_id_counter = send_if_id_counter;
        next_send_id_ex_counter = send_id_ex_counter;
        next_send_ex_mem_counter = send_ex_mem_counter;
        next_send_mem_wb_counter = send_mem_wb_counter;
        next_send_memory_counter = send_memory_counter;
        next_instruction_counter = instruction_counter;
        next_prog_reset = o_prog_reset;          // Por defecto: no reset
        next_reset_counter = reset_counter;      // Por defecto: no reset
        next_byte_counter = byte_counter;
        next_instruction_count = instruction_count;
        next_write_addr = o_write_addr;
        next_send_debug_instructions_counter = send_debug_instructions_counter;
        uart_tx_start_reg = 0;                    // Resetear el inicio de TX por defecto
        stop_pc = instruction_count;
        case (state)
            IDLE: begin
                uart_tx_start_reg = 0;            // Asegurarse de que TX no esté activo
                next_send_registers_counter = 0;  // Resetear contadores
                next_send_if_id_counter = 0;
                next_send_id_ex_counter = 0;
                next_send_ex_mem_counter = 0;
                next_send_mem_wb_counter = 0;
                next_send_memory_counter = 0;
                next_byte_counter = 1;
                next_instruction_counter = 0;
                next_prog_reset = 0;
                next_reset_counter = 0;
                uart_tx_data_reg = 0;
                padded_ex_mem = 0;
                padded_id_ex = 0;
                padded_if_id = 0;
                padded_mem_wb = 0;
                padded_registers = 0;
                next_send_debug_instructions_counter = 0;
                o_write_data = 0;
                o_clk_mem_read = 0;
                o_debug_addr = 0;
                if (uart_rx_done_reg) begin       // Si se reciben datos
                    case (uart_rx_data_reg)
                        8'h01: next_state = WAIT_RX_DONE_DOWN_SEND_REGISTERS; // Enviar registros
                        8'h02: next_state = WAIT_RX_DONE_DOWN_SEND_IF_ID; // Enviar IF/ID
                        8'h03: next_state = WAIT_RX_DONE_DOWN_SEND_ID_EX; // Enviar ID/EX
                        8'h04: next_state = WAIT_RX_DONE_DOWN_SEND_EX_MEM; // Enviar EX/MEM
                        8'h05: next_state = WAIT_RX_DONE_DOWN_SEND_MEM_WB; // Enviar MEM/WB
                        8'h06: next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY; // Enviar memoria de datos
                        8'h07: begin             // Cargar programa
                            next_write_addr = 0;  // Empezar a escribir en la dirección 0
                            o_mode = 1;           // Entrar en modo paso a paso
                            o_inst_write_enable = 1;
                            next_state = WAIT_RX_DONE_DOWN_RECEIVE_INSTRUCTION_COUNT;
                        end
                        8'h08: begin             // Modo continuo
                            o_mode = 0;           // Entrar en modo continuo
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h09: begin             // Modo paso a paso
                            o_mode = 1;           // Entrar en modo paso a paso
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h0A: next_state = STEP_CLOCK; // Paso de un ciclo de reloj
                        8'h0B: next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS; // Leer memoria de datos
                        8'h0E: next_state = WAIT_RX_DOWN_STOP_PC; // Recibir valor de parada del PC
                        8'h0D: begin             // Iniciar ejecución después de escribir
                            done_inst_write = 1;
                            o_inst_write_enable = 0;
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h10: next_state = SEND_DEBUG_INSTRUCTIONS; // Enviar instrucciones de depuración
                        8'h11: next_state = SEND_PC; // Nuevo comando para enviar PC
                        default: next_state = WAIT_RX_DONE_DOWN_IDLE; // Comando inválido
                    endcase
                end
            end

            SEND_IDLE_ACK: begin
                uart_tx_data_reg = "R";           // ASCII para 'R'
                uart_tx_start_reg = 1;            // Iniciar transmisión
                next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
            end

            WAIT_UART_TX_FULL_DOWN_IDLE_ACK: begin
                if (uart_tx_full) begin           // Si la transmisión está completa
                    uart_tx_start_reg = 0;        // Detener transmisión
                    next_state = WAIT_TX_DOWN_IDLE_ACK;
                end
            end

            WAIT_TX_DOWN_IDLE_ACK: begin
                if (!uart_tx_full) begin          // Si la transmisión no está activa
                    next_state = IDLE;            // Volver a IDLE
                end
            end

            WAIT_NO_TX_FULL: begin
                if (!uart_tx_full) begin
                    next_state = SEND_IDLE_ACK;
                end else begin
                    next_state = WAIT_NO_TX_FULL;
                end
            end

            SEND_REGISTERS: begin
                if (send_registers_counter < 1024) begin
                    uart_tx_data_reg = i_registers_debug[send_registers_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R"; // Enviar R inmediatamente después de los datos
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS: begin
                if (uart_tx_full) begin
                    next_send_registers_counter = send_registers_counter + 8;
                    next_state = SEND_REGISTERS;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS;
                end
            end
            
            SEND_IF_ID: begin
                padded_if_id = i_IF_ID;
                if (send_if_id_counter < IF_ID_SIZE) begin
                    uart_tx_data_reg = padded_if_id[send_if_id_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_IF_ID;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_IF_ID: begin
                if (uart_tx_full) begin
                    next_send_if_id_counter = send_if_id_counter + 8;
                    next_state = SEND_IF_ID;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_IF_ID;
                end
            end

            SEND_DEBUG_INSTRUCTIONS: begin
                if (send_debug_instructions_counter < SIZE*MEM_SIZE) begin
                    uart_tx_data_reg = i_debug_instructions[send_debug_instructions_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_DEBUG_INSTRUCTIONS;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R"; // Enviar R inmediatamente después de los datos
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end
            
            WAIT_UART_TX_FULL_DOWN_SEND_DEBUG_INSTRUCTIONS: begin
                if (uart_tx_full) begin
                    next_send_debug_instructions_counter = send_debug_instructions_counter + 8;
                    next_state = SEND_DEBUG_INSTRUCTIONS;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_DEBUG_INSTRUCTIONS;
                end
            end
            
            SEND_ID_EX: begin
                padded_id_ex = {7'b0, i_ID_EX};
                if (send_id_ex_counter < 136) begin
                    uart_tx_data_reg = padded_id_ex[send_id_ex_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_ID_EX;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_ID_EX: begin
                if (uart_tx_full) begin
                    next_send_id_ex_counter = send_id_ex_counter + 8;
                    next_state = SEND_ID_EX;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_ID_EX;
                end
            end
            
            SEND_EX_MEM: begin
                padded_ex_mem = {3'b0, i_EX_MEM};
                if (send_ex_mem_counter < 80) begin
                    uart_tx_data_reg = padded_ex_mem[send_ex_mem_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM: begin
                if (uart_tx_full) begin
                    next_send_ex_mem_counter = send_ex_mem_counter + 8;
                    next_state = SEND_EX_MEM;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM;
                end
            end
            

            SEND_MEM_WB: begin
                padded_mem_wb = {1'b0, i_MEM_WB};
                if (send_mem_wb_counter < 72) begin
                    uart_tx_data_reg = padded_mem_wb[send_mem_wb_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB: begin
                if (uart_tx_full) begin
                    next_send_mem_wb_counter = send_mem_wb_counter + 8;
                    next_state = SEND_MEM_WB;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB;
                end
            end

            SEND_MEMORY: begin
                o_clk_mem_read = 0;
                if (send_memory_counter < 32) begin
                    uart_tx_data_reg = i_debug_data[send_memory_counter +: 8];
                    uart_tx_start_reg = 1;
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY;
                end else begin
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_MEMORY: begin
                if (uart_tx_full) begin
                    next_send_memory_counter = send_memory_counter + 8;
                    next_state = SEND_MEMORY;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_MEMORY;
                end
            end

            RECEIVE_INSTRUCTION_COUNT: begin
                if (uart_rx_done_reg) begin
                    next_instruction_count = uart_rx_data_reg; // Recibir la cantidad de instrucciones
                    done_inst_write = 0;
                    next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                end
            end
            
            WAIT_RX_DONE_DOWN_RECEIVE_INSTRUCTION_COUNT: begin
                if (!uart_rx_done_reg) begin
                    next_state = RECEIVE_INSTRUCTION_COUNT;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_RECEIVE_INSTRUCTION_COUNT;
                end
            end
// Modificación en el estado LOAD_PROGRAM dentro del always @(*) begin
            LOAD_PROGRAM: begin
                // Este bloque se ejecuta cuando la máquina de estados está en el estado LOAD_PROGRAM.
                if (uart_rx_done_reg) begin
                    // Si la recepción UART ha terminado (un byte ha sido recibido).
                    uart_rx_done_reg_out = 1;
                    // Establecer la señal de salida para indicar que la recepción UART ha terminado.
                    case (byte_counter)
                        // Dependiendo del valor del contador de bytes, se procesa un byte diferente de la instrucción.
                        1: begin
                            // Si es el primer byte de la instrucción.
                            instruction_buffer[7:0] = uart_rx_data_reg;
                            // Almacenar el byte recibido en el buffer de instrucción (bits 7 a 0).
                            next_state = WAIT_RX_DONE_LOAD_PROGRAM_1;
                            // Pasar al estado de espera para que la recepción UART se complete antes de continuar.
                        end
                        2: begin
                            // Si es el segundo byte de la instrucción.
                            instruction_buffer[15:8] = uart_rx_data_reg;
                            // Almacenar el byte recibido en el buffer de instrucción (bits 15 a 8).
                            next_state = WAIT_RX_DONE_LOAD_PROGRAM_2;
                            // Pasar al estado de espera para que la recepción UART se complete antes de continuar.
                        end
                        3: begin
                            // Si es el tercer byte de la instrucción.
                            instruction_buffer[23:16] = uart_rx_data_reg;
                            // Almacenar el byte recibido en el buffer de instrucción (bits 23 a 16).
                            next_state = WAIT_RX_DONE_LOAD_PROGRAM_3;
                            // Pasar al estado de espera para que la recepción UART se complete antes de continuar.
                        end
                        4: begin
                            // Si es el cuarto byte de la instrucción.
                            instruction_buffer[31:24] = uart_rx_data_reg;
                            // Almacenar el byte recibido en el buffer de instrucción (bits 31 a 24).
                            o_write_data = instruction_buffer;
                            // Escribir la instrucción completa (4 bytes) en el registro de datos de escritura.
                            next_instruction_counter = instruction_counter + 1;
                            // Incrementar el contador de instrucciones recibidas.
                            
                            // Solo incrementar la dirección si no es la última instrucción
                            if (next_instruction_counter < instruction_count) begin
                                // Si no es la última instrucción a ser cargada.
                                next_write_addr = o_write_addr + 1;
                                // Incrementar la dirección de escritura para la siguiente instrucción.
                                next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                                // Volver al estado de espera para recibir el siguiente byte de la siguiente instrucción.
                            end else if (next_instruction_counter == instruction_count) begin
                                // Si es la última instrucción, no incrementar la dirección y pasar a WAIT_EXECUTE
                                next_write_addr = o_write_addr + 1; // Mantener la dirección actual
                                // Mantener la dirección de escritura actual.
                                next_state = WAIT_EXECUTE;
                                // Pasar al estado de espera para que la ejecución comience.
                            end
                        end
                        default: instruction_buffer = instruction_buffer;
                        // En caso de un valor inesperado del contador de bytes, mantener el buffer de instrucción sin cambios.
                    endcase
                end
            end

            WAIT_RX_DONE_LOAD_PROGRAM_1: begin
                // Estado de espera para que la recepción UART se complete (byte 1).
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_byte_counter = 2;
                    // Establecer el contador de bytes para el segundo byte de la instrucción.
                    next_state = LOAD_PROGRAM;
                    // Volver al estado LOAD_PROGRAM para recibir el siguiente byte.
                end else begin
                    next_state = WAIT_RX_DONE_LOAD_PROGRAM_1;
                    // Permanecer en este estado hasta que la recepción UART se complete.
                end
            end
            
            WAIT_RX_DONE_LOAD_PROGRAM_2: begin
                // Estado de espera para que la recepción UART se complete (byte 2).
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_byte_counter = 3;
                    // Establecer el contador de bytes para el tercer byte de la instrucción.
                    next_state = LOAD_PROGRAM;
                    // Volver al estado LOAD_PROGRAM para recibir el siguiente byte.
                end else begin
                    next_state = WAIT_RX_DONE_LOAD_PROGRAM_2;
                    // Permanecer en este estado hasta que la recepción UART se complete.
                end
            end

            WAIT_RX_DONE_LOAD_PROGRAM_3: begin
                // Estado de espera para que la recepción UART se complete (byte 3).
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_byte_counter = 4;
                    // Establecer el contador de bytes para el cuarto byte de la instrucción.
                    next_state = LOAD_PROGRAM;
                    // Volver al estado LOAD_PROGRAM para recibir el siguiente byte.
                end else begin
                    next_state = WAIT_RX_DONE_LOAD_PROGRAM_3;
                    // Permanecer en este estado hasta que la recepción UART se complete.
                end
            end
            
            WAIT_RX_DONE_DOWN_LOAD_PROGRAM: begin
                // Estado de espera general para que la recepción UART se complete durante la carga del programa.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_byte_counter = 1;
                    // Reiniciar el contador de bytes para la siguiente instrucción.
                    next_state = LOAD_PROGRAM;
                    // Volver al estado LOAD_PROGRAM para recibir el siguiente byte.
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                    // Permanecer en este estado hasta que la recepción UART se complete.
                end
            end

            RECEIVE_ADDRESS: begin
                // Estado para recibir la dirección de memoria para depuración.
                if (uart_rx_done_reg) begin
                    // Si la recepción UART ha terminado.
                    o_debug_addr = uart_rx_data_reg[ADDR_WIDTH-1:0];
                    // Actualizar la dirección de depuración con los bits recibidos.
                    o_clk_mem_read = 1;
                    // Habilitar la lectura de la memoria de datos.
                    next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY;
                    // Pasar al estado de espera antes de enviar la memoria.
                end
            end

            RECEIVE_STOP_PC: begin
                // Estado para recibir el valor del Program Counter (PC) en el que se detendrá la ejecución.
                if (uart_rx_done_reg) begin
                    // Si la recepción UART ha terminado.
                    stop_pc = uart_rx_data_reg;
                    // Almacenar el valor del PC en la variable stop_pc.
                    next_state = WAIT_NO_TX_FULL;
                    // Pasar al estado de espera para que la transmisión UART no esté en curso.
                end
            end

            WAIT_EXECUTE: begin
                // Estado de espera para que la ejecución se complete después de cargar el programa.
                if (next_instruction_counter == instruction_count && instruction_count > 0) begin
                    // Si el contador de instrucciones es igual al número de instrucciones a ejecutar y hay instrucciones para ejecutar.
                    o_write_data = 0;
                    // Limpiar el registro de datos de escritura.
                    reset_active = 1;           
                    // Activar la señal de reset.
                    next_prog_reset = 1;        
                    // Establecer la señal de reset del programa.
                    next_reset_counter = 0;     
                    // Reiniciar el contador de reset.
                    next_state = PROGRAM_RESET;
                    // Pasar al estado de reset del programa.
                end
            end

            PROGRAM_RESET: begin
                // Estado para resetear el programa.
                if (reset_counter == 15) begin
                    // Si el contador de reset ha alcanzado su valor máximo.
                    next_prog_reset = 0;
                    // Desactivar la señal de reset del programa.
                    uart_tx_start_reg = 1;
                    // Iniciar la transmisión UART.
                    uart_tx_data_reg = "R";
                    // Enviar el carácter 'R' para indicar que el reset ha terminado.
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                    // Pasar al estado de espera para que la transmisión UART se complete.
                end else begin
                    // Si el contador de reset no ha alcanzado su valor máximo.
                    next_prog_reset = 1;
                    // Mantener la señal de reset del programa activa.
                    next_reset_counter = reset_counter + 1;
                    // Incrementar el contador de reset.
                    next_state = PROGRAM_RESET;
                    // Permanecer en el estado de reset del programa.
                end
            end
            
            SEND_PC: begin
                // Estado para enviar el valor actual del Program Counter (PC) a través de UART.
                uart_tx_data_reg = i_pc[send_memory_counter +: 8];
                // Cargar los 8 bits actuales del PC en el registro de datos de transmisión UART.
                uart_tx_start_reg = 1;
                // Iniciar la transmisión UART.
                if (send_memory_counter < 32) begin
                    // Si aún no se han enviado todos los bytes del PC.
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_PC;
                    // Pasar al estado de espera para que la transmisión UART se complete.
                end else begin
                    // Si ya se han enviado todos los bytes del PC.
                    uart_tx_data_reg = "R";
                    // Cargar el carácter 'R' en el registro de datos de transmisión UART.
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                    // Pasar al estado de espera para que la transmisión UART se complete y enviar el ACK.
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_PC: begin
                // Estado de espera para que la transmisión UART del PC se complete.
                if (uart_tx_full) begin
                    // Si la transmisión UART se ha completado.
                    next_send_memory_counter = send_memory_counter + 8;
                    // Incrementar el contador de memoria para enviar el siguiente byte del PC.
                    next_state = SEND_PC;
                    // Volver al estado SEND_PC para enviar el siguiente byte.
                end else begin
                    // Si la transmisión UART aún no se ha completado.
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_PC;
                    // Permanecer en este estado hasta que la transmisión se complete.
                end
            end

            STEP_CLOCK: begin
                // Estado para generar un solo ciclo de reloj en modo paso a paso.
                if (!step_active || (step_active && step_counter == STEP_CYCLES - 1)) begin
                    // Si el modo paso a paso no está activo o si el contador de pasos ha alcanzado su valor máximo.
                    next_state = IDLE;
                    // Volver al estado IDLE.
                end
            end

            WAIT_RX_DOWN_STOP_PC: begin
                // Estado de espera para que la recepción UART del valor de parada del PC se complete.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = RECEIVE_STOP_PC;
                    // Volver al estado RECEIVE_STOP_PC para recibir el valor de parada del PC.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DOWN_STOP_PC;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_IDLE: begin
                // Estado de espera para que la recepción UART se complete antes de volver al estado IDLE.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = IDLE;
                    // Volver al estado IDLE.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_IDLE;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_SEND_REGISTERS: begin
                // Estado de espera para que la recepción UART se complete antes de enviar los registros.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = SEND_REGISTERS;
                    // Volver al estado SEND_REGISTERS para enviar los registros.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_SEND_REGISTERS;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_SEND_IF_ID: begin
                // Estado de espera para que la recepción UART se complete antes de enviar el registro IF/ID.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = SEND_IF_ID;
                    // Volver al estado SEND_IF_ID para enviar el registro IF/ID.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_SEND_IF_ID;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_SEND_ID_EX: begin
                // Estado de espera para que la recepción UART se complete antes de enviar el registro ID/EX.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = SEND_ID_EX;
                    // Volver al estado SEND_ID_EX para enviar el registro ID/EX.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_SEND_ID_EX;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_SEND_EX_MEM: begin
                // Estado de espera para que la recepción UART se complete antes de enviar el registro EX/MEM.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = SEND_EX_MEM;
                    // Volver al estado SEND_EX_MEM para enviar el registro EX/MEM.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_SEND_EX_MEM;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_SEND_MEM_WB: begin
                // Estado de espera para que la recepción UART se complete antes de enviar el registro MEM/WB.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = SEND_MEM_WB;
                    // Volver al estado SEND_MEM_WB para enviar el registro MEM/WB.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_SEND_MEM_WB;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_SEND_MEMORY: begin
                // Estado de espera para que la recepción UART se complete antes de enviar la memoria de datos.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = SEND_MEMORY;
                    // Volver al estado SEND_MEMORY para enviar la memoria de datos.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_LOAD_PROGRAM: begin
                // Estado de espera para que la recepción UART se complete antes de cargar el programa.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = LOAD_PROGRAM;
                    // Volver al estado LOAD_PROGRAM para cargar el programa.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS: begin
                // Estado de espera para que la recepción UART se complete antes de recibir la dirección.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = RECEIVE_ADDRESS;
                    // Volver al estado RECEIVE_ADDRESS para recibir la dirección.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            WAIT_RX_DONE_DOWN_WAIT_EXECUTE: begin
                // Estado de espera para que la recepción UART se complete antes de esperar la ejecución.
                if (!uart_rx_done_reg) begin
                    // Si la recepción UART no está en curso.
                    next_state = WAIT_EXECUTE;
                    // Volver al estado WAIT_EXECUTE para esperar la ejecución.
                end else begin
                    // Si la recepción UART está en curso.
                    next_state = WAIT_RX_DONE_DOWN_WAIT_EXECUTE;
                    // Permanecer en este estado hasta que la recepción se complete.
                end
            end
            default: next_state = IDLE;
            // Si el estado actual no coincide con ninguno de los estados definidos, volver al estado IDLE.
        endcase
    end
    // Generación de reloj para el modo paso a paso y el modo continuo
    always @(posedge i_clk or posedge i_reset) begin
        // Bloque always que se ejecuta en cada flanco de subida del reloj o en el reset.
        if (i_reset) begin
            // Si la señal de reset está activa.
            step_counter <= 0;
            // Reiniciar el contador de pasos.
            step_active <= 0;
            // Desactivar el modo paso a paso.
            step_clk <= 0;
            // Establecer el reloj de paso a 0.
            single_pulse <= 0; // Inicializar single_pulse en reset
        end else begin
            // Si la señal de reset no está activa.
            if (state == STEP_CLOCK) begin
                // Si la máquina de estados está en el estado STEP_CLOCK.
                if (!step_active) begin
                    // Si el modo paso a paso no está activo.
                    step_active <= 1;
                    // Activar el modo paso a paso.
                    step_counter <= 0;
                    // Reiniciar el contador de pasos.
                    step_clk <= 1;  // Start with rising edge
                    // Establecer el reloj de paso a 1 (flanco de subida).
                end else if (step_counter < STEP_CYCLES - 1) begin
                    // Si el contador de pasos es menor que el número de ciclos por paso menos 1.
                    step_counter <= step_counter + 1;
                    // Incrementar el contador de pasos.
                    step_clk <= ~step_clk;  // Toggle clock
                    // Invertir el reloj de paso (alternar entre 0 y 1).
                end else begin
                    // Si el contador de pasos ha alcanzado su valor máximo.
                    step_active <= 0;
                    // Desactivar el modo paso a paso.
                    step_clk <= 0;
                    // Establecer el reloj de paso a 0.
                end
            end else begin
                // Si la máquina de estados no está en el estado STEP_CLOCK.
                step_active <= 0;
                // Desactivar el modo paso a paso.
                step_clk <= 0;
                // Establecer el reloj de paso a 0.
                step_counter <= 0;
                // Reiniciar el contador de pasos.
            end

            // Lógica para generar un pulso único cuando se recibe el comando STEP_CLOCK
            if (state == IDLE && uart_rx_done_reg && uart_rx_data_reg == 8'h0A) begin
                single_pulse <= 1; // Generar un pulso
            end else begin
                single_pulse <= 0; // Mantener en bajo
            end
        end
    end

    // Señal para indicar si estamos en modo step
    reg in_step_mode;
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            in_step_mode <= 0;
        end else begin
            if (state == IDLE && uart_rx_done_reg) begin
                case (uart_rx_data_reg)
                    8'h09: in_step_mode <= 1; // Entrar en modo paso a paso
                    8'h08: in_step_mode <= 0; // Entrar en modo continuo
                endcase
            end
        end
    end

    // Asignación de la señal de reloj de depuración
    assign o_debug_clk = (o_mode == 0) ? 0 : (in_step_mode ? 1 : single_pulse);

    assign uart_tx_start = uart_tx_start_reg;
    // Asignar la señal de inicio de transmisión UART al registro de inicio de transmisión UART.

endmodule