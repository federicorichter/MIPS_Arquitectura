module debugger #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS),
    parameter SIZE_OP = 6,
    parameter MEM_SIZE = 64, // Tamaño de la memoria en bytes
    parameter ADDR_WIDTH = $clog2(MEM_SIZE),
    parameter IF_ID_SIZE = 64,
    parameter ID_EX_SIZE = 129,
    parameter EX_MEM_SIZE = 77,
    parameter MEM_WB_SIZE = 71,
    parameter STEP_CYCLES = 3
)(
    input wire i_clk,
    input wire i_reset,
    input wire i_uart_rx,
    input wire [(SIZE*NUM_REGISTERS)-1:0] i_registers_debug,
    input wire [IF_ID_SIZE-1:0] i_IF_ID,
    input wire [ID_EX_SIZE-1:0] i_ID_EX,
    input wire [EX_MEM_SIZE-1:0] i_EX_MEM,
    input wire [MEM_WB_SIZE-1:0] i_MEM_WB,
    input wire [SIZE-1:0] i_debug_data, 
    input wire [SIZE-1:0] i_pc,
    input wire [SIZE*MEM_SIZE-1:0] i_debug_instructions,
    output reg o_mode,
    output reg [ADDR_WIDTH-1:0] o_debug_addr,
    output reg [ADDR_WIDTH-1:0] o_write_addr_reg,
    output reg o_inst_write_enable_reg,
    output reg [SIZE-1:0] o_write_data_reg,
    output reg o_clk_mem_read,
    output reg [5:0] state_out,
    output reg [7:0] uart_rx_data_out,
    output reg [4:0] instruction_counter_out,
    output reg [4:0] instruction_count_out,
    output reg [2:0] byte_counter_out,
    output reg uart_rx_done_reg_out,
    output reg [4:0] i_pc_out,
    output reg o_prog_reset,
    output wire uart_tx_start,
    output wire o_uart_tx,
    output wire o_debug_clk,
    output wire uart_tx_full  
    );

    // State machine states
    localparam IDLE = 0;
    localparam SEND_REGISTERS = 1;
    localparam SEND_IF_ID = 2;
    localparam SEND_ID_EX = 3;
    localparam SEND_EX_MEM = 4;
    localparam SEND_MEM_WB = 5;
    localparam SEND_MEMORY = 6;
    localparam LOAD_PROGRAM = 10;
    localparam WAIT_EXECUTE = 11;
    localparam STEP_CLOCK = 12;
    localparam RECEIVE_ADDRESS = 14;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_REGISTERS = 15;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_IF_ID = 16;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_ID_EX = 17;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_EX_MEM = 18;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEM_WB = 19;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_MEMORY = 20;
    localparam WAIT_RX_DONE_DOWN_IDLE = 24;
    localparam WAIT_RX_DONE_DOWN_SEND_REGISTERS = 25;
    localparam WAIT_RX_DONE_DOWN_SEND_IF_ID = 26;
    localparam WAIT_RX_DONE_DOWN_SEND_ID_EX = 27;
    localparam WAIT_RX_DONE_DOWN_SEND_EX_MEM = 28;
    localparam WAIT_RX_DONE_DOWN_SEND_MEM_WB = 29;
    localparam WAIT_RX_DONE_DOWN_SEND_MEMORY = 30;
    localparam WAIT_RX_DONE_DOWN_LOAD_PROGRAM = 31;
    localparam WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS = 32;
    localparam SEND_IDLE_ACK = 34;
    localparam WAIT_UART_TX_FULL_DOWN_IDLE_ACK = 35;
    localparam WAIT_NO_TX_FULL = 36;
    localparam WAIT_TX_DOWN_IDLE_ACK = 37;
    localparam RECEIVE_STOP_PC = 38;
    localparam WAIT_RX_DOWN_STOP_PC = 39;
    localparam RECEIVE_INSTRUCTION_COUNT = 40;
    localparam WAIT_RX_DONE_DOWN_RECEIVE_INSTRUCTION_COUNT = 41;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_1 = 42;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_2 = 43;
    localparam WAIT_RX_DONE_LOAD_PROGRAM_3 = 44;
    localparam PROGRAM_RESET = 46;
    localparam SEND_DEBUG_INSTRUCTIONS = 48;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_DEBUG_INSTRUCTIONS = 49;
    localparam SEND_PC = 50;
    localparam WAIT_UART_TX_FULL_DOWN_SEND_PC = 51;
    
    
    localparam RX_IDLE = 0;
    localparam RX_RECEIVING = 1;
    localparam RX_DONE = 2;


    wire [7:0] uart_rx_data;
    wire [7:0] uart_tx_data;
    wire uart_rx_done; 

    reg [5:0] state, next_state;
    reg [31:0] i;
    reg [31:0] send_registers_counter = 0;
    reg [31:0] send_if_id_counter = 0;
    reg [31:0] send_id_ex_counter = 0;
    reg [31:0] send_ex_mem_counter = 0;
    reg [31:0] send_mem_wb_counter = 0;
    reg [31:0] send_memory_counter = 0;
    reg [31:0] next_send_registers_counter = 0;
    reg [31:0] next_send_if_id_counter = 0;
    reg [31:0] next_send_id_ex_counter = 0;
    reg [31:0] next_send_ex_mem_counter = 0;
    reg [31:0] next_send_mem_wb_counter = 0;
    reg [31:0] next_send_memory_counter = 0;
    reg [31:0] next_instruction_counter = 0;
    reg [31:0] next_instruction_count = 0;
    reg [ADDR_WIDTH-1:0] next_write_addr;
    reg [SIZE-1:0] stop_pc = 0;
    reg done_inst_write = 0;
    reg ctr_rx_done = 0;
    reg [3:0] reset_counter;
    reg reset_active;
    reg [31:0] send_debug_instructions_counter = 0;
    reg [31:0] next_send_debug_instructions_counter = 0;
    reg next_prog_reset;
    reg [3:0] next_reset_counter;
    reg uart_tx_start_reg = 0;
    reg uart_rx_done_reg;
    reg original_mode; 
    reg [7:0] uart_rx_data_reg = 0;
    reg [7:0] uart_tx_data_reg = 0;
    reg [31:0] instruction_buffer = 0; 
    reg [1023:0] padded_registers;
    reg [IF_ID_SIZE-1:0] padded_if_id;
    reg [135:0] padded_id_ex;
    reg [79:0] padded_ex_mem;
    reg [71:0] padded_mem_wb;
    reg [31:0] instruction_count = 0; 
    reg [31:0] instruction_counter = 0; 
    reg [IF_ID_SIZE-1:0] i_IF_ID_REG;
    reg send_idle_ack_flag;
    reg [ADDR_WIDTH-1:0] o_write_addr = 0;
    reg [SIZE-1:0] o_write_data = 0; 
    reg o_inst_write_enable = 0;
    reg step_clk;
    reg step_complete;
    reg [31:0] step_counter;
    reg step_active;
    reg [1:0] rx_state;
    integer next_byte_counter = 0;
    integer byte_counter = 1;

    

    // UART modules
    wire tick;
    baudrate_generator #(
        .COUNT(261)
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
        .tx_start(uart_tx_start),
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

    always @(*) begin
        o_write_addr_reg = o_write_addr;
        o_inst_write_enable_reg = o_inst_write_enable;
        o_write_data_reg = o_write_data;
    end

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
            byte_counter_out <= byte_counter[2:0];
            instruction_count_out <= instruction_count[4:0]; 
            instruction_counter_out <= instruction_counter[4:0]; 
        end
    end

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state <= IDLE;
            state_out <= IDLE;
            reset_counter <= 0;
            reset_active <= 0;
            o_prog_reset <= 0;
        end else begin
            state <= next_state;
            state_out <= state;
            reset_counter <= next_reset_counter;
            o_prog_reset <= next_prog_reset;
        end
    end

    always @(*) begin
        next_state = state;
        next_send_registers_counter = send_registers_counter;
        next_send_if_id_counter = send_if_id_counter;
        next_send_id_ex_counter = send_id_ex_counter;
        next_send_ex_mem_counter = send_ex_mem_counter;
        next_send_mem_wb_counter = send_mem_wb_counter;
        next_send_memory_counter = send_memory_counter;
        next_instruction_counter = instruction_counter;
        next_prog_reset = o_prog_reset;
        next_reset_counter = reset_counter; 
        next_byte_counter = byte_counter;
        next_instruction_count = instruction_count;
        next_write_addr = o_write_addr;
        next_send_debug_instructions_counter = send_debug_instructions_counter;
        uart_tx_start_reg = 0;
        stop_pc = instruction_count - 7;
        case (state)
            IDLE: begin
                uart_tx_start_reg = 0;
                next_send_registers_counter = 0;
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
                if (uart_rx_done_reg) begin
                    case (uart_rx_data_reg)
                        8'h01: next_state = WAIT_RX_DONE_DOWN_SEND_REGISTERS; // Comando para ver los registros
                        8'h02: next_state = WAIT_RX_DONE_DOWN_SEND_IF_ID;  // Comando para ver el IF_ID
                        8'h03: next_state = WAIT_RX_DONE_DOWN_SEND_ID_EX;  // Comando para ver el ID_EX
                        8'h04: next_state = WAIT_RX_DONE_DOWN_SEND_EX_MEM; // Comando para ver el EX_MEM
                        8'h05: next_state = WAIT_RX_DONE_DOWN_SEND_MEM_WB; // Comando para ver el MEM_WB
                        8'h06: next_state = WAIT_RX_DONE_DOWN_SEND_MEMORY; // Comando para ver la memoria de datos
                        8'h07: begin // Comando para cargar programa
                            next_write_addr = 0; 
                            o_mode = 1; // Cambiar a modo step
                            o_inst_write_enable = 1;
                            next_state = WAIT_RX_DONE_DOWN_RECEIVE_INSTRUCTION_COUNT;
                        end
                        8'h08: begin // Comando para cambiar a modo continuo
                            o_mode = 0; // Modo continuo
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h09: begin // Comando para cambiar a modo paso a paso
                            o_mode = 1; // Modo paso a paso
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h0A: next_state = STEP_CLOCK; // Comando para avanzar un ciclo de reloj
                        8'h0B: next_state = WAIT_RX_DONE_DOWN_RECEIVE_ADDRESS; // Comando para leer memoria de datos
                        8'h0E: next_state = WAIT_RX_DOWN_STOP_PC; // Comando para recibir el valor de PC_STOP
                        8'h0D: begin // Comando para iniciar después de la escritura
                            done_inst_write = 1;
                            o_inst_write_enable = 0;
                            next_state = WAIT_RX_DONE_DOWN_IDLE;
                        end
                        8'h10: next_state = SEND_DEBUG_INSTRUCTIONS; // Comando para ver la memoria de instrucciones
                        8'h11: next_state = SEND_PC; // Comando para ver el PC actual
                    
                        default: next_state = WAIT_RX_DONE_DOWN_IDLE;
                    endcase
                end
            end
            SEND_IDLE_ACK: begin
                uart_tx_data_reg = "R";
                uart_tx_start_reg = 1;
                next_state = WAIT_UART_TX_FULL_DOWN_IDLE_ACK;
            end
            WAIT_UART_TX_FULL_DOWN_IDLE_ACK: begin
                if (uart_tx_full) begin
                    uart_tx_start_reg = 0;
                    next_state = WAIT_TX_DOWN_IDLE_ACK;
                end
            end
            WAIT_TX_DOWN_IDLE_ACK: begin
                if (!uart_tx_full) begin
                    next_state = IDLE;
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
                    uart_tx_data_reg = "R";
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
                    uart_tx_data_reg = "R"; 
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
            default: next_state = IDLE;
        endcase
    end

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            step_counter <= 0;
            step_active <= 0;
            step_clk <= 0;
        end else begin
            if (state == STEP_CLOCK) begin
                if (!step_active) begin
                    step_active <= 1;
                    step_counter <= 0;
                    step_clk <= 1; 
                end else if (step_counter < STEP_CYCLES - 1) begin
                    step_counter <= step_counter + 1;
                    step_clk <= ~step_clk;
                end else begin
                    step_active <= 0;
                    step_clk <= 0;
                end
            end else begin
                step_active <= 0;
                step_clk <= 0;
                step_counter <= 0;
            end
        end
    end
    assign o_debug_clk = (o_mode || i_pc >= stop_pc) ? step_clk : i_clk;

    assign uart_tx_start = uart_tx_start_reg;

endmodule