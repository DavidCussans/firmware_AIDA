----- CELL dtype_fd                       -----
--
--@file
--
--@brief Aims to be the same as the Xilinx "FD" primitive -
-- D-Type flip-flop
--
-- Modified from D-type example in VHDL book.
-- See Xilinx spartan6_scm.pdf
--
-- David Cussans, Feb 2011
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dtype_fd is

  port(
    Q : out std_logic;      --! Output
    CLK   : in std_logic;   --! Clock - rising edge active
    D   : in std_logic     --! Input
    );

end dtype_fd;

architecture rtl of dtype_fd is
begin

  VITALBehavior         : process(CLK)
  begin

    if  rising_edge(CLK) then
      Q <= D ;
    end if;
  end process;

end rtl;

