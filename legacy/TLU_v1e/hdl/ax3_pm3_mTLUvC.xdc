# -------------------------------------------------------------------------------------------------
# -- Project             : Mars AX3 
# -- File description    : User Constraint File for Mars PM3 Base Board
# -- File name           : mars_ax3_pm3.xdc
# -- Authors             : Kanishk Sugand / Marc Oberholzer
# -------------------------------------------------------------------------------------------------
# -- Copyright © 2012 by Enclustra GmbH, Switzerland. All rights are reserved. 
# -- Unauthorized duplication of this document, in whole or in part, by any means is prohibited
# -- without the prior written permission of Enclustra GmbH, Switzerland.
# -- 
# -- Although Enclustra GmbH believes that the information included in this publication is correct
# -- as of the date of publication, Enclustra GmbH reserves the right to make changes at any time
# -- without notice.
# -- 
# -- All information in this document may only be published by Enclustra GmbH, Switzerland.
# -------------------------------------------------------------------------------------------------
# -- Notes:
# -- 1. For best I/O timing, it is necessary to set the following options in Xilinx ISE/PlanAhead: 
# --    map option "Pack I/O registers into IOBs" to "Inputs and Outputs"
# -- 2. The IO standards for banks 0, 2 and 3 are only valid if VCCO_0/VCCO_2/VCCO_3 = 3.3 V
# -------------------------------------------------------------------------------------------------
# -- File history:
# --
# -- Version | Date       | Author             | Remarks
# -- ----------------------------------------------------------------------------------------------
# -- 1.0     | 11.4.14    | C. Glattfelder     | converted from UCF
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# mars ax3: global clock inputs
# -------------------------------------------------------------------------------------------------

set_property PACKAGE_PIN P17 [get_ports {Clk_50}]
set_property IOSTANDARD LVCMOS33 [get_ports {Clk_50}]
set_property PACKAGE_PIN L16 [get_ports {Fpga_Emcclk}]
set_property IOSTANDARD LVCMOS33 [get_ports {Fpga_Emcclk}]

# -------------------------------------------------------------------------------------------------
# mars ax3: ddr3 sdram
# -------------------------------------------------------------------------------------------------

