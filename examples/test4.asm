# test4.asm - Prueba de operaciones load/store byte y lógicas
addi $1, $0, 15  # ADDI R1, R0, 15
sb $1, 0($0)     # SB R1, 0(0)
addi $2, $1, 7   # ADDI R2, R1, 7  
sb $2, 8($0)     # SB R2, 8(0)
lb $3, 8($0)     # LB R3, 8(0)
andi $4, $3, 11  # ANDI R4, R3, 11
addi $1, $4, 272 # ADDI R4, R4, 272