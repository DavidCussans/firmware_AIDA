--=============================================================================
--! @file IPBusInterface_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.IPBusInterface.rtl
--
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.ipbus.all;

--! @brief IPBus interface between 1GBit/s Ethernet and IPBus internal bus
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 16:06:57 11/09/12
--
--! @version v0.1
--
--! @details
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
ENTITY IPBusInterface IS
   GENERIC( 
      NUM_EXT_SLAVES : positive := 5;
      BUILD_SIMULATED_ETHERNET : integer := 0 --! Set to 1 to build simulated Ethernet interface using Modelsim FLI
   );
   PORT( 
      gmii_rx_clk_i    : IN     std_logic;
      gmii_rx_dv_i     : IN     std_logic;
      gmii_rx_er_i     : IN     std_logic;
      gmii_rxd_i       : IN     std_logic_vector (7 DOWNTO 0);
      ipbr_i           : IN     ipb_rbus_array (NUM_EXT_SLAVES-1 DOWNTO 0);  --! IPBus read signals
      sysclk_n_i       : IN     std_logic;
      sysclk_p_i       : IN     std_logic;                                   --! 200 MHz xtal clock
      clocks_locked_o  : OUT    std_logic;
      gmii_gtx_clk_o   : OUT    std_logic;
      gmii_tx_en_o     : OUT    std_logic;
      gmii_tx_er_o     : OUT    std_logic;
      gmii_txd_o       : OUT    std_logic_vector (7 DOWNTO 0);
      ipb_clk_o        : OUT    std_logic;                                   --! IPBus clock to slaves
      ipb_rst_o        : OUT    std_logic;                                   --! IPBus reset to slaves
      ipbw_o           : OUT    ipb_wbus_array (NUM_EXT_SLAVES-1 DOWNTO 0);  --! IBus write signals
      onehz_o          : OUT    std_logic;
      phy_rstb_o       : OUT    std_logic;
      dip_switch_i     : IN     std_logic_vector (3 DOWNTO 0); --! Used to select IP address
      clk_logic_xtal_o : OUT    std_logic  --! 40MHz clock that can be used for logic if not using external clock
   );

-- Declarations

END ENTITY IPBusInterface ;

--
ARCHITECTURE rtl OF IPBusInterface IS
  
  --! Number of slaves inside the IPBusInterface block.
  constant c_NUM_INTERNAL_SLAVES : positive := 1;

  signal clk125,  rst_125, rst_ipb: STD_LOGIC;
  signal mac_txd, mac_rxd : STD_LOGIC_VECTOR(7 downto 0);
  signal mac_txdvld, mac_txack, mac_rxclko, mac_rxdvld, mac_rxgoodframe, mac_rxbadframe : STD_LOGIC;
  signal ipb_master_out : ipb_wbus;
  signal ipb_master_in : ipb_rbus;
  signal mac_addr: std_logic_vector(47 downto 0);
  signal mac_tx_data, mac_rx_data: std_logic_vector(7 downto 0);
  signal mac_tx_valid, mac_tx_last, mac_tx_error, mac_tx_ready, mac_rx_valid, mac_rx_last, mac_rx_error: std_logic;

  signal ip_addr: std_logic_vector(31 downto 0);
  signal s_ipb_clk : std_logic;
  signal s_ipbw_internal: ipb_wbus_array (NUM_EXT_SLAVES+c_NUM_INTERNAL_SLAVES-1 DOWNTO 0);
  signal s_ipbr_internal: ipb_rbus_array (NUM_EXT_SLAVES+c_NUM_INTERNAL_SLAVES-1 DOWNTO 0);
  signal s_sysclk : std_logic;
  signal pkt_rx, pkt_tx, pkt_rx_led, pkt_tx_led, sys_rst: std_logic;
  
BEGIN

  -- Connect IPBus clock and reset to output ports.
  ipb_clk_o <= s_ipb_clk;
  ipb_rst_o <= rst_ipb;

  --! By default generate a physical MAC
  generate_physicalmac: if ( BUILD_SIMULATED_ETHERNET /= 1 ) generate
      
--	DCM clock generation for internal bus, ethernet
--	clocks: entity work.clocks_s6_extphy port map(
--          sysclk_p => sysclk_p_i,
--          sysclk_n => sysclk_n_i,
--          clk_logic_xtal_o => clk_logic_xtal_o,
--          clko_125 => clk125,
--          clko_ipb => s_ipb_clk,
--          locked => clocks_locked_o,
--          rsto_125 => rst_125,
--          rsto_ipb => rst_ipb,
--          onehz => onehz_o
--          );
    
    clocks: entity work.clocks_7s_extphy_Se port map(
        sysclk_p => sysclk_p_i,
        sysclk_n => sysclk_n_i,
        clk_logic_xtal_o => clk_logic_xtal_o,
        clko_125 => clk125,
        clko_ipb => s_ipb_clk,
        locked => clocks_locked_o,
        rsto_125 => rst_125,
        rsto_ipb => rst_ipb,
        onehz => onehz_o
        );
				
	-- leds <= ('0', '0', locked, onehz);
	
--	Ethernet MAC core and PHY interface
-- In this version, consists of hard MAC core and GMII interface to external PHY
-- Can be replaced by any other MAC / PHY combination

