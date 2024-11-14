module execution#(
    parameter SIZE = 32,
    parameter OP_SIZE = 6,
    parameter ALU_OP_SIZE = 3
)(  
    input wire clk,
    input wire i_shift_mux_a,
    input wire i_src_alu_b,
    input wire i_reg_dst,
    input wire [ALU_OP_SIZE-1:0]i_alu_op,
    input wire [SIZE-1:0] i_data_a,
    input wire [SIZE-1:0] i_data_b,
    input wire [SIZE-1:0] i_sign_ext,
    input wire [SIZE-1:0] i_rt_add,
    input wire [SIZE-1:0] i_rd_add,
    output wire [SIZE-1:0] o_reg_add,
    output wire [SIZE-1:0] o_alu_res,
    output wire [SIZE-1:0] o_mem_data
);  
    wire [SIZE-1:0] alu_a_data;
    wire [SIZE-1:0] alu_b_data;
    wire [SIZE-1:0] alu_op;
    
    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(5)
    )
    mux_reg_dest (
        i_reg_dst,
        {i_rt_add,i_rd_add},
        o_reg_add
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(32)
    )
    mux_b (
        i_src_alu_b,
        {i_data_b, i_sign_ext},
        alu_b_data
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(32)
    )
    mux_shift (
        i_shift_mux_a,
        {i_data_a,{27'b0, i_sign_ext[10 : 6]}},
        alu_a_data
    );

     control_alu #(
        .SIZE(SIZE),
        .ALU_OP_SIZE(ALU_OP_SIZE),
        .ALU_FUNC_SIZE(OP_SIZE)
     ) alu_control(
        .i_alu_op(i_alu_op),
        .i_alu_function(i_sign_ext[OP_SIZE-1: 0]),
        .o_alu_func(alu_op)
    );

    ALU  #(
        .DATA_WIDTH(SIZE),
        .MODE_WIDTH(OP_SIZE)
    )alu_inst(  
        .i_A(alu_a_data),
        .i_B(alu_b_data),
        .i_mode(alu_op),
        .o_result(o_alu_res)
    );

    assign o_mem_data = i_data_b;

endmodule