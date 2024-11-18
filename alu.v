module ALU #(
    parameter DATA_WIDTH = 8,  // Cantidad de bits parametrizable, por defecto 8
    parameter MODE_WIDTH = 6  // Cantidad de bits de modo parametrizable, por defecto 6
)(
    input wire unsigned [DATA_WIDTH-1:0] i_A,
    input wire unsigned [DATA_WIDTH-1:0] i_B,
    input wire [MODE_WIDTH-1:0] i_mode,
    output reg [DATA_WIDTH-1:0] o_result,
    output wire o_zero
);

    always @(*) begin
        case (i_mode)
            6'b100000: o_result = $signed(i_A) + $signed(i_B);  // Suma
            6'b100001: o_result = i_A + i_B;  // Suma (Unsigned)
            6'b100010: o_result = $signed(i_A) - $signed(i_B);  // Resta
            6'b100011: o_result = i_A - i_B;  // Resta (Unsigned)
            6'b100100: o_result = i_A & i_B;  // AND
            6'b100101: o_result = i_A | i_B;  // OR
            6'b100110: o_result = i_A ^ i_B;  // XOR
            6'b000011: o_result = $signed(i_A) >>> $signed(i_B);  // SRA (Desplazamiento aritmético a la derecha)
            6'b000010: o_result = i_A >> i_B;   // SRL (Desplazamiento lógico a la derecha)
            6'b000000: o_result = i_A << i_B;   // SLL (Desplazamiento lógico a la izquierda)
            6'b100111: o_result = ~(i_A | i_B); // NOR
            6'b101000: o_result = $signed(i_A) < $signed(i_B) ? 1 : 0;  // SLT (Set on less than)
            6'b101001: o_result = i_A < i_B ? 1 : 0;  // SLTU (Set on less than unsigned)
            
            default: o_result = 6'b111111;  // Resultado por defecto
        endcase
    end

    assign o_zero = (o_result == 0);
    

endmodule
