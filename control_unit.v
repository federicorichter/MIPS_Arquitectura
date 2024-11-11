module general_control #(
        parameter FUNC_SIZE = 6,
        parameter OP_SIZE = 6,
        parameter CONTROL_SIZE = 18
    )
    (
        input wire[FUNC_SIZE-1:0]  i_func,
        input wire[OP_SIZE-1:0]  i_opcode,
        output wire [CONTROL_SIZE-1:0]  o_control
    );

    // BITS Control
    // REG_WRITE BRANCH REG_DEST MEM_READ MEM_WRITE A_WRITE B_WRITE REG_DST SRC_B SRC_A ALU_OP[3]

    reg [CONTROL_SIZE-1:0] control_reg;
    always @(*)begin
        casez({i_opcode,i_func})
            12'b1?0?????????: // LOAD instructions -> RegDst,MemToReg,MemRead,ALUSrc,RegWrite,if i_op[1]->unsigned,i_op[0]->DataMask0, i_op[2]->DataMask1 
                control_reg = {000001010001,i_opcode[0],01}; 
            12'b1?1?????????: // STORE -> MemWrite, AluSrc, if i_op[2]unsigned,if[0]DataMask0, if[1]DataMask1 
                control_reg = {00000010010,i_opcode[2],00};
            12'b0?1?????????:  //SHIFT -> RegDst, DataMask0, DataMask1, AluSrc, RegWrite, Ope[2:0] -> i_op[2:0]
                control_reg = { 00,i_opcode[2], i_opcode[1],i_opcode[0],1010000001};
            12'b0?01????????: //BRANCH -> DataMask0, DataMask1, EQorNE->i_op[0], JmpSrc, Branch
                control_reg = {1,i_opcode[0] ,000000000000010};
            12'b0?001???????: //J->JmpOrBranch, DataMask0-1, JretDst->i_op[0], JmpSrc, i_op[0]->RegWrite
                control_reg = {110,i_opcode[0],00000000000001};
            12'b0?000?0?1???: // JR/JALR-> JMPOrBrch, DataMask0-1, RegWrite->i_func[0]
                control_reg = {1,15'b0,i_func[0]};
            default: // DataMask1-0, ShftSrc->~(i_func[5] | i_func[2]). RegWrite, OP0
                control_reg = {000000010,~(i_func[5] | i_func[2]),00000001};
        endcase
    end

    assign o_control = control_reg;
endmodule