set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Ba[0]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Ba[1]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[9]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[8]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {Ddr3_Dqs_P[1]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Ba[2]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[7]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[6]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[5]}]
set_property IOSTANDARD SSTL15 [get_ports Ddr3_Cas_N]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {Ddr3_Dqs_P[0]}]
set_property IOSTANDARD SSTL15 [get_ports Ddr3_Odt]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[4]}]
set_property IOSTANDARD SSTL15 [get_ports Ddr3_Cke]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[3]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[2]}]
set_property IOSTANDARD SSTL15 [get_ports Ddr3_We_N]
set_property IOSTANDARD DIFF_SSTL15 [get_ports Ddr3_Clk_N]
set_property IOSTANDARD SSTL15 [get_ports Ddr3_Ras_N]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[13]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[12]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports Ddr3_Clk_P]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {Ddr3_Dqs_N[0]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[11]}]
set_property IOSTANDARD SSTL15 [get_ports Ddr3_Reset_N]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dm[0]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[10]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[1]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_A[0]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dm[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {Ddr3_Dqs_N[1]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[0]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[9]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[1]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[8]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[10]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[7]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[11]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[6]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[12]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[5]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[13]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[4]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[14]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[3]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[15]}]
set_property IOSTANDARD SSTL15 [get_ports {Ddr3_Dq[2]}]
set_property PACKAGE_PIN A15 [get_ports {Ddr3_Dq[2]}]
set_property PACKAGE_PIN E15 [get_ports {Ddr3_Dq[3]}]
set_property PACKAGE_PIN B11 [get_ports {Ddr3_Dq[15]}]
set_property PACKAGE_PIN B18 [get_ports {Ddr3_Dq[4]}]
set_property PACKAGE_PIN F14 [get_ports {Ddr3_Dq[14]}]
set_property PACKAGE_PIN B17 [get_ports {Ddr3_Dq[5]}]
set_property PACKAGE_PIN A11 [get_ports {Ddr3_Dq[13]}]
set_property PACKAGE_PIN A16 [get_ports {Ddr3_Dq[6]}]
set_property PACKAGE_PIN F13 [get_ports {Ddr3_Dq[12]}]
set_property PACKAGE_PIN B16 [get_ports {Ddr3_Dq[7]}]
set_property PACKAGE_PIN D14 [get_ports {Ddr3_Dq[11]}]
set_property PACKAGE_PIN B14 [get_ports {Ddr3_Dq[8]}]
set_property PACKAGE_PIN B13 [get_ports {Ddr3_Dq[10]}]
set_property PACKAGE_PIN C14 [get_ports {Ddr3_Dq[9]}]
set_property PACKAGE_PIN E16 [get_ports {Ddr3_Dq[1]}]
set_property PACKAGE_PIN A14 [get_ports {Ddr3_Dqs_N[0]}]
set_property PACKAGE_PIN A18 [get_ports {Ddr3_Dq[0]}]
set_property PACKAGE_PIN D12 [get_ports {Ddr3_Dm[1]}]
set_property PACKAGE_PIN D15 [get_ports {Ddr3_Dm[0]}]
set_property PACKAGE_PIN A13 [get_ports {Ddr3_Dqs_P[0]}]
set_property PACKAGE_PIN C16 [get_ports Ddr3_Clk_P]
set_property PACKAGE_PIN C17 [get_ports Ddr3_Clk_N]
set_property PACKAGE_PIN G14 [get_ports Ddr3_Cke]
set_property PACKAGE_PIN B12 [get_ports {Ddr3_Dqs_N[1]}]
set_property PACKAGE_PIN F16 [get_ports Ddr3_Cas_N]
set_property PACKAGE_PIN K15 [get_ports {Ddr3_Ba[2]}]
set_property PACKAGE_PIN H14 [get_ports {Ddr3_Ba[1]}]
set_property PACKAGE_PIN C12 [get_ports {Ddr3_Dqs_P[1]}]
set_property PACKAGE_PIN D17 [get_ports {Ddr3_Ba[0]}]
set_property PACKAGE_PIN F18 [get_ports {Ddr3_A[9]}]
set_property PACKAGE_PIN H17 [get_ports {Ddr3_A[8]}]
set_property PACKAGE_PIN K16 [get_ports Ddr3_Odt]
set_property PACKAGE_PIN E18 [get_ports {Ddr3_A[7]}]
set_property PACKAGE_PIN K13 [get_ports {Ddr3_A[6]}]
set_property PACKAGE_PIN E17 [get_ports {Ddr3_A[5]}]
set_property PACKAGE_PIN F15 [get_ports Ddr3_Ras_N]
set_property PACKAGE_PIN J13 [get_ports {Ddr3_A[4]}]
set_property PACKAGE_PIN D18 [get_ports {Ddr3_A[3]}]
set_property PACKAGE_PIN J18 [get_ports {Ddr3_A[2]}]
set_property PACKAGE_PIN G13 [get_ports Ddr3_Reset_N]
set_property PACKAGE_PIN G17 [get_ports {Ddr3_A[13]}]
set_property PACKAGE_PIN H16 [get_ports {Ddr3_A[12]}]
set_property PACKAGE_PIN G18 [get_ports {Ddr3_A[11]}]
set_property PACKAGE_PIN J15 [get_ports Ddr3_We_N]
set_property PACKAGE_PIN G16 [get_ports {Ddr3_A[10]}]
set_property PACKAGE_PIN J14 [get_ports {Ddr3_A[1]}]
set_property PACKAGE_PIN J17 [get_ports {Ddr3_A[0]}]

