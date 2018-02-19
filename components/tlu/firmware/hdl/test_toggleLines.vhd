----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2017 10:09:26
-- Design Name: 
-- Module Name: test_toggleLines - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_toggleLines is
    Port (
        clk_in : in STD_LOGIC;
        toggle_o : out std_logic_vector(3 downto 0)
        );
end test_toggleLines;

architecture Behavioral of test_toggleLines is

    signal prescaler : unsigned(23 downto 0);
    signal outcounter: unsigned(3 downto 0);
    signal clk_slow_i : std_logic_vector(3 downto 0);
    
begin

  gen_clk : process (clk_in)
  begin  -- process gen_clk
    if rising_edge(clk_in) then   -- rising clock edge
      if prescaler = X"30D40" then     -- 200 000 in hex
        prescaler   <= (others => '0');
        --clk_slow_i   <= not clk_slow_i;
        outcounter <= outcounter +1;
        clk_slow_i(0) <= outcounter(0);
        clk_slow_i(1) <= outcounter(1);
        clk_slow_i(2) <= outcounter(2);
        clk_slow_i(3) <= outcounter(3);
      else
        prescaler <= prescaler + "1";
      end if;
    end if;
  end process gen_clk;

  toggle_o <= clk_slow_i;



end Behavioral;
