--=============================================================================
--! @file syncGenerator_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: syncGenerator
--
--============================================================================
--! Entity declaration for syncGenerator
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

--! Include math_real to get ceil and log2
-- use IEEE.math_real.all;

--! @brief Generates a sync signal for, eg. KPix
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date April 2018
--
--! @version v0.1
--
-------------------------------------------------------------------------------
--! @details
--! Address map:
--! 0x0 Control (bit-0 : high = shutter pulses on)
--! 0x1 Select source
--! 0x2 Internal trig generator period ( units = number of strobe pulses)
--! 0x3 Shutter on time - time between input trigger being received and shutter asserted(T1)
--! 0x4 Veto off time - time between input trigger and veto being de-asserted(T2)
--! 0x5 Shutter off time - time at which shutter de-asserted(T3)
--
--! \n\n<b>Last changes:</b>\n
--!



ENTITY syncGeneratorIPBus IS
  GENERIC (g_COUNTER_WIDTH : integer := 32; --! Number of bits in counter
           g_IPBUS_WIDTH : integer := 32; --! Width of IPBus data bus
           g_NUM_TRIG_SOURCES : integer := 4 --! Number of input trigger sources.
           );
  PORT
    (

      -- Input signals
      clock_i: 	IN STD_LOGIC;  --! rising edge active clock
      reset_i:  IN STD_LOGIC;  --! Active high. syncronous with rising clk
      strobe_i: IN STD_LOGIC;  --! one strobe pulse per 4 clock cycles
      trigger_sources_i: IN STD_LOGIC_VECTOR(g_NUM_TRIG_SOURCES-1 downto 0); --! array of possible trigger trigger_sources

      --! IPBus signals
      ipb_clk_i: in std_logic;
      ipb_in: in ipb_wbus;
      ipb_out: out ipb_rbus;

      --! Output Signals
      shutter_o: OUT STD_LOGIC;
      trigger_veto_o: OUT STD_LOGIC
      );
END syncGeneratorIPBus;

ARCHITECTURE rtl OF syncGeneratorIPBus IS

  --constant c_SELWIDTH : integer := integer(ceil(log2(real(g_NUM_TRIG_SOURCES))));

  signal s_sel : integer := 0;
  signal s_counter_value: std_logic_vector(g_COUNTER_WIDTH downto 0); -- One wider that comparator values.
  signal s_trigger, s_counter_enable, s_reset_counter: std_logic :='0';

  signal s_trigger_source_select: std_logic_vector(g_IPBUS_WIDTH-1 downto 0);
  signal s_counter_lt_t1 , s_counter_lt_t2 , s_counter_lt_t3 , s_counter_gt_cycle : std_logic := '0';
  signal s_shutter , s_veto : std_logic := '0';
  signal s_threshold_t1,s_threshold_t3,s_threshold_t2, s_internal_cycle_length : std_logic_vector(g_IPBUS_WIDTH-1 downto 0);

  signal s_enable_sequence : std_logic ; --! take high to enable sequence
  signal s_enable_internal_cycle : std_logic ; --! take high to enable internal sequence
  -- signal s_internal_cycle_length : STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0); --! Length of internally generated strobe cycle.


  constant c_NUM_CTRL_REGS  : integer := 6;
  constant c_NUM_STAT_REGS  : integer := 1;
  signal s_ipbus_statusregs:   ipb_reg_v(c_NUM_STAT_REGS - 1 downto 0) := (others => (others => '0'));
  signal s_ipbus_controlregs:  ipb_reg_v(c_NUM_CTRL_REGS - 1 downto 0);

  constant c_ipbus_qmask : ipb_reg_v(c_NUM_CTRL_REGS  - 1 downto 0) := (others => (others => '1'));

begin

cmp_SyncGen: entity work.syncGenerator
    generic map (
              g_COUNTER_WIDTH         => g_COUNTER_WIDTH ,
              g_IPBUS_WIDTH           => g_IPBUS_WIDTH ,
              g_NUM_TRIG_SOURCES      => g_NUM_TRIG_SOURCES  )
    port map (
              clock_i                 => clock_i,
              reset_i                 => reset_i,
              strobe_i                => strobe_i,
              trigger_sources_i       => trigger_sources_i,
              trigger_source_select_i => s_trigger_source_select,
              threshold_t1_i          => s_threshold_t1,
              threshold_t2_i          => s_threshold_t2,
              threshold_t3_i          => s_threshold_t3,
              enable_sequence_i       => s_enable_sequence,
              internal_cycle_length_i => s_internal_cycle_length,
              enable_internal_cycle_i => s_enable_internal_cycle,
              shutter_o               => shutter_o,
              trigger_veto_o          => trigger_veto_o );

cmp_ipbusReg: entity work.ipbus_syncreg_v
                      generic map(
                              N_CTRL => c_NUM_CTRL_REGS,
                              N_STAT => c_NUM_STAT_REGS
                      )
                      port map (
                              clk => ipb_clk_i,
                              rst => reset_i,
                              ipb_in => ipb_in,
                              ipb_out => ipb_out,
                              slv_clk => clock_i,
                              d => s_ipbus_statusregs,
                              q=> s_ipbus_controlregs,
                              qmask => c_ipbus_qmask,
                              stb => open,
                              rstb => open
                      );

s_enable_sequence <= s_ipbus_controlregs(0)(0);
s_enable_internal_cycle <= s_ipbus_controlregs(0)(1);
s_trigger_source_select <= s_ipbus_controlregs(1);

s_threshold_t1 <= s_ipbus_controlregs(3);
s_threshold_t2 <= s_ipbus_controlregs(4);
s_threshold_t3 <= s_ipbus_controlregs(5);

s_internal_cycle_length <= s_ipbus_controlregs(2);

END rtl;
