## Clock signal
set_property IOSTANDARD LVCMOS33 [get_ports i_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clkWiz/inst/clk_in1_clk_wiz_0]
###############################################################ar###########

set_property IOSTANDARD LVCMOS33 [get_ports o_uart_tx]

set_property IOSTANDARD LVCMOS33 [get_ports i_rst]

set_property IOSTANDARD LVCMOS33 [get_ports i_stall]

