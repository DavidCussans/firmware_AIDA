## Trigger inputs

#set_property IOSTANDARD LVCMOS18 [get_ports {threshold_discr_p_i[*]}]
#set_property PACKAGE_PIN J4 [get_ports {threshold_discr_p_i[4]}]
#set_property PACKAGE_PIN H1 [get_ports {threshold_discr_p_i[5]}]

set_property IOSTANDARD LVDS_25 [get_ports {threshold_discr_n_i[*]}]
set_property PACKAGE_PIN A1 [get_ports {threshold_discr_n_i[0]}]
set_property PACKAGE_PIN B1 [get_ports {threshold_discr_p_i[0]}]
set_property PACKAGE_PIN B4 [get_ports {threshold_discr_n_i[1]}]
set_property PACKAGE_PIN C4 [get_ports {threshold_discr_p_i[1]}]
set_property PACKAGE_PIN K1 [get_ports {threshold_discr_n_i[2]}]
set_property PACKAGE_PIN K2 [get_ports {threshold_discr_p_i[2]}]
set_property PACKAGE_PIN C5 [get_ports {threshold_discr_n_i[3]}]
set_property PACKAGE_PIN C6 [get_ports {threshold_discr_p_i[3]}]
set_property PACKAGE_PIN H4 [get_ports {threshold_discr_n_i[4]}]
set_property PACKAGE_PIN J4 [get_ports {threshold_discr_p_i[4]}]
set_property PACKAGE_PIN G1 [get_ports {threshold_discr_n_i[5]}]
set_property PACKAGE_PIN H1 [get_ports {threshold_discr_p_i[5]}]

## Miscellaneous I/O
set_property IOSTANDARD LVCMOS25 [get_ports clk_gen_rst]
set_property PACKAGE_PIN C1 [get_ports clk_gen_rst]
set_property IOSTANDARD LVCMOS25 [get_ports gpio]
set_property PACKAGE_PIN F6 [get_ports gpio]


## Crystal clock
set_property IOSTANDARD LVDS_25 [get_ports sysclk_40_i_p]
set_property PACKAGE_PIN T4 [get_ports sysclk_40_i_n]
set_property PACKAGE_PIN T5 [get_ports sysclk_40_i_p]

## Output clock (currently not working so set to 0)
set_property IOSTANDARD LVCMOS25 [get_ports sysclk_50_o_p]
set_property PACKAGE_PIN E3 [get_ports sysclk_50_o_p]
set_property IOSTANDARD LVCMOS25 [get_ports sysclk_50_o_n]
set_property PACKAGE_PIN D3 [get_ports sysclk_50_o_n]

