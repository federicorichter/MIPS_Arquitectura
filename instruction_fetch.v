module instruction_fetch #(
    parameter SIZE = 32,
    parameter MAX_INSTRUCTION = 64,
    parameter ADDR_WIDTH = $clog2(MAX_INSTRUCTION)
)(
    input wire i_clk,
    input wire i_rst,
    input wire i_rst_debug,
    input wire i_stall,
    input [SIZE-1:0] i_pc,
    input wire i_inst_write_enable,
    input wire i_clk_write,  // Reloj para escritura
    input wire [ADDR_WIDTH-1:0] i_write_addr,
    input wire [SIZE-1:0] i_write_data,
    output reg [SIZE-1:0] o_instruction,
    output reg [SIZE-1:0] o_pc,
    output wire o_writing_instruction_mem,
    output reg [(SIZE*MAX_INSTRUCTION)-1:0] o_debug_instruction
);

    // Memoria de instrucciones
    reg [SIZE-1:0] instruction_mem [MAX_INSTRUCTION-1:0];
    integer i;

    // Escritura en memoria de instrucciones
    always @(posedge i_clk_write or posedge i_rst) begin
        if (i_rst) begin
            for (i = 0; i < MAX_INSTRUCTION; i = i + 1) begin
                instruction_mem[i] <= 32'b0;
            end
            o_debug_instruction <= {(SIZE*MAX_INSTRUCTION){1'b0}};
        end else if (i_inst_write_enable && !i_rst) begin
            instruction_mem[i_write_addr] <= i_write_data;
            o_debug_instruction[i_write_addr*SIZE +: SIZE] <= i_write_data;
        end
    end

    // Lectura de memoria de instrucciones y actualización de PC
    always @(negedge i_clk or posedge i_rst_debug) begin
        if (i_rst_debug) begin
            o_pc <= 32'b0;
            o_instruction <= 32'b0;
        end else if (!i_stall && !i_inst_write_enable) begin
            o_pc <= i_pc;
            o_instruction <= instruction_mem[i_pc];
        end
    end

    // Señal de escritura en memoria de instrucciones
    assign o_writing_instruction_mem = i_inst_write_enable;

endmodule