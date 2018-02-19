--=============================================================================
--! @file eventFormatter_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.eventFormatter.rtl
--
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.fmcTLU.all;
USE work.ipbus.all;

use work.ipbus_reg_types.all;

--! @brief Takes the data delivered on each trigger and turns it into 64-bit
--!        words to push into event buffer
--! 
--!
--! @author David Cussans , David.Cussans@bristol.ac.uk
--!
--! @date 15:10:35 11/09/12
--!
--! @version v0.1
--!
--! @details
--! \n\n IPBus address:
--! \n (Decodes 3 bits)
--! \li 000 - read/write enable data recording.
--! \li 001 - write = reset timestamp,
--! \li 010 - read = current timestamp (low  32-bits)
--! \li 011 - read = current timestamp (high 16-bits)
--!
--! -----------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! Modified by: Alvaro Dosil , alvaro.dosil@usc.es \n
--! 27/Feb/14 DGC Change "If" when setting s_word2 to a case ... generate. Questasim
--!               doesn't like having an if that can take an array out of bounds.
--! 26/Sept/14 DGC Hacked out shutter etc. Can't figure out bug.
--!-----------------------------------------------------------------------------
--! @todo Add more input data: \n
--! a) shutter signals. One per DUT. ?? \n
--! b) input levels ( for recording edge data ). Record rising and falling edges\n
--! c) veto levels. One per DUT. Record rising and falling edges.\n
--! \n
--! Add backpressure output if short FIFOs fill up? But many inputs won't
--! respond - e.g. scintillator inputs. This data will be lost....
--! some ports are redundant - e.g. trigger counter, others confusingly
--! labelled. Sort this out..
--------------------------------------------------------------------------------


ENTITY eventFormatter IS
   GENERIC( 
      g_EVENT_DATA_WIDTH   : positive := 64;
      g_IPBUS_WIDTH        : positive := 32;
      g_COUNTER_TRIG_WIDTH : positive := 32;
      g_COUNTER_WIDTH      : positive := 12;
      g_EVTTYPE_WIDTH      : positive := 4; --! Width of the event type word
      --g_NUM_INPUT_TYPES     : positive := 4;               -- Number of different input types (trigger, shutter, edge...)
      g_NUM_EDGE_INPUTS    : positive := 4;      --! Number of edge inputs
      g_NUM_TRIG_INPUTS    : positive := 6      --! Number of trigger inputs
   );
   PORT( 
      clk_4x_logic_i         : IN     std_logic;                                           --! Rising edge active
      ipbus_clk_i            : IN     std_logic;
      logic_strobe_i         : IN     std_logic;                                           --! Pulses high once every 4 cycles of clk_4x_logic
      logic_reset_i          : IN     std_logic;                                           --! goes high to reset counters. Synchronous with clk_4x_logic
      rst_fifo_i             : IN     std_logic;                                           --! Goes high to reset FIFOs
      buffer_full_i          : IN     std_logic;                                           --! Goes high when output fifo full
      trigger_i              : IN     std_logic;                                           --! goes high to load trigger data. One cycle of clk_4x_logic
      trigger_times_i        : IN     t_triggerTimeArray (g_NUM_TRIG_INPUTS-1 DOWNTO 0);   --! Array of trigger times ( w.r.t. logic_strobe)
      trigger_inputs_fired_i : IN     std_logic_vector (g_NUM_TRIG_INPUTS-1 DOWNTO 0);     --! high for each input that "fired"
      trigger_cnt_i          : IN     std_logic_vector (g_COUNTER_TRIG_WIDTH-1 DOWNTO 0);  --! Trigger count
      shutter_i              : IN     std_logic;
      shutter_cnt_i          : IN     std_logic_vector (g_COUNTER_WIDTH-1 DOWNTO 0);
      spill_i                : IN     std_logic;
      spill_cnt_i            : IN     std_logic_vector (g_COUNTER_WIDTH-1 DOWNTO 0);
      edge_rise_i            : IN     std_logic_vector (g_NUM_EDGE_INPUTS-1 DOWNTO 0);     --! High when rising edge
      edge_fall_i            : IN     std_logic_vector (g_NUM_EDGE_INPUTS-1 DOWNTO 0);     --! High when falling edge
      edge_rise_time_i       : IN     t_triggerTimeArray (g_NUM_EDGE_INPUTS-1 DOWNTO 0);   --! Array of edge times ( w.r.t. logic_strobe)
      edge_fall_time_i       : IN     t_triggerTimeArray (g_NUM_EDGE_INPUTS-1 DOWNTO 0);   --! Array of edge times ( w.r.t. logic_strobe)
      ipbus_i                : IN     ipb_wbus;
      ipbus_o                : OUT    ipb_rbus;
      data_strobe_o          : OUT    std_logic;                                           --! goes high when data ready to load into event buffer
      event_data_o           : OUT    std_logic_vector (g_EVENT_DATA_WIDTH-1 DOWNTO 0);
      reset_timestamp_i      : IN     std_logic;                                           --! Taking high causes timestamp to be reset. Combined with internal timestmap reset and written to reset_timestamp_o
      reset_timestamp_o      : OUT    std_logic                                           --! Goes high for one clock cycle of clk_4x_logic when timestamp reset
   );

