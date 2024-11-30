module instruction_fetch #(
    parameter SIZE = 32,
    parameter MAX_INSTRUCTION = 11
)
(
    input wire clk,
    input wire rst,
    input wire i_stall,
    input wire [SIZE-1:0]i_instruction_jump, //bit control jump
    input [SIZE-1:0] i_pc,
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
        /*instruction_mem[0] = 32'b00111100000000010000000000000001; // LUI R1, 1
        instruction_mem[1] = 32'b00111100000000110000000000000011; // LUI R3, 3
        instruction_mem[2] = 32'b00111100000010110000000000000001; // NOP 
        instruction_mem[3] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[4] = 32'b10100100001000010000000000000001; // SH, R1 -> MEM[1]
        instruction_mem[5] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[6] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[7] = 32'b10000100001001010000000000000001; // LH, R5 <- MEM[1]
        instruction_mem[8] = 32'b00000000101000110011100000100001; // R7 = R5 + R3 
        instruction_mem[9] = 32'b00111100000010110000000000000011; // NOP
        instruction_mem[10] = 32'b00111100000010110000000000000001; // NOP
        instruction_mem[11] = 32'b00111100000010110000000000000001; // NOP*/

        /*instruction_mem[0] = 32'b00111100000000010000000000000011; // R1 = 3
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
        instruction_mem[14] = 32'b00111100000000010000000000000011; // R1 = 3*/

       /* instruction_mem[0] = 32'b00111100000000010000000000000011; // LUI R1, 3
        instruction_mem[1] = 32'b00111100000000110000000000000011; // LUI R3, 3
        instruction_mem[2] = 32'b00111100000001000000000000001001; // R4 = 9
        instruction_mem[3] = 32'b00010000001000110000000000000001; // BNE R1, R3, 1
        instruction_mem[4] = 32'b00111100000001110000000000011011; // R7 = 27
        instruction_mem[5] = 32'b00111100000001110000000000011001; // R7 = 25
        instruction_mem[6] = 32'b00111100000001110000000000011001; // R7 = 25
        instruction_mem[7] = 32'b00111100000001110000000000011001; // R7 = 25
        instruction_mem[8] = 32'b00111100000001110000000000011001; // R7 = 25
        instruction_mem[9] = 32'b00111100000001110000000000010001; // R7 = 17*/
        
        /*instruction_mem[0] = 32'b00001000000000000000000000000001; // JAL 1 -> 4 => Parece q anda
        instruction_mem[1] = 32'b00111100000000010000000000001000; // LUI R1, 8
        instruction_mem[2] = 32'b00111100000000010000000000000111; // LUI R1, 7 
        instruction_mem[3] = 32'b00111100000000010000000000000011; // LUI R1, 3
        instruction_mem[4] = 32'b00111100000000010000000000001101; // LUI R1, 13
        instruction_mem[5] = 32'b00111100000000010000000000001101; // LUI R1, 13 
        instruction_mem[6] = 32'b00111100000000010000000000001001; // LUI R1, 9 
        instruction_mem[7] = 32'b00111100000000010000000000000101; // LUI R1, 5
        instruction_mem[8] = 32'b00111100000000010000000000000101; // LUI R1, 5
        instruction_mem[9] = 32'b00111100000000010000000000000110; // LUI R1, 6*/

        /*instruction_mem[0] = 32'b00111100000000010000000000000111; // LUI R1, 7 => parece q anda
        instruction_mem[1] = 32'b00111100000000010000000000000110; // LUI R2, 5
        instruction_mem[2] = 32'b00111100000000010000000000000110; // LUI R2, 5
        instruction_mem[3] = 32'b00111100000000010000000000000110; // LUI R1, 6 
        instruction_mem[4] = 32'b00000000001000000000000000001000; // JR, R1
        instruction_mem[5] = 32'b00111100000000110000000000000011; // LUI R3, 3
        instruction_mem[6] = 32'b00111100000000110000000000001111; // LUI R3, 15
        instruction_mem[7] = 32'b00111100000000110000000000001101; // LUI R3, 13 -> Salta aca
        instruction_mem[8] = 32'b00111100000000110000000000000101; // LUI R3, 5 
        instruction_mem[9] = 32'b00111100000000110000000000000100; // LUI R3, 4
        instruction_mem[10] = 32'b00111100000000110000000000000110; // LUI R3, 6*/

        instruction_mem[0] = 32'b00111100000000010000000000000111; // LUI R1, 7 
        instruction_mem[1] = 32'b00111100000000100000000000000110; // LUI R2, 6
        instruction_mem[2] = 32'b00111100000000100000000000000110; // LUI R2, 6
        instruction_mem[3] = 32'b00111100000000100000000000000111; // LUI R2, 7
        instruction_mem[4] = 32'b00000000001000000100100000001001; // JALR, R9,R1
        instruction_mem[5] = 32'b00111100000000100000000000000110; // LUI R2, 6 
        instruction_mem[6] = 32'b00111100000000110000000000000011; // LUI R3, 3
        instruction_mem[7] = 32'b00111100000000110000000000001111; // LUI R3, 15 -> Salta aca
        instruction_mem[8] = 32'b00111100000000110000000000001101; // LUI R3, 13 
        instruction_mem[9] = 32'b00111100000000110000000000000101; // LUI R3, 5 
        instruction_mem[10] = 32'b00111100000000100000000000000110; // LUI R2, 6 
        //instruction_mem[9] = 32'b00111100000000110000000000000100; // LUI R3, 4
        //instruction_mem[10] = 32'b00111100000000110000000000000110; // LUI R3, 6

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
            if(pc_next < MAX_INSTRUCTION ) begin
                pc <= i_pc;
            end
            else begin
                pc <= 0;
            end
        end
        else begin
            pc <= pc;
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