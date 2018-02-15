----------------------------------------------------------------------------------
-- Company: Universidade de Santiago de Compostela
-- Engineer: Alvaro Dosil
-- 
-- Create Date:    31/07/2012 
-- Module Name:    Reg_2clks - Behavioral 
-- Revision 0.01 - File Created
-- Additional Comments: 
----------------------------------------------------------------------------------
-------------------------------------------------------
--! @file
--! @brief Synchronization module 1b
--! @author Alvaro Dosil
-------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Reg_2clks is
  port(
    clk_i : in std_logic;  --! Synchronous clock
	 async_i : in std_logic;  --! Asynchronous input data
	 sync_o : out std_logic   --! Synchronous output data
	 );
end Reg_2clks;

--! @brief
--! @details Synchronize 1 bit of data 

architecture Behavioral of Reg_2clks is
signal sreg : std_logic_vector(1 downto 0);

attribute TIG : string;
attribute IOB : string;
attribute ASYNC_REG : string;
attribute SHIFT_EXTRACT : string;
attribute HBLKNM : string;

attribute TIG of async_i : signal is "TRUE";
attribute IOB of async_i : signal is "FALSE";
attribute ASYNC_REG of sreg : signal is "TRUE";
attribute SHIFT_EXTRACT of sreg : signal is "NO";
attribute HBLKNM of sreg : signal is "sync_reg";

begin

process (clk_i)
begin
   if rising_edge(clk_i) then  
     sync_o <= sreg(1);
	  sreg <= sreg(0) & async_i;
   end if;
end process;

end Behavioral;

