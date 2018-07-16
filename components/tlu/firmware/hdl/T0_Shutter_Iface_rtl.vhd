--=============================================================================
--! @file T0_Shutter_Iface_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: T0_Shutter_Iface
--
--============================================================================
--! Entity declaration for T0_Shutter_Iface
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

--! @brief Generates T0 signal and shutter signals for, eg. KPix
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date April 2018
--
--! @version v0.1
--
-------------------------------------------------------------------------------
--! @details
--! \n IPBus Address map:
--! \li 0x0 Control (bit-0 : high = shutter pulses on)
--! \li 0x1 Select source
--! \li 0x2 Internal trig generator period ( units = number of strobe pulses)
--! \li 0x3 Shutter on time - time between input trigger being received and shutter asserted(T1)
--! \li 0x4 Veto off time - time between input trigger and veto being de-asserted(T2)
--! \li 0x5 Shutter off time - time at which shutter de-asserted(T3)
--! \li 0x8 Pulse T0
--! \n\n<b>Last changes:</b>\n
--!



ENTITY T0_Shutter_Iface IS
  GENERIC (g_COUNTER_WIDTH : integer := 32; --! Number of bits in counter
           g_IPBUS_WIDTH : integer := 32; --! Width of IPBus data bus
           g_NUM_ACCELERATOR_SIGNALS : integer := 4 --! Number of input trigger sources.
           );
  PORT
    (

      -- Input signals
      clk_4x_i: 	IN STD_LOGIC;  --! rising edge active clock
      reset_i:  IN STD_LOGIC;  --! Active high. syncronous with rising clk
      clk_4x_strobe_i: IN STD_LOGIC;  --! one strobe pulse per 4 clock cycles
      accelerator_signals_i: IN STD_LOGIC_VECTOR(g_NUM_ACCELERATOR_SIGNALS-1 downto 0); --! array of possible trigger trigger_sources

      --! IPBus signals
      ipbus_clk_i: in std_logic;
      ipbus_i: in ipb_wbus;
      ipbus_o: out ipb_rbus;

      --! Output Signals
      shutter_o: OUT STD_LOGIC; --! Shutter signal.
      shutter_veto_o: OUT STD_LOGIC; --! Goes high when shutter vetoes triggers. NB. Should be *low* when shutters are disabled.
      run_active_o: out std_logic;      --! goes high when run is active.
      T0_o: out std_logic --! T0 synchronization pulse. Pulses on leading edge of run_active_o
      );
END T0_Shutter_Iface;

ARCHITECTURE rtl OF T0_Shutter_Iface IS

  signal s_sel : integer := 0;
  signal s_counter_value: std_logic_vector(g_COUNTER_WIDTH downto 0); -- One wider that comparator values.
  signal s_trigger, s_counter_enable, s_reset_counter: std_logic :='0';

  signal s_trigger_source_select: std_logic_vector(g_IPBUS_WIDTH-1 downto 0);
  signal s_counter_lt_t1 , s_counter_lt_t2 , s_counter_lt_t3 , s_counter_gt_cycle : std_logic := '0';
  signal s_shutter , s_veto : std_logic := '0';
  signal s_threshold_t1,s_threshold_t3,s_threshold_t2, s_internal_cycle_length : std_logic_vector(g_IPBUS_WIDTH-1 downto 0);

  signal s_enable_sequence : std_logic ; --! take high to enable sequence
  signal s_enable_internal_cycle : std_logic ; --! take high to enable internal sequence
  -- signal s_T0_ipbus : std_logic; --! T0 synchronization signal on IPBus clock domain.
  signal s_run_active : std_logic; --! Take active to issue T0 pulse and enable shutters
  constant c_NUM_CTRL_REGS  : integer := 8;
  constant c_NUM_STAT_REGS  : integer := 1;
  signal s_ipbus_statusregs:   ipb_reg_v(c_NUM_STAT_REGS - 1 downto 0) := (others => (others => '0'));
  signal s_ipbus_controlregs:  ipb_reg_v(c_NUM_CTRL_REGS - 1 downto 0);

  constant c_ipbus_qmask : ipb_reg_v(c_NUM_CTRL_REGS  - 1 downto 0) := (others => (others => '1'));

