----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.02.2017 12:54:36
-- Design Name: 
-- Module Name: test_inputToOutput - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity test_inputToOutput is
    Port ( clk_i : in STD_LOGIC;
           test_i : in STD_LOGIC_VECTOR (3 downto 0);
           test_o : out STD_LOGIC_VECTOR (3 downto 0));
end test_inputToOutput;

architecture Behavioral of test_inputToOutput is
    signal synch_lines : std_logic_vector(3 downto 0);
begin
    synch_io : process (clk_i)
    begin
        if rising_edge(clk_i) then
            synch_lines <= test_i;
            test_o(1) <= synch_lines(0);
            test_o(3) <= synch_lines(2);
            test_o(0) <= '0';
            test_o(2) <= '1';
        end if;
    end process synch_io;
end Behavioral;
