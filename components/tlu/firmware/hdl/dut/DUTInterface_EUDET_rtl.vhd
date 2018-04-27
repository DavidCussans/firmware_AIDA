--! @file
-------------------------------------------------------------------------------
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! @brief "EUDET style" interfaces to a DUT connection. Outputs TRIGGER and receives DUT_CLK and BUSY
--! lines. Adapted from Trigger_Signal_Controller from EUDET TLU firmware.
--!
--! @author David.Cussans@bristol.ac.uk
--! @date 1/Sept/2015
------------------------------------------------------------------------------------
entity DUTInterface_EUDET is
  GENERIC( 
    g_TRIGGER_DATA_WIDTH : positive := 32 -- was32
   );
  port (
    rst_i : in std_logic;                --! asynchronous reset. Active high
    busy_o : out std_logic;             --! low if FSM is in IDLE state, high otherwise
    fsm_state_value_o : out std_logic_vector(3 downto 0);  --! detailed status of FSM.
    trigger_i : in std_logic;        --! Trigger retimed onto system clock.active high. 
    trigger_counter_i : in std_logic_vector(g_TRIGGER_DATA_WIDTH-1 downto 0);  --! event number
    system_clk_i : in std_logic;          --! rising edge active clock from TLU
    reset_or_clk_to_dut_i   : IN     std_logic;  --! Synchronization signal. Passed to DUT pins
    shutter_to_dut_i        : IN     std_logic;  --! Goes high to indicate data-taking active. DUTs report busy unless ignoreShutterVeto flag set high
    ignore_shutter_veto_i        : in     std_logic;
    enable_dut_veto_i : in std_logic;      --! If high: if DUT raises dut_busy_i, then  busy_o is raised
    -- Connections to DUT:
    dut_clk_i : in std_logic;             --! rising edge active clock from DUT
    dut_busy_i : in std_logic;            --! from DUT
    dut_shutter_o      : OUT    std_logic;     --! Shutter output.
    dut_trigger_o : out std_logic    --! trigger to DUT
    );
end DUTInterface_EUDET;

architecture rtl of DUTInterface_EUDET is

-----------------------------------------------------------------------------
-- Declarations for state machine
  type state_type is (IDLE , WAIT_FOR_BUSY_HIGH , TRIGGER_DEGLITCH_DELAY1 ,
                      TRIGGER_DEGLITCH_DELAY2 , WAIT_FOR_BUSY_LOW 
                     , DUT_INITIATED_VETO );
--                      );
  signal state , next_state : state_type;

  -- Xilinx Voodoo for state machine
  attribute SAFE_IMPLEMENTATION : string;
  attribute SAFE_IMPLEMENTATION of state : signal is "yes";
  -- End of Xilinx Voodoo

-----------------------------------------------------------------------------

--  signal internal_clk : std_logic;
  signal serial_trig_data : std_logic;
  signal trig_shift_reg : std_logic_vector(g_TRIGGER_DATA_WIDTH-1 downto 0);  
                                        -- shift register storing parallel trigger data
--  signal d1_output  :  std_logic;
--  signal d2_output  :  std_logic;
  signal dut_rising_edge  :  std_logic;
  signal shift_reg_ce  :  std_logic;

  signal dut_busy_r1 , dut_busy_r2 , dut_clk_r1 , dut_clk_r2 : std_logic;  -- ! registered values
  signal trigger_counter_copy : std_logic_vector(g_TRIGGER_DATA_WIDTH-1 downto 0);  --! registered copy of event number
  
begin  -- rtl


  dut_shutter_o <= shutter_to_dut_i ; -- for now just pass through.
  
  -- purpose: suppress meta-stability by registering input signals.
  -- type   : combinational
  -- inputs : dut_busy_r1 , dut_busy_r2 , dut_clk_r1 , dut_clk_r2
  -- outputs: dut_busy_r2 , dut_clk_r2
  register_signals: process ( dut_busy_r1 , dut_clk_r1 , system_clk_i )
  begin  -- process register_signals
    if rising_edge(system_clk_i) then

      dut_busy_r2 <= dut_busy_r1 ;
      dut_clk_r2 <= dut_clk_r1;
      dut_busy_r1 <= dut_busy_i ;
      dut_clk_r1 <= dut_clk_i;
      
    end if;
  end process register_signals;


  
  rising_edge_pulse: entity work.single_pulse
    port map (
      level => dut_clk_i,
      clk   => system_clk_i,
      pulse => dut_rising_edge);

  
-- look for the rising edge of DUT clock and enable CE for one cycle.
  -- I have a nasty suspicion that meta-stability issues may make this
  -- go horribly wrong .
-- Need to add timing constraint that shift_reg_ce must arrive before clock at trig_data_driver
-- also WAIT_FOR_BUSY_LOW must not mess things up.
  clk_enable_select: process (state, dut_rising_edge)
begin  -- process
  if (state=WAIT_FOR_BUSY_LOW) then
    shift_reg_ce <= dut_rising_edge;
  else
    shift_reg_ce <= '0';
  end if;