--        eth: entity work.eth_s6_gmii port map(
--          clk125 => clk125,
--          rst => rst_125,
--          gmii_gtx_clk => gmii_gtx_clk_o,
--          gmii_tx_en => gmii_tx_en_o,
--          gmii_tx_er => gmii_tx_er_o,
--          gmii_txd => gmii_txd_o,
--          gmii_rx_clk => gmii_rx_clk_i,
--          gmii_rx_dv => gmii_rx_dv_i,
--          gmii_rx_er => gmii_rx_er_i,
--          gmii_rxd => gmii_rxd_i,
--          tx_data => mac_tx_data,
--          tx_valid => mac_tx_valid,
--          tx_last => mac_tx_last,
--          tx_error => mac_tx_error,
--          tx_ready => mac_tx_ready,
--          rx_data => mac_rx_data,
--          rx_valid => mac_rx_valid,
--          rx_last => mac_rx_last,
--          rx_error => mac_rx_error
--          );
          
      eth: entity work.eth_7s_rgmii port map(
            clk125 => clk125,
            rst => rst_125,
            tx_data => mac_tx_data,
            tx_valid => mac_tx_valid,
            tx_last => mac_tx_last,
            tx_error => mac_tx_error,
            tx_ready => mac_tx_ready,
            rx_data => mac_rx_data,
            rx_valid => mac_rx_valid,
            rx_last => mac_rx_last,
            rx_error => mac_rx_error,
            gmii_gtx_clk => gmii_gtx_clk_o,
            gmii_tx_en => gmii_tx_en_o,
            gmii_tx_er => gmii_tx_er_o,
            gmii_txd => gmii_txd_o,
            gmii_rx_clk => gmii_rx_clk_i,
            gmii_rx_dv => gmii_rx_dv_i,
            gmii_rx_er => gmii_rx_er_i,
            gmii_rxd => gmii_rxd_i            
            );
          	
  end generate generate_physicalmac;

    --! Set generic BUILD_SIMULATED_ETHERNET to 1 to generate a simulated MAC
    generate_simulatedmac: if ( BUILD_SIMULATED_ETHERNET = 1 ) generate

      sim_clocks: entity work.clock_sim
	port map (
	  clko125 => clk125,
	  clko25 => s_ipb_clk,
	  clko40 =>  clk_logic_xtal_o,
	  nuke   => '0',
	  rsto   => rst_125
          );
      rst_ipb <= rst_125;
      clocks_locked_o  <= '1';
      
      -- clk125 <= sysclk_i; -- *must* run this simulation with 125MHz sysclk...
      simulated_eth: entity work.eth_mac_sim
        port map(
          clk => clk125,
          rst => rst_125,
          tx_data => mac_tx_data,
          tx_valid => mac_tx_valid,
          tx_last => mac_tx_last,
          tx_error => mac_tx_error,
          tx_ready => mac_tx_ready,
          rx_data => mac_rx_data,
          rx_valid => mac_rx_valid,
          rx_last => mac_rx_last,
          rx_error => mac_rx_error
          );
    end generate generate_simulatedmac;

  phy_rstb_o <= '1';
  
-- ipbus control logic
        ipbus: entity work.ipbus_ctrl
          generic map (
            BUFWIDTH => 2)
          port map(
            mac_clk => clk125,
            rst_macclk => rst_125,
            ipb_clk => s_ipb_clk,
            rst_ipb => rst_ipb,
            mac_rx_data => mac_rx_data,
            mac_rx_valid => mac_rx_valid,
            mac_rx_last => mac_rx_last,
            mac_rx_error => mac_rx_error,
            mac_tx_data => mac_tx_data,
            mac_tx_valid => mac_tx_valid,
            mac_tx_last => mac_tx_last,
            mac_tx_error => mac_tx_error,
            mac_tx_ready => mac_tx_ready,
            ipb_out => ipb_master_out,
            ipb_in => ipb_master_in,
            mac_addr => mac_addr,
            ip_addr => ip_addr,
            pkt_rx => pkt_rx,
            pkt_tx => pkt_tx,
            pkt_rx_led => pkt_rx_led,
            pkt_tx_led => pkt_tx_led
            );

	
	mac_addr <= X"020ddba115" & dip_switch_i & X"0"; -- Careful here, arbitrary addresses do not always work
	ip_addr   <= X"c0a8c8" & dip_switch_i & X"0"; -- 192.168.200.X
 
  fabric: entity work.ipbus_fabric
    generic map(NSLV => NUM_EXT_SLAVES+c_NUM_INTERNAL_SLAVES)
    port map(
      ipb_in => ipb_master_out,
      ipb_out => ipb_master_in,
      ipb_to_slaves => s_ipbw_internal,
      ipb_from_slaves => s_ipbr_internal
    );
    
    ipbw_o <= s_ipbw_internal(NUM_EXT_SLAVES-1 downto 0);

    s_ipbr_internal(NUM_EXT_SLAVES-1 downto 0) <= ipbr_i;
         
  -- Slave: firmware ID
  firmware_id: entity work.ipbus_ver
    port map(
      ipbus_in =>  s_ipbw_internal(NUM_EXT_SLAVES+c_NUM_INTERNAL_SLAVES-1),
      ipbus_out => s_ipbr_internal(NUM_EXT_SLAVES+c_NUM_INTERNAL_SLAVES-1)
      );

END ARCHITECTURE rtl;

