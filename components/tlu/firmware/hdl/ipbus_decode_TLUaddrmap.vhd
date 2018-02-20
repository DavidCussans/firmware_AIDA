-- Address decode logic for ipbus fabric
-- 
-- This file has been AUTOGENERATED from the address table - do not hand edit
-- 
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
-- 
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package ipbus_decode_TLUaddrmap is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_TLUaddrmap(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Mon Feb 19 12:09:48 2018 
  constant N_SLV_VERSION: integer := 0;
  constant N_SLV_DUTINTERFACES: integer := 1;
  constant N_SLV_SHUTTER: integer := 2;
  constant N_SLV_I2C_MASTER: integer := 3;
  constant N_SLV_EVENTBUFFER: integer := 4;
  constant N_SLV_EVENT_FORMATTER: integer := 5;
  constant N_SLV_TRIGGERINPUTS: integer := 6;
  constant N_SLV_TRIGGERLOGIC: integer := 7;
  constant N_SLV_LOGIC_CLOCKS: integer := 8;
  constant N_SLAVES: integer := 9;
-- END automatically generated VHDL

    
end ipbus_decode_TLUaddrmap;

package body ipbus_decode_TLUaddrmap is

  function ipbus_sel_TLUaddrmap(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Mon Feb 19 12:09:48 2018 
    if    std_match(addr, "----------------0000------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_VERSION, IPBUS_SEL_WIDTH)); -- version / base 0x00000001 / mask 0x0000f000
    elsif std_match(addr, "----------------0001------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_DUTINTERFACES, IPBUS_SEL_WIDTH)); -- DUTInterfaces / base 0x00001000 / mask 0x0000f000
    elsif std_match(addr, "----------------0010------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_SHUTTER, IPBUS_SEL_WIDTH)); -- Shutter / base 0x00002000 / mask 0x0000f000
    elsif std_match(addr, "----------------0011------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_I2C_MASTER, IPBUS_SEL_WIDTH)); -- i2c_master / base 0x00003000 / mask 0x0000f000
    elsif std_match(addr, "----------------0100------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_EVENTBUFFER, IPBUS_SEL_WIDTH)); -- eventBuffer / base 0x00004000 / mask 0x0000f000
    elsif std_match(addr, "----------------0101------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_EVENT_FORMATTER, IPBUS_SEL_WIDTH)); -- Event_Formatter / base 0x00005000 / mask 0x0000f000
    elsif std_match(addr, "----------------0110------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TRIGGERINPUTS, IPBUS_SEL_WIDTH)); -- triggerInputs / base 0x00006000 / mask 0x0000f000
    elsif std_match(addr, "----------------0111------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TRIGGERLOGIC, IPBUS_SEL_WIDTH)); -- triggerLogic / base 0x00007000 / mask 0x0000f000
    elsif std_match(addr, "----------------1000------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_LOGIC_CLOCKS, IPBUS_SEL_WIDTH)); -- logic_clocks / base 0x00008000 / mask 0x0000f000
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_TLUaddrmap;

end ipbus_decode_TLUaddrmap;

