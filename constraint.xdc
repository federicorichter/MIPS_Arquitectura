## Clock signal
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports i_clk]

###############################################################ar###########

set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports i_uart_rx]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports o_uart_tx]

set_property PACKAGE_PIN U18 [get_ports i_rst]
set_property IOSTANDARD LVCMOS33 [get_ports i_rst]

set_property PACKAGE_PIN T17 [get_ports i_stall]
set_property IOSTANDARD LVCMOS33 [get_ports i_stall]

## Asignar state_out[7:0] a los LEDs LD0-LD7
set_property PACKAGE_PIN U16 [get_ports {state_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[0]}]

set_property PACKAGE_PIN E19 [get_ports {state_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[1]}]

set_property PACKAGE_PIN U19 [get_ports {state_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[2]}]

set_property PACKAGE_PIN V19 [get_ports {state_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[3]}]

set_property PACKAGE_PIN W18 [get_ports {state_out[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[4]}]

set_property PACKAGE_PIN U15 [get_ports {state_out[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[5]}]

## Asignar byte_counter_out[4:0] a los LEDs LD6-LD10
set_property PACKAGE_PIN U14 [get_ports {byte_counter_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[0]}]

set_property PACKAGE_PIN V14 [get_ports {byte_counter_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[1]}]

set_property PACKAGE_PIN V13 [get_ports {byte_counter_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {byte_counter_out[2]}]

set_property PACKAGE_PIN W3 [get_ports uart_rx_done_reg_out]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_done_reg_out]

## Asignar instruction_counter_out[4:0] a los LEDs LD11-LD15
set_property PACKAGE_PIN U3 [get_ports {instruction_counter_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[0]}]

set_property PACKAGE_PIN P3 [get_ports {instruction_counter_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[1]}]

set_property PACKAGE_PIN N3 [get_ports {instruction_counter_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[2]}]

set_property PACKAGE_PIN P1 [get_ports {instruction_counter_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[3]}]

set_property PACKAGE_PIN L1 [get_ports {instruction_counter_out[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {instruction_counter_out[4]}]


set_property MARK_DEBUG true [get_nets {uut/dbg/byte_counter[0]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/byte_counter[1]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/byte_counter[2]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[0]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[1]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[2]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[3]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[4]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[5]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[6]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_count[7]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[24]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[5]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[0]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[18]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[1]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[19]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[20]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[22]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[23]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[21]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[2]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[3]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[4]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[6]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[7]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[8]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[9]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[31]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[30]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[17]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[28]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[29]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[26]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[27]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[25]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[10]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[11]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[12]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[13]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[14]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[15]}]
set_property MARK_DEBUG true [get_nets {uut/dbg/instruction_counter_reg_n_1_[16]}]


