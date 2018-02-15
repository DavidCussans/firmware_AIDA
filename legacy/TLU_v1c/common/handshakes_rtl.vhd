--=============================================================================
--! @file handshakes_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Santiago de Compostela, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.handshakes.rtl
--
--! @brief Handshakes between TLU and DUTs. \n
--
--
--! @author Alvaro Dosil , alvaro.dosil@usc.es
--
--! @date 12:08:30 25/06/14
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
--! <b>Modified by: </b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.ipbus.all;
use work.ipbus_reg_types.all;

ENTITY handshakes IS
   GENERIC( 
      g_IPBUS_WIDTH         : positive := 32
   );
   PORT( 
      clk_i    			: IN     std_logic;
		Trigger_i			: IN 		std_logic;
      ipbus_clk_i       : IN     std_logic;
      ipbus_i           : IN     ipb_wbus;
      ipbus_reset_i     : IN     std_logic;
      ipbus_o           : OUT    ipb_rbus;
      logic_reset_i     : IN     std_logic;    
		Busy_i				: IN		std_logic;
		AIDAhandshake_o	: OUT		std_logic;		-- running an AIDA handshake or the old EUDET handshake
		Trigger_o			: OUT 	std_logic;
		rst_or_clk_o		: OUT 	std_logic		-- CONT in schematics
   );

-- Declarations

END ENTITY handshakes ;

--
ARCHITECTURE rtl OF handshakes IS

	signal s_handshakeEnabled : std_logic_vector(g_IPBUS_WIDTH-1 downto 0);
	signal s_Shutter, s_T0sync : std_logic;
	signal s_Trigger, s_TrigAux : std_logic := '0';
	signal s_Busy, s_Busy_d1, s_Busy_d2, s_Busy_d3 : std_logic;
	
	signal TPx3_T0syncLen 	: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := x"00000004";   	--! T0-sync length
	signal TPx3_Start_T0sync 	: std_logic;   																--! Flag to start the T0-sync signal

	signal s_Veto 			: std_logic := '0';
	signal s_WU				: std_logic := '0';
	signal s_NMaxPulses 	: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := (others=>'0');
	signal s_SuDTime 		: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := (others=>'0');
	signal s_PulseLen 	: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := x"00000001";
	signal s_IpDTime 		: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := x"00000001";
	signal s_RearmTime 	: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := x"10000000";
	signal s_PulseDelay 	: std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0) := (others=>'0');
	signal s_MaxPulses	: std_logic;
	signal s_pulse			: std_logic;
	
	constant c_N_CTRL : positive := 13;
	constant c_N_STAT : positive := 13;
	signal s_status_to_ipbus, s_sync_status_to_ipbus : ipb_reg_v(c_N_STAT-1 downto 0);
	signal s_control_from_ipbus,s_sync_control_from_ipbus  : ipb_reg_v(c_N_CTRL-1 downto 0);

