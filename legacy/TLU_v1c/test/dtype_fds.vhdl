
--! @file dtype_fds.vhdl
--

--
library IEEE;

use IEEE.STD_LOGIC_1164.all;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group --
-- --
-------------------------------------------------------------------------------
--
-- unit name: dtype_fds
--
--! @brief   Aims to be the same as the Xilinx "FDS" primitive - D-Type flip-flop
--
--
--! @author David.Cussans@bristol.ac.uk
--
--! @date 7/May/2011
--
--! @version 0.1
--
--! @details -- Modified from D-type example in VHDL book.
--! See Xilinx spartan6_scm.pdf
--! Output goes high when input goes high ( asyncnronous to system clock).
--
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--! <reference one> \n
--! <reference two>
--!
--! <b>Modified by:</b>\n
--! Author: <name>
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! <date> <initials> <log>\n
--! <extended description>
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
-------------------------------------------------------------------------------

entity dtype_fds is

  port(
    Q : out std_logic;      --! Output
    CLK   : in std_logic;   --! Clock - rising edge active
    SET : in std_logic;     --! Active high, synchronous
    D   : in STD_LOGIC     --! Input
    );

end dtype_fds;

architecture rtl of dtype_fds is
begin

  VITALBehavior : process(CLK)
  begin

    if  rising_edge(CLK) then
      if (SET = '1') then
        Q <= '1';
      else
        Q <= D ;
      end if;
    end if;
  end process;

end rtl;

