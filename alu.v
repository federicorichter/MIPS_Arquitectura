module ALU #(
    parameter DATA_WIDTH = 8,  // Cantidad de bits parametrizable, por defecto 8
    parameter MODE_WIDTH = 6  // Cantidad de bits de modo parametrizable, por defecto 6
)(
    input wire signed [DATA_WIDTH-1:0] i_A,
    input wire signed [DATA_WIDTH-1:0] i_B,
    input wire [MODE_WIDTH-1:0] i_mode,
    output reg signed [DATA_WIDTH-1:0] o_result
);

    always @(*) begin
        case (i_mode)
            6'b100000: o_result = i_A + i_B;  // Suma
            6'b100010: o_result = i_A - i_B;  // Resta
            6'b100100: o_result = i_A & i_B;  // AND
            6'b100101: o_result = i_A | i_B;  // OR
            6'b100110: o_result = i_A ^ i_B;  // XOR
            6'b000011: o_result = i_A >>> i_B;  // SRA (Desplazamiento aritmético a la derecha)
            6'b000010: o_result = i_A >> i_B;   // SRL (Desplazamiento lógico a la derecha)
            6'b100111: o_result = ~(i_A | i_B); // NOR
            default: o_result = {DATA_WIDTH{1'b0}};  // Resultado por defecto
        endcase
    end
    

endmodule