# -------------------------------------------------------------------------------------------------
# mars ax3: ethernet
# -------------------------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Txd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Rxc]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Rst_N]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Rxd[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Txd[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Rxd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Mdio]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Rxd[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Mdc]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Rxd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Txc]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Txd[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports Eth_Link_N]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Tx_Ctl]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Int_N]
set_property IOSTANDARD LVCMOS33 [get_ports Eth_Rx_Ctl]
set_property IOSTANDARD LVCMOS33 [get_ports {Eth_Txd[3]}]
set_property PACKAGE_PIN T16 [get_ports Eth_Tx_Ctl]
set_property PACKAGE_PIN R18 [get_ports {Eth_Txd[0]}]
set_property PACKAGE_PIN V16 [get_ports {Eth_Rxd[3]}]
set_property PACKAGE_PIN V15 [get_ports {Eth_Rxd[2]}]
set_property PACKAGE_PIN V17 [get_ports {Eth_Rxd[1]}]
set_property PACKAGE_PIN T18 [get_ports {Eth_Txd[1]}]
set_property PACKAGE_PIN U16 [get_ports {Eth_Rxd[0]}]
set_property PACKAGE_PIN T14 [get_ports Eth_Rxc]
set_property PACKAGE_PIN R16 [get_ports Eth_Rx_Ctl]
set_property PACKAGE_PIN U17 [get_ports {Eth_Txd[2]}]
set_property PACKAGE_PIN M13 [get_ports Eth_Rst_N]
set_property PACKAGE_PIN N14 [get_ports Eth_Mdio]
set_property PACKAGE_PIN P14 [get_ports Eth_Mdc]
set_property PACKAGE_PIN U18 [get_ports {Eth_Txd[3]}]
set_property PACKAGE_PIN C15 [get_ports Eth_Link_N]
set_property PACKAGE_PIN N16 [get_ports Eth_Txc]
set_property PACKAGE_PIN T15 [get_ports Eth_Int_N]

# -------------------------------------------------------------------------------------------------
# mars ax3: i2c
# -------------------------------------------------------------------------------------------------

set_property PACKAGE_PIN R17 [get_ports I2c_Int_N]
set_property IOSTANDARD LVCMOS33 [get_ports I2c_Int_N]
set_property PACKAGE_PIN N17 [get_ports I2c_Scl]
set_property IOSTANDARD LVCMOS33 [get_ports I2c_Scl]
set_property PACKAGE_PIN P18 [get_ports I2c_Sda]
set_property IOSTANDARD LVCMOS33 [get_ports I2c_Sda]

# -------------------------------------------------------------------------------------------------
# mars ax3: spi flash
# -------------------------------------------------------------------------------------------------

set_property PACKAGE_PIN L13 [get_ports Flash_Cs_N]
set_property IOSTANDARD LVCMOS33 [get_ports Flash_Cs_N]
set_property PACKAGE_PIN K17 [get_ports Flash_Di]
set_property IOSTANDARD LVCMOS33 [get_ports Flash_Di]
set_property PACKAGE_PIN M14 [get_ports Flash_Hold_N]
set_property IOSTANDARD LVCMOS33 [get_ports Flash_Hold_N]
set_property PACKAGE_PIN L14 [get_ports Flash_Wp_N]
set_property IOSTANDARD LVCMOS33 [get_ports Flash_Wp_N]
set_property PACKAGE_PIN R10 [get_ports Flash_Clk]
set_property IOSTANDARD LVCMOS33 [get_ports Flash_Clk]
set_property PACKAGE_PIN K18 [get_ports Flash_Do]
set_property IOSTANDARD LVCMOS33 [get_ports Flash_Do]

# -------------------------------------------------------------------------------------------------
# mars ax3: led		
# -------------------------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports {Led_N[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Led_N[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Led_N[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Led_N[3]}]
set_property PACKAGE_PIN M17 [get_ports {Led_N[1]}]
set_property PACKAGE_PIN M16 [get_ports {Led_N[0]}]
set_property PACKAGE_PIN M18 [get_ports {Led_N[3]}]
set_property PACKAGE_PIN L18 [get_ports {Led_N[2]}]

# -------------------------------------------------------------------------------------------------
# mars ax3: system		
# -------------------------------------------------------------------------------------------------

set_property PACKAGE_PIN R11 [get_ports Pwr_Good]
set_property IOSTANDARD LVCMOS33 [get_ports Pwr_Good]
set_property PACKAGE_PIN N15 [get_ports {Reset_N}]
set_property IOSTANDARD LVCMOS33 [get_ports {Reset_N}]

# -------------------------------------------------------------------------------------------------
# mars pm3: fmc lpc connector
# -------------------------------------------------------------------------------------------------
set_property PACKAGE_PIN T4 [get_ports {CLK_TO_FPGA_N}]
set_property PACKAGE_PIN T5 [get_ports {CLK_TO_FPGA_P}]
set_property PACKAGE_PIN D3 [get_ports {CLK_FROM_FPGA_N}]
set_property PACKAGE_PIN E3 [get_ports {CLK_FROM_FPGA_P}]

