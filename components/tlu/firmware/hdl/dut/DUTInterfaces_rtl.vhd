--=============================================================================
--! @file DUTInterfaces_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.DUTInterfaces.rtl
--
--------------------------------------------------------------------------------
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
-- hds interface_start
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.ipbus.all;
use work.ipbus_reg_types.all;

library unisim;
use unisim.VComponents.all;

--! @brief Interfaces to Device Under Test (DUT) connectors.
--!
--! @author David Cussans , David.Cussans@bristol.ac.uk
--!
--! @date 15:09:50 11/09/12
--!
--! @version v0.1
--!
--! @details
--! \n\n IPBUS Address map:
--! \n (Decodes 4 bits)
--! \li 0x00000000 - DUT mask(write). 1 = active , 0 = inactive. Inactive DUT don't contribute to BUSY. One bit per DUT XXXXXXXXXXXXXXXXXXXXXXBA9876543210
--! \li 0x00000001 - Ignore DUT busy. 1 = ignore BUSY from this connector
--! \li 0x00000002 - Ignore shutter veto. 0 = raising shutter vetos triggers.
--! \li 0x00000003 - DUT interface mode, two bits per DUT. Up to 12 inputs  XXXXXXXXBBAA99887766554433221100 mode: 0 = EUDET mode , 1 = synchronous/AIDA ( LHC / Timepix ) , 2,3=reserved
--! \li 0x00000004 - DUT mode modifier: XXXXXXXXBBAA99887766554433221100 in EUDET mode: 0 = standard trigger/busy mode, 1 = raising BUSY outside handshake vetoes triggers
--! \li 0x00000008 - DUT mask ( read )
--! \li 0x0000000D - EUDET interface FSM status. Packed 4 bits per i/face ( read )
--!
--!
--! <b>Modified by:</b>\n
--! -----------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
-- todo  Indicate if the DUT works under AIDA/EUDET style
--
ENTITY DUTInterfaces IS
   GENERIC( 
      g_NUM_DUTS    : positive := 3;
      g_IPBUS_WIDTH : positive := 32
   );
   PORT( 
      clk_4x_logic_i          : IN     std_logic;
      strobe_4x_logic_i       : IN     std_logic;                                    --! goes high every 4th clock cycle
      trigger_counter_i       : IN     std_logic_vector (g_IPBUS_WIDTH-1 DOWNTO 0);  --! Number of trigger events since last reset
      trigger_i               : IN     std_logic;                                    --! goes high when trigger logic issues a trigger
      reset_or_clk_to_dut_i   : IN     std_logic;                                    --! Synchronization signal. Passed to DUT pins
      shutter_to_dut_i        : IN     std_logic;                                    --! Goes high to indicate data-taking active. DUTs report busy unless ignoreShutterVeto IPBus flag is set high
      -- IPBus signals.
      ipbus_clk_i             : IN     std_logic;
      ipbus_i                 : IN     ipb_wbus;                                     --! Signals from IPBus core to slave
      ipbus_reset_i           : IN     std_logic;
      ipbus_o                 : OUT    ipb_rbus;                                     --! signals from slave to IPBus core
      -- Signals to/from DUT
      busy_from_dut       : IN     std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! BUSY input from DUTs (single ended)
      busy_to_dut       : OUT     std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! BUSY input to DUTs (single ended)
      clk_from_dut  : IN std_logic_vector(g_NUM_DUTS-1 DOWNTO 0); --new signal for TLU, replace differential I/O
      clk_to_dut : OUT std_logic_vector(g_NUM_DUTS-1 DOWNTO 0); --new signal for TLU, replace differential I/O
      trigger_to_dut : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Trigger output
      
      --clk_to_dut_n_io         : INOUT  std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! clocks trigger data when in EUDET mode
      --clk_to_dut_p_io         : INOUT  std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! clocks trigger data when in EUDET mode
      --reset_or_clk_to_dut_n_o : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Either reset line or trigger
      --reset_or_clk_to_dut_p_o : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Either reset line or trigger
      reset_to_dut: OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Replaces reset_or_clk_to_dut
      --trigger_to_dut_n_o      : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Trigger output
      --trigger_to_dut_p_o      : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Trigger output
      --shutter_to_dut_n_o      : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Shutter output. Output 0 (RJ45) has no shutter signal
      --shutter_to_dut_p_o      : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Shutter output
      shutter_to_dut      : OUT    std_logic_vector (g_NUM_DUTS-1 DOWNTO 0);     --! Shutter output
      veto_o                  : OUT    std_logic                                     --! goes high when one or more DUT are busy or vetoed by shutter
   );

-- Declarations

END ENTITY DUTInterfaces ;
-- hds interface_end

