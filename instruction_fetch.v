module instruction_fetch #(
    SIZE = 32
)
(
    input wire clk,
    input wire rst,
    input wire [SIZE-1:0]i_instruction_jump, //bit control jump
    input wire i_mux_selec, // selector del mux
    output wire [SIZE-1:0]o_instruction // salida:instruccion
);

    wire [SIZE-1:0]adder_output;
    reg [SIZE-1:0]pc;
    wire [(SIZE * 2)-1:0]input_mux;
    wire [SIZE - 1:0] pc_next; 

    adder#(
        .SIZE(SIZE)
    ) adder (
        .i_a(pc),
        .i_b(4),
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
            pc <= pc_next;
    end

    //memory -> que IP core?
    //input: pc, clock?
    //output: instruction

   /* blk_mem_gen_0 instruction_memory (
            .clka(clk),
            .addra(pc[15:2]),  // Assuming word-aligned addresses, address 2 LSBs are ignored
            .douta(o_instruction)
        );
*/

    assign input_mux = {i_instruction_jump, adder_output};

endmodule