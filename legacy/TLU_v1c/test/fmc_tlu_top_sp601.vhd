--=============================================================================
--! @file fmc_tlu_top_sp601.vhd
--=============================================================================
-- @brief Top-level design for ipbus Maroc test . You must edit this file to set the IP and MAC addresses
--
--! @details Based on ipbus_demo_sp601 by Dave Newbold, 23/2/11
--! This version is for xc6slx16 on Xilinx SP601 eval board
--! Uses the s6 soft TEMAC core with GMII inteface to an external Gb PHY
--! You will need a license for the core
--
--! @author David Cussans, 31/07/12
--

-- Top-level design for trigger logic unit with IPBus readout
--
-- This version is for xc6slx16 on Xilinx SP601 eval board
-- Uses the s6 soft TEMAC core with GMII inteface to an external Gb PHY
-- You will need a license for the core
--
-- You must edit this file to set the IP and MAC addresses
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ipbus.ALL;
use work.ipbus_bus_decl.all;
use work.emac_hostbus_decl.all;

--! Use UNISIM for Xilix primitives
Library UNISIM;
use UNISIM.vcomponents.all;

entity fmc_tlu_top is port(
	sysclk_p, sysclk_n : in STD_LOGIC;
	leds: out STD_LOGIC_VECTOR(3 downto 0);
	gmii_gtx_clk, gmii_tx_en, gmii_tx_er : out STD_LOGIC;
	gmii_txd : out STD_LOGIC_VECTOR(7 downto 0);
	gmii_rx_clk, gmii_rx_dv, gmii_rx_er: in STD_LOGIC;
	gmii_rxd : in STD_LOGIC_VECTOR(7 downto 0);
	phy_rstb : out STD_LOGIC;
	dip_switch: in std_logic_vector(3 downto 0);

       	-- Main I2C signals
	i2c_sda_io: inout std_logic;
	i2c_scl_io: inout std_logic;

	);
end top;

architecture rtl of top is
        
        --
	signal clk125, ipb_clk, locked, rst_125, rst_ipb, onehz : STD_LOGIC;
        signal ipb_clk_n : STD_LOGIC;
	signal mac_txd, mac_rxd : STD_LOGIC_VECTOR(7 downto 0);
	signal mac_txdvld, mac_txack, mac_rxclko, mac_rxdvld, mac_rxgoodframe, mac_rxbadframe : STD_LOGIC;
	signal ipb_master_out : ipb_wbus;
	signal ipb_master_in : ipb_rbus;
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal hostbus_in: emac_hostbus_in;
	signal hostbus_out: emac_hostbus_out;

	-- signals for main I2C
	signal i2c_sda_oen_s: std_logic;
	signal i2c_scl_oen_s: std_logic;

begin

--	DCM clock generation for internal bus, ethernet

	clocks: entity work.clocks_s6_extphy port map(
		sysclk_p => sysclk_p,
		sysclk_n => sysclk_n,
		clko_125 => clk125,
		clko_ipb => ipb_clk,
		locked => locked,
		rsto_125 => rst_125,
		rsto_ipb => rst_ipb,
		onehz => onehz
		);
		
	leds <= ('0', '0', locked, onehz);
	
--	Ethernet MAC core and PHY interface
-- In this version, consists of hard MAC core and GMII interface to external PHY
-- Can be replaced by any other MAC / PHY combination
	
	eth: entity work.eth_s6_gmii port map(
		clk125 => clk125,
		rst => rst_125,
		gmii_gtx_clk => gmii_gtx_clk,
		gmii_tx_en => gmii_tx_en,
		gmii_tx_er => gmii_tx_er,
		gmii_txd => gmii_txd,
		gmii_rx_clk => gmii_rx_clk,
		gmii_rx_dv => gmii_rx_dv,
		gmii_rx_er => gmii_rx_er,
		gmii_rxd => gmii_rxd,
		txd => mac_txd,
		txdvld => mac_txdvld,
		txack => mac_txack,
		rxd => mac_rxd,
		rxclko => mac_rxclko,
		rxdvld => mac_rxdvld,
		rxgoodframe => mac_rxgoodframe,
		rxbadframe => mac_rxbadframe,
		hostbus_in => hostbus_in,
		hostbus_out => hostbus_out
	);
	
	phy_rstb <= '1';
	
-- ipbus control logic

	ipbus: entity work.ipbus_ctrl_udponly port map(
		ipb_clk => ipb_clk,
		rst_ipb => rst_ipb,
		rst_macclk => rst_125,
		mac_txclk => clk125,
		mac_rxclk => mac_rxclko,
		mac_rxd => mac_rxd,
		mac_rxdvld => mac_rxdvld,
		mac_rxgoodframe => mac_rxgoodframe,
		mac_rxbadframe => mac_rxbadframe,
		mac_txd => mac_txd,
		mac_txdvld => mac_txdvld,
		mac_txack => mac_txack,
		ipb_out => ipb_master_out,
		ipb_in => ipb_master_in,
		mac_addr => mac_addr,
		ip_addr => ip_addr
	);
		
	mac_addr <= X"020ddba115" & dip_switch & X"0"; -- Careful here, arbitrary addresses do not always work
	ip_addr <= X"c0a8c8" & dip_switch & X"0"; -- 192.168.200.X

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

	slaves: entity work.slaves port map(
		ipb_clk => ipb_clk,
		rst => rst_ipb,
		ipb_in => ipb_master_out,
		ipb_out => ipb_master_in,
-- Top level ports from here
		hostbus_out => hostbus_in,
		hostbus_in => hostbus_out,

                gpio => open,
		-- Main I2C signals
		i2c_scl_i => i2c_scl_io ,
		i2c_scl_oen_o => i2c_scl_oen_s ,
		i2c_sda_i => i2c_sda_io,
		i2c_sda_oen_o => i2c_sda_oen_s,
                
	);

        -- For main I2C bus, need to put in a tri-state....
	i2c_scl_io <= '0' when (i2c_scl_oen_s = '0') else 'Z';
	i2c_sda_io <= '0' when (i2c_sda_oen_s = '0') else 'Z';

end rtl;

