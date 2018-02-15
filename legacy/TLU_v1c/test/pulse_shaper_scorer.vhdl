--=============================================================================
--! @file pulse_stretcher_scorer.vhdl
--=============================================================================

--! Standard library
Library IEEE;

--! Standard logic package
use IEEE.STD_LOGIC_1164.all;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group --
-- --
-------------------------------------------------------------------------------
--
-- unit name: pulse_stretcher_scoer
--
--! @brief Checks that pulse_shaper is behaving correctly.
--! Check for Output goes high when input goes high ( asyncnronous to system clock).
--! Output goes low again a controllable number of clock cycles later,
--! synchronous with the rising edge of the clock.
--! Gap of at least one clock cycle before output goes high again.
--
--! @author David.Cussans@bristol.ac.uk
--
--! @date 7/May/2011
--
--! @version 0.1
--
--! @details
--
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
--
-------------------------------------------------------------------------------
--! @todo  \n
--
-------------------------------------------------------------------------------

entity pulse_shaper_scorer is
  port (
    clk_i       : in std_logic;         -- ! system clock
    pulse_in_a_i  : in std_logic;         -- ! input ( unstretched) pulse
    pulse_out_a_i : in std_logic -- ! stretched pulse (output of pulse_stretcher)
    pulse_length_i : in std_logic_vector;      --! Parameter to pulse_strecher
    );  
end pulse_shaper_scorer;

architecture rtl of pulse_shaper_scorer is

  
begin  -- rtl

  
end rtl;
