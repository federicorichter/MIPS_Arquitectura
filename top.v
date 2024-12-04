module top#(
    parameter SIZE = 32,
    parameter SIZE_OP = 6,
    parameter CONTROL_SIZE = 18,
    parameter SIZE_REG_DIR = 5,
    parameter IF_ID_SIZE = 64,
    parameter ID_EX_SIZE = 129,
    parameter EX_MEM_SIZE = 78,
    parameter MEM_WB_SIZE = 72,
    parameter MAX_INSTRUCTION = 64, // Define MAX_INSTRUCTION
    parameter NUM_REGISTERS = 32,
    parameter MEM_SIZE = 64, // Define MEM_SIZE
    parameter ADDR_WIDTH = $clog2(MEM_SIZE)
)(
    input wire i_rst,
    input wire i_stall,
    input wire i_uart_rx,
    output wire o_uart_tx,
    input wire i_clk,
    output wire reg_state_o, 
    output wire bit_load_program_o, 
    output wire reg_start_ex_o,
    output wire [7:0] uart_rx_o
);  
    wire o_locked;
    wire uart_tx_full, uart_rx_empty;
    wire [7:0] uart_rx_data, uart_tx_data;
    wire uart_wr_uart, uart_rd_uart;
  
    clk_wiz_0 clkWiz (
        .clk_out1(o_clk),
        .reset(i_rst),
        .locked(o_locked),
        .clk_in1(i_clk)        
    ); 
   
    mips #(
        .SIZE(SIZE),
        .SIZE_OP(SIZE_OP),
        .CONTROL_SIZE(CONTROL_SIZE),
        //.IF_ID_SIZE(IF_ID_SIZE),
        //.ID_EX_SIZE(ID_EX_SIZE),
        //.EX_MEM_SIZE(EX_MEM_SIZE),
        //.MEM_WB_SIZE(MEM_WB_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MAX_INSTRUCTION(MAX_INSTRUCTION),
        .NUM_REGISTERS(NUM_REGISTERS),
        .MEM_SIZE(MEM_SIZE)
    ) uut (
        .i_rst(i_rst || ~o_locked),
        .i_stall(1'b0),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .i_clk(o_clk),
        .reg_state_o(reg_state_o), 
        .bit_load_program_o(bit_load_program_o), 
        .reg_start_ex_o(reg_start_ex_o),
        .uart_rx_o(uart_rx_o)
    );

endmodule