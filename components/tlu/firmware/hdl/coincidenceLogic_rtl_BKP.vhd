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
    auxTrigger_o     : out std_logic;  --! Goes high when auxillary trigger pattern matched
    triggerPattern_i : in  std_logic_vector(g_patternWidth-1 downto 0);  --! Pattern to match triggers with
    loadPattern_i    : in  std_logic);  --! Pattern is loaded when loadPattern goes high.

end entity coincidenceLogic;

architecture rtl of coincidenceLogic is

  signal s_configDataSR , s_configEnableSR: std_logic_vector( triggerPattern_i'range ) := ( others => '0' );  --! shift reg for config data
  signal s_configBit , s_configEnable : std_logic := '0';  --! Take high to shift in configuration data.
  signal s_trigOut , s_auxTrigOut : std_logic := '0';  -- registers for output data.
  
begin  -- architecture rtl

  --assert g_nInputs /= 4 report "Wrong number of inputs in coincidence logic" severity failure;
  --assert g_patternWidth /= 32 report "Wrong pattern width in coincidence logic" severity failure;

  -- See Xilinx UG615 ( Spartan-6 Libraries guide for HDL Designs"
  CFGLUT5_inst : CFGLUT5
    generic map (
      INIT => X"FFFEFFFE") --! Default to "OR" of all inputs
    port map (
      CDO => open, -- Reconfiguration cascade output
      O5 => s_trigOut ,  -- 4-LUT output
      O6 => s_auxTrigOut, -- 5-LUT output
      CDI => s_configBit, -- Reconfiguration data input
      CE => s_configEnable, -- Reconfiguration enable input
      CLK => configClk_i, -- Clock input
      I0 => triggers_i(0), -- Logic data input
      I1 => triggers_i(1), -- Logic data input
      I2 => triggers_i(2), -- Logic data input
      I3 => triggers_i(3), -- Logic data input
      I4 => '1' --! Tie high to set O5 and O6 to different functions.
      );

  p_controlInit: process (configClk_i , triggerPattern_i , loadPattern_i) is
  begin  -- process p_controlInit

    if rising_edge(configClk_i) then

      -- Contol configuration
      if ( loadPattern_i = '1' ) then -- Load pattern into shift register
        s_configDataSR <= triggerPattern_i;
        s_configEnableSR <= ( others => '1');
        s_configBit <= '0';
        s_configEnable <= '0';
      else -- If load isn't active then shift data out.
        s_configBit    <= s_configDataSR( s_configDataSR'left ); --! Shift in MSB first.
        s_configDataSR <= s_configDataSR( s_configDataSR'left-1 downto 0) & '0'; --! Shift up
        
        s_configEnable <= s_configEnableSR ( s_configEnableSR'left); --! enable will stay high for as long as there is data in config data SR
        s_configEnableSR <= s_configEnableSR( s_configEnableSR'left-1 downto 0) & '0'; --! Shift up
      end if;

  end if;
  end process p_controlInit;

  --! Register output data
  p_registerData: process (logicClk_i) is
  begin  -- process p_registerData
    if rising_edge(logicClk_i) then
      trigger_o <=  s_trigOut;
      auxTrigger_o <= s_auxTrigOut;
    end if;
  end process p_registerData;
  
end architecture rtl;

