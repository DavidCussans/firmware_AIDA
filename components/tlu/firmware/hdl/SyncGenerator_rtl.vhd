--=============================================================================
--! @file syncGenerator_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------
-- unit name: syncGenerator
--
--============================================================================
--! Entity declaration for syncGenerator
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

use IEEE.math_real.all;

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
--! Starts sequence with trigger_veto_o high and shutter_o low.
--! If enable_sequence_i is high then when trigger_sources_i(trigger_source_select_i) goes high
--! then sequence starts.
--! At time T1 after Emin signal shutter_o goes higher
--! At time T2 after Emin veto_o goes low
--! At time T3 after Emin shutter_o goes low and veto_o goes high.
--! ( If sequence is not enabled, then veto_o is always low. )
--! \n\n<b>Last changes:</b>\n
--!



ENTITY syncGenerator IS
  GENERIC (g_COUNTER_WIDTH : integer := 32; --! Number of bits in counter
           g_IPBUS_WIDTH : integer := 32;
           g_NUM_TRIG_SOURCES : integer := 4 --! Number of input trigger sources.
           );
  PORT
    (

      -- Input signals
      clock_i: 	IN STD_LOGIC;  --! rising edge active clock
      reset_i:  IN STD_LOGIC;  --! Active high. syncronous with rising clk
      strobe_i: IN STD_LOGIC;  --! one strobe pulse per 4 clock cycles
      trigger_sources_i: IN STD_LOGIC_VECTOR(g_NUM_TRIG_SOURCES-1 downto 0); --! array of possible trigger trigger_sources
      trigger_source_select_i : IN STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0); --! Selects which input to use

      threshold_t1_i, threshold_t2_i, threshold_t3_i : IN STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0); --! Times at which sequence changes state.

      enable_sequence_i : in std_logic ; --! take high to enable sequence

      enable_internal_cycle_i : in std_logic ; --! take high to enable internal sequence
      internal_cycle_length_i : IN STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0); --! Length of internally generated strobe cycle.

      --! Output Signals
      shutter_o: OUT STD_LOGIC;
      trigger_veto_o: OUT STD_LOGIC
      );
END syncGenerator;

ARCHITECTURE rtl OF syncGenerator IS

  constant c_SELWIDTH : integer := integer(ceil(log2(real(g_NUM_TRIG_SOURCES))));

  signal s_sel : integer := 0;
  signal s_counter_value: std_logic_vector(g_COUNTER_WIDTH downto 0); -- One wider that comparator values.
  signal s_trigger, s_counter_enable, s_reset_counter: std_logic :='0';
  -- constant c_SELWIDTH : integer := 4; --! Up to 16 different trigger sources
  signal s_trigger_source_select: std_logic_vector(c_SELWIDTH-1 downto 0);
  signal s_counter_lt_t1 , s_counter_lt_t2 , s_counter_lt_t3 , s_counter_gt_cycle : std_logic := '0';
  signal s_shutter , s_veto : std_logic := '0';
  signal s_threshold_t1,s_threshold_t3,s_threshold_t2, s_internal_cycle_length,  s_truncated_counter_value : unsigned(g_COUNTER_WIDTH-1 downto 0);