end process;

  
   
  
  -- purpose: controls the serial_trig_data line
  -- type   : combinational
  -- inputs : system_clk_i , trigger_counter_i
  -- outputs: serial_trig_data
  trig_data_driver: process (system_clk_i , trigger_counter_copy , shift_reg_ce , trig_shift_reg , state)
  begin
    
    if rising_edge( system_clk_i ) then

      -- if busy is high in response to a trigger shift data out of
      -- register on rising edge of DUT clock . This is done by having a slow
      -- DUT clock and setting shift_reg_ce for one cycle of system_clk_i when
      -- the DUT clock rising edge comes by.
      if (shift_reg_ce ='1' ) then
        trig_shift_reg <= '0' & trig_shift_reg(g_TRIGGER_DATA_WIDTH-1 downto 1);
        serial_trig_data <= trig_shift_reg(0);

      -- otherwise load shift register if we have just had a trigger.
      elsif (state = WAIT_FOR_BUSY_HIGH ) then        
	-- only clock out bottom 15 bits of data. 
        -- (replace fixed width with a mask at some stage ?)
	   trig_shift_reg <=  "00000000000000000" & trigger_counter_copy(14 downto 0);
        serial_trig_data <= '0';
      end if;
      
      if ( state = IDLE ) and ( trigger_i = '1') then
        trigger_counter_copy <= trigger_counter_i; -- register the trigger number to shift it out
      end if;

    end if;
    
  end process trig_data_driver;


  -- purpose: Determine the next state
  -- type   : combinational
  -- inputs : state,Dut_Busy_r2, trigger_i
  state_logic: process (state,  trigger_i ,  enable_dut_veto_i , dut_clk_r2, dut_busy_r2 )
  begin  -- process state_logic
    case state is
	 
      when IDLE =>
        if ( trigger_i = '1') then  -- respond to trigger going high
          next_state <= WAIT_FOR_BUSY_HIGH;  -- wait for DUT to respond to busy
          --trigger_counter_copy <= trigger_counter_i; -- register the trigger number to shift it out

        elsif ( (dut_clk_r2 = '1') and (enable_dut_veto_i = '1') ) then      -- If DUT asserts DUT_CLK_I then veto triggers
          next_state <= DUT_INITIATED_VETO;          

        else          
          next_state <= IDLE;
        end if;

      when WAIT_FOR_BUSY_HIGH =>
        if (DUT_Busy_r2 = '1') then
          next_state <= TRIGGER_DEGLITCH_DELAY1;
        else
          next_state <= WAIT_FOR_BUSY_HIGH;
        end if;

        -- put in a pause to supress glitch in output trigger
        -- this is an inelegant (to say the least ) way of doing it.
      when TRIGGER_DEGLITCH_DELAY1 =>
          next_state <= TRIGGER_DEGLITCH_DELAY2;

      -- delay for two clock cycles.
      when TRIGGER_DEGLITCH_DELAY2 =>
        next_state <= WAIT_FOR_BUSY_LOW;



      when WAIT_FOR_BUSY_LOW =>
        if (DUT_Busy_r2 = '1')  then
          next_state <= WAIT_FOR_BUSY_LOW;
        else
          next_state <= IDLE;
        end if;        

      when DUT_INITIATED_VETO =>
        if (( dut_clk_r2 = '0' ) or ( enable_dut_veto_i = '0')) then
          next_state <= IDLE;
        else
          next_state <= DUT_INITIATED_VETO;
        end if;
        
    end case;
  end process state_logic;

  -- determine clock select and trigger_mux from FSM state

  
  -- purpose: Determines the state of the dut_trigger_o output based on the state of the FSM
  -- type   : combinational
  -- inputs : state
  -- outputs: dut_trigger_o
  output_logic: process (state,serial_trig_data)
  begin  -- process output_logic
    if ( state = IDLE ) then
      -- waiting for external trigger to arrive...
      dut_trigger_o <= '0';
    elsif ((state = WAIT_FOR_BUSY_HIGH) or ( state=TRIGGER_DEGLITCH_DELAY1) or (state=TRIGGER_DEGLITCH_DELAY2) ) then
      -- wait until the BUSY line goes high, then continue to hold TRIGGER high for two clock cycles.
      dut_trigger_o <= '1';
    elsif (state = WAIT_FOR_BUSY_LOW) then
      -- if BUSY is high then connect TRIGGER to serial trigger number register.
      dut_trigger_o <= serial_trig_data;
    else
      dut_trigger_o <= '0';
    end if;
  end process output_logic;

    -- purpose: Register that holds the current state of the FSM
  -- type   : combinational
  -- inputs : system_clk_i , rst_i
  -- outputs: state
  state_register: process (system_clk_i , rst_i)
  begin  -- process state_register
    if (rst_i = '1') then
      state <= IDLE;
    elsif rising_edge(system_clk_i) then
      state <= next_state;
    end if;
  end process state_register;


  -- purpose: sets the value of clock_select based on FSM state
  -- type   : combinational
  -- inputs : state
  -- outputs: clock_select , trigger_muxsel , fsm_state
  set_busy: process (system_clk_i , state)
  begin  -- process set_muxsel
    if rising_edge(system_clk_i) then
          if (state = IDLE) then
            busy_o <= '0';
          else
            busy_o <= '1';
          end if;
    end if;
 end process set_busy;
  
  -- purpose: Sets the fsm_state_value_o vector to a number representing the current state
  -- type   : combinational
  -- inputs : system_clk_i , state
  -- outputs: fsm_state_value_o
  store_state: process (system_clk_i , state)
  begin  -- process store_state
    case state is
      when IDLE =>
        fsm_state_value_o <= "0000";
      when WAIT_FOR_BUSY_HIGH =>
        fsm_state_value_o <= "0001";
      when TRIGGER_DEGLITCH_DELAY1 =>
        fsm_state_value_o <= "0010";
      when TRIGGER_DEGLITCH_DELAY2 =>
        fsm_state_value_o <= "0011";
      when WAIT_FOR_BUSY_LOW =>
        fsm_state_value_o <= "0100";
      when DUT_INITIATED_VETO =>
        fsm_state_value_o <= "0101";
      when others =>
        fsm_state_value_o <= "1111";
    end case;
  end process store_state;



  end rtl;

