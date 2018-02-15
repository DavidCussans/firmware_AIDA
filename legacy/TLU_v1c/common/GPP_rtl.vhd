--=============================================================================
--! @file GPP_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Santiago de Compostela, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- 
--
--! @brief GPP - General purpose pulser. Generates a sycronous custom pulse \n
--! IPBus address map:\n
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
--! Author: 
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

entity GPP is
   GENERIC( 
      g_IPBUS_WIDTH      : positive := 32
   );
	PORT( clk_i       		: IN     std_logic;                                          		--! Rising edge active
			Enable_i          : IN     std_logic;                                          --
			Reset_i           : IN     std_logic;                                          --
			RstPulsCnt_i     	: IN     std_logic;                                          -- Reset pulse counter
			Trigger_i         : IN     std_logic;                                          -- Trigger input signal
			NMaxPulses_i      : IN     std_logic_vector(g_IPBUS_WIDTH-1 downto 0);         -- Max number of pulses
			SuDTime_i         : IN     std_logic_vector(g_IPBUS_WIDTH-1 downto 0);         -- Startup dead time
			PulsLen_i     		: IN     std_logic_vector(g_IPBUS_WIDTH-1 downto 0);         -- Pulse length
		   IpDTime_i         : IN     std_logic_vector(g_IPBUS_WIDTH-1 downto 0);         -- Interpulse dead time
			RearmTime_i       : IN     std_logic_vector(g_IPBUS_WIDTH-1 downto 0);         -- Time before rearm after reach the max number of pulses
			Force_PullDown_i  : IN     std_logic;                                          -- Force pull down
			WU_i              : IN     std_logic;                                          -- Output trigger signal with update
			PulseDelay_i      : IN     std_logic_vector(g_IPBUS_WIDTH-1 downto 0);    		 -- Pulse delay
	      event_number_o    : OUT    std_logic_vector(g_IPBUS_WIDTH-1 downto 0);         -- Event number
			MaxPulses_o       : OUT    std_logic;                                          -- Maximun number of pulses reached
			Pulse_o           : OUT    std_logic;                                          --! pulse output
			Pulse_d_o         : OUT    std_logic                                           --! pulse output delayed
			);
end GPP;

architecture rtl of GPP is
   --! FSM state values
   type state_values is (st0, st1, st2, st3, st4, st5, st6);
	signal pres_state, next_state: state_values;
	
	signal s_PulsCnt_en  		: std_logic := '0';                                             --! Pulse counter enable
	signal s_RstPulsCnt       	: std_logic := '0';                                             --! Reset pulse counter
	signal s_RstPulsCnt_int   	: std_logic := '0';                                             --! Reset pulse counter internal signal
	signal s_PulsLen		      : std_logic_vector(g_IPBUS_WIDTH-1 downto 0);                   --! Pulse Length
	signal s_PulsCnt     		: unsigned(g_IPBUS_WIDTH-1 downto 0) := (others => '0');        --! Pulse counter value
	signal s_MaxPulses         : std_logic := '0';                                             --! Max number of pulses reached
	signal s_Pulse             : std_logic := '0';                                             --! Active pulse signal
	signal s_Pulse_d           : std_logic_vector(g_IPBUS_WIDTH-1 downto 0) := (others=>'0');  --! Active pulse signal delayed
   
	signal s_load_SuDTime      : std_logic := '1';                                             --! Counter load signal
	signal s_SuDTime 				: std_logic_vector(g_IPBUS_WIDTH-1 downto 0);                   --! Startup dead time counter
	signal EOSDT               : std_logic := '0';                                             --! End of startup dead time signal
	
	signal s_load_PulsLen     : std_logic := '1';                                           	--! Counter load
	signal EOP                 : std_logic := '0';                                             --! End of pulse length signal
	
	signal s_load_IpDTime      : std_logic := '1';                                             --! Counter load signal
	signal s_IpDTime 				: std_logic_vector(g_IPBUS_WIDTH-1 downto 0);                   --! Interpulse dead time counter
	signal EOIDT               : std_logic := '0';                                             --! End of interpulse dead time signal
	
	signal s_load_RearmTime    : std_logic := '1';                                             --! Rearm counter load signal
	signal s_RearmLen     		: std_logic_vector(g_IPBUS_WIDTH-1 downto 0);                   --! Startup dead time counter
	signal EOREARM             : std_logic := '0';                                             --! End of startup dead time signal