-- Declarations

END eventFormatter ;

--
ARCHITECTURE rtl OF eventFormatter IS

  
  constant c_NUM_INPUT_TYPES     : positive := 3+g_NUM_EDGE_INPUTS;               -- Number of different input types (trigger, shutter, edge(0), edge(1)...)
  
--  type t_fifo_io is array(natural range <>) of std_logic_vector(g_EVENT_DATA_WIDTH-1 downto 0);
-- type t_evttype is array(natural range <>) of std_logic_vector(g_EVTTYPE_WIDTH-1 downto 0);
--  type t_var is array(natural range <>) of std_logic_vector(g_COUNTER_WIDTH-1 downto 0);
  -- Input types:
  -- 0 - Trigger
  -- 1 - Shutter
  -- 2 - Edge signal
  -- 3 - Spill
  
  --! delayed strobes
  signal s_event_strobe , s_event_strobe_d1 ,s_event_strobe_d2 ,s_event_strobe_d3 , s_event_strobe_d3_opt : std_logic := '0';
  signal shutter_i_d1, shutter_i_d2, edge_i_d1, edge_i_d2, spill_i_d1, spill_i_d2 : std_logic := '0';
  
--  signal s_evttype : t_evttype(3+g_NUM_EDGE_INPUTS-1 downto 0) := (others=>(others=>'0'));   -- Event type
  signal s_evttype : std_logic_vector(g_EVTTYPE_WIDTH-1 downto 0) := ( others => '0');
  -- 0000 trigger internal
  -- 0001 trigger external
  -- 0010 shutter falling
  -- 0011 shutter rising
  -- 0100 edge falling
  -- 0101 edge rising
  -- 0111 spill on
  -- 0110 spill off
  
  signal s_var        : std_logic_vector(g_COUNTER_WIDTH-1 downto 0) := (others => '0');
    
  signal s_data_o        : std_logic_vector(g_EVENT_DATA_WIDTH-1 DOWNTO 0);         -- Multiplexed data from FIFOs
  
  constant c_COARSE_TIMESTAMP_WIDTH : positive := 48;  -- ! Number of bits in 40MHz timestamp
  signal s_coarse_timestamp : std_logic_vector(c_COARSE_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');  -- 40MHz timestamp.
  signal s_coarse_timestamp_ipbus : ipb_reg_v(1 downto 0) := ( others => (others => '0')); --! 40MHz timestamp on IPB clock domain.

--  signal s_event_number : unsigned(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- increment after each post-veto trigger.

  signal s_word0 , s_word1, s_word2 			: std_logic_vector(g_EVENT_DATA_WIDTH-1 downto 0) := (others => '0');  -- clocked to data output on logic_strobe , s_logic_strobe_d1 , etc.
  signal s_word0_p1  : std_logic_vector(g_EVENT_DATA_WIDTH-1 downto 0) := (others => '0');  -- clocked to data output on logic_strobe , s_logic_strobe_d1 , etc.
  signal s_word0_d1 , s_word1_d1, s_word2_d1 : std_logic_vector(g_EVENT_DATA_WIDTH-1 downto 0) := (others => '0');  -- clocked to data output on logic_strobe , s_logic_strobe_d1 , etc.
  signal s_word0_d2 , s_word1_d2, s_word2_d2 : std_logic_vector(g_EVENT_DATA_WIDTH-1 downto 0) := (others => '0');  -- clocked to data output on logic_strobe , s_logic_strobe_d1 , etc.
  signal s_word0_d3 , s_word1_d3, s_word2_d3 : std_logic_vector(g_EVENT_DATA_WIDTH-1 downto 0) := (others => '0');  -- clocked to data output on logic_strobe , s_logic_strobe_d1 , etc.
  signal trigger_times_d1							: t_triggerTimeArray (g_NUM_TRIG_INPUTS-1 DOWNTO 0) := (others => (others=>'0')); 

  signal s_reset_timestamp_4x, s_reset_timestamp_4x_ipbus , s_reset_timestamp_4x_external , s_reset_timestamp_4x_external_p1 , s_reset_timestamp_4x_external_p2 : std_logic := '0'; --! Single pulse on 4x domain
  signal s_reset_timestamp_ipbus : std_logic := '0'; --! Single pulse on IPBus clock domain
  
  signal s_ipbus_ack      : std_logic := '0';  -- used to produce a delayed IPBus ack signal
  signal s_enable_record, s_enable_record_ipb : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (2 downto 0 => '1', others=>'0'); -- Enable data record
  signal s_enable_trigger : std_logic := '1'; -- Enable trigger record
  signal s_enable_shutter : std_logic := '1'; -- Enable shutter record
  signal s_enable_spill   : std_logic := '1'; -- Enable spill record
  signal s_enable_edges   : std_logic_vector(g_NUM_EDGE_INPUTS-1 downto 0) := (others=>'0'); -- Enable edges record

  signal s_rst_fifo_d1 , s_rst_fifo_d2 , s_rst_fifo_clk4x  : std_logic := '0';
  signal s_buffer_full_d1 , s_buffer_full_d2 , s_buffer_full_clk4x  : std_logic := '0';
  signal s_trigger : std_logic := '0';  -- pulses on risng edge of triger in

  signal s_captured_trigger_times :  t_triggerTimeArray (g_NUM_TRIG_INPUTS-1 DOWNTO 0);   --! Array of trigger times,captured when trigger
  
BEGIN

  -----------------------------------------------------------------------------
  -- IPBus write
  -----------------------------------------------------------------------------
  ipbus_write: process (ipbus_clk_i)
  begin  -- process ipb_clk_i
    if rising_edge(ipbus_clk_i) then

      s_reset_timestamp_ipbus <= '0';
      if (ipbus_i.ipb_strobe = '1' and ipbus_i.ipb_write = '1') then

         case ipbus_i.ipb_addr(2 downto 0) is
           when "000" => s_enable_record_ipb <= ipbus_i.ipb_wdata ; -- Enable data record
           when "001" => s_reset_timestamp_ipbus <= '1';
           when others => null;
         end case;
          
       end if;

       s_ipbus_ack <= ipbus_i.ipb_strobe and not s_ipbus_ack;
       
    end if;
  end process ipbus_write;

  ipbus_o.ipb_ack <= s_ipbus_ack;
  ipbus_o.ipb_err <= '0';
  

  -----------------------------------------------------------------------------
  -- IPBUS read
  -----------------------------------------------------------------------------
  with ipbus_i.ipb_addr(2 downto 0) select
    ipbus_o.ipb_rdata <=
      s_enable_record_ipb                     when "000",
      s_coarse_timestamp_ipbus(0)              when "010",  
      s_coarse_timestamp_ipbus(1)             when "011",  
      (others => '1')                         when others;

  cmp_timestampDomainCross : entity work.synchronizeRegisters
    generic map (
      g_NUM_REGISTERS => 2 )
    port map (
      clk_input_i  => clk_4x_logic_i,
      data_i       => ( "0000000000000000" & s_coarse_timestamp(s_coarse_timestamp'left downto 32) , s_coarse_timestamp(31 downto 0) ) ,
      data_o       => s_coarse_timestamp_ipbus, 
      clk_output_i => ipbus_clk_i
      );

  -- Move reset timestamp pulse onto clk_4x_logic
  cmp_resetTimestampDomainCross: entity work.pulseClockDomainCrossing
    port map (
      clk_input_i  => ipbus_clk_i,
      pulse_i      => s_reset_timestamp_ipbus,
      clk_output_i => clk_4x_logic_i, 
      pulse_o      => s_reset_timestamp_4x_ipbus
    );

  -- Combine reset timestamp from IPBus and external source
  -- purpose: combines resets from IPBus and external source onto clk_4x_logic_i
  -- type   : combinational
  -- inputs : clk_4x_logic_i
  -- outputs: s_reset_timestamp_4x
  p_combine_reset_timestamps: process (clk_4x_logic_i) is
  begin  -- process p_combine_reset_timestamps
    if rising_edge(clk_4x_logic_i) then
      s_reset_timestamp_4x_external_p2 <= reset_timestamp_i;
      s_reset_timestamp_4x_external_p1 <= s_reset_timestamp_4x_external_p2 ;
      s_reset_timestamp_4x_external    <= s_reset_timestamp_4x_external_p1 ;
      s_reset_timestamp_4x <= s_reset_timestamp_4x_external or s_reset_timestamp_4x_ipbus;
    end if;
  end process p_combine_reset_timestamps;
  
  reset_timestamp_o <= s_reset_timestamp_4x;
  
  -- Change control signals from IPBus clock domain on to clk_4x_logic
  -- CHANGE ME - use synchronize registers instead.
  p_signals_clk_domain: process (clk_4x_logic_i )
  begin  -- process p_internal_triggers
    if rising_edge(clk_4x_logic_i) then
      s_enable_record  <= s_enable_record_ipb;
		
      s_enable_trigger <= s_enable_record(0);
      s_enable_shutter <= s_enable_record(1);
      s_enable_spill <= s_enable_record(2);
      s_enable_edges <= s_enable_record(g_NUM_EDGE_INPUTS-1+3 downto 3);

      -- move  "reset fifo" and "buffer full"  signals onto clock4x domain
      s_rst_fifo_d1 <= rst_fifo_i;
      s_rst_fifo_d2 <= s_rst_fifo_d1;
      s_rst_fifo_clk4x <= s_rst_fifo_d2 ;
      s_buffer_full_d1 <= buffer_full_i;
      s_buffer_full_d2 <= s_buffer_full_d1;
      s_buffer_full_clk4x <= s_buffer_full_d2;  
      
    end if;
  end process p_signals_clk_domain;

  cmp_triggerEdgeDetect: entity work.single_pulse
    port map (
      level => trigger_i,
      clk => clk_4x_logic_i,
      pulse => s_trigger
      );
  
  -- purpose: generate delayed strobes and write enable flags to the FIFOs
  -- type   : combinational
  -- inputs : clk_4x_logic_i , s_FIFO_rd
  -- outputs: s_event_strobe_d1 , s_event_strobe_d2 , s_event_strobe_d3 , s_FIFO_rd_d , s_**_evttype
  p_ff_rst: process (clk_4x_logic_i)
  begin  -- process p_generate_strobes
    if rising_edge(clk_4x_logic_i) then      
      if s_rst_fifo_clk4x = '1' then
        s_event_strobe_d1 <= '0';
        s_event_strobe_d2 <= '0';
        s_event_strobe_d3 <= '0';
		
      else
        -- set s_event_strobe high if trigger_i is high and pipeline is empty
        -- ( i.e. all event_strobe are zero)

        s_event_strobe_d1 <= s_trigger and s_enable_trigger and not buffer_full_i and
                             (not s_event_strobe_d1 ) and (not s_event_strobe_d2 ) and (not s_event_strobe_d3 );
        s_event_strobe_d2 <= s_event_strobe_d1;
        s_event_strobe_d3 <= s_event_strobe_d2;
		
      end if;
    end if;
  end process p_ff_rst;
  
  p_ff: process (clk_4x_logic_i)
  begin  -- process p_generate_strobes
    if rising_edge(clk_4x_logic_i) then

		trigger_times_d1 <= trigger_times_i;

        s_word0 <= s_word0_p1;
		s_word0_d1 <= s_word0;
		s_word1_d1 <= s_word1;
		s_word1_d2 <= s_word1_d1;
		s_word2_d1 <= s_word2;
		s_word2_d2 <= s_word2_d1;
		s_word2_d3 <= s_word2_d2;
		
	end if;
  end process;
	
  -- If there are more than 4 trigger inputs we need to fill a second word.
  -- .. do this by having an optional strobe.
  -- If 4 or fewer trigger inputs, just leave s_event_strobe_d3_opt at zero..
  gen_strobe_d3: if (g_NUM_TRIG_INPUTS > 4) generate
    s_event_strobe_d3_opt <= s_event_strobe_d3;
  end generate;

-------------------------------------------------------------------------------
-- Trigger event formater
-------------------------------------------------------------------------------
  s_evttype <= "0000" when unsigned(trigger_inputs_fired_i) = 0 else "0001";

  --s_var <= trigger_inputs_fired_i & std_logic_vector(to_unsigned(0,s_var'length-g_NUM_TRIG_INPUTS));
  s_var <= std_logic_vector(to_unsigned(0,s_var'length-g_NUM_TRIG_INPUTS)) & trigger_inputs_fired_i; -- Pad with zeroes on the left.

  s_word0_p1 <= s_evttype & s_var & s_coarse_timestamp;
  
  s_word1 <= "000" & trigger_times_d1(0) & "000" & trigger_times_d1(1) &
             "000" & trigger_times_d1(2) & "000" & trigger_times_d1(3) &
             trigger_cnt_i;
				 
	
  -- Different number of trigger inputs require packing into s_word2 in
  -- different ways.
  -- Do this in a generate since g_NUM_TRIG_INPUTS is static and
  -- Questasim doesn't like refering to indices outside declared range.
    gen_word2_init: if (g_NUM_TRIG_INPUTS <= 4) generate
       s_word2 <= (others=>'0');
    end generate;
  --s_word2 <= (others=>'0'); -- Set all bits to zero
  -- then override with the following assignments....
    gen_word2: for v_trigInput in 4 to g_NUM_TRIG_INPUTS-1 generate
        s_word2( (((11-v_trigInput)*8)+c_NUM_TIME_BITS-1) downto ((11-v_trigInput)*8) ) <= trigger_times_i(v_trigInput);
    end generate;
  
      
  --! Could also output data on trigger_i , but let's use the delayed signals. \n
  --! The counters are one cycle delayed from the signal generation
  p_fifo_i : process (clk_4x_logic_i)
  begin  
    if rising_edge(clk_4x_logic_i) then
      data_strobe_o <= s_event_strobe_d1 or s_event_strobe_d2 or s_event_strobe_d3_opt;
      
      if s_event_strobe_d1 = '1' then
        event_data_o <= s_word0_d1;
      elsif s_event_strobe_d2 = '1' then
        event_data_o <= s_word1_d2;
      elsif s_event_strobe_d3_opt = '1' then
        event_data_o <= s_word2_d3;
      else
        event_data_o <= (others=>'0');
      end if;
    end if;
  end process;
		

  cmp_timeStampCounter: entity work.counterWithReset
    generic map (
      g_COUNTER_WIDTH => s_coarse_timestamp'length)
    port map (
      clock_i  => clk_4x_logic_i,
      reset_i  => s_reset_timestamp_4x or logic_reset_i,
      enable_i => logic_strobe_i,
      result_o => s_coarse_timestamp);
    
 
  -- Generate data in format decided at DESY. Put out two strobes for the
  -- two 64 bit words.
  -- get trigger inputs to also generate a global time-stamp ??
  -- add trigger_inputs_active_i array (to indicate which triggers fired)
  
END ARCHITECTURE rtl;

