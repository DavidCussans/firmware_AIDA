--=============================================================================
--! @file triggerLogic_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.triggerLogic.rtl
--
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.ipbus.all;
use work.ipbus_reg_types.all;

USE work.fmcTLU.all;

--! @brief Produces triggers from either trigger inputs or internal generator
--!
--! @author David Cussans , David.Cussans@bristol.ac.uk
--!
--! @date 16:06:19 11/09/12
--!
--! @version v0.1
--!
--! @details
--! \br IPBus address map:
--! \li 0x00000000 RO - Number of triggers issued since last reset.
--! \li 0x00000001 RO - Number of possible triggers since last reset (i.e. pre-veto triggers)
--! \li 0x00000010 RW - Interval between internal triggers in ticks of logic_strobe_i
--! \li 0x00000011 RW - trigger pattern - value that gets loaded into CFGLUT5
--! \li 0x00000100 RW - bit-0 - internal trigger veto. Set high to halt triggers.
--! \li 0x00000101 RO - state of external veto
--! \li 0x00000110 RW - stretch of pulses. Additional width = 0-31 clock cycles.
--! \li 0x00000111 RW - delay of pulses. 0-31 clock cycles.
--!
--! <b>Modified by: Alvaro Dosil , alvaro.dosil@usc.es </b>\n
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! Move all IPBus stuff into ipbus_syncreg_v , which also handles clock domain
--! crossing. 20/Feb/2014 , David Cussans
--! Add stretchPulse and coincidenceLogic entities. May/15 , David Cussans
-------------------------------------------------------------------------------
ENTITY triggerLogic IS
   GENERIC( 
      g_NUM_INPUTS  : positive := 4; 
      g_IPBUS_WIDTH : positive := 32 
   );
   PORT( 
      clk_4x_logic_i      : IN     std_logic;                                     -- ! Rising edge active
      ipbus_clk_i         : IN     std_logic;
      ipbus_i             : IN     ipb_wbus;                                      -- Signals from IPBus core to slave
      ipbus_reset_i       : IN     std_logic;
      logic_reset_i       : IN     std_logic;                                     -- active high. Synchronous with clk_4x_logic
      logic_strobe_i      : IN     std_logic;                                     -- ! Pulses high once every 4 cycles of clk_4x_logic
      trigger_i           : IN     std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);    -- ! High when trigger from input connector active
      trigger_times_i     : IN     t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);  --! trigger arrival time
      veto_i              : IN     std_logic;                                     -- ! Halts triggers when high
      trigger_o           : OUT    std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);    -- ! High when trigger from input connector active and enabled
      trigger_times_o     : OUT    t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);  --! trigger arrival time
      event_number_o      : OUT    std_logic_vector (g_IPBUS_WIDTH-1 DOWNTO 0);   -- starts at one. Increments for each post_veto_trigger
      ipbus_o             : OUT    ipb_rbus;                                      -- signals from slave to IPBus core
      post_veto_trigger_o : OUT    std_logic;                                     -- ! goes high when trigger passes
      pre_veto_trigger_o  : OUT    std_logic;
      trigger_active_o    : OUT    std_logic                                      --! Goes high when triggers are active ( ie. not veoted)
   );

-- Declarations

END triggerLogic ;

