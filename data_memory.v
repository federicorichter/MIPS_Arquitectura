module data_memory #(
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE = 64, // Tamaño de la memoria en bytes
    parameter ADDR_WIDTH = $clog2(MEM_SIZE)
)(
    input wire clk,
    input wire rst, // Señal de reset
    input wire i_clk_mem_read,
    input wire i_mem_write,  // Señal de habilitación de escritura
    input wire i_mem_read,  // Señal de habilitación de lectura
    input wire i_zero_alu,
    input wire i_branch,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,
    input wire i_mask_1, // Señal de enmascaramiento 1
    input wire i_mask_2, // Señal de enmascaramiento 2
    output wire [DATA_WIDTH-1:0] read_data,
    input wire [ADDR_WIDTH-1:0] debug_addr, // Dirección de depuración
    output wire [DATA_WIDTH-1:0] debug_data,  // Datos de depuración
    output wire o_pc_source
);
    // ES LITTLE ENDIAN
    
    reg [7:0] mem [MEM_SIZE-1:0]; // Memoria en bytes
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
        end else if (i_mem_read) begin
            // Leer 32 bits (4 bytes) desde la memoria con enmascaramiento
            case ({i_mask_1, i_mask_2})
                2'b00: read_data_reg <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}; // No enmascarar
                2'b01: read_data_reg <= {8'b0,mem[addr+2],mem[addr+1], mem[addr]}; // Enmascarar los primeros 3 bytes
                2'b10: read_data_reg <= {16'b0,mem[addr+1], mem[addr]}; // Enmascarar los primeros 2 bytes
                2'b11: read_data_reg <= {24'b0, mem[addr]}; // Enmascarar el primer byte
            endcase
        end
    end

    always @(posedge clk) begin
        if (i_mem_write && !rst) begin
            // Escribir 32 bits (4 bytes) en la memoria con enmascaramiento
            case ({i_mask_1, i_mask_2})
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

    always @(negedge i_clk_mem_read) begin
        // Leer 32 bits (4 bytes) desde la memoria para depuración
        debug_data_reg <= {mem[debug_addr+3], mem[debug_addr+2], mem[debug_addr+1], mem[debug_addr]};
    end

    assign read_data = i_mem_read ? read_data_reg : addr;
    assign debug_data = debug_data_reg;
    assign o_pc_source = (i_zero_alu & i_branch);

endmodule