begin
	-----------------------------------------------------------------------------
	-- Counters
	-----------------------------------------------------------------------------
	--! Startup dead time counter
   c_startup_dtime : entity work.CounterDown
	generic map(
		MAX_WIDTH => g_IPBUS_WIDTH
	)
	port map( 
		Clk		=> clk_i,
		Reset		=> '0',
		Load 		=> s_load_SuDTime,
		InitVal 	=> std_logic_vector(unsigned(s_SuDTime)-1),
		Count		=> open,
		Q 			=> EOSDT
	);
	s_SuDTime <= x"00000001" when SuDTime_i = x"00000000"    -- At least one clock cycle pulse is generated
	             else SuDTime_i;
	
	--! Pulse time counter
   c_pulse_time : entity work.CounterDown
	generic map(
		MAX_WIDTH => g_IPBUS_WIDTH
	)
	port map( 
		Clk		=> clk_i,
		Reset		=> '0',
		Load 		=> s_load_PulsLen,
		InitVal 	=> std_logic_vector(unsigned(s_PulsLen)-1),
		Count		=> open,
		Q 			=> EOP
	);
	s_PulsLen <= x"00000001" when PulsLen_i = x"00000000"    -- At least one clock cycle pulse is generated
	             else PulsLen_i;
	
	--! Interpulse dead time counter
   c_interpulse_dtime : entity work.CounterDown
	generic map(
		MAX_WIDTH => g_IPBUS_WIDTH
	)
	port map( 
		Clk		=> clk_i,
		Reset		=> '0',
		Load 		=> s_load_IpDTime,
		InitVal 	=> std_logic_vector(unsigned(s_IpDTime)-1),
		Count		=> open,
		Q 			=> EOIDT
	);
	s_IpDTime <= x"00000001" when IpDTime_i = x"00000000"    -- At least one clock cycle pulse is generated
	             else IpDTime_i;
	
	--! Rearm time after the max pulses reached
   c_rearm_dtime : entity work.CounterDown
	generic map(
		MAX_WIDTH => g_IPBUS_WIDTH
	)
	port map( 
		Clk		=> clk_i,
		Reset		=> '0',
		Load 		=> s_load_RearmTime,
		InitVal 	=> std_logic_vector(unsigned(s_RearmLen)-1),
		Count		=> open,
		Q 			=> EOREARM
	);
	s_RearmLen <= x"00000001" when RearmTime_i = x"00000000"    -- At least one clock cycle pulse is generated
						else RearmTime_i;
			 

	--! FSM register
	statereg: process(clk_i, Enable_i, Reset_i)
	begin
		if Enable_i = '0'  then 
			pres_state <= st0;            -- Move to st0 - INITIAL STATE
      
		elsif Reset_i = '1' then
			pres_state <= st0;            -- Move to st0 - INITIAL STATE
        
		elsif rising_edge(clk_i) then
			pres_state <= next_state;     -- Move to next state
        
		end if;
	end process statereg;


   --! FSM combinational block
	fsm: process(pres_state, Enable_i, Reset_i, Trigger_i, s_MaxPulses, EOP, EOSDT, EOIDT, Force_PullDown_i)
	begin
	  next_state <= pres_state;
	  -- Default values
	  s_Pulse          	<= '0';
	  s_load_SuDTime     <= '1';
	  s_load_PulsLen 		<= '1';
	  s_load_IpDTime     <= '1';
	  s_load_RearmTime	<= '1';
	  s_RstPulsCnt_int   <= '0';
  
     case pres_state is
	  
	    -- st0 - INITIAL STATE
		 when st0=>
         if (Enable_i = '1') and (Reset_i = '0') then 
           next_state <= st1;            -- Next state is "st1 - IDLE"
         end if;
       
		 -- st1 - IDLE STATE
       when st1=>
         if s_MaxPulses = '1' then
           next_state <= st5;            -- Next state is "st5 - NMAX PULSES REACHED"
         else
           if Trigger_i = '1' and Force_PullDown_i = '0' then 
             if (to_integer(unsigned(SuDTime_i)) = 0) then
               next_state <= st3;        -- Next state is "st3 - PULSE"
             else
               next_state <= st2;        -- Next state is "st2 - STARTUP DEAD-TIME"
             end if; 
           end if;
         end if;
		 
		 -- st2 - STARTUP DEAD-TIME
       when st2=>
         s_load_SuDTime <= '0';
           if EOSDT = '1' then
             next_state <= st3;          -- Next state is "st3 - PULSE"
           end if;
		
		 -- st3 - PULSE
       when st3=>
         s_Pulse <= '1';
         s_load_PulsLen <= '0';
				
         if (EOP = '1') or (Force_PullDown_i = '1')then
           if (to_integer(unsigned(IpDTime_i)) = 0) then
             next_state <= st1;         -- Next state is "st1 - IDLE"
           else
             next_state <= st4;         -- Next state is "st4 - INTERPULSE DEAD-TIME"
           end if;
         end if;
				
         if Trigger_i = '1' then
           if (WU_i = '1') then
             next_state <= st6;         -- Next state is "st6 - RELOAD PULSE TIMER"
           end if;	
         end if;
       
		 
		 -- st4 - INTERPULSE DEAD-TIME
       when st4=>
         s_load_IpDTime <= '0';
         if EOIDT = '1' then
           next_state <= st1;            -- Next state is "st1 - IDLE"
         end if;
				
		 -- st5 - NMAX PULSES REACHED
       when st5=>
		   s_load_RearmTime <= '0';
			if EOREARM = '1' then
			  next_state <= st1;            -- Next state is "st1 - IDLE"
			  s_RstPulsCnt_int <= '1';
			end if;
			
		 -- st6 - RELOAD PULSE TIMER
       when st6=>
         s_Pulse <= '1';
         next_state <= st3;              -- Next state is "st3 - PULSE"
			
