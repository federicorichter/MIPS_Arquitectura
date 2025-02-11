# test5.asm - Prueba de branch not equal
addi $10, $0, 15  # ADDI R10, R0, 15
addi $20, $0, 15  # ADDI R20, R0, 15
bne $10, $20, 3   # BNE R10, R20, 3
addi $0, $0, 0    # NOP
addi $4, $0, 40   # ADDI R4, R0, 40
addi $5, $0, 50   # ADDI R5, R0, 50
addi $6, $0, 50   # ADDI R6, R0, 50
addi $1, $0, 10   # ADDI R1, R0, 10
addi $2, $0, 20   # ADDI R2, R0, 20
addi $3, $0, 30   # ADDI R3, R0, 30