set_property PACKAGE_PIN N5 [get_ports {CLK_GEN_LOL_N}]
set_property PACKAGE_PIN C1 [get_ports {CLK_GEN_RST_N}]
set_property PACKAGE_PIN C2 [get_ports {I2C_RESET_N}]
set_property PACKAGE_PIN F6 [get_ports {GPIO}]

set_property PACKAGE_PIN P5 [get_ports {CONT_TO_FPGA[0]}]
set_property PACKAGE_PIN P3 [get_ports {CONT_TO_FPGA[1]}]
set_property PACKAGE_PIN N6 [get_ports {CONT_TO_FPGA[2]}]
set_property PACKAGE_PIN L5 [get_ports {CONT_TO_FPGA[3]}]

# Warning - can't find CONT_FROM_FPGA[0] in Allegro netlist ....
set_property PACKAGE_PIN P4 [get_ports {CONT_FROM_FPGA[1]}]
set_property PACKAGE_PIN M6 [get_ports {CONT_FROM_FPGA[2]}]
set_property PACKAGE_PIN L6 [get_ports {CONT_FROM_FPGA[3]}]

set_property PACKAGE_PIN M1 [get_ports {SPARE_TO_FPGA[0]}]
set_property PACKAGE_PIN N4 [get_ports {SPARE_TO_FPGA[1]}]
set_property PACKAGE_PIN N1 [get_ports {SPARE_TO_FPGA[2]}]
set_property PACKAGE_PIN M2 [get_ports {SPARE_TO_FPGA[3]}]

set_property PACKAGE_PIN L1 [get_ports {SPARE_FROM_FPGA[0]}]
set_property PACKAGE_PIN M4 [get_ports {SPARE_FROM_FPGA[1]}]
set_property PACKAGE_PIN N2 [get_ports {SPARE_FROM_FPGA[2]}]
set_property PACKAGE_PIN M3 [get_ports {SPARE_FROM_FPGA[3]}]

set_property PACKAGE_PIN R5 [get_ports {TRIG_TO_FPGA[0]}]
set_property PACKAGE_PIN R2 [get_ports {TRIG_TO_FPGA[1]}]
set_property PACKAGE_PIN T1 [get_ports {TRIG_TO_FPGA[2]}]
set_property PACKAGE_PIN V1 [get_ports {TRIG_TO_FPGA[3]}]

set_property PACKAGE_PIN R6 [get_ports {TRIG_FROM_FPGA[0]}]
set_property PACKAGE_PIN P2 [get_ports {TRIG_FROM_FPGA[1]}]
set_property PACKAGE_PIN R1 [get_ports {TRIG_FROM_FPGA[2]}]
set_property PACKAGE_PIN U1 [get_ports {TRIG_FROM_FPGA[3]}]

set_property PACKAGE_PIN T6 [get_ports {BUSY_TO_FPGA[0]}]
set_property PACKAGE_PIN U3 [get_ports {BUSY_TO_FPGA[1]}]
set_property PACKAGE_PIN T8 [get_ports {BUSY_TO_FPGA[2]}]
set_property PACKAGE_PIN L4 [get_ports {BUSY_TO_FPGA[3]}]

set_property PACKAGE_PIN R7 [get_ports {BUSY_FROM_FPGA[0]}]
set_property PACKAGE_PIN U4 [get_ports {BUSY_FROM_FPGA[1]}]
set_property PACKAGE_PIN R8 [get_ports {BUSY_FROM_FPGA[2]}]
set_property PACKAGE_PIN K5 [get_ports {BUSY_FROM_FPGA[3]}]

set_property PACKAGE_PIN L3 [get_ports {DUT_CLK_TO_FPGA[0]}]
set_property PACKAGE_PIN F3 [get_ports {DUT_CLK_TO_FPGA[1]}]
set_property PACKAGE_PIN D2 [get_ports {DUT_CLK_TO_FPGA[2]}]
set_property PACKAGE_PIN G3 [get_ports {DUT_CLK_TO_FPGA[3]}]

set_property PACKAGE_PIN K3 [get_ports {DUT_CLK_FROM_FPGA_P[0]}]
set_property PACKAGE_PIN F4 [get_ports {DUT_CLK_FROM_FPGA_P[1]}]
set_property PACKAGE_PIN E2 [get_ports {DUT_CLK_FROM_FPGA_P[2]}]
set_property PACKAGE_PIN G4 [get_ports {DUT_CLK_FROM_FPGA_P[3]}]

