--=============================================================================
--! @file triggerInputs_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.triggerInputs.rtl
--
--------------------------------------------------------------------------------
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.ipbus.all;
USE work.ipbus_reg_types.all;
USE work.fmcTLU.all;


library unisim ;
use unisim.vcomponents.all;

--! @brief Measures arrival time of trigger pulses using two deserializers
--! clocked on 14x clock ( 640MHz) 
--! Based on TDC code by Alvaro Dosil
--!
--! @author David Cussans , David.Cussans@bristol.ac.uk
--!
--!
--! @date 15:43:57 11/08/12
--!
--! @version v0.1
--!
--! @details
--! \li IPBus address 0 = control and status
--!  \li bit0 = reset serdes
--!  \li bit1 = reset counter
--!  \li bit2 = calibrate IDELAYs
--!  \li bit3 = not connected
--!  \li bit4 = Thresh discr  IDelay(0) status prompt
--!  \li bit5 = Thresh discr  IDelay(0) status delayed
--!  \li bit6 = Thresh discr  IDelay(1) status prompt
--!  \li bit7 = Thresh discr  IDelay(1) status delayed
--!  \li bit8 = Thresh discr  IDelay(2) status prompt
--!  \li bit9 = Thresh discr  IDelay(2) status delayed
--!  \li bit10= Thresh discr  IDelay(3) status prompt
--!  \li bit11= Thresh discr  IDelay(3) status delayed
--!  \li bit12= CFD discr  IDelay(0) status prompt
--!  \li bit13= CFD discr  IDelay(0) status delayed
--!  \li bit14= CFD discr  IDelay(1) status prompt
--!  \li bit15= CFD discr  IDelay(1) status delayed
--!  \li bit16= CFD discr  IDelay(2) status prompt
--!  \li bit17= CFD discr  IDelay(2) status delayed
--!  \li bit18= CFD discr  IDelay(3) status prompt
--!  \li bit19= CFD discr  IDelay(3) status delayed
--!  \li bit20= Thresh deserialized data monitor(0)
--!  \li bit21= Thresh deserialized data monitor(1)
--!  \li bit22= Thresh deserialized data monitor(2)
--!  \li bit23= Thresh deserialized data monitor(3)
--!  \li bit24= CFD deserialized data monitor(0)
--!  \li bit25= CFD deserialized data monitor(1)
--!  \li bit26= CFD deserialized data monitor(2)
--!  \li bit27= CFD deserialized data monitor(3)
--!
--! \li IPBus address 1 = edge rising(0) counter
--! \li IPBus address 2 = edge rising(1) counter
--! \li IPBus address 3 = edge rising(2) counter
--! \li IPBus address 4 = edge rising(3) counter
--!
--!
--! <b>Modified by: Alvaro Dosil , alvaro.dosil@usc.es </b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo Implement a periodic calibration sequence 
--

ENTITY triggerInputs_newTLU IS
   GENERIC( 
      g_NUM_INPUTS  : natural  := 1;--1
      g_IPBUS_WIDTH : positive := 32
   );
   PORT( 
      --cfd_discr_p_i        : IN     std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --! Inputs from constant-fraction discriminators
      --cfd_discr_n_i        : IN     std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --! Input from CFD
      clk_4x_logic         : IN     std_logic;                                          --! Rising edge active. By default = 4*40MHz = 160MHz
      clk_200_i : IN     std_logic;
      strobe_4x_logic_i    : IN     std_logic;                                          --! Pulses high once every 4 cycles of clk_4x_logic
      threshold_discr_p_i  : IN     std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --! inputs from threshold comparators
      threshold_discr_n_i  : IN     std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --! inputs from threshold comparators
      reset_i              : IN     std_logic;
      trigger_times_o      : OUT    t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);       --! trigger arrival time ( w.r.t. logic_strobe)
      trigger_o            : OUT    std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --!  Goes high on leading edge of trigger, in sync with clk_4x_logic_i
      --trigger_debug_o      : OUT    std_logic_vector ( ((2*g_NUM_INPUTS)-1) DOWNTO 0);  --! Copy of input trigger level. High bits CFD, Low threshold
      edge_rising_times_o  : OUT    t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);       --! edge arrival time ( w.r.t. logic_strobe)
      edge_falling_times_o : OUT    t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);       --! edge arrival time ( w.r.t. logic_strobe)
      edge_rising_o        : OUT    std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --! High when rising edge. Syncronous with clk_4x_logic_i
      edge_falling_o       : OUT    std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);         --! High when falling edge
      ipbus_clk_i          : IN     std_logic;
      ipbus_reset_i        : IN     std_logic;
      ipbus_i              : IN     ipb_wbus;                                           --! Signals from IPBus core to slave
      ipbus_o              : OUT    ipb_rbus;                                           --! signals from slave to IPBus core
      clk_8x_logic_i      : IN     std_logic;                                          --! 320MHz clock ( 8x 40MHz )
      strobe_8x_logic_i   : IN     std_logic                                           --! Pulses one cycle every 4 of 8x clock.
   );

