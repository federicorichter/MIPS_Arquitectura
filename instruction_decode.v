module instruction_decode #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog(NUM_REGISTERS),
    parameter SIZE_OP = 6
)
(
    input wire [SIZE-1:0]i_instruction,
    
    input wire [SIZE_REG_DIR-1:0] i_w_dir,
    input wire [SIZE-1:0] i_w_data,

    output wire [SIZE-1:0] o_reg_A,
    output wire [SIZE-1:0] o_reg_B,

    output wire [SIZE_OP-1:0] o_op,

    output wire [SIZE-1:0] o_immediate,

    output wire [SIZE-1:0] o_dir_rs,
    output wire [SIZE-1:0] o_dir_rt,
    output wire [SIZE-1:0] o_dir_rd
);
    reg[SIZE-1:0] reg_jump;

    mux #(
        .BITS_ENABLES(2),
        .BUS_SIZE(SIZE)
    ) mux_A(
        .i_en(),
        .i_data(),
        .o_data()
    );

    mux #(
        .BITS_ENABLES(2),
        .BUS_SIZE(SIZE)
    ) mux_B(
        .i_en(),
        .i_data(),
        .o_data()
    );


    register_bank#(
        .SIZE(SIZE),
        .NUM_REGISTERS(NUM_REGISTERS)
    ) registers (
        .clk(clk),
        .rst(rst),
        .i_write_enable(i_write_enable),
        .i_dir_regA(i_instruction[25:21]),
        .i_dir_regB(i_instruction[20:16]),
        .i_w_dir(i_w_dir),
        .i_w_data(i_w_data),
        .o_reg_A(o_reg_A),
        .o_reg_B(o_reg_B)
    );

    sign_extender sign_extender(
        i_instruction[15:0],
        reg_jump
    );

    assign o_immediate = reg_jump;
    assign o_op = i_instruction[31:26];
    assign o_dir_rd = i_instruction[15:11];
    assign o_dir_rs =   i_instruction[25:21]; 
    assign o_dir_rt =   i_instruction[20:16]; 


endmodule