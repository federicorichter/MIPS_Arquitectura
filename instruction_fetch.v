module instruction_fetch #(
    parameter SIZE = 32,
    parameter MAX_INSTRUCTION = 64,
    parameter ADDR_WIDTH = $clog2(MAX_INSTRUCTION)
)(
    input wire i_clk,
    input wire i_clk_write,  // Nuevo reloj para escritura
    input wire i_rst,
    input wire i_stall,
    input [SIZE-1:0] i_pc,
    input wire i_mux_selec,
    input wire i_inst_write_enable,
    input wire [ADDR_WIDTH-1:0] i_write_addr,
    input wire [SIZE-1:0] i_write_data,
    output wire [SIZE-1:0] o_instruction,
    output wire [SIZE-1:0] o_pc,
    output wire o_writing_instruction_mem
);

    // Internal registers and signals
    reg [SIZE-1:0] pc;
    reg [SIZE-1:0] instruction_mem [MAX_INSTRUCTION-1:0];
    reg prev_write_enable; // Register to track previous write enable state
    integer i;

    // Main sequential logic
    always @(posedge i_clk_write or posedge i_rst) begin
        if (i_rst) begin
            // Reset all memory locations and control signals
            for (i = 0; i < MAX_INSTRUCTION; i = i + 1) begin
                instruction_mem[i] <= 32'b0;
            end
            pc <= 0;
            prev_write_enable <= 0;
        end
        else begin
            // Update previous write enable state
            prev_write_enable <= i_inst_write_enable;
            
            if (i_inst_write_enable) begin
                // During write mode
                pc <= 0;
                instruction_mem[i_write_addr] <= i_write_data;
            end
            else if (prev_write_enable && !i_inst_write_enable) begin
                // Transition from write to read mode
                pc <= 0; // Force PC to 0 during transition
            end
        end
    end

    always @(posedge i_clk) begin
        if (!i_stall && !i_inst_write_enable) begin
            // Normal read mode operation
            if (pc < MAX_INSTRUCTION - 1) begin
                pc <= i_pc;
            end 
        end
    end

    // Output assignments
    assign o_pc = pc;
    assign o_instruction = (i_inst_write_enable || i_rst) ? 32'b0 : instruction_mem[pc];
    assign o_writing_instruction_mem = i_inst_write_enable;

endmodule