--
ARCHITECTURE rtl OF DUTInterfaces IS

  signal s_intermediate_busy_or : std_logic_vector(g_NUM_DUTS downto 0);  -- OR tree


  signal s_clk_to_DUT , s_busy_from_dut , s_dut_veto , s_reset_or_clk_to_dut , s_trigger_to_dut , s_shutter_to_dut : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '0');
  signal s_clk_from_dut_eudet , s_busy_from_dut_eudet , s_dut_veto_eudet , s_reset_or_clk_to_dut_eudet , s_trigger_to_dut_eudet , s_shutter_to_dut_eudet : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '0');
  signal s_clk_to_DUT_AIDA , s_busy_from_dut_aida , s_dut_veto_aida , s_reset_or_clk_to_dut_aida , s_trigger_to_dut_aida , s_shutter_to_dut_aida : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '0');
  signal s_DUT_mask : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '0');   	--! Mask for the DUTs used. 1 = active
  signal s_dut_clk_is_output : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '1');  --! Set low to enable transmission of clock from TLU to DUT

  constant c_NUM_EUDET_FSM_BITS : positive := 4;
  signal s_dut_fsm_status_eudet : std_logic_vector((c_NUM_EUDET_FSM_BITS*g_NUM_DUTS)-1 downto 0) ; --! Stores status from EUDET interface FSM. Can only support up to 32/4 = 8 DUT interfaces, not 12...

  signal s_DUT_ignore_busy : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '0');  --! set bit to 1 for BUSY to be ignored.
  signal s_DUT_interface_mode : std_logic_vector((2*g_NUM_DUTS)-1 downto 0) := (others => '1'); --! sets AIDA/EUDET/whatever interface.
  signal s_DUT_aida_eudet_mode : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '1');  --! set bit to 1 for AIDA mode, 0 for EUDET
  signal s_dut_enable_veto_eudet : std_logic_vector(g_NUM_DUTS-1 downto 0) := (others => '1'); --! set bit high to allow asynchronous veto using DUT_CLK when in EUDET mode

  signal s_DUT_interface_mode_modifier : std_logic_vector((2*g_NUM_DUTS)-1 downto 0) := (others => '1');  
  signal s_IgnoreShutterVeto : std_logic := '0';  -- --! When high the shutter won't veto triggers when low.
  
  signal s_SPILL_delay : std_logic_vector(31 downto 0) := (others => '0');
  signal s_SPILL_wait : std_logic_vector(31 downto 0) := (others => '0');
  signal s_SPILL_width : std_logic_vector(31 downto 0) := (others => '0');

  
  -- Signal for IPBus
  constant c_N_CTRL : positive := 9;
  constant c_N_STAT : positive := 9;
  signal s_status_to_ipbus, s_sync_status_to_ipbus : ipb_reg_v(c_N_STAT-1 downto 0);
  signal s_control_from_ipbus,s_sync_control_from_ipbus : ipb_reg_v(c_N_CTRL-1 downto 0);
                                                               
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
  s_DUT_mask                    <= s_sync_control_from_ipbus(0)(g_NUM_DUTS-1 downto 0);
  s_DUT_ignore_busy             <= s_sync_control_from_ipbus(1)(g_NUM_DUTS-1 downto 0);
  s_IgnoreShutterVeto           <= s_sync_control_from_ipbus(2)(0);
  s_DUT_interface_mode          <= s_sync_control_from_ipbus(3)((2*g_NUM_DUTS)-1 downto 0);
  s_DUT_interface_mode_modifier <= s_sync_control_from_ipbus(4)((2*g_NUM_DUTS)-1 downto 0);
  
  
    -- Map the status registers
  s_status_to_ipbus(0) <= std_logic_vector(to_unsigned(0,g_IPBUS_WIDTH-g_NUM_DUTS)) & s_DUT_mask;
  s_status_to_ipbus(1) <= std_logic_vector(to_unsigned(0,g_IPBUS_WIDTH-g_NUM_DUTS)) & s_DUT_ignore_busy;
  s_status_to_ipbus(2) <= std_logic_vector(to_unsigned(0,g_IPBUS_WIDTH-1)) & s_IgnoreShutterVeto;
  s_status_to_ipbus(3) <= std_logic_vector(to_unsigned(0,g_IPBUS_WIDTH-(2*g_NUM_DUTS))) & s_DUT_interface_mode;
  s_status_to_ipbus(4) <= std_logic_vector(to_unsigned(0,g_IPBUS_WIDTH-(2*g_NUM_DUTS))) & s_DUT_interface_mode_modifier;
  s_status_to_ipbus(5) <= std_logic_vector(to_unsigned(0,g_IPBUS_WIDTH-( c_NUM_EUDET_FSM_BITS*g_NUM_DUTS))) & s_dut_fsm_status_eudet ;
  
  
  ------------------------------------------------------------------------------
  -- Instantiate BUFIODS  
  ------------------------------------------------------------------------------
  
  -- Loop through *all* DUTs ( including RJ45 )
  dut_clk_busy_trig_rst_io: for dut in 0 to g_NUM_DUTS-1 generate

