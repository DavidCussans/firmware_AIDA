--=============================================================================
--! @file stretchPulse_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.triggerLogic.rtl
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Include UNISIM to get CFGLUT5 definition
Library UNISIM;
use UNISIM.vcomponents.all;

--! @brief Takes a set of input pulses and produces an output pulse based on trigger
--! pattern. Defaults to "OR" of all inputs.
--!
--! @details If triggers_i matches a pattern in triggerPattern then trigger_o
--! goes high for one clock cycle of logicClk_o. Load a new pattern by taking loadPattern_i high for one cycle of configClk_i
--!
--! @author David Cussans
--! @date 2014
-------------------------------------------------------------------------------

entity coincidenceLogic is
  
  generic (
    g_nInputs      : positive := 4;  --! Number of trigger inputs. Must be four for this implementation
    g_patternWidth : positive := 32);  --! Width of trigger pattern. Must be 32 in this implementation

  port (
    configClk_i      : in  std_logic;   --! Rising edge active
    logicClk_i       : in  std_logic;   --! Rising edge active
    triggers_i       : in  std_logic_vector(g_nInputs-1 downto 0);  --! Array of trigger inputs
    trigger_o        : out std_logic;  --! Goes high when trigger pattern matched
    --auxTrigger_o     : out std_logic;  --! Goes high when auxillary trigger pattern matched
    triggerPattern_low_i : in  std_logic_vector(g_patternWidth-1 downto 0);  --! Pattern to match triggers with (lowest 32-bits)
    triggerPattern_high_i : in  std_logic_vector(g_patternWidth-1 downto 0);  --! Pattern to match triggers with (highest 32-bits)
    loadPatternHi_i    : in std_logic; --! Pattern (high 32 bits) is loaded when loadPatternHi goes high.
    loadPatternLo_i    : in  std_logic);  --! Pattern (low 32 bits) is loaded when loadPatternLo goes high.

end entity coincidenceLogic;

architecture rtl of coincidenceLogic is

  signal s_configDataSR_low , s_configEnableSR_low: std_logic_vector( triggerPattern_low_i'range ) := ( others => '0' );  --! shift reg for config data
  signal s_configDataSR_high , s_configEnableSR_high: std_logic_vector( triggerPattern_high_i'range ) := ( others => '0' );  --! shift reg for config data
  signal s_configBit_low, s_configBit_high, s_configEnable_low, s_configEnable_high : std_logic := '0';  --! Take high to shift in configuration data.
  signal s_trigOut_low, s_trigOut_high, s_auxTrigOut_low, s_auxTrigOut_high : std_logic := '0';  -- registers for output data. (s_auxTrig high and low should be removed)
  
begin  -- architecture rtl

  --assert g_nInputs /= 4 report "Wrong number of inputs in coincidence logic" severity failure;
  --assert g_patternWidth /= 32 report "Wrong pattern width in coincidence logic" severity failure;

  -- See Xilinx UG615 ( Spartan-6 Libraries guide for HDL Designs"
  -- We now need 6 inputs in the LUT and we need to dynamically change it so we merge two 5-inputs together:
  -- one does the low 32 bits of the address table, the other the high 32 bits.
  LUT_low : CFGLUT5
    generic map (
      INIT => X"FFFEFFFE") --! Default to "OR" of all inputs (exclude case with no input at all)
    port map (
      CDO => open, -- Reconfiguration cascade output
      O5 => open ,  -- 4-LUT output
      O6 => s_trigOut_low, -- 5-LUT output
      CDI => s_configBit_low, -- Reconfiguration data input
      CE => s_configEnable_low, -- Reconfiguration enable input
      CLK => configClk_i, -- Clock input
      I0 => triggers_i(0), -- Logic data input
      I1 => triggers_i(1), -- Logic data input
      I2 => triggers_i(2), -- Logic data input
      I3 => triggers_i(3), -- Logic data input
      I4 => triggers_i(4) --! Tie high to set O5 and O6 to different functions.
      );
   
   LUT_high : CFGLUT5
    generic map (
        INIT => X"FFFFFFFF") --! Default to "OR" of all inputs
    port map (
        CDO => open, -- Reconfiguration cascade output
        O5 => open ,  -- 4-LUT output
        O6 => s_trigOut_high, -- 5-LUT output
        CDI => s_configBit_high, -- Reconfiguration data input
        CE => s_configEnable_high, -- Reconfiguration enable input
        CLK => configClk_i, -- Clock input
        I0 => triggers_i(0), -- Logic data input
        I1 => triggers_i(1), -- Logic data input
        I2 => triggers_i(2), -- Logic data input
        I3 => triggers_i(3), -- Logic data input
        I4 => triggers_i(4) --! Tie high to set O5 and O6 to different functions.
    );   

  p_controlInitLo: process (configClk_i , triggerPattern_low_i , loadPatternLo_i) is
  begin  -- process p_controlInit

    if rising_edge(configClk_i) then

      -- Control configuration
      if ( loadPatternLo_i = '1' ) then -- Load pattern into shift register
        s_configDataSR_low <= triggerPattern_low_i;
        s_configEnableSR_low <= ( others => '1');
        s_configBit_low <= '0';
        s_configEnable_low <= '0';
      else -- If load isn't active then shift data out.
        s_configBit_low    <= s_configDataSR_low( s_configDataSR_low'left ); --! Shift in MSB first.
        s_configDataSR_low <= s_configDataSR_low( s_configDataSR_low'left-1 downto 0) & '0'; --! Shift up
                
        s_configEnable_low <= s_configEnableSR_low ( s_configEnableSR_low'left); --! enable will stay high for as long as there is data in config data SR
        s_configEnableSR_low <= s_configEnableSR_low( s_configEnableSR_low'left-1 downto 0) & '0'; --! Shift up
      end if;

  end if;
  end process p_controlInitLo;
  
  -- Add a second control for the secondary LUT introduced when we moved to 6 inputs.
  p_controlInitHi: process (configClk_i , triggerPattern_high_i,  loadPatternHi_i) is
    begin  -- process p_controlInit
  
      if rising_edge(configClk_i) then
  
        -- Control configuration
        if ( loadPatternHi_i = '1' ) then -- Load pattern into shift register
          s_configDataSR_high <= triggerPattern_high_i;
          s_configEnableSR_high <= ( others => '1');
          s_configBit_high <= '0';
          s_configEnable_high <= '0';
        else -- If load isn't active then shift data out.
          s_configBit_high    <= s_configDataSR_high( s_configDataSR_high'left ); --! Shift in MSB first.
          s_configDataSR_high <= s_configDataSR_high( s_configDataSR_high'left-1 downto 0) & '0'; --! Shift up
                  
          s_configEnable_high <= s_configEnableSR_high ( s_configEnableSR_high'left); --! enable will stay high for as long as there is data in config data SR
          s_configEnableSR_high <= s_configEnableSR_high( s_configEnableSR_high'left-1 downto 0) & '0'; --! Shift up
        end if;
  
    end if;
    end process p_controlInitHi;

  --! Register output data
  p_registerData: process (logicClk_i) is
  begin  -- process p_registerData
    if rising_edge(logicClk_i) then
        if triggers_i(5) = '0' then -- the LUT has 5 inputs. We use a MUX to considere the 6th one (triggers_i(5)).
            trigger_o <=  s_trigOut_low;
            --auxTrigger_o <= s_auxTrigOut_low;
        else
            trigger_o <=  s_trigOut_high;
            --auxTrigger_o <= s_auxTrigOut_high;
        end if;
    end if;
  end process p_registerData;
  
end architecture rtl;

