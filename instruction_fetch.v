module instruction_fetch #(
    parameter SIZE = 32,
    parameter MAX_INSTRUCTION = 64, // Asegúrate de que este parámetro esté correctamente definido
    parameter ADDR_WIDTH = $clog2(MAX_INSTRUCTION)
)
(
    input wire i_clk,
    input wire i_rst,
    input wire i_stall,
    input [SIZE-1:0] i_pc,
    input wire i_mux_selec, // selector del mux
    input wire i_inst_write_enable, // habilitación de escritura
    input wire [ADDR_WIDTH-1:0] i_write_addr, // dirección de escritura
    input wire [SIZE-1:0] i_write_data, // datos de escritura
    output wire [SIZE-1:0] o_instruction, // salida:instruccion
    output wire [SIZE-1:0] o_pc,
    output wire o_writing_instruction_mem // Señal de control para indicar escritura en memoria de instrucciones

); 

    //wire [SIZE-1:0] adder_output;
    reg [SIZE-1:0] pc;
    //wire [(SIZE * 2)-1:0] input_mux;
    //wire [SIZE-1:0] pc_next;
    integer i;
    reg [SIZE-1:0] instruction_mem [MAX_INSTRUCTION-1:0];  // Declarar como "reg"
    reg [SIZE-1:0] o_instruction_reg;
    /*mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(32)
    ) mux (
        .i_en(i_mux_selec),
        .i_data(input_mux),
        .o_data(pc_next)
    );*/

    /*always @(negedge i_clk) begin
        if (i_rst) 
            pc <= 32'b0;
        else if (!i_stall && !i_inst_write_enable) begin
            if (pc < MAX_INSTRUCTION - 1) begin
                pc <= i_pc;
            end else begin
                pc <= 0;
                o_instruction_reg <= instruction_mem[pc];
            end
        end
        else if (i_inst_write_enable) begin
            pc <= 0;
        end
        else begin
            pc <= pc;
        end
    end
*/
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (i = 0; i < MAX_INSTRUCTION; i = i + 1) begin
                instruction_mem[i] <= 32'b0;
            end
            pc <= 0;
        end
        else if (i_inst_write_enable) begin
            pc <= 0;
            instruction_mem[i_write_addr] <= i_write_data;
        end
        else if (!i_stall && !i_inst_write_enable) begin
            if (pc < MAX_INSTRUCTION - 1) begin
                pc <= i_pc;
            end else begin
                pc <= 0;
                //o_instruction_reg <= instruction_mem[pc];
            end
        end
    end

    //assign input_mux = {32'b0, adder_output};
    assign o_pc = pc;
    //assign o_instruction = o_instruction_reg;
    assign o_instruction = (i_inst_write_enable || i_rst) ? 32'b0 : instruction_mem[pc];
   //assign o_adder = adder_output;
    assign o_writing_instruction_mem = i_inst_write_enable;

endmodule