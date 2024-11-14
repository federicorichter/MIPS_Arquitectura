module register_bank #(
    parameter SIZE = 32,
    parameter NUM_REGISTERS = 32,
    parameter SIZE_REG_DIR = $clog2(NUM_REGISTERS)
)(
    input wire clk,
    input wire rst,
    input wire i_write_enable,

    input wire [SIZE_REG_DIR-1:0]i_dir_regA, //dir register A
    input wire [SIZE_REG_DIR-1:0]i_dir_regB, //dir register B

    input wire [SIZE_REG_DIR-1:0]i_w_dir, //dir write register
    input wire [SIZE-1:0]i_w_data,        //data to write in register


    output wire [SIZE-1:0]o_reg_A,
    output wire [SIZE-1:0]o_reg_B
);

    reg [SIZE-1:0] registers[NUM_REGISTERS-1:0];

    integer i;
    reg [SIZE-1:0]reg_A, reg_B;

    always@(posedge clk)begin
        if(rst)begin
            for (i = 0 ; i < NUM_REGISTERS ; i = i + 1)begin
                if(i==1)begin
                    registers[i] <= 1;    
                end 
                else begin
                    registers[i] <= 3;
                end
            end
        end
        else if(i_write_enable && i_w_dir != 0)begin
            registers[i_w_dir] <= i_w_data;
        end
    end

    always @(negedge clk)begin
        reg_A <= registers[i_dir_regA];
        reg_B <= registers[i_dir_regB];
    end

    assign o_reg_A = reg_A;
    assign o_reg_B = reg_B;

endmodule