--
ARCHITECTURE rtl OF triggerLogic IS

    --! vector that stores trigger output for each combination of trigger inputs.
    signal s_trigger_inputs_enabled , s_trigger_inputs_enabled_ipb : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := x"00000001";--(others=>'1');  
    signal s_external_trigger_p , s_external_trigger_l , s_auxTrigger , s_internal_veto , s_internal_veto_ipb : std_logic := '0';
    signal s_internal_trigger_interval: std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- setting s_internal_trigger_interval to zero means no internal triggers
    signal s_pre_veto_trigger_counter , s_post_veto_trigger_counter , s_aux_trigger_counter: unsigned(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- ! counters for triggers before and after veto
    signal s_pre_veto_trigger_counter_ipb , s_post_veto_trigger_counter_ipb : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- ! counters for triggers before and after veto, on ipbus clock domain
    
    signal s_triggers : std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0) := (others=>'0');
    signal s_trigger_times : t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0) := (others=>(others=>'0'));
    signal s_internal_trigger, s_internal_trigger_d : std_logic := '0';  -- ! Strobes high for one clock cycle at intervals of s_internal_trigger_interval cycles
    --  signal s_internal_trigger_timer : unsigned(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- counter for internal trigger generation
    signal s_internal_trigger_timer , s_internal_trigger_timer_d : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- counter for internal trigger generation and counter delay
    signal s_internal_trigger_active , s_internal_trigger_active_d, s_internal_trigger_active_ipb : std_logic := '0';  -- ! Goes high when internal trigger is running.
    
    --  signal s_logic_reset ,  s_logic_reset_ipb : std_logic := '0';  -- ! Take high to reset counters etc.
    signal s_pre_veto_trigger ,s_post_veto_trigger : std_logic := '0';  -- ! Can't read from an output port so keep internal copy
    
    signal s_TriggerPattern_low : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  --! Pattern to load into LUT for trigger generation (low 32-bits)
    signal s_TriggerPattern_high : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  --! Pattern to load into LUT for trigger generation (high 32-bits)
    
    signal s_PulseStretchWord : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  --! Length of trigger pulses
    signal s_PulseWidthWord : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  --! Length of trigger pulses
    signal s_PulseDelayWord : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  --!number of cycles to delay trigger pulses.
    signal s_TriggerHoldOffWord : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0'); --! minimum number of clock cycles between triggers
    
    constant c_PARAM_WIDTH : positive := 5;    -- length of pulse width and delay.
    constant c_BYTE_WIDTH : positive := 5;    --Length of padded field for parameters. This should be at least equal to c_PARAM_WIDTH.
                                              --If c_BYTE_WIDTH= 8 then the values are aligned to bytes in the 32-bit word (but we cannot store 6 of them...)
                                              --If c_BYTE_WIDTH=5 then all the values are one after the other.
    
    constant c_N_CTRL : positive := 16;
    constant c_N_STAT : positive := 16;
    signal s_controlRegStrobes : std_logic_vector(c_N_CTRL-1 downto 0) := ( others => '0') ; --!
                                                                             --Bit strobes when control reg is loaded
    signal s_status_to_ipbus, s_sync_status_to_ipbus : ipb_reg_v(c_N_STAT-1 downto 0);
    signal s_control_from_ipbus,s_sync_control_from_ipbus  : ipb_reg_v(c_N_CTRL-1 downto 0);
    signal s_veto_word : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');
    signal s_external_veto_word : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');
    signal s_loadTriggerPattern , s_loadTriggerPattern_p1 : std_logic := '0';  -- take high to load trigger pattern
    signal s_loadTriggerPatternHi , s_loadTriggerPatternHi_p1 : std_logic := '0';  -- take high to load trigger pattern
    
    signal s_delayedTriggerTimes, s_delayedTriggerTimes_d1, s_delayedTriggerTimes_d2 : t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);  --! Array of std_logic_vectors
    signal s_stretchedTriggers ,  s_stretchedTriggers_d1 ,  s_stretchedTriggers_d2 : std_logic_vector( trigger_i'range) := (others => '0');  -- --! Triggers after stretch and delay
    
    COMPONENT internalTriggerGenerator
    PORT (
        CLK : IN STD_LOGIC;
        CE : IN STD_LOGIC;
        LOAD : IN STD_LOGIC;
        L : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Q : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;
  
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
        stb=> s_controlRegStrobes
    );

  -- Synchronize registers from logic clock to ipbus.
    sync_status: entity work.synchronizeRegisters
    generic map (
        g_NUM_REGISTERS => c_N_STAT )
    port map (
        clk_input_i => clk_4x_logic_i,
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
        clk_output_i => clk_4x_logic_i);

  -- Map the control registers
  -- workaround to match the number of clock cycles with the configured interval
    s_internal_trigger_interval <= x"00000000" when s_sync_control_from_ipbus(2)<x"00000005" else
										std_logic_vector(unsigned(s_sync_control_from_ipbus(2))-2);
										
    --s_TriggerPattern_low <= s_control_from_ipbus(3);
    s_LoadTriggerPattern_p1 <= s_controlRegStrobes(10);
    s_LoadTriggerPatternHi_p1 <= s_controlRegStrobes(11);
    s_veto_word <= s_sync_control_from_ipbus(4);
    s_internal_veto <= s_veto_word(0);
    s_PulseWidthWord <= s_sync_control_from_ipbus(6);
    s_PulseDelayWord <= s_sync_control_from_ipbus(7);
    s_TriggerHoldOffWord <= s_sync_control_from_ipbus(8);
    s_TriggerPattern_low <= s_control_from_ipbus(10);
    s_TriggerPattern_high <= s_control_from_ipbus(11);
    --s_PulseWidthWord <=s_sync_control_from_ipbus(10);
    
    s_external_veto_word(0) <= veto_i;
    s_external_veto_word(g_IPBUS_WIDTH-1 downto 1) <= (others=>'0');
    
    -- Map the status registers
    s_status_to_ipbus(0) <= std_logic_vector(s_post_veto_trigger_counter);
    s_status_to_ipbus(1) <= std_logic_vector(s_pre_veto_trigger_counter);
    s_status_to_ipbus(2) <= s_internal_trigger_interval;
    --s_status_to_ipbus(3) <= s_TriggerPattern_low;
    s_status_to_ipbus(4) <= s_veto_word;
    s_status_to_ipbus(5) <= s_external_veto_word;
    s_status_to_ipbus(6) <= s_PulseWidthWord; 
    s_status_to_ipbus(7) <= s_PulseDelayWord; --fixed in addr. map
    s_status_to_ipbus(8) <= s_TriggerHoldOffWord;
    s_status_to_ipbus(9) <= std_logic_vector(s_aux_trigger_counter);-- not used and never updated. Remove at some point.
    s_status_to_ipbus(10) <= s_TriggerPattern_low;
    s_status_to_ipbus(11) <= s_TriggerPattern_high;

    -- purpose: Delay pulse that loads trigger pattern by one cycle of IPBus clk.
    -- type   : combinational
    -- inputs : ipbus_clk_i
    -- outputs: 
    p_delayLoadPulse: process (ipbus_clk_i) is
    begin  -- process p_delayLoadPulse
    if rising_edge(ipbus_clk_i) then
        s_LoadTriggerPattern <= s_LoadTriggerPattern_p1;
        s_LoadTriggerPatternHi <= s_LoadTriggerPatternHi_p1;
    end if;
    end process p_delayLoadPulse;

  -- Stretch and delay pulses.
  --D Put in delay for trigger times as well.
  
    --
    gen_stretchVals: for v_inputNumber in 0 to g_NUM_INPUTS-1 generate
        cmp_stretchPulse: entity work.stretchPulse
        generic map (
            g_PARAM_WIDTH => c_PARAM_WIDTH)
        port map (
            clk_i         => clk_4x_logic_i,
            pulse_i       => trigger_i(v_inputNumber),
            pulse_o       => s_stretchedTriggers(v_inputNumber),
            triggerTime_i => trigger_times_i(v_inputNumber),
            triggerTime_o => s_delayedTriggerTimes(v_inputNumber),
    --        pulsewidth_i  => s_PulseStretchWord( (v_inputNumber*c_BYTE_WIDTH) + c_PARAM_WIDTH -1 downto v_inputNumber*c_BYTE_WIDTH ),
            pulsewidth_i  => s_PulseWidthWord( (v_inputNumber*c_BYTE_WIDTH) + c_PARAM_WIDTH -1 downto v_inputNumber*c_BYTE_WIDTH ),
            pulseDelay_i  => s_PulseDelayWord( (v_inputNumber*c_BYTE_WIDTH) + c_PARAM_WIDTH -1 downto v_inputNumber*c_BYTE_WIDTH )
    --        pulsewidth_i  => s_PulseStretchWord( (0*c_BYTE_WIDTH) + c_PARAM_WIDTH -1 downto 0*c_BYTE_WIDTH ),
    --        pulseDelay_i  => s_PulseDelayWord(   (0*c_BYTE_WIDTH) + c_PARAM_WIDTH -1 downto 0*c_BYTE_WIDTH )
            );
    end generate gen_stretchVals;

  --! Trigger coincidence logic 
    cmp_coincidence_logic : entity work.coincidenceLogic
    generic map(
        g_nInputs	=> g_NUM_INPUTS,
        g_patternWidth => g_IPBUS_WIDTH
    )
    Port map( 
        configClk_i 	=> ipbus_clk_i, --! No point in moving off IPBus clock
        logicClk_i        => clk_4x_logic_i,
        triggers_i 	=> s_stretchedTriggers,
        trigger_o         => s_external_trigger_l,
        --auxTrigger_o      => s_auxTrigger,
        -- Control ports...
        triggerPattern_low_i  => s_TriggerPattern_low,
        triggerPattern_high_i  => s_TriggerPattern_high,
        loadPatternHi_i     => s_loadTriggerPatternHi,
        loadPatternLo_i     => s_loadTriggerPattern
        );
	
  --! just look for the rising edge ( with long stretch can get multiple clock
  --! cycle triggers )
    cmp_triggerRisingEdge : entity work.single_pulse
    port map (
        level => s_external_trigger_l,
        clk => clk_4x_logic_i,
        pulse => s_external_trigger_p
        );
  
  --! Produce triggers....
    trigGen : process  ( clk_4x_logic_i ) 
    begin 
        if rising_edge(clk_4x_logic_i)  then 
            s_post_veto_trigger <= (s_external_trigger_p or s_internal_trigger) and (not ( s_internal_veto or veto_i) );
            s_pre_veto_trigger <= (s_external_trigger_p or s_internal_trigger);
    
            -- delay output of which input triggers fired so that they go high at the
            -- same time as the pre/post veto trigger signals.
            s_stretchedTriggers_d1 <= s_stretchedTriggers;
            s_stretchedTriggers_d2 <= s_stretchedTriggers_d1;
                                                            
            s_delayedTriggerTimes_d1 <= s_delayedTriggerTimes;
            s_delayedTriggerTimes_d2 <= s_delayedTriggerTimes_d1;
             
            trigger_o <= s_stretchedTriggers_d2;
            trigger_times_o <= s_delayedTriggerTimes_d2; -- trigger_times_i;  -- put delayed version of trigger times here
        end if;
    end process;
	

    pre_veto_trigger_o <= s_pre_veto_trigger ;
    post_veto_trigger_o <= s_post_veto_trigger;
    trigger_active_o <= s_post_veto_trigger;

	
	--! Internal trigger generator
    p_internal_triggers: process (clk_4x_logic_i )
    begin  -- process p_internal_triggers
        if rising_edge(clk_4x_logic_i) then
            if (s_internal_trigger_interval = x"00000000") then
                s_internal_trigger_active <= '0';
            else
                s_internal_trigger_active <= '1';
            end if;
        
            s_internal_trigger_active_d <= s_internal_trigger_active;    -- signal delayed
            s_internal_trigger_timer_d <= s_internal_trigger_timer;      -- Signal delayed
        end if;
    end process p_internal_triggers;
  
    s_internal_trigger <= '1' when (s_internal_trigger_timer = ( x"00000000" )) and (s_internal_trigger_timer_d = ( x"00000001" )) else '0';
				
				
				
    -- Use a coregen counter to allow timing constraints to be met.
    --c_internal_triggers: entity work.internalTriggerGenerator
    c_internal_triggers: internalTriggerGenerator
    PORT MAP (
        clk => clk_4x_logic_i,
        ce => s_internal_trigger_active,
        load => s_internal_trigger or (s_internal_trigger_active and not s_internal_trigger_active_d),
        l => s_internal_trigger_interval,
        q => s_internal_trigger_timer
    );
  
  -----------------------------------------------------------------------------
  -- Count triggers
  -----------------------------------------------------------------------------
    p_trigger_counter: process (clk_4x_logic_i )
    begin  -- process p_trigger_counter
        if rising_edge(clk_4x_logic_i) then
            if logic_reset_i = '1' then
                s_post_veto_trigger_counter <= ( others => '0');
            elsif s_post_veto_trigger = '1' then
                s_post_veto_trigger_counter <= s_post_veto_trigger_counter + 1;
            end if;
            
            if logic_reset_i = '1' then
                s_pre_veto_trigger_counter <= ( others => '0');
            elsif s_pre_veto_trigger = '1' then
                s_pre_veto_trigger_counter <= s_pre_veto_trigger_counter + 1;
            end if;
            
            --if logic_reset_i = '1' then
            --    s_aux_trigger_counter <= ( others => '0');
            --elsif s_auxTrigger = '1' then
            --    s_aux_trigger_counter <= s_aux_trigger_counter + 1;
            --end if;
        end if;
    end process p_trigger_counter;
 
    event_number_o <= std_logic_vector(s_post_veto_trigger_counter);
  
END ARCHITECTURE rtl;

