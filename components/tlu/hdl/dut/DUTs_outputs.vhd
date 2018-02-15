----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.02.2017 13:17:26
-- Design Name: 
-- Module Name: DUTs_outputs - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity DUTs_outputs is
    Port ( clk_in : in STD_LOGIC;
           d_clk_o : out STD_LOGIC_VECTOR (3 downto 0);
           d_trg_o : out STD_LOGIC_VECTOR (3 downto 0);
           d_busy_o : out STD_LOGIC_VECTOR (3 downto 0);
           d_cont_o : out STD_LOGIC_VECTOR (3 downto 0);
           d_spare_o : out STD_LOGIC_VECTOR (3 downto 0));
end DUTs_outputs;

architecture Behavioral of DUTs_outputs is
signal toggleme : std_logic := '0'; 
begin
    gen_clk : process (clk_in)
    begin  -- process gen_clk
        
        if rising_edge(clk_in) then   -- rising clock edge
            toggleme <= not toggleme;
            d_clk_o(1) <= toggleme;
            d_clk_o(2) <= toggleme;
            d_clk_o(3) <= toggleme;
            d_trg_o <=  (toggleme & toggleme & toggleme & toggleme);
            d_busy_o <= (toggleme & toggleme & toggleme & toggleme);
            d_cont_o <= (toggleme & toggleme & toggleme & toggleme);
            d_spare_o <=(toggleme & toggleme & toggleme & toggleme);
        end if;
        d_clk_o(0) <= clk_in;
    end process gen_clk;

end Behavioral;
