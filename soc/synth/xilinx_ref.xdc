
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk_i];
set_property -dict {PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports rst_in];
set_property -dict {PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports gpi_i];
set_property -dict {PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports gpo_o];

create_clock -add -name sys_clk_pin -period 100.00 -waveform {0 50} [get_ports clk_i];