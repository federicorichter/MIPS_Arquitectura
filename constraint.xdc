## Clock signal
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { i_clk }]

## Override the dedicated clock route for clk_in1 (if needed)
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clkWiz/inst/clk_in1_clk_wiz_0]

## UART signals
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports { i_uart_rx }]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports { o_uart_tx }]

## Reset signal
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { i_rst }]

## Stall signal
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports { i_stall }]


## Asignar uart_rx_o[7:0] a los LEDs LD0-LD7
set_property PACKAGE_PIN U16 [get_ports {uart_rx_o[0]}] ; # LD0
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[0]}]

set_property PACKAGE_PIN E19 [get_ports {uart_rx_o[1]}] ; # LD1
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[1]}]

set_property PACKAGE_PIN U19 [get_ports {uart_rx_o[2]}] ; # LD2
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[2]}]

set_property PACKAGE_PIN V19 [get_ports {uart_rx_o[3]}] ; # LD3
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[3]}]

set_property PACKAGE_PIN W18 [get_ports {uart_rx_o[4]}] ; # LD4
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[4]}]

set_property PACKAGE_PIN U15 [get_ports {uart_rx_o[5]}] ; # LD5
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[5]}]

set_property PACKAGE_PIN U14 [get_ports {uart_rx_o[6]}] ; # LD6
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[6]}]

set_property PACKAGE_PIN V14 [get_ports {uart_rx_o[7]}] ; # LD7
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx_o[7]}]


set_property PACKAGE_PIN L1 [get_ports {reg_state_o}] ; # LD7
set_property IOSTANDARD LVCMOS33 [get_ports {reg_state_o}]

set_property PACKAGE_PIN P1 [get_ports {bit_load_program_o}] ; # LD7
set_property IOSTANDARD LVCMOS33 [get_ports {bit_load_program_o}]

set_property PACKAGE_PIN N3 [get_ports {reg_start_ex_o}] ; # LD7
set_property IOSTANDARD LVCMOS33 [get_ports {reg_start_ex_o}]