--  constant c_T0_address : std_logic_vector(3 downto 0) := "1000"; --! Write 1 to bit 0 of this address to produce a enable shutters and produce T0 pulse 
                                                                 
begin

  cmp_SyncGen: entity work.syncGenerator
    generic map (
              g_COUNTER_WIDTH         => g_COUNTER_WIDTH ,
              g_IPBUS_WIDTH           => g_IPBUS_WIDTH ,
              g_NUM_TRIG_SOURCES      => g_NUM_ACCELERATOR_SIGNALS  )
    port map (
              clock_i                 => clk_4x_i,
              reset_i                 => reset_i,
              strobe_i                => clk_4x_strobe_i,
              trigger_sources_i       => accelerator_signals_i,
              trigger_source_select_i => s_trigger_source_select,
              threshold_t1_i          => s_threshold_t1,
              threshold_t2_i          => s_threshold_t2,
              threshold_t3_i          => s_threshold_t3,
              enable_sequence_i       => s_enable_sequence,
              internal_cycle_length_i => s_internal_cycle_length,
              enable_internal_cycle_i => s_enable_internal_cycle,
              shutter_o               => shutter_o,
              trigger_veto_o          => shutter_veto_o );

  cmp_ipbusReg: entity work.ipbus_syncreg_v
    generic map(
      N_CTRL => c_NUM_CTRL_REGS,
      N_STAT => c_NUM_STAT_REGS
      )
    port map (
      clk => ipbus_clk_i,
      rst => reset_i,
      ipb_in => ipbus_i,
      ipb_out => ipbus_o,
      slv_clk => clk_4x_i,
      d => s_ipbus_statusregs,
      q=> s_ipbus_controlregs,
      qmask => c_ipbus_qmask,
      stb => open,
      rstb => open
      );

--  s_enable_sequence <= ( s_ipbus_controlregs(0)(0) and s_run_active ) when (rising_edge(clk_4x_i) and (clk_4x_strobe_i = '1'));
  s_enable_sequence <=  ( s_ipbus_controlregs(0)(0) and  s_run_active)  when (rising_edge(clk_4x_i) and (clk_4x_strobe_i = '1'));
--  s_run_active <= s_ipbus_controlregs(8)(0); --! Set to 1 to issue T0 and start shutter 
  
  s_enable_internal_cycle <= s_ipbus_controlregs(0)(1);
  s_trigger_source_select <= s_ipbus_controlregs(1);

  s_internal_cycle_length <= s_ipbus_controlregs(2);
  
  s_threshold_t1 <= s_ipbus_controlregs(3);
  s_threshold_t2 <= s_ipbus_controlregs(4);
  s_threshold_t3 <= s_ipbus_controlregs(5);

  s_run_active <= s_ipbus_controlregs(6)(0);
  
  run_active_o <= s_run_active;

  ---- A bodge. I can't figure out which standard IPBus register generates a
  ---- pulse, so put this logic in parallel.
  ----------------------
  --ipbus_generateT0: process (ipbus_clk_i)
  --begin  -- process ipbus_clk_i
  --if rising_edge(ipbus_clk_i) then

  --    if (ipbus_i.ipb_strobe = '1' and ipbus_i.ipb_write = '1' and ipbus_i.ipb_addr(3 downto 0) = c_T0_address ) then
  --      s_T0_ipbus <= '1'; -- set T0 signal high
  --    else
  --      s_T0_ipbus <= '0';
  --    end if;

  --  end if;
  --end process ipbus_generateT0;

  --! Retime T0 generated by IPBus onto clk_4x and align with strobe
  cmp_T0_retime: entity work.stretchPulse4x
    port map (
      clk_4x_i      => clk_4x_i,
      clk_4x_strobe_i => clk_4x_strobe_i,
      pulse_i       => s_run_active,
--      pulse_i       => s_T0_ipbus, 
      pulse_o       => T0_o);

END rtl;
