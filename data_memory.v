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
    input wire mask_1, // Señal de enmascaramiento 1
    input wire mask_2, // Señal de enmascaramiento 2
    output wire [DATA_WIDTH-1:0] read_data,
    input wire [ADDR_WIDTH-1:0] debug_addr, // Dirección de depuración
    output wire [DATA_WIDTH-1:0] debug_data  // Datos de depuración
);
    // ES LITTLE ENDIAN
    
    reg [7:0] mem [0:MEM_SIZE-1]; // Memoria en bytes
    reg [DATA_WIDTH-1:0] read_data_reg;
    reg [DATA_WIDTH-1:0] debug_data_reg;
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Inicializa toda la memoria a cero
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                mem[i] <= 8'b0;
            end
            read_data_reg <= 32'b0;
        end else if (re) begin
            // Leer 32 bits (4 bytes) desde la memoria con enmascaramiento
            case ({mask_1, mask_2})
                2'b00: read_data_reg <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}; // No enmascarar
                2'b01: read_data_reg <= {8'b0,mem[addr+2],mem[addr+1], mem[addr]}; // Enmascarar los primeros 3 bytes
                2'b10: read_data_reg <= {16'b0,mem[addr+1], mem[addr]}; // Enmascarar los primeros 2 bytes
                2'b11: read_data_reg <= {24'b0, mem[addr]}; // Enmascarar el primer byte
            endcase
        end
    end

    always @(negedge clk) begin
        if (we && !rst) begin
            // Escribir 32 bits (4 bytes) en la memoria con enmascaramiento
            case ({mask_1, mask_2})
                2'b00: begin
                    mem[addr] <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                    mem[addr+3] <= write_data[31:24];
                end
                2'b01: begin
                    mem[addr] <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                end
                2'b10: begin
                    mem[addr] <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                end
                2'b11: begin
                    mem[addr] <= write_data[7:0];
                end
            endcase
        end
    end

    always @(posedge clk) begin
        // Leer 32 bits (4 bytes) desde la memoria para depuración
        debug_data_reg <= {mem[debug_addr+3], mem[debug_addr+2], mem[debug_addr+1], mem[debug_addr]};
    end

    assign read_data = read_data_reg;
    assign debug_data = debug_data_reg;

endmodule