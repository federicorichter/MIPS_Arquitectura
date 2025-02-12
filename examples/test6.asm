# test6.asm - Prueba de jump register y subroutines
addi $0, $0, 0    # NOP
addi $1, $0, 6    # ADDI R1, R0, 6
jalr $10, $1      # JALR R10, R1 -> salta a PC = 6 y guarda en R10 PC = 4
addi $0, $0, 0    # NOP
addi $4, $0, 7    # ADDI R4, R0, 7
addi $5, $0, 7    # ADDI R5, R0, 7 -> salta aca (?
addi $6, $0, 7    # ADDI R6, R0, 7
addi $7, $0, 10   # ADDI R7, R0, 10
addi $2, $0, 5    # ADDI R2, R0, 5
addi $3, $0, 7    # ADDI R3, R0, 7
jr $10            # JR R10