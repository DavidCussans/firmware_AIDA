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
--! @brief Takes a pulse on input, stretches it and delays it.
--
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

--! Definition of trigger time
USE work.fmcTLU.all;                    

entity stretchPulse is
  
  generic (
    g_PARAM_WIDTH : positive := 5);  --! number of bits in parameters (width,  delay)

  port (
    clk_i        : in  std_logic;       --! Active high
    pulse_i      : in  std_logic;       --! Active high
    pulse_o      : out std_logic;       --! delayed and stretched
    triggerTime_i : in t_triggerTime;   --! 5-bit time
    triggerTime_o : out t_triggerTime;  --! Delayed by same amount as pulse
    
    pulseWidth_i : in  std_logic_vector(g_PARAM_WIDTH-1 downto 0);  --! Minimum pulse width ( in clock cycles )
    pulseDelay_i : in  std_logic_vector(g_PARAM_WIDTH-1 downto 0) --! Delay is pulseDelay_i +1 clock cycles
    );      

end entity stretchPulse;

-- For now just delay the pulse.
architecture rtl of stretchPulse is

  signal s_delaySR : std_logic_vector( (2**g_PARAM_WIDTH) -1 downto 0) := ( others => '0' );  -- --! Shift register to generate delay
  signal s_stretchSR : std_logic_vector( (2**g_PARAM_WIDTH) -1 downto 0) := ( others => '0' );  -- --! Shift register to generate stretch
  signal s_delayedPulse : std_logic := '0';  -- delayed pulse before stretch

  signal s_triggerTimeSR : t_triggerTimeArray ( (2**g_PARAM_WIDTH)-1 downto 0) := ( others => ( others => '0'));  -- array of trigger times
  signal s_triggerTime_d1 : t_triggerTime := ( others => '0');  -- shim out by one more clock cycle...
  signal s_stretchedTriggerTime : t_triggerTime := ( others => '0');  -- shim out by one more clock cycle...
  
begin  -- architecture rtl

  
  --! Delay pulse
  p_delayPulse: process (clk_i , pulse_i) is
  begin  -- process p_delayPulse
    if rising_edge(clk_i) then
      s_delaySR <= s_delaySR( (s_delaySR'left -1) downto 0 ) & pulse_i;
      s_delayedPulse <= s_delaySR( to_integer(unsigned(pulseDelay_i)) );

      -- delay the trigger time to match trigger delay
      s_triggerTimeSR <=  s_triggerTimeSR( (s_triggerTimeSR'left -1)  downto 0 ) & triggerTime_i;
      s_triggerTime_d1 <=  s_triggerTimeSR( to_integer(unsigned(pulseDelay_i)) ); 
--      triggerTime_o <= s_triggerTime_d1 ;
      
    end if;
  end process p_delayPulse;

  --! Stretch pulse. the output pulse is always at least as long as the input pulse
  p_stretchPulse: process (clk_i , pulse_i) is
  begin  -- process p_stretchPulse
    if rising_edge(clk_i) then
      if s_delayedPulse = '1' then
        s_stretchSR <= ( others => '1' ) ;
        pulse_o <= s_delayedPulse ;
      else
        s_stretchSR <= s_stretchSR( (s_stretchSR'left -1) downto 0 ) & '0';
        pulse_o <= s_stretchSR( to_integer(unsigned(pulseWidth_i)) );
      end if;

      if s_stretchSR( to_integer(unsigned(pulseWidth_i)) ) = '0' then
        --s_stretchedTriggerTime <= s_triggerTimeSR( to_integer(unsigned(pulseDelay_i)) );
        triggerTime_o <= s_triggerTime_d1;
      end if;
      --triggerTime_o <= s_stretchedTriggerTime ;
      
    end if;
  end process p_stretchPulse;

end architecture rtl;

