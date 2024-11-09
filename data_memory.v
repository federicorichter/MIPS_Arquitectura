module data_memory #(
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE = 4096, // Tamaño de la memoria en bytes
    parameter ADDR_WIDTH = $clog2(MEM_SIZE)
)(
    input wire clk,
    input wire rst, // Señal de reset
    input wire we,  // Señal de habilitación de escritura
    input wire re,  // Señal de habilitación de lectura
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,
    output reg [DATA_WIDTH-1:0] read_data
);

    reg [7:0] mem [0:MEM_SIZE-1]; // Memoria en bytes
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Inicializa toda la memoria a cero
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                mem[i] <= 8'b0;
            end
            read_data <= 32'b0;
        end else if (re) begin
            // Leer 32 bits (4 bytes) desde la memoria
            read_data <= {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]};
        end
    end

    always @(negedge clk) begin
        if (we && !rst) begin
            // Escribir 32 bits (4 bytes) en la memoria
            mem[addr] <= write_data[31:24];
            mem[addr+1] <= write_data[23:16];
            mem[addr+2] <= write_data[15:8];
            mem[addr+3] <= write_data[7:0];
        end
    end

endmodule