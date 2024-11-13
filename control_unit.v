module general_control #(
    parameter FUNC_SIZE = 6,
    parameter OP_SIZE = 6,
    parameter CONTROL_SIZE = 18
)(
    input wire [FUNC_SIZE-1:0] i_func,
    input wire [OP_SIZE-1:0] i_opcode,
    output wire [CONTROL_SIZE-1:0] o_control
);
    // Control Bits
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

    reg [CONTROL_SIZE-1:0] control_reg;
    always @(*) begin
        casez ({i_opcode, i_func})
            // R-type instructions
            12'b000000000000: control_reg = 18'b100000010000000000; // SLL
            // REG_WRITE = 1 (write to register)
            // BRANCH = 0 (not a branch instruction)
            // UNSIGNED = 0 (signed operation)
            // MEM_READ = 0 (not a memory read)
            // MEM_WRITE = 0 (not a memory write)
            // A_WRITE = 0 (not writing to A)
            // B_WRITE = 0 (not writing to B)
            // REG_DST = 1 (destination register is rd)
            // SRC_A = 0 (shift source is rs)
            // SRC_B = 1 (ALU source is rt)
            // ALU_OP = 000 (ALU operation is shift left logical)
            // MEM_2_REG = 0 (not writing memory to register)
            // J_RET_DST = 0 (not a jump/return instruction)
            // EQorNE = 0 (not a branch on equal/not equal)
            // JUMP_SRC = 0 (not a jump instruction)
            // JUMP_OR_B = 0 (not a jump or branch instruction)

            12'b000000000010: control_reg = 18'b100000010000000001; // SRL
            // Similar justification as SLL, but ALU_OP = 001 (shift right logical)

            12'b000000000011: control_reg = 18'b100000010000000010; // SRA
            // Similar justification as SLL, but ALU_OP = 010 (shift right arithmetic)

            12'b000000000100: control_reg = 18'b100000010000000011; // SLLV
            // Similar justification as SLL, but ALU_OP = 011 (shift left logical variable)

            12'b000000000110: control_reg = 18'b100000010000000100; // SRLV
            // Similar justification as SLL, but ALU_OP = 100 (shift right logical variable)

            12'b000000000111: control_reg = 18'b100000010000000101; // SRAV
            // Similar justification as SLL, but ALU_OP = 101 (shift right arithmetic variable)

            12'b000000100001: control_reg = 18'b100000000000000110; // ADDU
            // REG_WRITE = 1 (write to register)
            // BRANCH = 0 (not a branch instruction)
            // UNSIGNED = 1 (unsigned operation)
            // MEM_READ = 0 (not a memory read)
            // MEM_WRITE = 0 (not a memory write)
            // A_WRITE = 0 (not writing to A)
            // B_WRITE = 0 (not writing to B)
            // REG_DST = 1 (destination register is rd)
            // SRC_A = 0 (ALU source is rs)
            // SRC_B = 0 (ALU source is rt)
            // ALU_OP = 110 (ALU operation is add unsigned)
            // MEM_2_REG = 0 (not writing memory to register)
            // J_RET_DST = 0 (not a jump/return instruction)
            // EQorNE = 0 (not a branch on equal/not equal)
            // JUMP_SRC = 0 (not a jump instruction)
            // JUMP_OR_B = 0 (not a jump or branch instruction)

            12'b000000100011: control_reg = 18'b100000000000000111; // SUBU
            // Similar justification as ADDU, but ALU_OP = 111 (subtract unsigned)

            12'b000000100100: control_reg = 18'b100000000000001000; // AND
            // Similar justification as ADDU, but ALU_OP = 000 (AND operation)

            12'b000000100101: control_reg = 18'b100000000000001001; // OR
            // Similar justification as ADDU, but ALU_OP = 001 (OR operation)

            12'b000000100110: control_reg = 18'b100000000000001010; // XOR
            // Similar justification as ADDU, but ALU_OP = 010 (XOR operation)

            12'b000000100111: control_reg = 18'b100000000000001011; // NOR
            // Similar justification as ADDU, but ALU_OP = 011 (NOR operation)

            12'b000000101010: control_reg = 18'b100000000000001100; // SLT
            // Similar justification as ADDU, but ALU_OP = 100 (set less than)

            12'b000000101011: control_reg = 18'b100000000000001101; // SLTU
            // Similar justification as ADDU, pero UNSIGNED = 1 (unsigned operation)

            // I-type instructions
            12'b100000??????: control_reg = 18'b100010010001000000; // LB
            // REG_WRITE = 1 (write to register)
            // BRANCH = 0 (not a branch instruction)
            // UNSIGNED = 0 (signed operation)
            // MEM_READ = 1 (memory read)
            // MEM_WRITE = 0 (not a memory write)
            // A_WRITE = 0 (not writing to A)
            // B_WRITE = 0 (not writing to B)
            // REG_DST = 0 (destination register is rt)
            // SRC_A = 0 (ALU source is rs)
            // SRC_B = 1 (ALU source is immediate)
            // ALU_OP = 000 (ALU operation is add)
            // MEM_2_REG = 1 (write memory to register)
            // J_RET_DST = 0 (not a jump/return instruction)
            // EQorNE = 0 (not a branch on equal/not equal)
            // JUMP_SRC = 0 (not a jump instruction)
            // JUMP_OR_B = 0 (not a jump or branch instruction)

            12'b100001??????: control_reg = 18'b100010010001000000; // LH
            // Similar justification as LB, but ALU_OP = 000 (load halfword)

            12'b100011??????: control_reg = 18'b100010010001000000; // LW
            // Similar justification as LB, but ALU_OP = 000 (load word)

            12'b100111??????: control_reg = 18'b100010010001000000; // LWU
            // Similar justification as LB, but ALU_OP = 000 (load word unsigned)

            12'b100100??????: control_reg = 18'b100010010001000000; // LBU
            // Similar justification as LB, but ALU_OP = 000 (load byte unsigned)

            12'b100101??????: control_reg = 18'b100010010001000000; // LHU
            // Similar justification as LB, but ALU_OP = 000 (load halfword unsigned)

            12'b001000??????: control_reg = 18'b100001010000000000; // ADDI
            // REG_WRITE = 1 (write to register)
            // BRANCH = 0 (not a branch instruction)
            // UNSIGNED = 0 (signed operation)
            // MEM_READ = 0 (not a memory read)
            // MEM_WRITE = 0 (not a memory write)
            // A_WRITE = 0 (not writing to A)
            // B_WRITE = 0 (not writing to B)
            // REG_DST = 0 (destination register is rt)
            // SRC_A = 0 (ALU source is rs)
            // SRC_B = 1 (ALU source is immediate)
            // ALU_OP = 000 (ALU operation is add)
            // MEM_2_REG = 0 (not writing memory to register)
            // J_RET_DST = 0 (not a jump/return instruction)
            // EQorNE = 0 (not a branch on equal/not equal)
            // JUMP_SRC = 0 (not a jump instruction)
            // JUMP_OR_B = 0 (not a jump or branch instruction)

            12'b001001??????: control_reg = 18'b100001010000000000; // ADDIU
            // Similar justification as ADDI, but UNSIGNED = 1 (unsigned operation)

            12'b001100??????: control_reg = 18'b100001010000000000; // ANDI
            // Similar justification as ADDI, but ALU_OP = 000 (AND immediate)

            12'b001101??????: control_reg = 18'b100001010000000000; // ORI
            // Similar justification as ADDI, but ALU_OP = 000 (OR immediate)

            12'b001110??????: control_reg = 18'b100001010000000000; // XORI
            // Similar justification as ADDI, but ALU_OP = 000 (XOR immediate)

            12'b001111??????: control_reg = 18'b100001010000000000; // LUI
            // Similar justification as ADDI, but ALU_OP = 000 (load upper immediate)

            12'b001010??????: control_reg = 18'b100001010000000000; // SLTI
            // Similar justification as ADDI, but ALU_OP = 000 (set less than immediate)

            12'b001011??????: control_reg = 18'b100001010000000000; // SLTIU
            // Similar justification as ADDI, but UNSIGNED = 1 (unsigned operation)

            12'b000100??????: control_reg = 18'b010000000000000000; // BEQ
            // REG_WRITE = 0 (not writing to register)
            // BRANCH = 1 (branch instruction)
            // UNSIGNED = 0 (signed operation)
            // MEM_READ = 0 (not a memory read)
            // MEM_WRITE = 0 (not a memory write)
            // A_WRITE = 0 (not writing to A)
            // B_WRITE = 0 (not writing to B)
            // REG_DST = 0 (not writing to register)
            // SRC_A = 0 (ALU source is rs)
            // SRC_B = 0 (ALU source is rt)
            // ALU_OP = 000 (ALU operation is subtract)
            // MEM_2_REG = 0 (not writing memory to register)
            // J_RET_DST = 0 (not a jump/return instruction)
            // EQorNE = 1 (branch on equal)
            // JUMP_SRC = 0 (not a jump instruction)
            // JUMP_OR_B = 1 (branch instruction)

            12'b000101??????: control_reg = 18'b010000000000000000; // BNE
            // Similar justification as BEQ, but EQorNE = 0 (branch on not equal)

            // J-type instructions
            12'b000010??????: control_reg = 18'b000000000000000000; // J
            // REG_WRITE = 0 (not writing to register)
            // BRANCH = 0 (not a branch instruction)
            // UNSIGNED = 0 (signed operation)
            // MEM_READ = 0 (not a memory read)
            // MEM_WRITE = 0 (not a memory write)
            // A_WRITE = 0 (not writing to A)
            // B_WRITE = 0 (not writing to B)
            // REG_DST = 0 (not writing to register)
            // SRC_A = 0 (ALU source is rs)
            // SRC_B = 0 (ALU source is rt)
            // ALU_OP = 000 (ALU operation is add)
            // MEM_2_REG = 0 (not writing memory to register)
            // J_RET_DST = 0 (not a jump/return instruction)
            // EQorNE = 0 (not a branch on equal/not equal)
            // JUMP_SRC = 1 (jump instruction)
            // JUMP_OR_B = 1 (jump instruction)

            12'b000011??????: control_reg = 18'b100000000000000000; // JAL
            // Similar justificación que J, pero REG_WRITE = 1 (escribir en el registro)

            default: control_reg = 18'b000000000000000000; // Default control signals
        endcase
    end

    assign o_control = control_reg;
endmodule