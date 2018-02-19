-------------------------------------------------------------------------------
--! @file
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-------------------------------------------------------------------------------
--
-- VHDL for producing a single clock low-high-low pulse on the rising edge
-- of input signal (LEVEL)
--
-- David Cussans, Ocala, April 2005
--
-- LEVEL (input) - when LEVEL goes high, PULSE goes high for one clock cycle
--               - on next rising edge of CLK
-- CLK (input)   - rising edge active
-- PULSE         - changes on rising edge of clk
--
--! @brief gives a single cycle pulse ( high active) following the rising edge of LEVEL

entity single_pulse is
  generic (
    g_PRE_REGISTER  : boolean := false;  -- --! Set true to put a register before rising edge detect
    g_POST_REGISTER : boolean := false);  -- --! Set tru to put a register after rising edge detect
  port (
    level : in  std_logic; --! When LEVEL goes high, PULSE goes high for one clock cycle
    clk : in  std_logic; --! rising edge active
    pulse : out  std_logic              --! Pulses high for one cycle
    );
end entity single_pulse;

architecture rtl of single_pulse is

  signal pre_level, pre_pulse , x, v : std_logic;
  
begin  -- architecture rtl

  -----------------------------------------------
  -- Optional register on input
  -----------------------------------------------
  gen_pre_ff: if g_PRE_REGISTER=true generate
    ffpre: process (clk , level) is
    begin  -- process ff1
      if rising_edge(clk) then
        pre_level <= level;
      end if;
    end process ffpre;
  end generate gen_pre_ff;

  gen_no_pre_ff: if g_PRE_REGISTER=false generate
    pre_level <= level;
  end generate gen_no_pre_ff;

  -----------------------------------------------
  -- Register signal
  -----------------------------------------------  
  ff1: process (clk , level) is
  begin  -- process ff1
    if rising_edge(clk) then
      x <= pre_level;
    end if;
  end process ff1;

  -----------------------------------------------
  -- Edge detection logic
  -----------------------------------------------  
  ff2: process (clk , x) is
  begin  -- process ff2
    if rising_edge(clk) then
      v <= not x;
    end if;
  end process ff2;                           
                           
  pre_pulse <= ( x and v );


  -----------------------------------------------
  -- Optional register on output
  -----------------------------------------------
  gen_post_ff: if g_POST_REGISTER=true generate
    ffpost: process (clk , level) is
    begin  -- process ff1
      if rising_edge(clk) then
        pulse <= pre_pulse;
      end if;
    end process ffpost;
  end generate gen_post_ff;

  gen_no_post_ff: if g_POST_REGISTER=false generate
    pulse <= pre_pulse;
  end generate gen_no_post_ff;
  
end architecture rtl;
