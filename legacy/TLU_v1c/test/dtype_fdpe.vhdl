----- CELL dtype_fdpe                       -----
--
--@file
--
--@brief Aims to be the same as the Xilinx "FDPE" primitive -
-- D-Type flip-flop with asynchronous set.
--
-- Modified from D-type example in VHDL book.
-- See Xilinx spartan6_scm.pdf
--
-- David Cussans, Feb 2011
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;
-- use IEEE.VITAL_Timing.all;

entity dtype_fdpe is

  port(
    Q : out std_logic;      --! Output
    CLK   : in std_logic;   --! Clock - rising edge active
    D   : in std_logic;     --! Input
    CE  : in std_logic;     --! Clock enable
    PRE : in std_logic      --! Asynchronous preload
    );

end dtype_fdpe;

architecture dtype_V of dtype_fdpe is
begin

  VITALBehavior         : process(CLK, PRE , CE)
  begin

    if (PRE = '1') then
      Q <= '1';
    elsif ( rising_edge(CLK) and CE = '1' ) then
      Q <= D ;
    end if;
  end process;

end dtype_V;

