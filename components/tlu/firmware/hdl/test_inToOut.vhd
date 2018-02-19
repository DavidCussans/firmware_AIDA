----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.02.2017 14:45:31
-- Design Name: 
-- Module Name: test_inToOut - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

entity test_inToOut is
    Generic(
        DUT_TOGGLE : integer  :=1; --HDMI that toggles
        DUT_OUT : integer := 2; --HDMI used as input
        DUT_IN : integer := 0; --HDMI used as output
        DUT_DULL : integer := 3 --HDMI not used
    );
    Port ( clk_in : in STD_LOGIC;
           busy_in : in STD_LOGIC_VECTOR (3 downto 0);
           control_in : in STD_LOGIC_VECTOR (3 downto 0);
           trig_in : in STD_LOGIC_VECTOR (3 downto 0);
           clkDut_in : in STD_LOGIC_VECTOR (3 downto 0);
           spare_in : in STD_LOGIC_VECTOR (3 downto 0);
           busy_out : out STD_LOGIC_VECTOR (3 downto 0);
           control_out : out STD_LOGIC_VECTOR (3 downto 0);
           trig_out : out STD_LOGIC_VECTOR (3 downto 0);
           clkDut_out : out STD_LOGIC_VECTOR (3 downto 0);
           spare_out : out STD_LOGIC_VECTOR (3 downto 0));
end test_inToOut;

architecture Behavioral of test_inToOut is

    signal prescaler : unsigned(23 downto 0);
    signal outcounter: unsigned(4 downto 0);
    signal clk_slow_i : std_logic_vector(4 downto 0);
    signal placeholder: std_logic_vector(4 downto 0);

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
        clk_slow_i(4) <= outcounter(4);
      else
        prescaler <= prescaler + "1";
      end if;
      clkDut_out(DUT_TOGGLE) <= clk_slow_i(0);
      busy_out(DUT_TOGGLE) <= clk_slow_i(1);
      control_out(DUT_TOGGLE) <= clk_slow_i(2);
      trig_out(DUT_TOGGLE) <= clk_slow_i(3);
      spare_out(DUT_TOGGLE) <= clk_slow_i(4);
      
      clkDut_out(DUT_TOGGLE) <= clk_slow_i(0);
      busy_out(DUT_TOGGLE) <= clk_slow_i(1);
      control_out(DUT_TOGGLE) <= clk_slow_i(2);
      trig_out(DUT_TOGGLE) <= clk_slow_i(3);
      spare_out(DUT_TOGGLE) <= clk_slow_i(4);
  
      clkDut_out(DUT_OUT) <= clkDut_in(DUT_IN);
      busy_out(DUT_OUT) <= busy_in(DUT_IN);
      control_out(DUT_OUT) <= control_in(DUT_IN);
      trig_out(DUT_OUT) <= trig_in(DUT_IN);
      spare_out(DUT_OUT) <= spare_in(DUT_IN);
      
      clkDut_out(DUT_DULL) <= '0';
      busy_out(DUT_DULL) <= '0';
      control_out(DUT_DULL) <= '0';
      trig_out(DUT_DULL) <= '0';
      spare_out(DUT_DULL) <= '0';
    end if;
    end process gen_clk;
    


end Behavioral;
