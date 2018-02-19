----------------------------------------------------------------------------------
-- Company: Universidade de Santiago de Compostela
-- Engineer: Alvaro Dosil
-- 
-- Create Date:    15/08/2012 
-- Module Name:    Conf_Regs - Behavioral 
-- Revision 1.00 - File Created
-- Additional Comments: 
----------------------------------------------------------------------------------
-------------------------------------------------------
--! @file
--! @brief Synchronization module 32b
--! @author Alvaro Dosil
-------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity sync_reg is
  generic(g_Data_width : positive := 32);
  port(
    clk_i : in std_logic;  --! synchronous clock
    Async_i : in std_logic_vector(g_Data_width-1 downto 0); --! Asynchronous input data
	 Sync_o : out std_logic_vector(g_Data_width-1 downto 0)); --! Synchronous output data
  
end sync_reg;

--! @brief
--! @details Synchronize words (n bits)of data 

architecture Behavioral of sync_reg is

signal s_async_i : std_logic_vector(g_Data_width-1 downto 0);
signal s_sync_o : std_logic_vector(g_Data_width-1 downto 0);
begin
  
loop0: for i in 0 to g_Data_width-1 generate
  begin
  reg: entity work.Reg_2clks
    port map(
	   clk_i => clk_i,
		async_i => s_async_i(i),
		sync_o => s_sync_o(i));
  end generate;
 
s_async_i <= Async_i; 
Sync_o <= s_sync_o;

end Behavioral;

