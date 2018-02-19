-- Top-level design for ipbus demo
--
-- This version is for Enclustra AX3 module, using the RGMII PHY on the PM3 baseboard
--
-- You must edit this file to set the IP and MAC addresses
--
-- Dave Newbold, 4/10/16--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--Library UNISIM;
--use UNISIM.vcomponents.all;

use work.ipbus.ALL;

entity top is
    generic(
    g_NUM_DUTS  : positive := 3;
    g_NUM_TRIG_INPUTS   :positive := 4;
    g_NUM_EXT_SLAVES    :positive :=8;
    g_EVENT_DATA_WIDTH  :positive := 64;
    g_IPBUS_WIDTH   :positive := 32;
    g_NUM_EDGE_INPUTS   :positive := 4;
    g_SPILL_COUNTER_WIDTH   :positive := 12;
    g_BUILD_SIMULATED_MAC   :integer := 0
    );
    port(
        sysclk: in std_logic;
        leds: out std_logic_vector(3 downto 0); -- status LEDs
        dip_sw: in std_logic_vector(3 downto 0); -- switches
        rgmii_txd: out std_logic_vector(3 downto 0);
        rgmii_tx_ctl: out std_logic;
        rgmii_txc: out std_logic;
        rgmii_rxd: in std_logic_vector(3 downto 0);
        rgmii_rx_ctl: in std_logic;
        rgmii_rxc: in std_logic;
        i2c_scl_b: inout std_logic_vector(2 downto 0);
        i2c_sda_b: inout std_logic_vector(2 downto 0);
        phy_rstn: out std_logic; --default example ends here
        busy_n_i: in std_logic_vector(g_NUM_DUTS-1 downto 0);
        busy_p_i: in std_logic_vector(g_NUM_DUTS-1 downto 0);
        cfd_discr_n_i: in std_logic_vector(g_NUM_TRIG_INPUTS-1 downto 0);
        cfd_discr_p_i: in std_logic_vector(g_NUM_TRIG_INPUTS-1 downto 0);
        threshold_discr_n_i: in std_logic_vector(g_NUM_TRIG_INPUTS-1 downto 0);
        threshold_discr_p_i: in std_logic_vector(g_NUM_TRIG_INPUTS-1 downto 0);
        gpio_hdr: out std_logic_vector(3 downto 0);
        reset_or_clk_n_o: out std_logic_vector(g_NUM_DUTS-1 downto 0);
        reset_or_clk_p_o: out std_logic_vector(g_NUM_DUTS-1 downto 0);
        shutter_to_dut_n_o: out std_logic_vector(g_NUM_DUTS-1 downto 1);
        shutter_to_dut_p_o: out std_logic_vector(g_NUM_DUTS-1 downto 1)
        );

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, nuke, soft_rst, phy_rst_e, userled: std_logic;
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal inf_leds: std_logic_vector(1 downto 0);
	SIGNAL s_i2c_scl_enb         : std_logic_vector(2 downto 0);
    SIGNAL s_i2c_sda_enb         : std_logic_vector(2 downto 0);
	--signal s_i2c_sda_i : std_logic;
	--signal s_i2c_scl_i : std_logic;
	
begin
    
--led_iic_test <= iic_test;

--Implicit instantiation of output tristate buffers.
    i2c_scl_b(0) <= '0' when (s_i2c_scl_enb(0) = '0') else 'Z';
    i2c_sda_b(0) <= '0' when (s_i2c_sda_enb(0) = '0') else 'Z';
    i2c_scl_b(1) <= '0' when (s_i2c_scl_enb(1) = '0') else 'Z';
    i2c_sda_b(1) <= '0' when (s_i2c_sda_enb(1) = '0') else 'Z';
    i2c_scl_b(2) <= '0' when (s_i2c_scl_enb(2) = '0') else 'Z';
    i2c_sda_b(2) <= '0' when (s_i2c_sda_enb(2) = '0') else 'Z';
-- Infrastructure




	infra: entity work.enclustra_ax3_pm3_infra
		port map(
			sysclk => sysclk,
			clk_ipb_o => clk_ipb,
			rst_ipb_o => rst_ipb,
			rst_125_o => phy_rst_e,
			nuke => nuke,
			soft_rst => soft_rst,
			leds => inf_leds,
			rgmii_txd => rgmii_txd,
			rgmii_tx_ctl => rgmii_tx_ctl,
			rgmii_txc => rgmii_txc,
			rgmii_rxd => rgmii_rxd,
			rgmii_rx_ctl => rgmii_rx_ctl,
			rgmii_rxc => rgmii_rxc,
			mac_addr => mac_addr,
			ip_addr => ip_addr,
			ipb_in => ipb_in,
			ipb_out => ipb_out
		);
		
	leds <= not ('0' & userled & inf_leds);
	phy_rstn <= not phy_rst_e;
		
--	mac_addr <= X"020ddba1151" & dip_sw; -- Careful here, arbitrary addresses do not always work
--	ip_addr <= X"c0a8c81" & dip_sw; -- 192.168.200.16+n
	mac_addr <= X"020ddba1151f"; -- Careful here, arbitrary addresses do not always work
	ip_addr <= X"c0a8c81f"; -- 192.168.200.16+n

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

--	slaves: entity work.ipbus_example
--		port map(
--			ipb_clk => clk_ipb,
--			ipb_rst => rst_ipb,
--			ipb_in => ipb_out,
--			ipb_out => ipb_in,
--			nuke => nuke,
--			soft_rst => soft_rst,
--			i2c_scl_b => i2c_scl_b,
--            i2c_sda_b => i2c_sda_b,
--			userled => userled
--		);
    --OBUFT: Single-ended 3-state Output Buffer
--7 Series
-- Xilinx HDL Libraries Guide, version 2012.2

--OBUFT_inst_scl : IOBUF
--generic map (
--	DRIVE => 12,
--	IOSTANDARD => "DEFAULT",
--	SLEW => "SLOW")
--port map (
--    IO => i2c_scl_b, -- Buffer output (connect directly to top-level port)
--    I => '0', -- Buffer input
--    T => s_i2c_scl_enb, -- 3-state enable input
--    O =>  s_i2c_scl_i
--); -- End of OBUFT_inst instantiation

--OBUFT_inst_sda : IOBUF
--generic map (
--	DRIVE => 12,
--	IOSTANDARD => "DEFAULT",
--	SLEW => "SLOW")
--port map (
--    IO => i2c_sda_b, -- Buffer output (connect directly to top-level port)
--    I => '0', -- Buffer input
--    T => s_i2c_sda_enb, -- 3-state enable input
--    O =>  s_i2c_sda_i
--); -- End of OBUFT_inst instantiation
    
    slaves: entity work.ipbus_example
    port map(
        ipb_clk => clk_ipb,
        ipb_rst => rst_ipb,
        ipb_in => ipb_out,
        ipb_out => ipb_in,
        nuke => nuke,
        soft_rst => soft_rst,
        --i2c_scl_i => s_i2c_scl_i,
        --i2c_sda_i => s_i2c_sda_i,
        i2c_sda_i => i2c_sda_b,
        i2c_scl_i => i2c_scl_b,
        i2c_scl_enb_o => s_i2c_scl_enb,
        i2c_sda_enb_o => s_i2c_sda_enb,
        userled => userled
    );

end rtl;
