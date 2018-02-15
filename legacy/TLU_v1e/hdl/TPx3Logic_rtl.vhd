--=============================================================================
--! @file TPx3Logic_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Santiago de Compostela, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture fmc_mTLU_lib.TPx3Logic.rtl
--
--! @brief Produces shutters \n
--! IPBus address map:\n
--
--! @author Alvaro Dosil , alvaro.dosil@usc.es
--
--! @date 16:06:19 11/06/14
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
--! <b>Modified by: Alvaro Dosil , alvaro.dosil@usc.es </b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! Move all IPBus stuff into ipbus_syncreg_v , which also handles clock domain
--! crossing. 20/Feb/2014 , David Cussans
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.ipbus.all;
use work.ipbus_reg_types.all;

ENTITY TPx3Logic IS
	GENERIC( 
      g_IPBUS_WIDTH         : positive := 32
   );
   PORT( 
      clk_i      				: IN     std_logic;                                    -- ! Rising edge active
		Start_T0sync_i			: IN 		std_logic;
		T0syncLen_i				: IN 		std_logic_vector(g_IPBUS_WIDTH-1 DOWNTO 0);
      logic_reset_i       	: IN     std_logic;                                    -- active high. Synchronous with clk_4x_logic
      Busy_i					: IN     std_logic;
		Veto_i					: IN     std_logic;
		Shutter_o				: OUT 	std_logic;
		T0sync_o 				: OUT 	std_logic
   );
	

-- Declarations

END ENTITY TPx3Logic ;

--
ARCHITECTURE rtl OF TPx3Logic IS

	type state_values is (st0, st1);
	signal pres_state, next_state: state_values;

	signal s_Enable : std_logic := '0';
	signal s_Shutter, s_Shutter_d1f, s_Shutter_d1, s_T0sync, s_T0sync_d1f : std_logic := '0';
	signal s_Start_T0sync, s_Start_T0sync_d1, s_Start_T0sync_d2, s_Start_T0sync_d3 : std_logic;
	signal Rst_T0sync, T0syncT : 		std_logic;   	--Load signal and flag for the T0sync
	signal s_RunNumber : unsigned(g_IPBUS_WIDTH-1 downto 0) := (others => '0');  -- ! counters for runs
	
BEGIN

	-----------------------------------------------------------------------------
	-- Counters
	-----------------------------------------------------------------------------
	--T0sync counter
	c_T0sync: entity work.CounterDown
	generic map(
		MAX_WIDTH => g_IPBUS_WIDTH
	)
	port map( 
		Clk		=> clk_i,
		Reset		=> '0',
		Load 		=> Rst_T0sync,
		InitVal 	=> std_logic_vector(unsigned(T0syncLen_i)-1),
		Count		=> open,
		Q 			=> T0syncT
	);
  
  
  -----------------------------------------------------------------------------
  -- FSM register
  -----------------------------------------------------------------------------
	statereg: process(clk_i)
	begin
		if rising_edge(clk_i) then
			pres_state <= next_state;  --Move to the next state
		end if;
	end process statereg;
	
	
	-----------------------------------------------------------------------------
	-- FSM combinational block
	-----------------------------------------------------------------------------
	fsm: process(pres_state, s_Start_T0sync, T0syncT)
	begin
		next_state<=pres_state;
		s_T0sync	<='0';
		Rst_T0sync <= '1';
		
		case pres_state is
			when st0=>
				if s_Start_T0sync = '1' then 
					next_state <= st1; --Next state is "Whait for end of T0sync signal"
				end if;
			when st1 =>
				Rst_T0sync <='0';
				s_T0sync <='1';
				if T0syncT = '1' then
					next_state<=st0; --Next state is "Whait for end of T0-sync counter"
				end if;
			when others=>
				next_state<=st0; --Next state is "Whait for T0sync start"
		end case;
	end process fsm;

  
	-----------------------------------------------------------------------------
	-- Busy signals
	-----------------------------------------------------------------------------
	s_Enable <= not Veto_i;
	s_Shutter <= not Busy_i and not Veto_i;
	--Shutter_o <= s_Shutter;
	--T0sync_o <= s_T0sync;
  
	
	-----------------------------------------------------------------------------
	-- Count runs and synchronization
	-----------------------------------------------------------------------------
	p_run_counter: process (clk_i )
	begin  -- process p_run_counter
		if rising_edge(clk_i) then
			s_Start_T0sync_d1 <= Start_T0sync_i;
			s_Start_T0sync_d2 <= s_Start_T0sync_d1;
			s_Start_T0sync_d3 <= s_Start_T0sync_d2;
			s_Start_T0sync <= s_Start_T0sync_d2 and ( not s_Start_T0sync_d3); 
		
			s_Shutter_d1 <= s_Shutter;
		
			if logic_reset_i = '1' then
				s_RunNumber <= (others => '0');
			elsif s_Shutter='1' and s_Shutter_d1='0' then
				s_RunNumber <= s_RunNumber + 1;
			end if;
		end if;
		-- Signals synchronous with falling edge clock
		if falling_edge(clk_i) then
			s_Shutter_d1f <= s_Shutter;
			Shutter_o <= s_Shutter_d1f;
			
			s_T0sync_d1f <= s_T0sync;
			T0sync_o <= s_T0sync_d1f;
		end if;
  end process p_run_counter;
  
END ARCHITECTURE rtl;

