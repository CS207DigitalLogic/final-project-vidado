
create_clock -period 10.000 [get_ports clk] -name sys_clk
set_property PACKAGE_PIN P17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports rst_n]

set_property PACKAGE_PIN T4 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN J4 [get_ports traverse_trig]
set_property IOSTANDARD LVCMOS33 [get_ports traverse_trig]
set_property PULLDOWN true [get_ports traverse_trig]  

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

set_property PACKAGE_PIN G4 [get_ports traverse_done]  
set_property IOSTANDARD LVCMOS33 [get_ports traverse_done]  

