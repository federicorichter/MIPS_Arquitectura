module mips #(
    parameter SIZE = 32,
    parameter SIZE_OP = 6,
    parameter CONTROL_SIZE = 18,
    parameter SIZE_REG_DIR = 5,
    parameter IF_ID_SIZE = 32,
    parameter ID_EX_SIZE = 129,
    parameter EX_MEM_SIZE = 77,
    parameter MEM_WB_SIZE = 71,
    parameter ADDR_WIDTH = 32,
    parameter MAX_INSTRUCTION = 64, // Define MAX_INSTRUCTION
    parameter NUM_REGISTERS = 32,
    parameter MEM_SIZE = 64 // Define MEM_SIZE
)(
    input wire i_rst,
    input wire i_stall,
    input wire i_uart_rx,
    output wire o_uart_tx,
    input wire i_clk,
    output wire rx_done_tick, // Añadir señal de tick de recepción
    output wire tx_done_tick  // Añadir señal de tick de transmisión
);  

    //Control Bits
    localparam REG_WRITE = 0; //Reg_Write
    localparam BRANCH = 1; //Branch
    localparam UNSIGNED = 2; //Unsigned
    localparam MEM_READ = 3; //MEM_Read
    localparam MEM_WRITE = 4; //MEM_W
    localparam MASK_1 = 5;
    localparam MASK_2 = 6;
    localparam REG_DST = 7; //Reg_dst
    localparam SHIFT_SRC = 8; //ShiftSrc
    localparam ALU_SRC = 9; //AluSrc
    localparam ALU_OP0 = 10; //Op0
    localparam ALU_OP1 = 11; //Op1
    localparam ALU_OP2 = 12; //Op2
    localparam MEM_2_REG = 13; //MEM_ToREG
    localparam J_RET_DST = 14;
    localparam EQorNE = 15;
    localparam JUMP_SRC = 16;
    localparam JUMP_B = 17;



    wire [SIZE-1:0]instruction, instruction_plus4;
    wire [SIZE-1:0] reg_a;
    wire [SIZE-1:0] reg_b;
    wire [SIZE_OP-1:0] operand;
    wire [SIZE-1:0] immediate;
    wire [4:0] rs_dir, rd_dir, rt_dir;
    wire [CONTROL_SIZE-1:0] control_signals;
    wire [63:0] if_to_id;
    wire [128:0] id_to_ex;
    wire [4:0]reg_address;
    wire [SIZE-1:0] reg_alu_res;
    wire [SIZE-1:0] reg_mem_data;
    wire zero_alu;
    wire [77:0] ex_to_mem;
    wire [SIZE-1:0] mem_data;
    wire pc_source;
    wire [71:0] mem_to_wb;
    wire [SIZE-1:0] data_write_reg;
    wire [4:0] address_write_reg;
    wire [1:0] mux_a_ex, mux_b_ex;
    wire debug_clk;
    wire [SIZE-1:0] instruction_memory [14:0]; // Memoria de instrucciones de depuración
    wire [ADDR_WIDTH-1:0] debug_addr; // Dirección de depuración para la memoria de datos
    wire [SIZE-1:0] debug_data; // Datos de depuración de la memoria de datos
    wire i_inst_write_enable;
    wire [ADDR_WIDTH-1:0] i_write_addr;
    wire [SIZE-1:0] i_write_data;
    wire o_writing_instruction_mem;
    wire [IF_ID_SIZE-1:0] if_to_id;
    reg [IF_ID_SIZE-1:0] if_to_id_reg;
    wire [ID_EX_SIZE-1:0] id_to_ex; // Declarar como arreglo
    reg [ID_EX_SIZE-1:0] id_to_ex_reg;
    wire [EX_MEM_SIZE-1:0] ex_to_mem;
    reg [EX_MEM_SIZE-1:0] ex_to_mem_reg;
    wire [MEM_WB_SIZE-1:0] mem_to_wb;
    reg [MEM_WB_SIZE-1:0] mem_to_wb_reg;
    wire o_mode; // Wire to indicate the mode of operation for debugging
    wire [NUM_REGISTERS*SIZE-1:0]i_registers_debug;
    wire uart_rx_done, uart_tx_start, uart_tx_full, uart_rx_empty;
    wire [7:0] uart_rx_data, uart_tx_data;
    wire baud_tick;
    wire clk_to_use;


    always @(posedge i_clk) begin
        if (i_rst) begin
            if_to_id_reg <= 0;
            id_to_ex_reg <= 0;
            ex_to_mem_reg <= 0;
            mem_to_wb_reg <= 0;
            //pc_if <= 0;
        end
        else begin
            if_to_id_reg <= if_to_id;
            id_to_ex_reg <= id_to_ex;
            ex_to_mem_reg <= ex_to_mem;
            mem_to_wb_reg <= mem_to_wb;
        end
    end

    debugger #(
        .SIZE(SIZE),
        .NUM_REGISTERS(32),
        .SIZE_OP(SIZE_OP),
        .MEM_SIZE(MEM_SIZE),
        .IF_ID_SIZE(IF_ID_SIZE),
        .ID_EX_SIZE(ID_EX_SIZE),
        .EX_MEM_SIZE(EX_MEM_SIZE),
        .MEM_WB_SIZE(MEM_WB_SIZE)
    ) dbg (
        .i_clk(i_clk),
        .i_reset(i_rst),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .i_IF_ID(if_to_id_reg),
        .i_ID_EX(id_to_ex_reg),
        .i_EX_MEM(ex_to_mem_reg),
        .i_MEM_WB(mem_to_wb_reg),
        .i_debug_data(debug_data),
        .i_pc(pc_value),
        .o_mode(o_mode),
        .o_debug_clk(clk_to_use),
        .o_debug_addr(debug_addr),
        .o_inst_write_enable(i_inst_write_enable),
        .o_write_addr(i_write_addr),
        .o_write_data(i_write_data),
        .i_registers_debug(i_registers_debug),
        .uart_tx_start(uart_tx_start),
        .uart_tx_full(uart_tx_full),
        .uart_rx_empty(uart_rx_empty)
    );
    
    wire hazard_output;
    wire [SIZE-1:0] reg_a_conditional, reg_b_conditional;
    wire reg_equal_conditional;
    wire res_branch;
    wire pc_plus_immediate_sel;
    wire [SIZE-1:0] pc_if;
    wire [SIZE-1:0] o_mux_pc_immed;
    wire [SIZE-1:0] pc_plus;
    wire [25:0] o_jmp_direc;
    wire [SIZE-1:0] o_mux_dir;
    wire [SIZE-1:0] pc_value;
    wire [SIZE-1:0] immediate_plus_pc;
    wire if_flush;
    wire [SIZE-1:0] pc_plus_4;

    hazard_detection #(
        .SIZE_REG_DIR(5),
        .SIZE(SIZE)
    ) hazard_detection_unit(
        .i_rs_if_id(rs_dir),
        .i_rt_if_id(rt_dir),
        .i_rt_id_ex(id_to_ex[27:23]),
        .i_mem_read_id_ex(id_to_ex[14]),
        .i_jump_brch(control_signals[JUMP_B]),
        .i_branch(pc_plus_immediate_sel),
        .o_flush(if_flush),
        .o_hazard(hazard_output)
    );
      
    adder #(
        .SIZE(SIZE)
    )
    adder_pc(
        .i_a(pc_value),
        .i_b(1),
        .i_stall(i_stall || i_inst_write_enable),
        .o_result(pc_plus_4)
    );
  
    instruction_fetch #(
        .SIZE(32)
    ) IF (
        .i_clk(clk_to_use),
        .i_rst(i_rst),
        .i_stall(i_stall || o_writing_instruction_mem || hazard_output), // Bloquear el pipeline mientras se escribe la memoria de instrucciones
        .i_pc(pc_if),
        .i_mux_selec(pc_source), // selector del mux
        .o_instruction(instruction), // salida:instruccion
        .o_pc(pc_value), // salida: contador de programa
        .o_adder(instruction_plus4),
        .i_inst_write_enable(i_inst_write_enable), // habilitación de escritura
        .i_write_addr(i_write_addr), // dirección de escritura
        .i_write_data(i_write_data), // datos de escritura
        .o_writing_instruction_mem(o_writing_instruction_mem) // Señal de control para indicar escritura en memoria de instrucciones
    );

    latch #(
        .BUS_DATA(32)
    )
    IF_ID (
        .clk(clk_to_use),
        .rst(i_rst || if_flush),
        .i_enable(~i_stall && ~hazard_output && ~o_writing_instruction_mem),
        .i_data({
            //pc_plus,//PC + 4
            instruction //PC
         
        }),
        .o_data(if_to_id[31:0])
    );

    latch #(
        .BUS_DATA(32)
    )
    IF_ID2 (
        .clk(clk_to_use),
        .rst(i_rst),
        .i_enable(~i_stall && ~hazard_output && ~o_writing_instruction_mem),
        .i_data({
            pc_plus_4//PC + 4
            //instruction //PC
         
        }),
        .o_data(if_to_id[63:32])
    );
    
    general_control #(
        .CONTROL_SIZE(CONTROL_SIZE)
    )
    control_unit(
        .i_func(if_to_id[5:0]),
        .i_enable(~hazard_output),
        .i_opcode(operand),
        .o_control(control_signals)
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(SIZE)
    )
    mux_jmp_brch(
        .i_en(control_signals[JUMP_B]), //0 in branchs, 1 in Jumps
        .i_data({o_mux_dir, o_mux_pc_immed}),
        .o_data(pc_if)
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(SIZE)
    )
    mux_dir(
        .i_en(control_signals[JUMP_SRC]),
        .i_data({{6'b0,o_jmp_direc} << 2 , reg_a_conditional}), 
        .o_data(o_mux_dir)
    );

    assign reg_equal_conditional = reg_a_conditional == reg_b_conditional;

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(1)
    )
    mux_eq_neq(
        .i_en(control_signals[EQorNE]),
        .i_data({reg_equal_conditional, ~reg_equal_conditional}),
        .o_data(res_branch)
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(SIZE)
    )
    mux_pc_immediate(
        .i_en(pc_plus_immediate_sel),
        .i_data({immediate_plus_pc, pc_plus_4}),
        .o_data(o_mux_pc_immed)
    );
    assign pc_plus_immediate_sel = res_branch && control_signals[BRANCH];

    adder #(
        .SIZE(SIZE)
    ) adder_pc_immediate(
        .i_stall(i_stall || i_inst_write_enable),
        .i_a(if_to_id[63:32]),
        .i_b(immediate),
        .o_result(immediate_plus_pc)
    );


    instruction_decode #(
        .SIZE(32),
        .NUM_REGISTERS(32),
        .SIZE_REG_DIR($clog2(NUM_REGISTERS)),
        .SIZE_OP(6)
    ) ID (
        .i_stall(i_stall || o_writing_instruction_mem),
        .i_instruction(if_to_id[31:0]),
        .rst(i_rst),
        .clk(clk_to_use),
        .i_pc_if(if_to_id[63:32]),
        .i_jump_brch(control_signals[JUMP_B]),
        .i_write_enable(mem_to_wb[1]),
        .i_w_dir(address_write_reg),
        .i_w_data(data_write_reg),
        .i_rd_id_ex(reg_address),
        .i_rd_ex_mem(ex_to_mem[4:0]),
        .i_rd_mem_wb(address_write_reg),
        .i_reg_wr_id_ex(id_to_ex[17]),
        .i_data_id_ex(reg_alu_res),
        .i_data_ex_mem(mem_data),
        .i_data_mem_wb(data_write_reg),
        .i_reg_wr_ex_mem(ex_to_mem[75]),
        .i_reg_wr_mem_wb(mem_to_wb[1]),
        .i_rs_ex(id_to_ex[128:124]),
        .i_rt_ex(id_to_ex[27:23]),
        //.o_mux_a(mux_a_ex),
        //.o_mux_b(mux_b_ex),
        .o_reg_A_branch(reg_a_conditional),
        .o_reg_B_branch(reg_b_conditional),
        .o_reg_A(reg_a),
        .o_reg_B(reg_b),
        .o_op(operand),
        .o_immediate(immediate),
        .o_jmp_direc(o_jmp_direc),
        .o_dir_rs(rs_dir),
        .o_dir_rt(rt_dir),
        .o_dir_rd(rd_dir),  
        .o_registers_debug(i_registers_debug)

    );

    latch #(
        .BUS_DATA(129)
    ) ID_EX (
        .clk(clk_to_use),
        .rst(i_rst),
        .i_enable(~i_stall && ~o_writing_instruction_mem),
        .i_data({
            rs_dir, // [128:124]
            reg_a, // [123:92]
            reg_b, // [91:60]
            immediate, // [59:28]
            rt_dir, // [27:23]
            rd_dir, // [22:18]
            control_signals[REG_WRITE], control_signals[BRANCH],
            control_signals[UNSIGNED], control_signals[MEM_READ],
            control_signals[MEM_WRITE], control_signals[MASK_1],
            control_signals[MASK_2], control_signals[REG_DST],
            control_signals[SHIFT_SRC], control_signals[ALU_SRC],
            control_signals[ALU_OP2], control_signals[ALU_OP1],
            control_signals[ALU_OP0], control_signals[MEM_2_REG],
            control_signals[J_RET_DST], control_signals[EQorNE],
            control_signals[JUMP_SRC], control_signals[JUMP_B]
        }),
        .o_data(id_to_ex)
    );

    execution #(
        .SIZE(SIZE),
        .OP_SIZE(6),
        .ALU_OP_SIZE(3)
    ) EX (
        .clk(clk_to_use),
        .i_is_unsigned(id_to_ex[15]),
        .i_shift_mux_a(id_to_ex[9]),
        .i_src_alu_b(id_to_ex[8]),
        .i_reg_dst(id_to_ex[10]),
        .i_alu_op({id_to_ex[7],id_to_ex[6], id_to_ex[5]}),
        .i_data_a(id_to_ex[123:92]),
        .i_data_b(id_to_ex[91:60]),
        .i_sign_ext(id_to_ex[59:28]),
        .i_rt_add(id_to_ex[27:23]),
        .i_rd_add(id_to_ex[22:18]),
        //.i_data_ex(ex_to_mem[68:37]),
        //.i_data_mem(data_write_reg),
        //.i_mux_A(mux_a_ex),
        //.i_mux_B(mux_b_ex),
        .o_reg_add(reg_address),
        .o_alu_res(reg_alu_res),
        .o_mem_data(reg_mem_data),
        .o_zero(zero_alu)
    );

    latch #(
        .BUS_DATA(78)
    ) EX_MEM (
        .clk(clk_to_use),
        .rst(i_rst),
        .i_enable(~i_stall && ~o_writing_instruction_mem),
        .i_data({
            id_to_ex[3], // J_RET_DST[77]
            id_to_ex[4], //MEM_TO_REG [76]
            id_to_ex[17], //REG_WRITE [75]
            id_to_ex[12], //MASK_1 [74]
            id_to_ex[11], //MASK_2 [73]
            id_to_ex[16], //BRANCH [72]
            id_to_ex[13], //MEM_WRITE [71]
            id_to_ex[14], //MEM_READ [70]
            zero_alu, // 1 bit [69]
            reg_alu_res, // 32 bits [68:37]
            reg_mem_data, // 32 bits [36:5]
            reg_address  //destiny reg - 5bits [4:0]
        }),
        .o_data(ex_to_mem)
    );

    data_memory #(
        .DATA_WIDTH(SIZE),
        .MEM_SIZE(1024)
    ) MEM (
        .clk(clk_to_use),
        .rst(i_rst),
        .i_mem_write(ex_to_mem[71]),
        .i_mem_read(ex_to_mem[70]),
        .i_zero_alu(ex_to_mem[69]),
        .i_branch(ex_to_mem[72]),
        .addr(ex_to_mem[68:37]),
        .write_data(ex_to_mem[36:5]),
        .i_mask_1(ex_to_mem[74]),
        .i_mask_2(ex_to_mem[73]),
        .read_data(mem_data),
        .debug_addr(debug_addr), // Dirección de depuración
        .debug_data(debug_data), // Datos de depuración
        .o_pc_source(pc_source)
    );

    latch #(
        .BUS_DATA(72)
    ) MEM_WB (
        .clk(clk_to_use),
        .rst(i_rst),
        .i_enable(~i_stall && ~o_writing_instruction_mem),
        .i_data({
            ex_to_mem[77], //destiny return address [71]
            ex_to_mem[68:37], // alu result [70:39]
            mem_data, // data read from memory [38:7]
            ex_to_mem[4:0], //reg destiny [6:2]
            ex_to_mem[75], //REG_WRITE [1]
            ex_to_mem[76] //MEM_TO_REG [0]
        }),
        .o_data(mem_to_wb)
    );

    write_back #(
        .SIZE(SIZE)
    ) WB (
        .i_mem_to_reg(mem_to_wb[0]),
        .i_data_read(mem_to_wb[38:7]),
        .i_res_alu(mem_to_wb[70:39]),
        .o_data_wb(data_write_reg)
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(SIZE_REG_DIR)
    ) mux_ret_jump (
        .i_en(mem_to_wb[71]),
        .i_data({5'b11111,mem_to_wb[6:2]}),
        .o_data(address_write_reg)
    );

    //assign address_write_reg = (ex_to_mem[75] == 1 ? mem_to_wb[6:2] : 5'b0 );

endmodule