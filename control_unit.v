module general_control #(
    parameter FUNC_SIZE = 6,
    parameter OP_SIZE = 6,
    parameter CONTROL_SIZE = 18
)(
    input wire i_enable,
    input wire [FUNC_SIZE-1:0] i_func,
    input wire [OP_SIZE-1:0] i_opcode,
    output wire [CONTROL_SIZE-1:0] o_control
);
    // TODO: Revisar los opcodes de los cases y pasar los control_reg de los comentarios a codigo xd

    // Control Bits
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
    localparam ALU_OP0 = 10; //Op0  (000: sub) (001: add) (010: slt) (011: and) (100: or) (101: xor) (110: lui)
    localparam ALU_OP1= 11;  //Op1
    localparam ALU_OP2 = 12; //Op2
    localparam MEM_2_REG = 13; //MEM_ToREG
    localparam J_RET_DST = 14;
    localparam EQorNE = 15;
    localparam JUMP_SRC = 16;
    localparam JUMP_OR_B = 17;

    reg [CONTROL_SIZE-1:0] control_reg;
    always @(*) begin
        if(i_enable) begin
            casez ({i_opcode, i_func})
            // R-Type Instructions
            12'b000000000000: control_reg = 18'b000001110110000001; // SLL (shift left logical)
            12'b000000000010: control_reg = 18'b000001110110000001; // SRL (shift right logical)
            12'b000000000011: control_reg = 18'b000001110110000001; // SRA (shift right arithmetic)
            12'b000000000100: control_reg = 18'b000001110010000001; // SLLV (shift left logical variable)
            12'b000000000110: control_reg = 18'b000001110010000001; // SRLV (shift right logical variable)
            12'b000000000111: control_reg = 18'b000001110010000001; // SRAV (shift right arithmetic variable)
            12'b000000100001: control_reg = 18'b000001110010000101; // ADDU (add unsigned)
            12'b000000100011: control_reg = 18'b000001110010000101; // SUBU (subtract unsigned)
            12'b000000100100: control_reg = 18'b000001110010000101; // AND (bitwise and)
            12'b000000100101: control_reg = 18'b000001110010000101; // OR (bitwise or)
            12'b000000100110: control_reg = 18'b000001110010000101; // XOR (bitwise xor)
            12'b000000100111: control_reg = 18'b000001110010000101; // NOR (bitwise nor)
            12'b000000101010: control_reg = 18'b000001110010000001; // SLT (set less than)
            12'b000000101011: control_reg = 18'b000001110010000101; // SLTU (set less than unsigned)

            // I-Type Instructions
            12'b100000??????: control_reg = 18'b000010011001101001; // LB (load byte)
            12'b100001??????: control_reg = 18'b000010011000101001; // LH (load halfword)
            12'b100011??????: control_reg = 18'b000010011000001001; // LW (load word)
            12'b100111??????: control_reg = 18'b000010011000001101; // LWU (load word unsigned)
            12'b100100??????: control_reg = 18'b000010011001101101; // LBU (load byte unsigned)
            12'b100101??????: control_reg = 18'b000010011000101101; // LHU (load halfword unsigned)
            12'b101000??????: control_reg = 18'b000000011001110000; // SB (store byte)
            12'b101001??????: control_reg = 18'b000000011000110000; // SH (store halfword)
            12'b101011??????: control_reg = 18'b000000011000010000; // SW (store word)
            12'b001000??????: control_reg = 18'b000000011000000001; // ADDI (add immediate)
            12'b001001??????: control_reg = 18'b000000011000000101; // ADDIU (add immediate unsigned)
            12'b001100??????: control_reg = 18'b000000111000000101; // ANDI (and immediate)
            12'b001101??????: control_reg = 18'b000001001000000101; // ORI (or immediate)
            12'b001110??????: control_reg = 18'b000001011000000101; // XORI (xor immediate)
            12'b001111??????: control_reg = 18'b000000011000000101; // LUI (load upper immediate)
            12'b001010??????: control_reg = 18'b000000101000000001; // SLTI (set less than immediate)
            12'b001011??????: control_reg = 18'b000000101000000101; // SLTIU (set less than immediate unsigned)
            12'b000100??????: control_reg = 18'b101000000000000010; // BEQ (branch on equal)
            12'b000101??????: control_reg = 18'b101000000000000010; // BNE (branch on not equal)

            // J-Type Instructions
            12'b000010??????: control_reg = 18'b110000000000000000; // J (jump)
            12'b000011??????: control_reg = 18'b110000000000000001; // JAL (jump and link)
            12'b000000001001: control_reg = 18'b110100000000000001; // JALR (jump and link register)
            12'b000000001000: control_reg = 18'b110100000000000000; // JR (jump register)

            default: control_reg = 18'b000000000000000000; // Default control signals
            endcase
        end
        else begin
            control_reg = 18'b000000000000000000;
        end
    end

    assign o_control = control_reg;
endmodule