module write_back #(
    parameter SIZE = 32,
    parameter SIZE_REG_DIR = $clog2(SIZE)
)
(
    input wire i_mem_to_reg,
    input wire [SIZE-1:0] i_data_read,
    input wire [SIZE-1:0] i_res_alu,
    //input wire [SIZE_REG_DIR-1:0] i_reg_dst,
    output wire [SIZE-1:0] o_data_wb
);

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(32)
    ) mux_wb (
        i_mem_to_reg,
        {i_data_read,i_res_alu},
        o_data_wb
    );


endmodule