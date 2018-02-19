--Counter down
--Outputs: 	Q<='1' while counting
--				Q<='0' if not counting


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY CounterDown IS
	GENERIC(
		MAX_WIDTH: positive := 32
	);
	PORT( 
		Clk		: in  std_logic; 
		Reset		: in  std_logic; 
		Load 		: in  std_logic; 
		InitVal 	: in std_logic_vector(MAX_WIDTH-1 downto 0);
		Count		: out Std_logic_vector(MAX_WIDTH-1 downto 0);
		Q 			: out std_logic
	);
END ENTITY CounterDown;

architecture rtl of CounterDown is 
	signal cnt	: std_logic_vector(MAX_WIDTH-1 downto 0);
	signal Qtmp	: std_logic;
  
begin 
	Counter: process (Clk, Reset)
	begin 
		if (Reset='1') then 
			cnt <= (others =>'0');
		elsif rising_edge(Clk) then
			if (Load='1') then
				cnt <= InitVal;
			else
				if Qtmp='0' then
					cnt <= std_logic_vector(unsigned(cnt) - 1);
				end if;
			end if;
		end if; 
	end process;
      
	Qtmp <= 	'1' when cnt=(cnt'range=>'0') else
				'0';
          
	Count <= cnt;
	Q <= Qtmp;
end rtl;
