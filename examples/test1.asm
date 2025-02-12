# test1.asm - Prueba de operaciones aritméticas básicas
lui $1, 0x0003      # R1 <- 3
lui $2, 0x0001      # R2 <- 1
lui $3, 0x0009      # R3 <- 9
lui $4, 0x0007      # R4 <- 7
lui $5, 0x0003      # R5 <- 3
lui $6, 0x0065      # R6 <- 101
lui $7, 0x0019      # R7 <- 25 
subu $3, $1, $2     # R3 <- R1 - R2 = 3 - 1 = 2
addu $5, $3, $4     # R5 <- R3 + R4 = 2 + 7 = 9
addu $7, $3, $6     # R7 <- R3 + R6 = 2 + 101 = 102
addu $5, $3, $4     # R5 <- R3 + R4 = 2 + 7 = 8
lui $15, 0x012c     # R15 <- 300
lui $1, 0x0003
lui $1, 0x0003
lui $1, 0x0003