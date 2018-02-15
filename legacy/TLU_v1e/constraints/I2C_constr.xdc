set_property IOSTANDARD LVCMOS33 [get_ports i2c_reset]
set_property PACKAGE_PIN C2 [get_ports i2c_reset]

set_property IOSTANDARD LVCMOS33 [get_ports i2c_scl_b]
set_property PACKAGE_PIN N17 [get_ports i2c_scl_b]

set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_b]
set_property PACKAGE_PIN P18 [get_ports i2c_sda_b]



create_clock -period 25.000 -name sysclk_40_i_p -waveform {0.000 12.500} [get_ports sysclk_40_i_p]


#Define clock groups and make them asynchronous with each other
set_clock_groups -asynchronous -group {clk_enclustra I I_1 mmcm_n_10 mmcm_n_6 mmcm_n_8 clk_ipb_i} -group {sysclk_40_i_p pll_base_inst_n_2 s_clk160}

# -------------------------------------------------------------------------------------------------


#DEBUG PROBES





