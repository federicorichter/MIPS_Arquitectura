# test8.asm - Prueba de jump and link
addi $0, $0, 0    # NOP
jal 5             # JAL 5
addi $0, $0, 0    # NOP
addi $4, $0, 40   # ADDI R4, R0, 40
addi $5, $0, 40   # ADDI R5, R0, 40
addi $6, $0, 40   # ADDI R6, R0, 40
addi $1, $0, 10   # ADDI R1, R0, 10
addi $2, $0, 5    # ADDI R2, R0, 5
addi $3, $0, 7    # ADDI R3, R0, 7
jr $31            # JR R31