## Clock signal
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports i_clk]

###############################################################ar###########

set_property -dict { PACKAGE_PIN B18    IOSTANDARD LVCMOS33 } [get_ports { i_uart_rx }]; 
set_property -dict { PACKAGE_PIN A18    IOSTANDARD LVCMOS33 } [get_ports { o_uart_tx }];

set_property PACKAGE_PIN U18 [get_ports {i_rst}] ; # Load B
set_property IOSTANDARD LVCMOS33 [get_ports {i_rst}]

set_property PACKAGE_PIN T17 [get_ports {i_stall}] ; # Load op
set_property IOSTANDARD LVCMOS33 [get_ports {i_stall}]

## Asignar state_out[7:0] a los LEDs LD0-LD7
set_property PACKAGE_PIN U16 [get_ports {state_out[0]}] ; # LD0
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[0]}]

set_property PACKAGE_PIN E19 [get_ports {state_out[1]}] ; # LD1
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[1]}]

set_property PACKAGE_PIN U19 [get_ports {state_out[2]}] ; # LD2
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[2]}]

set_property PACKAGE_PIN V19 [get_ports {state_out[3]}] ; # LD3
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[3]}]

set_property PACKAGE_PIN W18 [get_ports {state_out[4]}] ; # LD4
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[4]}]

set_property PACKAGE_PIN U15 [get_ports {state_out[5]}] ; # LD5
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[5]}]

## Asignar byte_counter_out[4:0] a los LEDs LD6-LD10
set_property PACKAGE_PIN U14 [get_ports {byte_counter_out[0]}] ; # LD6
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[0]}]

set_property PACKAGE_PIN V14 [get_ports {byte_counter_out[1]}] ; # LD7
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[1]}]

set_property PACKAGE_PIN V13 [get_ports {byte_counter_out[2]}] ; # LD8
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[2]}]

set_property PACKAGE_PIN V3 [get_ports {byte_counter_out[3]}] ; # LD9
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[3]}]

set_property PACKAGE_PIN W3 [get_ports {byte_counter_out[4]}] ; # LD10
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[4]}]

## Asignar instruction_counter_out[4:0] a los LEDs LD11-LD15
set_property PACKAGE_PIN U3 [get_ports {instruction_counter_out[0]}] ; # LD11
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[0]}]

set_property PACKAGE_PIN P3 [get_ports {instruction_counter_out[1]}] ; # LD12
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[1]}]

set_property PACKAGE_PIN N3 [get_ports {instruction_counter_out[2]}] ; # LD13
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[2]}]

set_property PACKAGE_PIN P1 [get_ports {instruction_counter_out[3]}] ; # LD14
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[3]}]

set_property PACKAGE_PIN L1 [get_ports {instruction_counter_out[4]}] ; # LD15
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[4]}]

