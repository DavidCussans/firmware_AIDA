----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.02.2017 11:31:53
-- Design Name: 
-- Module Name: testbench_myclocks - Behavioral
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
use work.ipbus.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity testbench_myclocks is
end testbench_myclocks;

architecture Behavioral of testbench_myclocks is

 COMPONENT logic_clocks
    GENERIC (
        g_USE_EXTERNAL_CLK : integer := 1
    );
    PORT (
        ipbus_clk_i           : IN     std_logic ;
        ipbus_i               : IN     ipb_wbus ;
        ipbus_reset_i         : IN     std_logic ;
        Reset_i               : IN     std_logic ;
        clk_logic_xtal_i      : IN     std_logic ; -- ! 40MHz clock from onboard xtal
        clk_8x_logic_o       : OUT    std_logic ; -- 640MHz clock
        clk_4x_logic_o        : OUT    std_logic ; -- 160MHz clock
        ipbus_o               : OUT    ipb_rbus ;
        strobe_8x_logic_o    : OUT    std_logic ; -- strobes once every 4 cycles of clk_16x
        strobe_4x_logic_o     : OUT    std_logic ; -- one pulse every 4 cycles of clk_4x
        --extclk_p_b            : INOUT  std_logic ; -- either external clock in, or a clock being driven out
        --extclk_n_b            : INOUT  std_logic ;
        DUT_clk_o             : OUT    std_logic ;
        logic_clocks_locked_o : OUT    std_logic ;
        logic_reset_o         : OUT    std_logic   -- Goes high TO reset counters etc. Sync with clk_4x_logic
    );
    END COMPONENT logic_clocks;
    FOR ALL : logic_clocks USE ENTITY work.logic_clocks;
    SIGNAL sysclk_40         : std_logic := '0';
    SIGNAL clk_8x_logic         : std_logic := '0';
    SIGNAL clk_4x_logic         : std_logic := '0';
    SIGNAL strobe_8x_logic         : std_logic := '0';
    SIGNAL strobe_4x_logic         : std_logic := '0';
    SIGNAL logic_reset         : std_logic := '0';
    signal ipbus_i_const             : ipb_wbus;


begin
    
      ipbus_i_const.ipb_strobe <= '0';
      ipbus_i_const.ipb_write <= '0';
      ipbus_i_const.ipb_wdata <= (others => '0');
    
        I3_Clocks : logic_clocks
    GENERIC MAP (
        g_USE_EXTERNAL_CLK => 0
    )
    PORT MAP (
        ipbus_clk_i           => '0',
        ipbus_i               => ipbus_i_const,
        ipbus_reset_i         => '0',
        Reset_i               => '0',
        clk_logic_xtal_i      => sysclk_40, -- Not sure this is correct
        clk_8x_logic_o       => clk_8x_logic,
        clk_4x_logic_o        => clk_4x_logic,
        ipbus_o               => open,
        strobe_8x_logic_o    => strobe_8x_logic,
        strobe_4x_logic_o     => strobe_4x_logic,
        DUT_clk_o             => open,
        logic_clocks_locked_o => open,
        logic_reset_o         => logic_reset
    );  

end Behavioral;
