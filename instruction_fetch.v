module instruction_fetch #(
    parameter SIZE = 32,
    parameter MAX_INSTRUCTION = 64 // Asegúrate de que este parámetro esté correctamente definido
)
(
    input wire i_clk,
    input wire i_rst,
    input wire i_stall,
    input wire [SIZE-1:0] i_instruction_jump, //bit control jump
    input wire i_mux_selec, // selector del mux
    input wire i_inst_write_enable, // habilitación de escritura
    input wire [ADDR_WIDTH-1:0] i_write_addr, // dirección de escritura
    input wire [SIZE-1:0] i_write_data, // datos de escritura
    output wire [SIZE-1:0] o_instruction, // salida:instruccion
    output wire [SIZE-1:0] o_pc,
    output wire [SIZE-1:0] o_adder,
    output wire o_writing_instruction_mem // Señal de control para indicar escritura en memoria de instrucciones
);
    localparam ADDR_WIDTH = $clog2(MAX_INSTRUCTION);

    wire [SIZE-1:0] adder_output;
    reg [SIZE-1:0] pc;
    wire [(SIZE * 2)-1:0] input_mux;
    wire [SIZE-1:0] pc_next;

    reg [SIZE-1:0] instruction_mem [MAX_INSTRUCTION-1:0];  // Declarar como "reg"

    initial begin
        instruction_mem[0] = 32'b00111100000000010000000000000011; // R1 = 3
        instruction_mem[1] = 32'b00111100000000100000000000000001; // R2 = 1
        instruction_mem[2] = 32'b00111100000000110000000000001001; // R3 = 9
        instruction_mem[3] = 32'b00111100000001000000000000000111; // R4 = 7
        instruction_mem[4] = 32'b00111100000001010000000000000011; // R5 = 3
        instruction_mem[5] = 32'b00111100000001100000000001100101; // R6 = 101
        instruction_mem[6] = 32'b00111100000001110000000000011001; // R7 = 25 
        instruction_mem[7] = 32'b00000000001000100001100000100011; // R3 = R1 - R2 -> 2
        instruction_mem[8] = 32'b00000000011001000010100000100001; // R5 = R3 + R4 -> 9
        instruction_mem[9] = 32'b00000000011001100011100000100001; // R7 = R3 + R6 -> 103
        instruction_mem[10] = 32'b00000000011001000010100000100001; // R15 = R3 + R5
        instruction_mem[11] = 32'b0; // R1 = 3
        instruction_mem[12] = 32'b00111100000000010000000000000011; // R1 = 3
        instruction_mem[13] = 32'b00111100000000010000000000000011; // R1 = 3
        instruction_mem[14] = 32'b00111100000000010000000000000011; // R1 = 3
    end

    adder #(
        .SIZE(SIZE)
    ) adder (
        .i_a(pc),
        .i_b(1),
        .o_result(adder_output)
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(32)
    ) mux (
        .i_en(i_mux_selec),
        .i_data(input_mux),
        .o_data(pc_next)
    );

    always @(posedge i_clk) begin
        if (i_rst) 
            pc <= 32'b0;
        else if (!i_stall && !i_inst_write_enable) begin
            if (pc_next < MAX_INSTRUCTION - 1) begin
                pc <= pc_next;
            end else begin
                pc <= 0;
            end
        end
    end

    always @(negedge i_clk) begin
        if (i_inst_write_enable) begin
            instruction_mem[i_write_addr] <= i_write_data;
        end
    end

    assign input_mux = {i_instruction_jump, adder_output};
    assign o_pc = pc;
    assign o_instruction = instruction_mem[pc];
    assign o_adder = adder_output;
    assign o_writing_instruction_mem = i_inst_write_enable;

endmodule