-- Declarations
END triggerInputs_newTLU ;

--
ARCHITECTURE rtl OF triggerInputs_newTLU IS
  
    signal s_rst_iserdes : std_logic := '0'; --! Reset ISERDES and IDELAY
    signal s_threshold_discr_input , s_thr_in_p, s_thr_in_n : std_logic_vector(g_NUM_INPUTS-1 downto 0);  --! inputs from comparator
    type t_deserialized_trigger_data_array is array ( natural range <> ) of std_logic_vector(7 downto 0); --
    signal s_deserialized_threshold_data, s_deserialized_threshold_data_d , s_deserialized_cfd_data, s_deserialized_cfd_data_d : t_deserialized_trigger_data_array(g_NUM_INPUTS-1 downto 0);
    type t_deserialized_trigger_data_array_l is array ( natural range <> ) of std_logic_vector(8 downto 0); --
    signal s_deserialized_threshold_data_l , s_deserialized_cfd_data_l : t_deserialized_trigger_data_array_l(g_NUM_INPUTS-1 downto 0);
    --signal s_cfd_trigger_times              : t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);
    --signal s_CFD_rising_edge                : std_logic_vector(g_NUM_INPUTS-1 downto 0); 
    --signal s_CFD_falling_edge               : std_logic_vector(g_NUM_INPUTS-1 downto 0); 
    signal s_threshold_previous_late_bit    : std_logic_vector(g_NUM_INPUTS-1 downto 0) := (others => '0');  -- last bit to arrive from previous 4
    --signal s_CFD_previous_late_bit          : std_logic_vector(g_NUM_INPUTS-1 downto 0) := (others => '0');  -- last bit to arrive from previous 4
    signal s_ipbus_ack                      : std_logic := '0';  -- used to produce a delayed IPBus ack signal
    signal s_edge_rising_times:   t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);  --! edge arrival time ( w.r.t. logic_strobe)
    signal s_edge_falling_times:  t_triggerTimeArray (g_NUM_INPUTS-1 DOWNTO 0);  --! edge arrival time ( w.r.t. logic_strobe)
    signal s_edge_rising:         std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);    --! High when rising edge
    signal s_edge_falling:        std_logic_vector (g_NUM_INPUTS-1 DOWNTO 0);    --! High when falling edge
    constant c_N_CTRL : positive := 1;
    constant c_N_STAT : positive := g_NUM_INPUTS+1 ;
    signal s_status_to_ipbus , s_sync_status_to_ipbus: ipb_reg_v(c_N_STAT-1 downto 0);
    signal s_control_from_ipbus , s_sync_control_from_ipbus: ipb_reg_v(c_N_CTRL-1 downto 0);
    --  signal s_reset_reg , s_status_reg: std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others => '0');
    signal s_counter_reset, s_calibrate_idelay: std_logic := '0';
  
BEGIN
    -----------------------------------------------------------------------------
    -- IPBus interface 
    -----------------------------------------------------------------------------

    -- Can't get ipbus_syncreg_v to meet timing. So use non-syncronized followed
    -- by synchronizer.
    ipbus_registers: entity work.ipbus_ctrlreg_v
    generic map (
        N_STAT =>  c_N_STAT )
    port map(
        clk=> ipbus_clk_i,
        reset => ipbus_reset_i ,
        ipbus_in =>  ipbus_i,
        ipbus_out => ipbus_o,
        d=>  s_sync_status_to_ipbus,
        q=>  s_control_from_ipbus,
        stb => open
        );

    -- sync data from I/O logic to IPBus
    sync_registers: entity work.synchronizeRegisters
    generic map (
        g_NUM_REGISTERS => c_N_STAT )
    port map (
        clk_input_i => clk_4x_logic,
        data_i      => s_status_to_ipbus,
        data_o      => s_sync_status_to_ipbus,
        clk_output_i => ipbus_clk_i);

    -- sync data from I/O logic to IPBus
    sync_ipbus: entity work.synchronizeRegisters
    generic map (
        g_NUM_REGISTERS => c_N_CTRL )
    port map (
        clk_input_i => ipbus_clk_i,
        data_i      => s_control_from_ipbus,
        data_o      => s_sync_control_from_ipbus,
        clk_output_i => clk_4x_logic);

    -- Map the control registers...
    -- Register that controls IODELAY and ISERDES reset is at address 0
    s_rst_iserdes <= reset_i or s_sync_control_from_ipbus(0)(0);
    s_counter_reset <= s_sync_control_from_ipbus(0)(1);
    s_calibrate_idelay <= s_sync_control_from_ipbus(0)(2);
  
    s_status_to_ipbus(0)(0) <= s_rst_iserdes;
    s_status_to_ipbus(0)(1) <= s_counter_reset;
    s_status_to_ipbus(0)(2) <= s_calibrate_idelay;
    -- Connect up unused lines in status regiser to 0.
    s_status_to_ipbus(0)(3) <= '0';
    s_status_to_ipbus(0)(g_IPBUS_WIDTH-1 downto 28) <= (others => '0');

    -----------------------------------------------------------------------------
    -- Connect up trigger inputs to deserializers and a LUT to determine
    -- arrival time
    -----------------------------------------------------------------------------
    idelaytriggers0: idelayctrl port map(
          refclk => clk_200_i,
          rst => reset_i
    );
 
    --BEGIN FOR LOOP
    trigger_input_loop: for triggerInput in 0 to (g_NUM_INPUTS-1) generate

