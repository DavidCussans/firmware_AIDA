--! @file stretchPulse4x_rtl.vhd
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

--! @brief Takes a pulse on 4x clock and produces a pulse with a width
--!determined by clk_4x_strobe
--
--
--! @details
--! @author David Cussans

entity stretchPulse4x is
  port (
    clk_4x_i                    : in  std_logic;    --! system clock
    clk_4x_strobe_i               : in  std_logic;    --! strobes high for one cycle every 4 of clk_4x
    pulse_i                     : in  std_logic;    --! Input pulse
    pulse_o                     : out std_logic    --! Output pulse
    );
end entity stretchPulse4x;

architecture rtl of stretchPulse4x is

  signal s_pulse_in_rising_edge , s_stretchedPulse: std_logic; --! Shaped to be single cycle of clock 4x
  signal s_stretchedPulseSR , s_stretchedPulseSR_retimed : std_logic_vector(2 downto 0) := (others => '0');  --! shifted by clk4x
begin  -- architecture rtl


  --! Shape the input signal to be a single cycle of clk4x
  cmp_rising_edge: entity work.single_pulse
    generic map (
      g_PRE_REGISTER  => true,
      g_POST_REGISTER => true)
    port map (
      level => pulse_i,
      clk   => clk_4x_i,
      pulse => s_pulse_in_rising_edge);

  -- purpose: produces a pulse 4 cycles of clk4x wide that starts when clk4x_strobe is high
  -- type   : combinational
  -- inputs : clk_4x_i
  -- outputs: pulse_o
  p_pulseStretch: process (clk_4x_i) is
  begin  -- process p_pulseStretch
    if rising_edge(clk_4x_i) then
      if s_pulse_in_rising_edge = '1' then
        s_stretchedPulse <= '1';
        s_stretchedPulseSR <= "111";
      else
        s_stretchedPulse <= s_stretchedPulseSR(0);
        s_stretchedPulseSR <= '0' & s_stretchedPulseSR(s_stretchedPulseSR'left downto 1);
      end if;
    end if;
  end process p_pulseStretch;

  -- purpose: moves stretched pulse so that it aligns with clk_4x_strobe
  -- type   : combinational
  -- inputs : clk_4x_i
  -- outputs: pulse_o
  p_retimePulse: process (clk_4x_i) is
  begin  -- process p_retimePulse
    if rising_edge(clk_4x_i) and (clk_4x_strobe_i ='1') then
      pulse_o <= s_stretchedPulse;
    end if;
  end process p_retimePulse;
  
end architecture rtl;
