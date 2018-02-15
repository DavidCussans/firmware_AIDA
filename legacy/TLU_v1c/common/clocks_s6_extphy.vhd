--! @file clocks_s6_extphy
-- 
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

--! @brief Generates a 125MHz ethernet clock and 31MHz ipbus clock from the 200MHz reference
--! Includes reset logic for ipbus
--
--! @author Dave Newbold
--! @date April 2011
--
entity clocks_s6_extphy is port(
	sysclk_p, sysclk_n: in std_logic; --! From on board crystal. By default 200MHz
	clk_logic_xtal_o : out std_logic; --! Clock for TLU timing logic ( when not using external clock ). sysclk/5 ( i.e. by default 40MHz) 
	clko_125: out std_logic; --! 125MHz for IPBus logic
	clko_ipb: out std_logic; --! 32.5MHz for IPBus logic
	locked: out std_logic;
	rsto_125: out std_logic;
	rsto_ipb: out std_logic;
	onehz: out std_logic
	);

end clocks_s6_extphy;

architecture rtl of clocks_s6_extphy is

	signal clk_ipb_i, clk_ipb_b, clk_125_i, clk_125_b, sysclk : std_logic;
        -- signal sysclk_in : std_logic;
	signal d25, d25_d, dcm_locked: std_logic;
	signal rst: std_logic := '1';
	signal s_xtal_dcm_locked: std_logic;
        signal s_clk_logic_xtal : std_logic;
	-- signal clk_400: std_logic;
	
--	component clock_divider_s6 port(
--		clk: in std_logic;
--		d25: out std_logic;
--		d28: out std_logic
--	);
--	end component;
	
begin

	ibufgds0: IBUFGDS port map(
		i => sysclk_p,
		ib => sysclk_n,
		o => sysclk
	);

--        -- Add global clock buffer in sysclk path.
--        bufg_sysclk : BUFG port map (
--          i => sysclk_in,
--          o => sysclk);
        
	bufg_125: BUFG port map(
		i => clk_125_i,
		o => clk_125_b
	);
	
	clko_125 <= clk_125_b;
	
	bufg_ipb: BUFG port map(
		i => clk_ipb_i,
		o => clk_ipb_b
	);
	
	bufg_clk_logic_xtal: BUFG port map(
	  i => s_clk_logic_xtal,
	  o => clk_logic_xtal_o
	  );
	  
	clko_ipb <= clk_ipb_b;

	dcm0: DCM_CLKGEN
		generic map(
			CLKIN_PERIOD => 5.0,
			CLKFX_MULTIPLY => 5,
			CLKFX_DIVIDE => 8,
			CLKFXDV_DIVIDE => 4
		)
		port map(
			clkin => sysclk,
			clkfx => clk_125_i,
			clkfxdv => clk_ipb_i,
			locked => dcm_locked,
			rst => '0'
		);
		
	clkdiv: entity work.clock_divider_s6 port map(
--        clkdiv: entity work.clock_div port map(
		clk => sysclk,
--                D17 => open,
		d25 => d25,
		d28 => onehz
	);
	  
	process(sysclk)
	begin
		if rising_edge(sysclk) then
			d25_d <= d25;
			if d25='1' and d25_d='0' then
				rst <= not dcm_locked;
			end if;
		end if;
	end process;
	
	locked <= dcm_locked;

	process(clk_ipb_b)
	begin
		if rising_edge(clk_ipb_b) then
			rsto_ipb <= rst;
		end if;
	end process;
	
	process(clk_125_b)
	begin
		if rising_edge(clk_125_b) then
			rsto_125 <= rst;
		end if;
	end process;

        sys40_gen : BUFIO2
          generic map (
            DIVIDE => 5,            -- DIVCLK divider (1-8)
            DIVIDE_BYPASS => FALSE) -- Bypass the divider circuitry (TRUE/FALSE)
          port map (
            I => SysClk,        -- 1-bit input: Clock input (connect to IBUFG)
            DIVCLK =>  s_clk_logic_xtal,   -- 1-bit output: Divided clock output
            IOCLK => open,          -- 1-bit output: I/O output clock
            SERDESSTROBE => open);  -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
        
                
end rtl;
