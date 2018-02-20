--! @file DelayPulse4x_rtl.vhd
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

--! @brief Takes a pulse on 4x clock , delays it and produces a pulse with a width determined by clk_4x_strobe
--
--
--! @details
--! @author David Cussans

entity DelayPulse4x is
  generic (
    g_MAX_WIDTH : positive := 32);
  port (
    clk_4x_i                    : in  std_logic;    --! system clock
    clk_4x_strobe_i               : in  std_logic;    --! strobes high for one cycle every 4 of clk_4x
    delay_cycles_i              : in std_logic_vector(g_MAX_WIDTH-1 downto 0); --! Number of strobes of clk_4x_strobe to delay pulse by
    pulse_i                     : in  std_logic;    --! Input pulse
    pulse_o                     : out std_logic    --! Output pulse
    );
end entity DelayPulse4x;

architecture rtl of DelayPulse4x is

  signal s_retimed_pulse : std_logic := '0';  --! 4 cycles of clk_4x_i , synchronized by 4x strobe
  signal s_counting_down_n, s_counting_down_n_d1 : std_logic := '0';  --! low if delay is counting down
  
begin  -- architecture rtl

  cmp_stretchPulse: entity work.stretchPulse4x
    port map (
      clk_4x_i        => clk_4x_i,
      clk_4x_strobe_i => clk_4x_strobe_i,
      pulse_i         => pulse_i,
      pulse_o         => s_retimed_pulse);

  cmp_counter: entity work.counterDownGated
    generic map (
      g_MAX_WIDTH => g_MAX_WIDTH)
    port map (
      clk_i     => clk_4x_i,
      Gate_i    => clk_4x_strobe_i,
      Reset_i   => '0',
      Load_i    => s_retimed_pulse,
      InitVal_i => delay_cycles_i,
      Count_o   => open,
      Q_o       => s_counting_down_n);

  
  -- purpose: detects rising edge of s_counting_down_n
  -- type   : combinational
  -- inputs : clk_4x_i
  -- outputs: pulse_o
  p_fallingEdge: process (clk_4x_i) is
  begin  -- process p_fallingEdge
    if rising_edge(clk_4x_i) and (clk_4x_strobe_i = '1') then
      if s_counting_down_n = '1' and s_counting_down_n_d1 = '0' then
        pulse_o <= '1';
      else
        pulse_o <= '0';
      end if;
      s_counting_down_n_d1 <= s_counting_down_n;
    end if;
  end process p_fallingEdge;
  

end architecture rtl;
