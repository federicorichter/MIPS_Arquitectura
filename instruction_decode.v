module instruction_decode #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS),
    parameter SIZE_OP = 6
)
(
    input wire i_stall,
    input wire rst,
    input wire clk,
    input wire [SIZE-1:0]i_instruction,
    
    input wire [SIZE_REG_DIR-1:0] i_w_dir,
    input wire [SIZE-1:0] i_w_data,
    input wire i_write_enable,

    input wire [SIZE_REG_DIR-1:0] i_rd_ex_mem,
    input wire [SIZE_REG_DIR-1:0] i_rd_mem_wb,
    input wire [SIZE_REG_DIR-1:0] i_rd_id_ex,
    
    input wire i_reg_wr_id_ex,
    input wire i_reg_wr_ex_mem,
    input wire i_reg_wr_mem_wb,

    input wire [SIZE-1:0] i_rs_ex,
    input wire [SIZE-1:0] i_rt_ex,

    input wire [SIZE-1:0] i_data_id_ex,
    input wire [SIZE-1:0] i_data_ex_mem,
    input wire [SIZE-1:0] i_data_mem_wb,

    output wire [SIZE-1:0] o_reg_A,
    output wire [SIZE-1:0] o_reg_B,

    output wire [SIZE_OP-1:0] o_op,

    output wire [SIZE-1:0] o_immediate,

    output wire [SIZE_REG_DIR-1:0] o_dir_rs,
    output wire [SIZE_REG_DIR-1:0] o_dir_rt,
    output wire [SIZE_REG_DIR-1:0] o_dir_rd
    //output wire [1:0] o_mux_a,
    //output wire [1:0] o_mux_b
);
    reg[SIZE-1:0] reg_jump;
    wire [1:0] i_mux_A, i_mux_B;
    wire [SIZE-1:0] reg_a, reg_b;

    forwarding_unit #(
        .TAM_BITS_FORWARD(2),
        .TAM_DIREC_REG(5)
    ) forwarding_unit(
        .i_rs_if_id(i_instruction[25:21]),
        .i_rt_if_id(i_instruction[20:16]),
        .i_rd_ex_mem(i_rd_ex_mem),
        .i_rd_id_ex(i_rd_id_ex),
        .i_rd_mem_wb(i_rd_mem_wb),
        .i_reg_wr_id_ex(i_reg_wr_id_ex),
        .i_reg_wr_ex_mem(i_reg_wr_ex_mem),
        .i_reg_wr_mem_wb(i_reg_wr_mem_wb),
        .o_forward_a(i_mux_A),
        .o_forward_b(i_mux_B)
    );

    mux #(
        .BITS_ENABLES(2),
        .BUS_SIZE(SIZE)
    ) mux_A(
        .i_en(i_mux_A),
        .i_data({i_data_id_ex,i_data_mem_wb,i_data_ex_mem,reg_a}),
        .o_data(o_reg_A)
    );

    mux #(
        .BITS_ENABLES(2),
        .BUS_SIZE(SIZE)
    ) mux_B(
        .i_en(i_mux_B),
        .i_data({i_data_id_ex,i_data_mem_wb,i_data_ex_mem,reg_b}),
        .o_data(o_reg_B)
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
        .o_reg_A(reg_a),
        .o_reg_B(reg_b)
    );

    sing_extender sign_extender(
        i_instruction[15:0],
        o_immediate
    );

    //assign o_immediate = reg_jump;
    assign o_op = i_instruction[31:26];
    assign o_dir_rd = i_instruction[15:11];
    assign o_dir_rs =   i_instruction[25:21]; 
    assign o_dir_rt =   i_instruction[20:16]; 


endmodule