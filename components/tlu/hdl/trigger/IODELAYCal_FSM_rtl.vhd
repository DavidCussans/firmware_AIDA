--=============================================================================
--! @file IODELAYCal_FSM_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- UoB , USC
-- --
------------------------------------------------------------------------------- --
--
--! @brief Finite-state machine to control calibration and reset signals to
--! Iserdes, IDelay
--! based on code by Alvaro Dosil\n
--
--! @author  Alvaro Dosil 
--
--! @date 22/Feb/2014
--
--! @version v0.1
--
--! @details
--
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo Implement a periodic calibration sequence\n
--! <another thing to do> \n

  LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity IODELAYCal_FSM is
	port (
		clk_i 		: in std_logic;		--! Global clock
		startcal_i 	: in std_logic;      --! Start calibration
		busy_i 		: in std_logic;     	--! Status of the IDELAY component
		calibrate_o : out std_logic;     --! Calibration signals to IODELAY
		reset_o 		: out std_logic  		--! Reset to IODELAY component
    );
end entity IODELAYCal_FSM;

architecture rtl of IODELAYCal_FSM is

  --! Calibration FSM state values
  type state_values is (st0, st1, st2, st3);
  signal pres_state, next_state: state_values := st0;
  
	signal s_cal_FSM      : std_logic := '0';         -- IODELAY reset
  signal s_rst_FSM      : std_logic := '0';         -- IODELAY reset
  
begin  -- rtl

  --! Calibration FSM register
  statereg: process(clk_i)
  begin
    if rising_edge(clk_i) then
      pres_state <= next_state;     -- Move to next state
      
    end if;
  end process statereg;


  --! Calibration FSM combinational block
  fsm: process(pres_state, startcal_i, busy_i)
  begin
    next_state <= pres_state;
    -- Default values
    s_Rst_FSM <= '0';
    s_cal_FSM <= '0';
    
    case pres_state is
      
      -- st0 - IDLE
      when st0=>
        if ( startcal_i = '1') then 
          next_state <= st1;            -- Next state is "st1 - SEND CALIBRATION SIGNAL"
        end if;
        
      -- st1 - SEND CALIBRATION SIGNAL
      when st1=>
        s_cal_FSM <= '1';
		  next_state <= st2;            -- Next state is "st2 - WAIT BUSY = '0'"
        
      -- st2 - WAIT BUSY = '0'
      when st2=>
        if busy_i = '0' then 
          next_state <= st3;            -- Next state is "st3 - RESET STATE"
        end if;
        
        -- st3 - RESET STATE
      when st3=>
        s_Rst_FSM <= '1';
		  next_state <= st0;              -- Next state is "st0 - IDLE"
		
    end case;
    
  end process fsm;

  calibrate_o <= s_cal_FSM;
  reset_o <= s_Rst_FSM;
                
end rtl;