set_property PACKAGE_PIN A1 [get_ports {BEAM_TRIGGER_N[0]}]
set_property PACKAGE_PIN B1 [get_ports {BEAM_TRIGGER_P[0]}]
set_property PACKAGE_PIN B4 [get_ports {BEAM_TRIGGER_N[1]}]
set_property PACKAGE_PIN C4 [get_ports {BEAM_TRIGGER_P[1]}]
set_property PACKAGE_PIN K1 [get_ports {BEAM_TRIGGER_N[2]}]
set_property PACKAGE_PIN K2 [get_ports {BEAM_TRIGGER_P[2]}]
set_property PACKAGE_PIN C5 [get_ports {BEAM_TRIGGER_N[3]}]
set_property PACKAGE_PIN C6 [get_ports {BEAM_TRIGGER_P[3]}]
set_property PACKAGE_PIN H4 [get_ports {BEAM_TRIGGER_N[4]}]
set_property PACKAGE_PIN J4 [get_ports {BEAM_TRIGGER_P[4]}]
set_property PACKAGE_PIN G1 [get_ports {BEAM_TRIGGER_N[5]}]
set_property PACKAGE_PIN H1 [get_ports {BEAM_TRIGGER_P[5]}]

# -------------------------------------------------------------------------------------------------
# mars pm3: ft232 uart interface
# -------------------------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports FTDI_RXD]
set_property IOSTANDARD LVCMOS33 [get_ports FTDI_TXD]
set_property PACKAGE_PIN B3 [get_ports FTDI_TXD]
set_property PACKAGE_PIN B2 [get_ports FTDI_RXD]

# -------------------------------------------------------------------------------------------------
# mars pm3: ez-usb fx3 interface
# -------------------------------------------------------------------------------------------------

set_property PACKAGE_PIN V2 [get_ports FX3_A1]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_A1]
set_property PACKAGE_PIN V7 [get_ports FX3_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_CLK]
set_property PACKAGE_PIN U12 [get_ports FX3_DQ0]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ0]
set_property PACKAGE_PIN R15 [get_ports FX3_DQ1]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ1]
set_property PACKAGE_PIN U9 [get_ports FX3_DQ10]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ10]
set_property PACKAGE_PIN V5 [get_ports FX3_DQ11]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ11]
set_property PACKAGE_PIN T3 [get_ports FX3_DQ12]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ12]
set_property PACKAGE_PIN R3 [get_ports FX3_DQ13]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ13]
set_property PACKAGE_PIN V4 [get_ports FX3_DQ14]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ14]
set_property PACKAGE_PIN U7 [get_ports FX3_DQ15]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ15]
set_property PACKAGE_PIN V12 [get_ports FX3_DQ2]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ2]
set_property PACKAGE_PIN P15 [get_ports FX3_DQ3]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ3]
set_property PACKAGE_PIN U11 [get_ports FX3_DQ4]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ4]
set_property PACKAGE_PIN U13 [get_ports FX3_DQ5]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ5]
set_property PACKAGE_PIN T13 [get_ports FX3_DQ6]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ6]
set_property PACKAGE_PIN T11 [get_ports FX3_DQ7]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ7]
set_property PACKAGE_PIN V9 [get_ports FX3_DQ8]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ8]
set_property PACKAGE_PIN U6 [get_ports FX3_DQ9]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_DQ9]
set_property PACKAGE_PIN V6 [get_ports FX3_FLAGA]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_FLAGA]
set_property PACKAGE_PIN U2 [get_ports FX3_FLAGB]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_FLAGB]
set_property PACKAGE_PIN T10 [get_ports FX3_PKTEND_N]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_PKTEND_N]
set_property PACKAGE_PIN T9 [get_ports FX3_SLOE_N]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_SLOE_N]
set_property PACKAGE_PIN R12 [get_ports FX3_SLRD_N]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_SLRD_N]
set_property PACKAGE_PIN R13 [get_ports FX3_SLWR_N]
set_property IOSTANDARD LVCMOS33 [get_ports FX3_SLWR_N]

# -------------------------------------------------------------------------------------------------
# timing constraints
# -------------------------------------------------------------------------------------------------


create_clock -name {Clk_50} -period 20.000 [get_ports {Clk_50}]


# -------------------------------------------------------------------------------------------------
# eof
# -------------------------------------------------------------------------------------------------



