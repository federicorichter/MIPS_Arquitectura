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
    output wire [DATA_WIDTH-1:0] read_data,
    input wire [ADDR_WIDTH-1:0] debug_addr, // Dirección de depuración
    output wire [DATA_WIDTH-1:0] debug_data  // Datos de depuración
);

    reg [7:0] mem [0:MEM_SIZE-1]; // Memoria en bytes
    reg [DATA_WIDTH-1:0] read_data_reg;
    reg [DATA_WIDTH-1:0] debug_data_reg;
    integer i;

    always @(negedge clk) begin
        if (rst) begin
            // Inicializa toda la memoria a cero
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                mem[i] <= 8'b0;
            end
            read_data_reg <= 32'b0;
        end else if (re) begin
            // Leer 32 bits (4 bytes) desde la memoria
            read_data_reg <= {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]};
        end
    end

    always @(posedge clk) begin
        if (we && !rst) begin
            // Escribir 32 bits (4 bytes) en la memoria
            mem[addr] <= write_data[31:24];
            mem[addr+1] <= write_data[23:16];
            mem[addr+2] <= write_data[15:8];
            mem[addr+3] <= write_data[7:0];
        end
    end

    always @(posedge clk) begin
        // Leer 32 bits (4 bytes) desde la memoria para depuración
        debug_data_reg <= {mem[debug_addr], mem[debug_addr+1], mem[debug_addr+2], mem[debug_addr+3]};
    end

    assign read_data = read_data_reg;
    assign debug_data = debug_data_reg;

endmodule