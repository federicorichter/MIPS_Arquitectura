module mips #(
    parameter SIZE = 32,
    parameter SIZE_OP = 6
)(
    input wire clk,
    input wire rst,
    input wire i_stall
    //o_instruction
);  
    wire [SIZE-1:0]instruction;
    wire [SIZE-1:0] reg_a;
    wire [SIZE-1:0] reg_b;
    wire [SIZE_OP-1:0] operand;
    wire [SIZE-1:0] immediate;
    wire [4:0] rs_dir, rd_dir, rt_dir;
    
    instruction_fetch #(
    .SIZE(32),
    .MAX_INSTRUCTION(10)
    ) IF (
    .clk(clk),
    .rst(rst),
    .i_stall(i_stall),
    //.i_instruction_jump(), //bit control jump
    .i_mux_selec(0), // selector del mux
    .o_instruction(instruction) // salida:instruccion
    //o_pc
    );

    instruction_decode #(
        .SIZE(32),
        .NUM_REGISTERS(32),
        //.SIZE_REG_DIR = $clog2(NUM_REGISTERS),
        .SIZE_OP(6)
    ) ID (
        .i_stall(i_stall),
        .i_instruction(instruction),
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