------------------------------------------------------------------        
--    clk_IOBUFDS_inst : IOBUFDS
--      generic map (
--        IOSTANDARD => "BLVDS_25")
--      port map (
--        O => s_clk_from_dut_eudet(dut), --! Clock *from* DUT
--        IO => clk_to_dut_p_io(dut),  --! Diff_p dut clock I/O (connect directly to top-level port)
--        IOB => clk_to_dut_n_io(dut), --! Diff_n dut clock I/O (connect directly to top-level port)
--        I => s_clk_to_dut_aida(dut), --! Clock generated by TLU to DUT
--        T => s_dut_clk_is_output(dut) --! Set *low* to enable transmission of clock from TLU to DUT
--        );
    
        clk_to_dut(dut) <= s_clk_to_dut_aida(dut); -- do we need to disable this using T? No, the TLU now has enable signals.
        s_clk_from_dut_eudet(dut) <= clk_from_dut(dut);
        
------------------------------------------------------------------        
        -- Now the signals are single ended: remove IBUFDS and use IBUF
--    busy_IBUFDS_inst : IBUFDS
--      generic map (
--        DIFF_TERM => TRUE, -- Differential Termination 
--        IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
--        IOSTANDARD => "LVDS_25")
--      port map (
--        O => s_busy_from_dut(dut),  -- Buffer output
--        I => busy_from_dut_p_i(dut),  -- Diff_p buffer input (connect directly to top-level port)
--        IB => busy_from_dut_n_i(dut) -- Diff_n buffer input (connect directly to top-level port)
--      );

--    busy_IBUF_inst : IBUF
--    generic map(
--        IBUF_LOW_PWR => TRUE,
--        IOSTANDARD => "DEFAULT"
--    )
--    port map(
--        O => s_busy_from_dut(dut),
--        I => busy_from_dut(dut)
--    );
    s_busy_from_dut(dut) <= busy_from_dut(dut) ;
------------------------------------------------------------------        
   
--    trig_OBUFDS_inst : OBUFDS
--      generic map (
--        IOSTANDARD => "LVDS_25")
--      port map (
--        O =>  trigger_to_dut_p_o(dut),     						-- Diff_p output (connect directly to top-level port)
--        OB => trigger_to_dut_n_o(dut),   							-- Diff_n output (connect directly to top-level port)
--        I =>  s_trigger_to_dut(dut)     -- Buffer input 
--      );

    trigger_to_dut(dut) <= s_trigger_to_dut(dut);
------------------------------------------------------------------        
     
--    clk_rst_OBUFDS_inst : OBUFDS
--      generic map (
--        IOSTANDARD => "LVDS_25")
--      port map (
--        O =>  reset_or_clk_to_dut_p_o(dut),    							-- Diff_p output (connect directly to top-level port)
--        OB => reset_or_clk_to_dut_n_o(dut),   							-- Diff_n output (connect directly to top-level port)
--        I =>  s_reset_or_clk_to_dut(dut) 	--s_reset_or_clk_to_dut(dut) and s_DUT_mask(dut)     -- Buffer input 
--      );
	
	reset_to_dut(dut) <= s_reset_or_clk_to_dut(dut) and s_DUT_mask(dut); 
		 
  end generate dut_clk_busy_trig_rst_io;
  
  -- Loop through DUTs 
  dut_shutter_io: for dut in 0 to g_NUM_DUTS-1 generate

