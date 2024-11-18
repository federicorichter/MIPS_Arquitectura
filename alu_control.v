module control_alu#(
    parameter SIZE = 32,
    parameter ALU_OP_SIZE = 3,
    parameter ALU_FUNC_SIZE = 6
)(
    input wire i_is_unsigned,
    input wire [ALU_OP_SIZE-1:0] i_alu_op,
    input wire [ALU_FUNC_SIZE - 1:0] i_alu_function,
    output wire [ALU_FUNC_SIZE - 1:0] o_alu_func
);

    reg [ALU_FUNC_SIZE-1:0] alu_func;

    localparam [ALU_OP_SIZE-1:0] ALU_SUB = 3'b000,
                                 ALU_ADD = 3'b001,
                                 ALU_SLT = 3'b010,
                                 ALU_AND = 3'b011,
                                 ALU_OR = 3'b100,
                                 ALU_XOR = 3'b101;


    always @(*) begin
        case({i_alu_op,i_is_unsigned}) 
            {ALU_SUB, 1'b0} : alu_func = 6'b100010; //signed sub
            {ALU_ADD, 1'b0} : alu_func = 6'b100000; //signed add
            {ALU_SLT, 1'b0} : alu_func = 6'b101000; //signed slt
            {ALU_SUB, 1'b1} : alu_func = 6'b100011; //unsigned sub 
            {ALU_ADD, 1'b1} : alu_func = 6'b100001; //unsigned add
            {ALU_SLT, 1'b1} : alu_func = 6'b101001; //unsigned slt
            {ALU_AND, 1'b0} : alu_func = 6'b100100; 
            {ALU_OR,1'b0}  : alu_func = 6'b100101;
            {ALU_XOR,1'b0} : alu_func = 6'b100110;
            default : alu_func = i_alu_function;
        endcase
    end
    

    assign o_alu_func = alu_func;

endmodule