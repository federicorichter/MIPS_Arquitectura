# test2.asm - Prueba de saltos y control de flujo JALR
lui $1, 8      # LUI R1, 8
lui $3, 6      # LUI R3, 6
lui $3, 6      # LUI R3, 6
lui $3, 6      # LUI R3, 6
jalr $9, $1    # JALR R9, R1 -> guarda en R3 el PC + 1 (6) y salta a pc = 8
lui $3, 3      # LUI R3, 3 
lui $3, 15     # LUI R3, 15
lui $3, 13     # LUI R3, 13 -> salta aca => R3 = 13
lui $5, 5      # LUI R3, 5
lui $6, 4      # LUI R3, 4
lui $7, 6      # LUI R3, 6