--=============================================================================
--! @file fmcTlu_pinTest_struct.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL -- VHDL Architecture work.fmcTlu_pinTest.struct
--
--! @brief \n
--! \n
--
--! @author David Cussans , David.Cussans@bristol.ac.uk ( phdgc.users (fortis.phy.bris.ac.uk))
--
--! @date 16:18:26 01/24/14
--
--! @version v0.1
--
--! @details
--!
--!
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------
--
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY fmcTlu_pinTest IS
   GENERIC( 
      g_NUM_DUTS            : positive := 3;
      g_NUM_TRIG_INPUTS     : positive := 4;
      g_NUM_EXT_SLAVES      : positive := 11;      --! Number of slaves outside IPBus interface
      g_EVENT_DATA_WIDTH    : positive := 64;
      g_IPBUS_WIDTH         : positive := 32;
      g_NUM_EDGE_INPUTS     : positive := 4;
      g_SPILL_COUNTER_WIDTH : positive := 12
   );
   PORT( 
      cfd_discr_n_i       : IN     std_logic_vector (g_NUM_TRIG_INPUTS-1 DOWNTO 0);
      cfd_discr_p_i       : IN     std_logic_vector (g_NUM_TRIG_INPUTS-1 DOWNTO 0);
      dip_switch_i        : IN     std_logic_vector (3 DOWNTO 0);
      gmii_rx_clk_i       : IN     std_logic;
      gmii_rx_dv_i        : IN     std_logic;
      gmii_rx_er_i        : IN     std_logic;
      gmii_rxd_i          : IN     std_logic_vector (7 DOWNTO 0);
      sysclk_n_i          : IN     std_logic;                                        --! 200 MHz xtal clock
      sysclk_p_i          : IN     std_logic;
      threshold_discr_n_i : IN     std_logic_vector (g_NUM_TRIG_INPUTS-1 DOWNTO 0);
      threshold_discr_p_i : IN     std_logic_vector (g_NUM_TRIG_INPUTS-1 DOWNTO 0);
      reset_i				  : IN 		std_logic;
      gmii_gtx_clk_o      : OUT    std_logic;
      gmii_tx_en_o        : OUT    std_logic;
      gmii_tx_er_o        : OUT    std_logic;
      gmii_txd_o          : OUT    std_logic_vector (7 DOWNTO 0);
      gpio_hdr            : OUT    std_logic_vector (7 DOWNTO 0);
      leds_o              : OUT    std_logic_vector (3 DOWNTO 0);
      phy_rstb_o          : OUT    std_logic;
      i2c_scl_b           : INOUT  std_logic;
      i2c_sda_b           : INOUT  std_logic;
      -- Signal definitions for TLU in normal use:
      --busy_n_i            : IN     std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      --busy_p_i            : IN     std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);         --! Busy lines from DUTs ( active high )
      --dut_clk_n_o         : INOUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      --dut_clk_p_o         : INOUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      --reset_or_clk_n_o    : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      --reset_or_clk_p_o    : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      --triggers_n_o        : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      --triggers_p_o        : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);         --! Trigger lines to DUT
      --extclk_n_b          : INOUT  std_logic;
      --extclk_p_b          : INOUT  std_logic;                                        --! either external clock in, or a clock being driven out
      -- Declare all as outputs for test purposes
      busy_n_o            : OUT     std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      busy_p_o            : OUT     std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);         --! Busy lines from DUTs ( active high )
      dut_clk_n_o         : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      dut_clk_p_o         : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      reset_or_clk_n_o    : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      reset_or_clk_p_o    : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      triggers_n_o        : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);
      triggers_p_o        : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);         --! Trigger lines to DUT
		spare_p_o           : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 1);
		spare_n_o           : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 1);
      extclk_n_o          : OUT  std_logic;
      extclk_p_o          : OUT  std_logic                                      --! either external clock in, or a clock being driven out

   );

-- Declarations

END ENTITY fmcTlu_pinTest ;



LIBRARY work;
--USE work.ipbus.all;
--USE work.emac_hostbus_decl.all;
--
--USE work.fmcTLU.all;
LIBRARY unisim;
USE unisim.vcomponents.all;


ARCHITECTURE struct OF fmcTlu_pinTest IS

   -- Architecture declarations
	
   constant c_NUM_OUTPUTS : positive := 6;
   signal s_patternData : std_logic_vector( c_NUM_OUTPUTS-1 downto 0);
   signal s_reset : std_logic := '0';
	signal ipbus_clk : std_logic := '0';
	
BEGIN

	cmp_clks: entity work.clocks_s6_extphy
		port map (
			sysclk_p        => sysclk_p_i,
			sysclk_n        => sysclk_n_i,
			clk_logic_xtal_o=> OPEN,
			clko_125        => OPEN,
			clko_ipb        => ipbus_clk,
			locked          => leds_o(2),
			rsto_125        => OPEN,
			rsto_ipb        => s_reset,
			onehz           => leds_o(3)
		);
	                              
	leds_o(1 downto 0) <= ( others => '0');
	
	i2c_scl_b  <= 'Z';
   i2c_sda_b  <= 'Z';
		
   cmp_pattern: entity work.comb_generator
     generic map (
       g_N_OUTPUT_BITS => c_NUM_OUTPUTS
       )
     port map (
       clk_i => ipbus_clk,
       reset_i => s_reset,
       data_o => s_patternData
       );

   gen_duts: for nDut in 0 to g_NUM_DUTS-1 generate

     OBUFDS_busy_inst : OBUFDS
       generic map (
         IOSTANDARD => "DEFAULT")
       port map (
         O =>  busy_p_o(nDut),    -- Diff_p output 
         OB => busy_n_o(nDut),   -- Diff_n output 
         I =>  s_patternData(0)      -- Buffer input
         );     

     OBUFDS_dut_clk_inst : OBUFDS
       generic map (
         IOSTANDARD => "DEFAULT")
       port map (
         O =>  dut_clk_p_o(nDut),    -- Diff_p output 
         OB => dut_clk_n_o(nDut),   -- Diff_n output 
         I =>  s_patternData(1)      -- Buffer input
         );

     OBUFDS_reset_or_clk_inst : OBUFDS
       generic map (
         IOSTANDARD => "DEFAULT")
       port map (
         O =>  reset_or_clk_p_o(nDut),    -- Diff_p output 
         OB => reset_or_clk_n_o(nDut),   -- Diff_n output 
         I =>  s_patternData(2)      -- Buffer input
         );

     OBUFDS_triggers_inst : OBUFDS
       generic map (
         IOSTANDARD => "DEFAULT")
       port map (
         O =>  triggers_p_o(nDut),    -- Diff_p output 
         OB => triggers_n_o(nDut),   -- Diff_n output 
         I =>  s_patternData(3)      -- Buffer input
         );
     		
   end generate gen_duts;

	gen_duts1: for nDut in 1 to g_NUM_DUTS-1 generate
	    OBUFDS_spare_inst : OBUFDS
			generic map (
				IOSTANDARD => "DEFAULT")
			port map (
				O =>  spare_p_o(nDut),    -- Diff_p output 
				OB => spare_n_o(nDut),   -- Diff_n output 
				I =>  s_patternData(4)      -- Buffer input
				);
	end generate gen_duts1;
	
   OBUFDS_extclk_inst : OBUFDS
     generic map (
       IOSTANDARD => "DEFAULT")
     port map (
       O =>  extclk_p_o,    -- Diff_p output 
       OB => extclk_n_o,   -- Diff_n output 
       I =>  s_patternData(5)      -- Buffer input
       );
   
END ARCHITECTURE struct;