--    shutter_OBUFDS_inst : OBUFDS
--      generic map (
--        IOSTANDARD => "LVDS_25")
--      port map (
--        O =>  shutter_to_dut_p_o(dut), -- Diff_p output (connect directly to top-level port)
--        OB => shutter_to_dut_n_o(dut), -- Diff_n output (connect directly to top-level port)
--        I =>  s_shutter_to_dut(dut) 	
--        );
        
    shutter_to_dut(dut) <= s_shutter_to_dut(dut) ;	  
  end generate dut_shutter_io;


  ------------------------------------------------------------------------------
  -- Instantiate interfaces to DUTs  
  ------------------------------------------------------------------------------
  dut_interfaces: for dut in 0 to g_NUM_DUTS-1 generate

    --! AIDA style interface
    aida_dut_interface: ENTITY work.DUTInterface_AIDA
      generic map (
        g_IPBUS_WIDTH => g_IPBUS_WIDTH
        )
      PORT map ( 
        clk_4x_logic_i          => clk_4x_logic_i ,
        strobe_4x_logic_i       => strobe_4x_logic_i ,
        trigger_counter_i       => trigger_counter_i , 
        trigger_i               => trigger_i , 
        reset_or_clk_to_dut_i   => reset_or_clk_to_dut_i,
        shutter_to_dut_i        => shutter_to_dut_i ,
        ignore_shutter_veto_i   => s_IgnoreShutterVeto ,
        ignore_dut_busy_i       => s_DUT_ignore_busy(dut),
        --dut_mask_i              => s_DUT_mask(dut),
        busy_o                  => s_dut_veto_aida(dut),
      
        -- Signals to/from DUT
        dut_busy_i              => s_busy_from_dut(dut),
        dut_clk_o               => s_clk_to_dut_aida(dut),
        dut_reset_or_clk_o      => s_reset_or_clk_to_dut_aida(dut), 
        dut_shutter_o           => s_shutter_to_dut_aida(dut),
        dut_trigger_o           => s_trigger_to_dut_aida(dut)

        );

    --! EUDET style interface
    eudet_dut_interface: entity work.DUTInterface_EUDET
      GENERIC map ( 
        g_TRIGGER_DATA_WIDTH => g_IPBUS_WIDTH
        )
      port map (
        rst_i                 => ipbus_reset_i, 
        busy_o                => s_dut_veto_eudet(dut),
        fsm_state_value_o     => s_dut_fsm_status_eudet( (c_NUM_EUDET_FSM_BITS*(dut+1)-1) downto c_NUM_EUDET_FSM_BITS*(dut) ),
        trigger_i             => trigger_i , 
        trigger_counter_i     => trigger_counter_i , 
        system_clk_i          => clk_4x_logic_i ,
        reset_or_clk_to_dut_i => reset_or_clk_to_dut_i,
        shutter_to_dut_i      => shutter_to_dut_i ,
        ignore_shutter_veto_i => s_IgnoreShutterVeto ,
        enable_dut_veto_i     => s_dut_enable_veto_eudet(dut),
        -- Connections to DUT:
        dut_clk_i             => s_clk_from_dut_eudet(dut),
        dut_busy_i            => s_busy_from_dut(dut),
        dut_shutter_o         => s_shutter_to_dut_eudet(dut),
        dut_trigger_o         => s_trigger_to_dut_eudet(dut)
        );

    s_DUT_aida_eudet_mode(dut) <= s_DUT_interface_mode(2*dut);
    s_dut_enable_veto_eudet(dut) <= s_DUT_interface_mode_modifier(2*dut);
    
    -- Produce "OR" of veto/busy signals from DUTs, take into account IGNORE BUSY bit
    s_intermediate_busy_or(dut+1) <= s_intermediate_busy_or(dut) or ( s_dut_veto(dut) and (not s_DUT_ignore_busy(dut) ) );
    
  end generate dut_interfaces;

  s_dut_clk_is_output <= not s_DUT_aida_eudet_mode; -- at the moment can hardwire clk_is_output to mode_is_aida
                                               
  s_intermediate_busy_or(0) <= '0';
  veto_o <=  s_intermediate_busy_or(g_NUM_DUTS);

  -- purpose: Multiplexes signals between EUDET and AIDA interfaces
  -- type   : combinational
  -- inputs : clk_4x_logic_i 
  -- outputs: s_trigger_to_dut , s_reset_or_clk_to_dut , s_shutter_to_dut , s_dut_veto
  p_signal_mux: process (clk_4x_logic_i ) is
  begin  -- process p_signal_mux
    if rising_edge(clk_4x_logic_i) then
      s_trigger_to_dut <= (( s_trigger_to_dut_eudet and (not s_DUT_aida_eudet_mode)) or ( s_trigger_to_dut_aida and  s_DUT_aida_eudet_mode)) and s_DUT_mask ; -- move DutMask one level up to affect both AIDA and EUDET modes
      s_dut_veto <= (( s_dut_veto_eudet and (not s_DUT_aida_eudet_mode)) or ( s_dut_veto_aida and  s_DUT_aida_eudet_mode)) and s_DUT_mask ; -- move DutMask one level up to affect both AIDA and EUDET modes
      s_shutter_to_dut <= ( s_shutter_to_dut_eudet and (not s_DUT_aida_eudet_mode)) or ( s_shutter_to_dut_aida and  s_DUT_aida_eudet_mode) ; 
      s_reset_or_clk_to_dut <= ( s_reset_or_clk_to_dut_aida and  s_DUT_aida_eudet_mode) ; --! reset_or_clk line stays low if in EUDET mode
      
    end if;
  end process p_signal_mux;
  
END ARCHITECTURE rtl;

