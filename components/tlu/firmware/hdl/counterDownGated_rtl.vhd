--=============================================================================
--! @file counterDownGated_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Santiago de Compostela, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- 
--
--! @brief CountDown - load with a value and counts to zero. Flag Q_o goes high during count
--
--! @author Alvaro Dosil , alvaro.dosil@usc.es
--
--! @date 15:42:31 01/15/2013 
--
--! @version v0.1
--
--! @details
--!
--!
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--!
--! <b>Modified by: 
--! Author: David Cussans. Added gating. Made reset synchronous. 20/2/18
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY CounterDownGated IS
  GENERIC(
    g_MAX_WIDTH: positive := 32
    );
  PORT( 
		Clk_i		: in  std_logic; --! Rising edge active
                Gate_i          : in  std_logic; --! If high circuit clocks. If low, no change
		Reset_i		: in  std_logic; --! Active high. Synchronous
		Load_i 		: in  std_logic; --! Take high to load counter with InitVal
		InitVal_i 	: in std_logic_vector(g_MAX_WIDTH-1 downto 0);     --! Initial value ( counts down from here )
		Count_o		: out Std_logic_vector(g_MAX_WIDTH-1 downto 0);    --! Current Count value
		Q_o 		: out std_logic                                  --! 0 while counting. 1 otherwise
                
	);
END ENTITY Counterdowngated;

architecture rtl of Counterdowngated is 
	signal s_cnt	: std_logic_vector(g_MAX_WIDTH-1 downto 0) := (others => '0');
	signal s_Qtmp	: std_logic;
  
begin 
	Counter: process (Clk_I)
	begin                   
          if rising_edge(Clk_I) and ( Gate_i = '1') then
            if (Reset_I='1') then 
              s_cnt <= (others =>'0');
              elsif (Load_I='1') then
                s_cnt <= Initval_I;
              else
                if s_Qtmp='0' then
                  s_cnt <= std_logic_vector(unsigned(s_cnt) - 1);
                end if;
              end if;
            end if; 
	end process;
      
	s_Qtmp <= 	'1' when s_cnt=(s_cnt'range=>'0') else '0';
          
	Count_O <= s_cnt;
	Q_O <= s_Qtmp;
        
end rtl;