--        thresholdInputBuffer: IBUFDS
--          generic map (
--            DIFF_TERM        => true,
--            IBUF_LOW_PWR     => false,
--            IOSTANDARD       => "LVDS_25")
--          port map (
--            O  => s_threshold_discr_input(triggerInput),
--            I  => threshold_discr_p_i(triggerInput),
--            IB => threshold_discr_n_i(triggerInput)
--            );
    
        IBUFDS_DIFF_OUT_inst : IBUFDS_DIFF_OUT
        generic map (
            IBUF_LOW_PWR => false,
            IOSTANDARD       => "LVDS_25"
        )
        port map (
            O => s_thr_in_p(triggerInput),
            OB => s_thr_in_n(triggerInput),
            I => threshold_discr_p_i(triggerInput),
            IB => threshold_discr_n_i(triggerInput)
        );
            
        thresholdDeserializer: entity work.dualSERDES_1to4
        port map (
            reset_i 			=> s_rst_iserdes,
            --calibrate_i 		=> s_calibrate_idelay,
            --data_i         => s_threshold_discr_input(triggerInput),
            data_i         => '0',
            data_i_pos     => s_thr_in_p(triggerInput),
            data_i_neg     => s_thr_in_n(triggerInput),
            fastClk_i      => clk_8x_logic_i,
            fabricClk_i    => clk_4x_logic,
            strobe_i       => strobe_8x_logic_i,
            data_o         => s_deserialized_threshold_data(triggerInput),
            status_o       => s_status_to_ipbus(0)(5+(2*triggerInput) downto 4+(2*triggerInput))
        );
                  
        s_deserialized_threshold_data_l(triggerInput) <= s_deserialized_threshold_data(triggerInput) & s_threshold_previous_late_bit(triggerInput);
            
        thresholdLUT : entity work.arrivalTimeLUT
        port map (
            clk_4x_logic_i      => clk_4x_logic,
            strobe_4x_logic_i   => strobe_4x_logic_i,
            deserialized_data_i => s_deserialized_threshold_data_l(triggerInput),
            first_rising_edge_time_o => s_edge_rising_times(triggerInput), 
            last_falling_edge_time_o => s_edge_falling_times(triggerInput), 
            rising_edge_o       => s_edge_rising(triggerInput), 
            falling_edge_o      => s_edge_falling(triggerInput),
            multiple_edges_o    => open
        );
        
        -- The leading edge may be a high-->low or a low-->high transition (
        -- depending on polarity of input signal. ). For now assume that leading
        -- edge is low-->high and connect trigger times and trigger output accordingly.
        -- In the future have this selectable.
        edge_rising_times_o(triggerInput) <= s_edge_rising_times(triggerInput);
        edge_falling_times_o(triggerInput) <= s_edge_falling_times(triggerInput);
        edge_rising_o(triggerInput) <= s_edge_rising(triggerInput);
        edge_falling_o(triggerInput) <= s_edge_falling(triggerInput);
        trigger_times_o(triggerInput) <= s_edge_rising_times(triggerInput);
        trigger_o(triggerInput) <= s_edge_rising(triggerInput);
            
    
        p_register_delayed_bits : process ( clk_4x_logic ) 
        begin 
            if rising_edge(clk_4x_logic) then
                s_threshold_previous_late_bit(triggerInput) <= s_deserialized_threshold_data(triggerInput)(7);
                --s_CFD_previous_late_bit(triggerInput) <= s_deserialized_CFD_data(triggerInput)(7);
                -- Monitor output of serdes - just look at one per serdes
                -- Don't care about latency so put a couple of registers in to aid
                -- timing closure.
                s_status_to_ipbus(0)(20+triggerInput) <= s_threshold_previous_late_bit(triggerInput);
                --s_status_to_ipbus(0)(24+triggerInput) <= s_CFD_previous_late_bit(triggerInput);
            end if ; 
        end process;
        
        --! Instantiate counter for output triggers.
        --! Input I is connected to address I+1
        cmp_inputTriggerCounter : entity work.counterWithReset
        generic map (
            g_COUNTER_WIDTH => g_IPBUS_WIDTH)
        port map (
            clock_i  => clk_4x_logic,
            reset_i  => s_counter_reset,
            enable_i => s_edge_rising(triggerInput),
            result_o => s_status_to_ipbus(triggerInput+1)
        );
    end generate trigger_input_loop;
  --END FOR LOOP
  
  --trigger_debug_o( (g_NUM_INPUTS-1) downto 0) <= s_threshold_discr_input;
  --trigger_debug_o( ((2*g_NUM_INPUTS)-1) downto g_NUM_INPUTS) <=  s_edge_rising;
  
END ARCHITECTURE rtl;

