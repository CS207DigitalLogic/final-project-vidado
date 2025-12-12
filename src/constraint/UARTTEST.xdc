
create_clock -period 10.000 [get_ports clk] -name sys_clk
set_property PACKAGE_PIN P17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports rst_n]

set_property PACKAGE_PIN T4 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN U4 [get_ports traverse_trig]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_trig]

set_property PACKAGE_PIN P5 [get_ports traverse_row[0]]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_row[0]] 

set_property PACKAGE_PIN P4 [get_ports traverse_row[1]]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_row[1]] 

set_property PACKAGE_PIN P3 [get_ports traverse_row[2]]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_row[2]] 

set_property PACKAGE_PIN P2 [get_ports traverse_col[0]]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_col[0]] 

set_property PACKAGE_PIN R2 [get_ports traverse_col[1]]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_col[1]] 

set_property PACKAGE_PIN M4 [get_ports traverse_col[2]]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_col[2]] 


set_property PACKAGE_PIN F6 [get_ports traverse_busy]  
set_property IOSTANDARD LVCMOS33 [get_ports traverse_busy]  

set_property PACKAGE_PIN K3 [get_ports traverse_done]  
set_property IOSTANDARD LVCMOS33 [get_ports traverse_done]  

set_property PACKAGE_PIN R17 [get_ports all_traverse_trig]
set_property IOSTANDARD LVCMOS33 [get_ports all_traverse_trig]

set_property PACKAGE_PIN G4 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN G3 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN J4 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN H4 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN J3 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN J2 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN K2 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN K1 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

set_property PACKAGE_PIN H6 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]

set_property PACKAGE_PIN H5 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]

set_property PACKAGE_PIN J5 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]

set_property PACKAGE_PIN K6 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]

set_property PACKAGE_PIN L1 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]

set_property PACKAGE_PIN M1 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]