--       when others=>
--         next_state<=st0;                -- Next state is "st0 - INITIAL STATE"
     
	  end case;
	
	end process fsm;    
	
	-- Pulse reg
	p_reg_pulse : process ( clk_i , Reset_i )
   begin  
	  if Reset_i = '1' then
	    s_Pulse_d <= (others => '0');
	  
	  elsif rising_edge(clk_i) then
       for i in 0 to g_IPBUS_WIDTH-2 loop
         s_Pulse_d(i+1) <= s_Pulse_d(i);
       end loop;
	    s_Pulse_d(0) <= s_Pulse;
	  end if;
	end process p_reg_pulse;
	
	event_number_o <= std_logic_vector(s_PulsCnt);
	MaxPulses_o <= s_MaxPulses;
	Pulse_o 		<= s_Pulse;
	Pulse_d_o 	<= s_Pulse when PulseDelay_i = x"00000000" else
						s_Pulse_d(to_integer(unsigned(PulseDelay_i)-1));
	
	
	-----------------------------------------------------------------------------
	-- Count runs and synchronization
	-----------------------------------------------------------------------------
	p_PulsCounter : process (clk_i )
	begin  -- process p_run_counter

		if rising_edge(clk_i) then
			if s_RstPulsCnt = '1' then
				s_PulsCnt <= (others => '0');
			elsif s_PulsCnt_en = '1' then
				s_PulsCnt <= s_PulsCnt + 1;
			end if;
		
		end if;
	end process p_PulsCounter;
  
	s_RstPulsCnt <= Reset_i or RstPulsCnt_i or s_RstPulsCnt_int;
	s_PulsCnt_en <= '1' when (s_Pulse = '1') and (s_Pulse_d(0) = '0') and (s_MaxPulses = '0')
	                      else '0'; 
	s_MaxPulses <= '1' when (s_PulsCnt = unsigned(NMaxPulses_i)) and (NMaxPulses_i /= x"00000000")
                  else '0';


END ARCHITECTURE rtl;

