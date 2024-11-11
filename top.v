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
    localparam A_WRITE = 5; 
    localparam B_WRITE = 6;
    localparam REG_DST = 7; //Reg_dst
    localparam SRC_A = 8; //ShiftSrc
    localparam SRC_B = 9; //AluSrc
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
    wire [67:0] if_to_id;
    
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

    /*latch #(
        .BUS_DATA(120)
    ) ID_EX (
        .clk(clk),
        .rst(rst),
        .i
    );*/

    instruction_decode #(
        .SIZE(32),
        .NUM_REGISTERS(32),
        //.SIZE_REG_DIR = $clog2(NUM_REGISTERS),
        .SIZE_OP(6)
    ) ID (
        .i_stall(i_stall),
        .i_instruction(if_to_id[63:32]),
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

endmodule