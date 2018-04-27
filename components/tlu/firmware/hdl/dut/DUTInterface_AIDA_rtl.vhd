--=============================================================================
--! @file DUTInterface_AIDA_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.DUTInterface_AIDA.rtl
--
--------------------------------------------------------------------------------
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

--! @brief "AIDA Style" Interface to a Device Under Test (DUT) connector.
--! factorized from original DUTInterfaces_rtl.vhd firmware.
--!
--! @author David Cussans , David.Cussans@bristol.ac.uk
--!
--! @date 1/Sept/2015
--!
--! @version v0.1
--!
--! @details
--

ENTITY DUTInterface_AIDA IS
   GENERIC( 
      g_IPBUS_WIDTH : positive := 32
   );
   PORT( 
      clk_4x_logic_i          : IN     std_logic;
      strobe_4x_logic_i       : IN     std_logic;      --! goes high every 4th clock cycle
      trigger_counter_i       : IN     std_logic_vector (g_IPBUS_WIDTH-1 DOWNTO 0);  --! Number of trigger events since last reset
      trigger_i               : IN     std_logic;      --! goes high when trigger logic issues a trigger
      reset_or_clk_to_dut_i   : IN     std_logic;      --! Synchronization signal. Passed to DUT pins
      shutter_to_dut_i        : IN     std_logic;      --! Goes high to indicate data-taking active. DUTs report busy unless ignore_shutter_veto  flag is set high
      ignore_shutter_veto_i   : in     std_logic;
      ignore_dut_busy_i       : in     std_logic;
      --dut_mask_i              : in     std_logic;      --! Set high if DUT is active. Moved one level up
      busy_o                  : OUT    std_logic;      --! goes high when DUT is busy or vetoed by shutter
      
      -- Signals to/from DUT
      dut_busy_i       : IN     std_logic;     --! BUSY input from DUTs
      dut_clk_o        : OUT    std_logic;     --! clocks trigger data when in EUDET mode
      dut_reset_or_clk_o : OUT    std_logic;     --! Either reset line or trigger
      dut_shutter_o      : OUT    std_logic;     --! Shutter output. Output 0 (RJ45) has no shutter signal
      dut_trigger_o      : OUT    std_logic     --! Trigger output

   );

-- Declarations

END ENTITY DUTInterface_AIDA ;

--
ARCHITECTURE rtl OF DUTInterface_AIDA IS

  signal s_strobe_4x_logic_d1 : std_logic;
  signal s_dut_clk : std_logic := '0';  -- Clock to be sent to DUT connectors ( before final register )
  signal s_dut_clk_sr : std_logic_vector(2 downto 0) := "001"; --! Gets shifted out by clk_4x logic. Loaded by strobe_4x_logic
  signal s_stretch_trig_in : std_logic := '0';  -- ! stretched version of trigger_i 
  signal s_stretch_trig_in_sr : std_logic_vector(2 downto 0) := "111"; --! Gets shifted out by clk_4x logic. Loaded by trigger_i
  signal s_trigger_out : std_logic := '0';  -- ! trigger shifted to start on strobe_4x_logic

  -- Set length of output trigger here ( output length = length of this vector + 1 ) 
  signal s_trigger_out_sr : std_logic_vector(2 downto 0) := ( others => '1'); --! Gets shifted out by clk_4x logic. Loaded by strobe_4x_logic.
  
                                                               
BEGIN

     
  -- Copy reset/clk signal straight through
  dut_reset_or_clk_o <= reset_or_clk_to_dut_i;

  dut_shutter_o <= shutter_to_dut_i;
      
  -- purpose: generates a clock from 4x clock and strobe ( high once every 4 cycles )
  -- should produce 11001100... etc. ie. 40MHz clock from 160MHz clock
  -- type   : combinational
  -- inputs : clk_4x_logic_i , strobe_4x_i
  -- outputs: s_dut_clk
  p_dut_clk_gen: process (clk_4x_logic_i , strobe_4x_logic_i) is
  begin  -- process p_dut_clk_gen
    if rising_edge(clk_4x_logic_i) then
      if (strobe_4x_logic_i = '1') then
        s_dut_clk <= '1';
        s_dut_clk_sr <= "001";
      else
        s_dut_clk <= s_dut_clk_sr(0);
        s_dut_clk_sr <= '0' & s_dut_clk_sr(s_dut_clk_sr'left downto 1);          
      end if;
    end if;
  end process p_dut_clk_gen;

  -- purpose: re-times a single cycle pulse on trigger on clk_4x_logic onto clk_logic 
  -- type   : combinational
  -- inputs : clk_4x_logic_i , strobe_4x_logic_i , trigger_i
  -- outputs: s_premask_trigger_to_dut
  p_dut_trig_retime: process (clk_4x_logic_i , strobe_4x_logic_i , trigger_i) is
  begin  -- process p_dut_trig_retime
    if rising_edge(clk_4x_logic_i)  then

      -- Stretch trigger_i pulse to 4 clock cycles on clk4x
      if trigger_i = '1' then
        s_stretch_trig_in <= '1';
        s_stretch_trig_in_sr <= ( others => '1' );
      else
        s_stretch_trig_in <= s_stretch_trig_in_sr(0);
        s_stretch_trig_in_sr <= '0' & s_stretch_trig_in_sr(s_stretch_trig_in_sr'left downto 1);
      end if;

      -- 
      if (strobe_4x_logic_i  = '1') and ( s_stretch_trig_in = '1' ) then
        s_trigger_out <= '1';
        s_trigger_out_sr <= ( others => '1' );
      else
        s_trigger_out <= s_trigger_out_sr(0);
        s_trigger_out_sr <= '0' & s_trigger_out_sr(s_trigger_out_sr'left downto 1);
      end if;
      
    end if;
  end process p_dut_trig_retime;

    
  -- purpose: register for internal signals and output signals
  -- type   : combinational
  -- inputs : clk_4x_logic_i , strobe_4x_logic_i , s_veto
  -- outputs: busy_o
  register_signals: process (clk_4x_logic_i)-- , strobe_4x_logic_i , s_veto)
  begin  -- process register_signals
    if rising_edge(clk_4x_logic_i) then

      s_strobe_4x_logic_d1 <= strobe_4x_logic_i;

      --busy_o <= ((not ignore_shutter_veto_i ) and (not shutter_to_dut_i)) or
      --          ((dut_busy_i and DUT_mask_i ) and (not ignore_dut_busy_i) );
                
      --busy_o <= ((not ignore_shutter_veto_i ) and (not shutter_to_dut_i)) or ( (dut_busy_i and DUT_mask_i )  );
      busy_o <= ((not ignore_shutter_veto_i ) and (not shutter_to_dut_i)) or ( dut_busy_i    );

      dut_clk_o <= s_dut_clk ;
      --dut_trigger_o <= DUT_mask_i and s_trigger_out;
      dut_trigger_o <= s_trigger_out;
      
    end if;
  end process register_signals;

  
END ARCHITECTURE rtl;