BEGIN


  -- Instantiate a counter
  cmp_Counter: ENTITY work.counterWithResetPreset
  GENERIC MAP (g_COUNTER_WIDTH => g_COUNTER_WIDTH+1
           )
  PORT MAP
    (
      clock_i => clock_i,
      reset_i => s_reset_counter,
      preset_i => reset_i, --! Preload top bit to halt counter
      enable_i => s_counter_enable,
      result_o => s_counter_value); --! std_logic_vector output


  --! Process to generate a reset signal for counter
  --! Will reset ( and hence start to count ) if input trigger is high and
  --! the sequence isn't running and sequence is enabled.
  --! (The sequence isn't running if either the counter exceeds T3 or the top
  --! bit of the counter is set and has stopped running.)
  p_generateReset: PROCESS (clock_i)
    BEGIN
      IF rising_edge(clock_i) THEN
        if (s_trigger = '1') and
           ((s_counter_lt_t3 = '0') or (s_counter_value(s_counter_value'left) = '1')) and 
           (enable_sequence_i = '1') then
          s_reset_counter<= '1';
        else
          s_reset_counter <= '0';
        end if;
      END IF;
  END PROCESS p_generateReset;

  --! Process to stop counter before it wraps round
  --! and only count when strobe_i is high.
  p_generateStrobe: PROCESS (clock_i)
    BEGIN
      IF rising_edge(clock_i) THEN
        if ((s_counter_value(s_counter_value'left) = '0') and (strobe_i = '1')) then
          s_counter_enable <= '1';
        else
          s_counter_enable <= '0';
        end if;
      END IF;
  END PROCESS p_generateStrobe;

  -- Trim the source select value and convert to integer.
  s_trigger_source_select <= trigger_source_select_i(s_trigger_source_select'range);
  s_sel <= to_integer(unsigned(s_trigger_source_select));

  --! Process to register trigger input
  p_triggerSelect: PROCESS (clock_i)
  BEGIN
    --IF rising_edge(clock_i) and (strobe_i='1') THEN
    IF rising_edge(clock_i) THEN
      if (enable_internal_cycle_i='0') then
        s_trigger <= trigger_sources_i(s_sel); --! Trigger on external signals if not generating internal cycles
      else
        s_trigger <= s_counter_gt_cycle; --! Trigger on internal cycle
      end if;

    END IF;
  END PROCESS p_triggerSelect;


  -- Trim threshold values and convert to unsigned.
  s_threshold_t1 <= unsigned(threshold_t1_i(s_threshold_t1'range));
  s_threshold_t2 <= unsigned(threshold_t2_i(s_threshold_t2'range));
  s_threshold_t3 <= unsigned(threshold_t3_i(s_threshold_t3'range));
  s_internal_cycle_length <= unsigned(internal_cycle_length_i(s_internal_cycle_length'range) );

  -- Truncate the top bit of the counter ( which is only used to halt count
  -- when needed.
  s_truncated_counter_value <= unsigned( s_counter_value(  s_truncated_counter_value'range));
  
  --! Process to drive s_counter_lt_t1 , s_counter_lt_t2, s_counter_lt_t3
  p_comparators: PROCESS (clock_i)
  BEGIN
    IF rising_edge(clock_i) and (strobe_i='1') THEN

      if  s_truncated_counter_value < s_threshold_t1  THEN
        s_counter_lt_t1 <= '1';
      else
        s_counter_lt_t1 <= '0';
      end if;

      if  s_truncated_counter_value < s_threshold_t2  THEN
        s_counter_lt_t2 <= '1';
      else
        s_counter_lt_t2 <= '0';
      end if;

      if  s_truncated_counter_value < s_threshold_t3 THEN
        s_counter_lt_t3 <= '1';
      else
        s_counter_lt_t3 <= '0';
      end if;

      if  s_truncated_counter_value > s_internal_cycle_length then
        s_counter_gt_cycle <= '1';
      else
        s_counter_gt_cycle <= '0';
      end if;

    END IF;
  END PROCESS p_comparators;

  --! sequence: Emin --> Shutter-on --> Veto-off --> (shutter-off,veto-on)
  --! NB. Need to ensure T1 < T2 < T3
  --! If enable_sequence_i=0 then veto is always low. 
  s_veto <= '0' when ((s_counter_lt_t3 ='1') and (s_counter_lt_t2 = '0')) or (enable_sequence_i='0') else '1';
  s_shutter <= '1' when (s_counter_lt_t3 ='1') and (s_counter_lt_t1 = '0') else '0';

  --! Process to set output signals
  p_setOutput: PROCESS (clock_i)
  BEGIN
    IF rising_edge(clock_i) and (strobe_i='1') THEN
      trigger_veto_o <= s_veto;
      shutter_o <= s_shutter;
    END IF;
  END PROCESS p_setOutput;




END rtl;
