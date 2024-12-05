## Clock signal
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports i_clk]
###############################################################ar###########

set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports i_uart_rx]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports o_uart_tx]

set_property PACKAGE_PIN U18 [get_ports i_rst]
set_property IOSTANDARD LVCMOS33 [get_ports i_rst]

set_property PACKAGE_PIN T17 [get_ports i_stall]
set_property IOSTANDARD LVCMOS33 [get_ports i_stall]
