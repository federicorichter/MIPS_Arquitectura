module control_alu#(
    parameter SIZE = 32
)(
    input wire [2:0] alu_op,
    input wire [5:0] alu_function,
    output wire [5:0] o_alu_func
);

    reg [5:0] alu_func;

    

    assign o_alu_func = alu_func;

endmodule