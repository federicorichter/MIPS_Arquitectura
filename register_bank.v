module register_bank #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS)
)(
    input wire clk,
    input wire rst,
    input wire i_write_enable,
    input wire i_stall,

    input wire [SIZE_REG_DIR-1:0]i_dir_regA, //dir register A
    input wire [SIZE_REG_DIR-1:0]i_dir_regB, //dir register B

    input wire [SIZE_REG_DIR-1:0]i_w_dir, //dir write register
    input wire [SIZE-1:0]i_w_data,        //data to write in register

    output wire [SIZE-1:0]o_reg_A,
    output wire [SIZE-1:0]o_reg_B,
    output wire [SIZE*NUM_REGISTERS-1:0] o_registers_debug // Salida de depuración
);

    reg [SIZE-1:0] registers[NUM_REGISTERS-1:0];
    reg [SIZE*NUM_REGISTERS-1:0] registers_debug;

    integer i;
    reg [SIZE-1:0] reg_A, reg_B;

    always@(posedge clk or posedge rst)begin
        if(rst)begin
            for (i = 0 ; i < NUM_REGISTERS ; i = i + 1)begin
                registers[i] <= 0;
            end
        end
        else if(i_write_enable && i_w_dir != 0 &&  ~i_stall)begin
            registers[i_w_dir] <= i_w_data;
        end
    end

    always @(negedge clk)begin
            if( ~i_stall)begin
            reg_A <= registers[i_dir_regA];
            reg_B <= registers[i_dir_regB];
            
            // Actualizar el arreglo de depuración
            for (i = 0; i < NUM_REGISTERS; i = i + 1) begin
                registers_debug[i*SIZE +: SIZE] <= registers[i];
            end
        end
    end

    assign o_reg_A = reg_A;
    assign o_reg_B = reg_B;
    assign o_registers_debug = registers_debug;

endmodule