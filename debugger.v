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
    output reg step_signal,                    // Señal de reloj para depuración (puede ser el reloj del sistema o el reloj de paso)
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
    reg single_pulse_internal;
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
    reg single_pulse;
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
    reg step_signal_internal;

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

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            single_pulse_internal <= 0;
        end else begin
            if (state == IDLE && uart_rx_done_reg && uart_rx_data_reg == 8'h0A) begin
                single_pulse_internal <= 1;
            end else begin
                single_pulse_internal <= 0;
            end
        end
    end

    reg in_step_mode;
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            in_step_mode <= 0;
        end else begin
            if (state == IDLE && uart_rx_done_reg) begin
                case (uart_rx_data_reg)
                    8'h09: in_step_mode <= 1;
                    8'h08: in_step_mode <= 0;
                endcase
            end
        end
    end

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            step_signal <= 0;
            step_signal_internal <= 0;
        end else begin
            if (o_mode == 0) begin
                step_signal <= 0;
                step_signal_internal <= 0;
            end else begin
                if (in_step_mode) begin
                    step_signal_internal <= 1;
                end else begin
                    step_signal_internal <= single_pulse_internal;
                end
                step_signal <= step_signal_internal;
            end
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
            one_pulse_low <= 0;
        end else begin
            state <= next_state;
            state_out <= state;
            reset_counter <= next_reset_counter;
            o_prog_reset <= next_prog_reset;
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
            RECEIVE_INSTRUCTION_COUNT: begin
                if (uart_rx_done_reg) begin
                    next_instruction_count = uart_rx_data_reg;
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

            LOAD_PROGRAM: begin
                if (uart_rx_done_reg) begin
                    uart_rx_done_reg_out = 1;
                    case (byte_counter)
                        1: begin
                            instruction_buffer[7:0] = uart_rx_data_reg;
                            next_state = WAIT_RX_DONE_LOAD_PROGRAM_1;
                        end
                        2: begin
                            instruction_buffer[15:8] = uart_rx_data_reg;
                            next_state = WAIT_RX_DONE_LOAD_PROGRAM_2;
                        end
                        3: begin
                            instruction_buffer[23:16] = uart_rx_data_reg;
                            next_state = WAIT_RX_DONE_LOAD_PROGRAM_3;
                        end
                        4: begin
                            instruction_buffer[31:24] = uart_rx_data_reg;
                            o_write_data = instruction_buffer;
                            next_instruction_counter = instruction_counter + 1;

                            if (next_instruction_counter < instruction_count) begin
                                next_write_addr = o_write_addr + 1;
                                next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                            end else if (next_instruction_counter == instruction_count) begin
                                next_write_addr = o_write_addr + 1;
                                next_state = WAIT_EXECUTE;
                            end
                        end
                        default: instruction_buffer = instruction_buffer;
                    endcase
                end
            end

            WAIT_RX_DONE_LOAD_PROGRAM_1: begin
                if (!uart_rx_done_reg) begin
                    next_byte_counter = 2;
                    next_state = LOAD_PROGRAM;
                end else begin
                    next_state = WAIT_RX_DONE_LOAD_PROGRAM_1;
                end
            end

            WAIT_RX_DONE_LOAD_PROGRAM_2: begin
                if (!uart_rx_done_reg) begin
                    next_byte_counter = 3;
                    next_state = LOAD_PROGRAM;
                end else begin
                    next_state = WAIT_RX_DONE_LOAD_PROGRAM_2;
                end
            end

            WAIT_RX_DONE_LOAD_PROGRAM_3: begin
                if (!uart_rx_done_reg) begin
                    next_byte_counter = 4;
                    next_state = LOAD_PROGRAM;
                end else begin
                    next_state = WAIT_RX_DONE_LOAD_PROGRAM_3;
                end
            end

            WAIT_RX_DONE_DOWN_LOAD_PROGRAM: begin
                if (!uart_rx_done_reg) begin
                    next_byte_counter = 1;
                    next_state = LOAD_PROGRAM;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                end
            end

            RECEIVE_ADDRESS: begin
                if (uart_rx_done_reg) begin
                    o_debug_addr = uart_rx_data_reg[ADDR_WIDTH-1:0];
                    o_clk_mem_read = 1;
                    next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY;
                end
            end

            RECEIVE_STOP_PC: begin
                if (uart_rx_done_reg) begin
                    stop_pc = uart_rx_data_reg;
                    next_state = WAIT_NO_TX_FULL;
                end
            end

            WAIT_EXECUTE: begin
                if (next_instruction_counter == instruction_count && instruction_count > 0) begin
                    o_write_data = 0;
                    reset_active = 1;
                    next_prog_reset = 1;
                    next_reset_counter = 0;
                    next_state = PROGRAM_RESET;
                end
            end

            PROGRAM_RESET: begin
                if (reset_counter == 15) begin
                    next_prog_reset = 0;
                    uart_tx_start_reg = 1;
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end else begin
                    next_prog_reset = 1;
                    next_reset_counter = reset_counter + 1;
                    next_state = PROGRAM_RESET;
                end
            end

            SEND_PC: begin
                uart_tx_data_reg = i_pc[send_memory_counter +: 8];
                uart_tx_start_reg = 1;
                if (send_memory_counter < 32) begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_PC;
                end else begin
                    uart_tx_data_reg = "R";
                    next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
                end
            end

            WAIT_UART_TX_FULL_DOWN_SEND_PC: begin
                if (uart_tx_full) begin
                    next_send_memory_counter = send_memory_counter + 8;
                    next_state = SEND_PC;
                end else begin
                    next_state = WAIT_UART_TX_FULL_DOWN_SEND_PC;
                end
            end

            STEP_CLOCK: begin
                if (!step_active || (step_active && step_counter == STEP_CYCLES - 1)) begin
                    next_state = IDLE;
                end
            end

            WAIT_RX_DOWN_STOP_PC: begin
                if (!uart_rx_done_reg) begin
                    next_state = RECEIVE_STOP_PC;
                end else begin
                    next_state = WAIT_RX_DOWN_STOP_PC;
                end
            end
            WAIT_RX_DONE_DOWN_IDLE: begin
                if (!uart_rx_done_reg) begin
                    next_state = IDLE;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_IDLE;
                end
            end
            WAIT_RX_DONE_DOWN_SEND_REGISTERS: begin
                if (!uart_rx_done_reg) begin
                    next_state = SEND_REGISTERS;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_SEND_REGISTERS;
                end
            end
            WAIT_RX_DONE_DOWN_SEND_IF_ID: begin
                if (!uart_rx_done_reg) begin
                    next_state = SEND_IF_ID;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_SEND_IF_ID;
                end
            end
            WAIT_RX_DONE_DOWN_SEND_ID_EX: begin
                if (!uart_rx_done_reg) begin
                    next_state = SEND_ID_EX;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_SEND_ID_EX;
                end
            end
            WAIT_RX_DONE_DOWN_SEND_EX_MEM: begin
                if (!uart_rx_done_reg) begin
                    next_state = SEND_EX_MEM;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_SEND_EX_MEM;
                end
            end
            WAIT_RX_DONE_DOWN_SEND_MEM_WB: begin
                if (!uart_rx_done_reg) begin
                    next_state = SEND_MEM_WB;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_SEND_MEM_WB;
                end
            end
            WAIT_RX_DONE_DOWN_SEND_MEMORY: begin
                if (!uart_rx_done_reg) begin
                    next_state = SEND_MEMORY;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY;
                end
            end
            WAIT_RX_DONE_DOWN_LOAD_PROGRAM: begin
                if (!uart_rx_done_reg) begin
                    next_state = LOAD_PROGRAM;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_LOAD_PROGRAM;
                end
            end
            WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS: begin
                if (!uart_rx_done_reg) begin
                    next_state = RECEIVE_ADDRESS;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS;
                end
            end
            WAIT_RX_DONE_DOWN_WAIT_EXECUTE: begin
                if (!uart_rx_done_reg) begin
                    next_state = WAIT_EXECUTE;
                end else begin
                    next_state = WAIT_RX_DONE_DOWN_WAIT_EXECUTE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    reg in_step_mode;
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            in_step_mode <= 0;
        end else begin
            if (state == IDLE && uart_rx_done_reg) begin
                case (uart_rx_data_reg)
                    8'h09: in_step_mode <= 1;
                    8'h08: in_step_mode <= 0;
                endcase
            end
        end
    end

    reg single_pulse_done;
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            step_signal <= 0;
            single_pulse_internal <= 0;
            single_pulse_done <= 0;
        end else begin
            if (o_mode == 0) begin
                step_signal <= 0;
                single_pulse_internal <= 0;
                single_pulse_done <= 0;
            end else begin
                if (in_step_mode) begin
                    step_signal <= 1;
                    single_pulse_internal <= 0;
                    single_pulse_done <= 0;
                end else begin
                    if (state == IDLE && uart_rx_done_reg && uart_rx_data_reg == 8'h0A && !single_pulse_done) begin
                        step_signal <= 1;
                        single_pulse_internal <= 1;
                        single_pulse_done <= 1;
                    end else if (single_pulse_internal) begin
                        step_signal <= 0;
                        single_pulse_internal <= 0;
                        single_pulse_done <= 1;
                    end else begin
                        step_signal <= 0;
                        single_pulse_internal <= 0;
                        single_pulse_done <= 0;
                    end
                end
            end
        end
    end

    assign uart_tx_start = uart_tx_start_reg;

endmodule