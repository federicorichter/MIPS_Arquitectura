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
    input wire i_clk
    //output wire rx_done_tick, // Añadir señal de tick de recepción
    //output wire tx_done_tick  // Añadir señal de tick de transmisión
);  
  
    clk_wiz_0 clkWiz (
        .clk_out1(o_clk),
        .reset(i_reset),
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
        .i_rst(i_rst),
        .i_stall(1'b0),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .i_clk(o_clk)
        //.rx_done_tick(uart_rx_done),
        //.tx_done_tick(uart_tx_start)
    );

endmodule
 