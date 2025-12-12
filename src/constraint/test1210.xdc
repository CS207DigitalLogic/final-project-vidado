# -------------------------- 系统时钟与复位约束 --------------------------
# 系统时钟：100MHz，引脚P17
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} [get_ports clk]

# 系统复位：低电平有效，引脚P15
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports rst_n]

set_property -dict {PACKAGE_PIN P5 IOSTANDARD LVCMOS33} [get_ports {sw_row[2]}]
set_property -dict {PACKAGE_PIN P4 IOSTANDARD LVCMOS33} [get_ports {sw_row[1]}]
set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {sw_row[0]}]
set_property -dict {PACKAGE_PIN P2 IOSTANDARD LVCMOS33} [get_ports {sw_col[2]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {sw_col[1]}]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports {sw_col[0]}]
set_property PACKAGE_PIN R17 [get_ports btn_trigger]
set_property IOSTANDARD LVCMOS33 [get_ports btn_trigger]

set_property PACKAGE_PIN K3 [get_ports {dbg_matrix_data_0[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[7]}]

set_property PACKAGE_PIN M1 [get_ports {dbg_matrix_data_0[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[6]}]

set_property PACKAGE_PIN L1 [get_ports {dbg_matrix_data_0[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[5]}]

set_property PACKAGE_PIN K6 [get_ports {dbg_matrix_data_0[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[4]}]

set_property PACKAGE_PIN J5 [get_ports {dbg_matrix_data_0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[3]}]

set_property PACKAGE_PIN H5 [get_ports {dbg_matrix_data_0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[2]}]

set_property PACKAGE_PIN H6 [get_ports {dbg_matrix_data_0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[1]}]

set_property PACKAGE_PIN K1 [get_ports {dbg_matrix_data_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_data_0[0]}]

set_property PACKAGE_PIN K2 [get_ports {dbg_matrix_row[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_row[2]}]

set_property PACKAGE_PIN J2 [get_ports {dbg_matrix_row[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_row[1]}]

set_property PACKAGE_PIN J3 [get_ports {dbg_matrix_row[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_row[0]}]

set_property PACKAGE_PIN H4 [get_ports { dbg_matrix_col[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_col[2]}]

set_property PACKAGE_PIN J4 [get_ports {dbg_matrix_col[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_col[1]}]

set_property PACKAGE_PIN G3 [get_ports {dbg_matrix_col[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_matrix_col[0]}]

set_property PACKAGE_PIN G4 [get_ports {num[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num[0]}]

set_property PACKAGE_PIN F6 [get_ports {num[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PACKAGE_PIN T4 [get_ports uart_tx]
set_property PACKAGE_PIN N5 [get_ports uart_rx]