## Inputs/Outputs for DUTs
set_property IOSTANDARD LVCMOS25 [get_ports {busy_o[*]}]
set_property PACKAGE_PIN R7 [get_ports {busy_o[0]}]
set_property PACKAGE_PIN U4 [get_ports {busy_o[1]}]
set_property PACKAGE_PIN R8 [get_ports {busy_o[2]}]
set_property PACKAGE_PIN K5 [get_ports {busy_o[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {triggers_o[*]}]
set_property PACKAGE_PIN R6 [get_ports {triggers_o[0]}]
set_property PACKAGE_PIN P2 [get_ports {triggers_o[1]}]
set_property PACKAGE_PIN R1 [get_ports {triggers_o[2]}]
set_property PACKAGE_PIN U1 [get_ports {triggers_o[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {cont_o[*]}]
set_property PACKAGE_PIN N5 [get_ports {cont_o[0]}]
set_property PACKAGE_PIN P4 [get_ports {cont_o[1]}]
set_property PACKAGE_PIN M6 [get_ports {cont_o[2]}]
set_property PACKAGE_PIN L6 [get_ports {cont_o[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {spare_o[*]}]
set_property PACKAGE_PIN L1 [get_ports {spare_o[0]}]
set_property PACKAGE_PIN M4 [get_ports {spare_o[1]}]
set_property PACKAGE_PIN N2 [get_ports {spare_o[2]}]
set_property PACKAGE_PIN M3 [get_ports {spare_o[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {dut_clk_o[*]}]
set_property PACKAGE_PIN K3 [get_ports {dut_clk_o[0]}]
set_property PACKAGE_PIN F4 [get_ports {dut_clk_o[1]}]
set_property PACKAGE_PIN E2 [get_ports {dut_clk_o[2]}]
set_property PACKAGE_PIN G4 [get_ports {dut_clk_o[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {cont_i[*]}]
set_property PACKAGE_PIN P5 [get_ports {cont_i[0]}]
set_property PACKAGE_PIN P3 [get_ports {cont_i[1]}]
set_property PACKAGE_PIN N6 [get_ports {cont_i[2]}]
set_property PACKAGE_PIN L5 [get_ports {cont_i[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {spare_i[*]}]
set_property PACKAGE_PIN M1 [get_ports {spare_i[0]}]
set_property PACKAGE_PIN N4 [get_ports {spare_i[1]}]
set_property PACKAGE_PIN N1 [get_ports {spare_i[2]}]
set_property PACKAGE_PIN M2 [get_ports {spare_i[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {triggers_i[*]}]
set_property PACKAGE_PIN R5 [get_ports {triggers_i[0]}]
set_property PACKAGE_PIN R2 [get_ports {triggers_i[1]}]
set_property PACKAGE_PIN T1 [get_ports {triggers_i[2]}]
set_property PACKAGE_PIN V1 [get_ports {triggers_i[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {busy_i[*]}]
set_property PACKAGE_PIN T6 [get_ports {busy_i[0]}]
set_property PACKAGE_PIN U3 [get_ports {busy_i[1]}]
set_property PACKAGE_PIN T8 [get_ports {busy_i[2]}]
set_property PACKAGE_PIN L4 [get_ports {busy_i[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {dut_clk_i[*]}]
set_property PACKAGE_PIN L3 [get_ports {dut_clk_i[0]}]
set_property PACKAGE_PIN F3 [get_ports {dut_clk_i[1]}]
set_property PACKAGE_PIN D2 [get_ports {dut_clk_i[2]}]
set_property PACKAGE_PIN G3 [get_ports {dut_clk_i[3]}]

# -------------------------------------------------------------------------------------------------


create_clock -period 25.000 -name sysclk_40_i_p -waveform {0.000 12.500} [get_ports sysclk_40_i_p]

#Define clock groups and make them asynchronous with each other
#set_clock_groups -asynchronous -group {sysclk I I_1 mmcm_n_10 mmcm_n_6 mmcm_n_8 clk_ipb_i} -group {sysclk_40_i_p pll_base_inst_n_2 s_clk160}
# What has gone wrong ....
# FIXME
#set_clock_groups -asynchronous -group {sysclk clk_ipb_i} -group {sysclk_40_i_p pll_base_inst_n_2 s_clk160}
#set_clock_groups -asynchronous -group {sysclk clk_ipb_i} -group {sysclk_40_i_p s_clk160}
#set_clock_groups -asynchronous -group { [get_nets sysclk] } -group { [get_nets *sysclk_40_i*]}

set_input_delay -clock [get_clocks [get_clocks -of_objects [get_pins I4/pll_base_inst/CLKOUT0]]] -rise -min 0.300 [get_ports -regexp -filter { NAME =~  ".*thresh.*" && DIRECTION == "IN" }]
set_input_delay -clock [get_clocks [get_clocks -of_objects [get_pins I4/pll_base_inst/CLKOUT0]]] -rise -max 0.400 [get_ports -regexp -filter { NAME =~  ".*thresh.*" && DIRECTION == "IN" }]


set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# -false_path 

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {sysclk clk_ipb_i}] -group [get_clocks -include_generated_clocks {s_clk160 sysclk_40_i_p}]

