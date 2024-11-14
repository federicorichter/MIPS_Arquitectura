module mips #(
    parameter SIZE = 32,
    parameter SIZE_OP = 6,
    parameter CONTROL_SIZE = 18
)(
    input wire clk,
    input wire rst,
    input wire i_stall
    //o_instruction
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
    localparam ALU_OP1= 11;  //Op1
    localparam ALU_OP2 = 12; //Op2
    localparam MEM_2_REG = 13; //MEM_ToREG
    localparam J_RET_DST = 14;
    localparam EQorNE = 15;
    localparam JUMP_SRC = 16;
    localparam JUMP_OR_B = 17;



    wire [SIZE-1:0]instruction, instruction_plus4;
    wire [SIZE-1:0] reg_a;
    wire [SIZE-1:0] reg_b;
    wire [SIZE_OP-1:0] operand;
    wire [SIZE-1:0] immediate;
    wire [4:0] rs_dir, rd_dir, rt_dir;
    wire [CONTROL_SIZE-1:0] control_signals;
    wire [63:0] if_to_id;
    wire [123:0] id_to_ex;
    wire [4:0]reg_address;
    wire [SIZE-1:0] reg_alu_res;
    wire [SIZE-1:0] reg_mem_data;

    
    instruction_fetch #(
        .SIZE(32),
        .MAX_INSTRUCTION(10)
    ) IF (
        .clk(clk),
        .rst(rst),
        .i_stall(i_stall),
        //.i_instruction_jump(), //bit control jump
        .i_mux_selec(0), // selector del mux
        .o_instruction(instruction), // salida:instruccion
        .o_adder(instruction_plus4)
    );

    latch #(
        .BUS_DATA(64)
    )
    IF_ID (
        .clk(clk),
        .rst(rst),
        .i_enable(~i_stall),
        .i_data({
            instruction,
            instruction_plus4
        }),
        .o_data(if_to_id)
    );
    
    general_control #(
        .CONTROL_SIZE(CONTROL_SIZE)
    )
    control_unit(
        .i_func(if_to_id[37:32]),
        .i_opcode(operand),
        .o_control(control_signals)
    );

    instruction_decode #(
        .SIZE(32),
        .NUM_REGISTERS(32),
        //.SIZE_REG_DIR = $clog2(NUM_REGISTERS),
        .SIZE_OP(6)
    ) ID (
        .i_stall(i_stall),
        .i_instruction(if_to_id[63:32]),
        .rst(rst),
        .clk(clk),
        //.i_w_dir(),
        //.i_w_data,
        .o_reg_A(reg_a),
        .o_reg_B(reg_b),
        .o_op(operand),
        .o_immediate(immediate),
        .o_dir_rs(rs_dir),
        .o_dir_rt(rt_dir),
        .o_dir_rd(rd_dir)
    );

    latch #(
        .BUS_DATA(124)
    ) ID_EX (
        .clk(clk),
        .rst(rst),
        .i_enable(~i_stall),
        .i_data({
            //if_to_id[63:32],
            reg_a,
            reg_b,
            immediate,
            rt_dir,
            rd_dir,
            control_signals[REG_WRITE], control_signals[BRANCH],
            control_signals[UNSIGNED], control_signals[MEM_READ],
            control_signals[MEM_WRITE], control_signals[MASK_1],
            control_signals[MASK_2], control_signals[REG_DST],
            control_signals[SHIFT_SRC], control_signals[ALU_SRC],
            control_signals[ALU_OP2], control_signals[ALU_OP1],
            control_signals[ALU_OP0], control_signals[MEM_2_REG],
            control_signals[J_RET_DST], control_signals[EQorNE],
            control_signals[JUMP_SRC], control_signals[JUMP_OR_B]
        }),
        .o_data(id_to_ex)
    );

    execution #(
        .SIZE(SIZE),
        .OP_SIZE(6),
        .ALU_OP_SIZE(3)
    ) EX (
        .clk(clk),
        .i_is_unsigned(id_to_ex[15]),
        .i_shift_mux_a(id_to_ex[9]),
        .i_src_alu_b(id_to_ex[8]),
        .i_reg_dst(id_to_ex[10]),
        .i_alu_op(id_to_ex[7:5]),
        .i_data_a(id_to_ex[123:92]),
        .i_data_b(id_to_ex[91:60]),
        .i_sign_ext(id_to_ex[59:28]),
        .i_rt_add(id_to_ex[27:23]),
        .i_rd_add(id_to_ex[22:18]),
        .o_reg_add(reg_address),
        .o_alu_res(reg_alu_res),
        .o_mem_data(reg_mem_data)

    );


endmodule