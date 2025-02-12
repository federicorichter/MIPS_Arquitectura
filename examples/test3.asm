# test3.asm - Prueba de load/store halfword
lui $1, 55 # LUI R1, 3
lui $3, 3   # LUI R3, 3
addi $0, $0, 0 # NOP
addi $0, $0, 0 # NOP
sh $1, 1($0)   # SH R1 -> MEM[0 + 1] 
addi $0, $0, 0 # NOP
addi $0, $0, 0 # NOP
lh $5, 1($0)   # LH R5 <- MEM[0 + 1]
addu $7, $5, $3 # R7 = R5 + R3 = 3 + 150 = 153
addi $0, $0, 0 # NOP
addi $0, $0, 0 # NOP
addi $0, $0, 0 # NOP