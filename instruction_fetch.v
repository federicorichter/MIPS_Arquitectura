module instruction_fetch #(
    parameter SIZE = 32,
    parameter MAX_INSTRUCTION = 9
)
(
    input wire clk,
    input wire rst,
    input wire i_stall,
    input wire [SIZE-1:0]i_instruction_jump, //bit control jump
    input wire i_mux_selec, // selector del mux
    output wire [SIZE-1:0]o_instruction, // salida:instruccion
    output wire [SIZE-1:0] o_pc,
    output wire [SIZE-1:0] o_adder
);
    localparam ADDRESS_SIZE = $clog2(MAX_INSTRUCTION) ;

    wire [SIZE-1:0]adder_output;
    reg [SIZE-1:0]pc;
    wire [(SIZE * 2)-1:0]input_mux;
    wire [SIZE - 1:0] pc_next; 

    reg [SIZE-1:0] instruction_mem [MAX_INSTRUCTION-1:0];  // Declarar como "reg"

    initial begin
        instruction_mem[0] = 32'b00111100000000010000000000000001; // LUI R1, 1
        instruction_mem[1] = 32'b00111100000000110000000000000011; // LUI R3, 2
        instruction_mem[2] = 32'b00111100000010110000000000000001; // NOP 
        instruction_mem[3] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[4] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[5] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[6] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[7] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[8] = 32'b00000000001000110011100000100001; // ADDU R7, R1, R3
    end

    adder#(
        .SIZE(SIZE)
    ) adder (
        .i_a(pc),
        .i_b(1),
        .o_result(adder_output)
    );

    mux #(
        .BITS_ENABLES(1),
        .BUS_SIZE(32)
    ) mux(
        .i_en(i_mux_selec),
        .i_data(input_mux),
        .o_data(pc_next)

    );

    always @(posedge clk) begin
        if(rst) 
            pc <= 32'b0;
        else
        if(!i_stall) begin
            if(pc_next < MAX_INSTRUCTION -1) begin
                pc <= pc_next;
            end
            else begin
                pc <= 0;
            end
        end
    end

    //memory -> queadder_output IP core?
    //input: pc, clock?
    //output: instruction

   /* blk_mem_gen_0 instruction_memory (
            .clka(clk),
            .addra(pc[15:2]),  // Assuming word-aligned addresses, address 2 LSBs are ignored
            .douta(o_instruction)
        );
*/  

    assign input_mux = {i_instruction_jump, adder_output};
    assign o_pc = pc;
    assign o_instruction = instruction_mem[pc];
    assign o_adder = adder_output;

endmodule