BEGIN

  -----------------------------------------------------------------------------
  -- IPBus interface 
  -----------------------------------------------------------------------------
  ipbus_registers: entity work.ipbus_ctrlreg_v
    generic map(
      N_CTRL => c_N_CTRL,
      N_STAT => c_N_STAT
      )
    port map(
      clk => ipbus_clk_i,
      reset=> '0',--ipbus_reset_i ,
      ipbus_in=>  ipbus_i,
      ipbus_out=> ipbus_o,
      d=>  s_sync_status_to_ipbus,
      q=>  s_control_from_ipbus,
      stb=>  open
      );

  -- Synchronize registers from logic clock to ipbus.
    sync_status: entity work.synchronizeRegisters
    generic map (
      g_NUM_REGISTERS => c_N_STAT )
    port map (
      clk_input_i => clk_i,
      data_i      =>  s_status_to_ipbus,
      data_o      => s_sync_status_to_ipbus,
      clk_output_i => ipbus_clk_i);

    -- Synchronize registers from logic clock to ipbus.
    sync_ctrl: entity work.synchronizeRegisters
    generic map (
      g_NUM_REGISTERS => c_N_CTRL )
    port map (
      clk_input_i => ipbus_clk_i,
      data_i      =>  s_control_from_ipbus,
      data_o      => s_sync_control_from_ipbus,
      clk_output_i => clk_i);
		
	-----------------------------------------------------------------------------
	-- Logic not ready to use
	-----------------------------------------------------------------------------
		
	--Map the control registers
	s_handshakeEnabled <= s_sync_control_from_ipbus(0);
	
	s_status_to_ipbus(0) <= s_handshakeEnabled;

	
	-- No handshake registers
	s_NMaxPulses <= s_sync_control_from_ipbus(5);
	s_SuDTime <= s_sync_control_from_ipbus(6);
	s_PulseLen <= s_sync_control_from_ipbus(7);
	s_IpDTime <= s_sync_control_from_ipbus(8);
	s_RearmTime <= s_sync_control_from_ipbus(9);
	s_PulseDelay <= s_sync_control_from_ipbus(10);
	s_Veto <= s_sync_control_from_ipbus(11)(0);
	s_WU <= s_sync_control_from_ipbus(11)(1);
	
	s_status_to_ipbus(5) <= s_NMaxPulses;
	s_status_to_ipbus(6) <= s_SuDTime;
	s_status_to_ipbus(7) <= s_PulseLen;
	s_status_to_ipbus(8) <= s_IpDTime;
	s_status_to_ipbus(9) <= s_RearmTime;
	s_status_to_ipbus(10) <= s_PulseDelay;
	s_status_to_ipbus(11) <= x"0000000"& "00" & s_WU & s_Veto;
	s_status_to_ipbus(12) <= x"0000000"& "000" & s_MaxPulses;
	
	-- TPx3 registers
	TPx3_Start_T0sync <= s_sync_control_from_ipbus(1)(0);
	TPx3_T0syncLen 	<= x"00000001" when s_sync_control_from_ipbus(2)<x"000000002" else
								s_sync_control_from_ipbus(2);
  
	s_status_to_ipbus(1) <= x"0000000" & "000" & TPx3_Start_T0sync;
	s_status_to_ipbus(2) <= TPx3_T0syncLen;
  
  
	-----------------------------------------------------------------------------
	-- Synchronization - Rewrite!!!
	-----------------------------------------------------------------------------
	p_trigger : process(Trigger_i, s_Trigger)
	begin
		if Trigger_i = '1' then
			s_TrigAux <= '1';
		elsif s_Trigger = '1' then
			s_TrigAux <= '0';
		end if;
	end process p_trigger;
	
	p_sync: process (clk_i )
	begin  -- process p_run_counter
		if rising_edge(clk_i) then
			s_Trigger <= s_TrigAux;
			
			s_Busy_d1 <= Busy_i;
			s_Busy_d2 <= s_Busy_d1;
			s_Busy_d3 <= s_Busy_d2;
			s_Busy <= s_Busy_d2;
		end if;
  end process p_sync;
	
	-----------------------------------------------------------------------------
	-- I/O
	-----------------------------------------------------------------------------
	Trigger_o <= 	s_Trigger when s_handshakeEnabled(1 downto 0) = "00"  and s_Busy = '0' else
						s_pulse when s_handshakeEnabled(1 downto 0) = "01" else							-- No handshake
						s_Shutter when s_handshakeEnabled(1 downto 0) = "10" else						-- TPx3 handshake
						'0';
	rst_or_clk_o <= 	s_T0sync when s_handshakeEnabled(1 downto 0) = "10" else
							'0';
	
	AIDAhandshake_o <= not s_handshakeEnabled(3); 	-- s_handshakeEnabled = x"00001000" => EUDET handshake.
																	-- All handshakes with s_handshakeEnabled(3)='0' are AIDA handshakes
	
	-- No Handshake (GPP)
	No_handshake:  entity work.GPP
	GENERIC MAP( 
		g_IPBUS_WIDTH => g_IPBUS_WIDTH)
	PORT MAP( 
		clk_i       		=> clk_i,
		Enable_i          => not (s_Busy or s_Veto),
      Reset_i           => logic_reset_i,
      RstPulsCnt_i     	=> '0',
      Trigger_i         => s_Trigger,
      NMaxPulses_i      => s_NMaxPulses,
      SuDTime_i         => s_SuDTime,
      PulsLen_i     		=> s_PulseLen,
      IpDTime_i         => s_IpDTime,
		RearmTime_i       => s_RearmTime,
      Force_PullDown_i  => s_Busy or s_Veto,
      WU_i              => s_WU,
      PulseDelay_i      => s_PulseDelay,
		event_number_o    => open,
      MaxPulses_o       => s_MaxPulses,
      Pulse_o           => s_pulse,
      Pulse_d_o         => open);
		
	-- TPx3 Handshake
	TPx3_logic: entity work.TPx3Logic
   PORT MAP( 
      clk_i					=> clk_i,
		Start_T0sync_i		=> TPx3_Start_T0sync,
		T0syncLen_i			=> TPx3_T0syncLen,
      logic_reset_i     => logic_reset_i,
      Busy_i				=> s_Busy,
		Veto_i				=> s_Veto,
		Shutter_o			=> s_Shutter,
		T0sync_o 			=>	s_T0sync
   );

END ARCHITECTURE rtl;

