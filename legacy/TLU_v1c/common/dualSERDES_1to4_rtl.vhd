--=============================================================================
--! @file dualSERDES_1to4_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture work.dualSERDES_1to4.rtl
--
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

library unisim ;
use unisim.vcomponents.all;

--! @brief Two 1:4 Deserializers. One has input delayed w.r.t. other
--! based on TDC by Alvaro Dosil
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 12:06:53 11/16/12
--
--! @version v0.1
--
--! @details
--! data_o(7) is the most recently arrived data , data_o(0) is the oldest data.
--!
--! <b>Modified by: Alvaro Dosil , alvaro.dosil@usc.es </b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! Separated FSM for calibration control into a separate entity. DGC, 22/Feb/14
-------------------------------------------------------------------------------
--! @todo Implement a periodic calibration sequence\n
--
--------------------------------------------------------------------------------

ENTITY dualSERDES_1to4 IS
   PORT( 
      reset_i        : IN     std_logic;                      --! Resets  IODELAY
      --calibrate_i    : IN     std_logic;                      --! Starts IODELAY calibration.
      --data_i         : IN     std_logic;                      --! from input buffer.
      data_i_pos     : IN     std_logic;                      --! from positive differential input pin 
      data_i_neg     : IN     std_logic;                      --! from negative differential input pin 
      fastClk_i      : IN     std_logic;                      --! 2x fabric clock. e.g. 320MHz
      fabricClk_i    : IN     std_logic;                      --! clock for output to FPGA. e.g. 160MHz
      strobe_i       : IN     std_logic;                      --! Strobes once every 4 cycles of fastClk
      data_o         : OUT    std_logic_vector (7 DOWNTO 0);  --! Deserialized data. Interleaved between prompt and delayed  serdes.
                                                              --! data_o(0) is the oldest data
      status_o       : OUT    std_logic_vector(1 downto 0)    --! outputs from IODELAY "busy" 0=prompt,1=delayed
   );

-- Declarations


END ENTITY dualSERDES_1to4 ;

--
ARCHITECTURE rtl OF dualSERDES_1to4 IS

    constant c_S : positive := 4;                     -- ! SERDES division ratio

    signal s_Data_i_d_p   : std_logic;
    signal s_Data_i_d_d   : std_logic;
    signal s_busy_idelay_p  : std_logic;              -- Busy from iodelay.
    signal s_busy_idelay_d  : std_logic;              -- Busy from iodelay.
    signal s_busy			  : std_logic;              -- Busy from the two iodelays.
    signal s_data_o       : std_logic_vector(7 downto 0);  --! Deserialized data
	signal s_cal			 : std_logic := '0'; 				--! Calibration signal
	signal s_rst_cal		: std_logic := '0'; 				--! reset after calibration process
    signal delay_val :std_logic_vector(4 downto 0);
    signal prompt_val :std_logic_vector(4 downto 0);
    signal delayed_out: std_logic_vector(4 downto 0);
    signal prompt_out: std_logic_vector(4 downto 0);
---------------------------------------------
    component delayIO
    generic
    (-- width of the data for the system
    SYS_W       : integer := 1;
    -- width of the data for the device
    DEV_W       : integer := 1);
    port
        (
        -- From the system into the device
        data_in_from_pins_p     : in    std_logic_vector(SYS_W-1 downto 0);
        data_in_from_pins_n     : in    std_logic_vector(SYS_W-1 downto 0);
        data_in_to_device       : out   std_logic_vector(DEV_W-1 downto 0);
        
        -- Input, Output delay control signals
        delay_clk               : in    std_logic;
        in_delay_reset          : in    std_logic;                    -- Active high synchronous reset for input delay
        in_delay_data_ce        : in    std_logic_vector(SYS_W -1 downto 0);                    -- Enable signal for delay 
        in_delay_data_inc       : in    std_logic_vector(SYS_W -1 downto 0);                    -- Delay increment (high), decrement (low) signal
        delay_locked            : out   std_logic;                    -- Locked signal from IDELAYCTRL
        ref_clock               : in    std_logic;                    -- Reference Clock for IDELAYCTRL. Has to come from BUFG.
        
        -- Clock and reset signals
        clk_in                  : in    std_logic;                    -- Fast clock from PLL/MMCM 
        clock_enable            : in    std_logic;
        io_reset                : in    std_logic);                   -- Reset signal for IO circuit
    end component;

  
BEGIN
 
	-- IODELAYs calibration FSM
	IODELAYCal: entity work.IODELAYCal_FSM
    port map (
        clk_i       => fabricClk_i,
        startcal_i  => reset_i,
        busy_i		=> s_busy,
        calibrate_o     => s_cal,
        reset_o         => s_rst_cal
    );


-----------------------------------------------------
--    iodelay_prompt : delayIO
--    port map 
--    ( 
--        data_in_from_pins_p(0) => data_i_pos,
--        data_in_from_pins_n(0) => data_i_neg,
--        data_in_to_device(0) => s_Data_i_d_p,
--        delay_clk => fabricClk_i,
--        in_delay_reset => '0',                    
--        in_delay_data_ce(0) => '1',      
--        in_delay_data_inc(0) => '0',     
        
--        delay_locked => open,                      
--        ref_clock => fabricClk_i,                         
--        clk_in => fastClk_i,                            
--        clock_enable => '1',
--        io_reset => s_rst_cal
--    );
    prompt_val <= "00000";

    IDELAY2_Prompt : IDELAYE2
    generic map (
        IDELAY_TYPE => "VARIABLE",
        DELAY_SRC => "IDATAIN",
        SIGNAL_PATTERN => "DATA"
    )
    port map (
        CNTVALUEOUT=> prompt_out,--5-bitoutput:Countervalueoutput
        DATAOUT=> s_Data_i_d_p,    --1-bitoutput:Delayeddataoutput
        C=> fabricClk_i,    --1-bitinput:Clockinput
        CE=> '0',    --1-bitinput:Activehighenableincrement/decrementinput
        CINVCTRL=> '0' ,--1-bitinput:Dynamicclockinversioninput
        CNTVALUEIN=> prompt_val,--5-bitinput:Countervalueinput
        DATAIN=> '0',    --1-bitinput:Internaldelaydatainput
        IDATAIN => not data_i_neg, --- THIS MUST BE INVERTED!!!!
        --IDATAIN=> data_i,    --1-bitinput:DatainputfromtheI/O
        INC=> '0',    --1-bitinput:Increment/Decrementtapdelayinput
        LD=> '0',    --1-bitinput:LoadIDELAY_VALUEinput
        LDPIPEEN=> '0',--1-bitinput:EnablePIPELINEregistertoloaddatainput
        REGRST=> s_rst_cal    --1-bitinput:Active-highresettap-delayinput
    );
    


----IODELAY2 no longer valid. Replaced using IP delay (SelectIO interface wizard generated)
--  IODELAY2_Prompt : IODELAY2
--    generic map (
--      COUNTER_WRAPAROUND => "STAY_AT_LIMIT" ,  -- "STAY_AT_LIMIT" or "WRAPAROUND" 
--      DATA_RATE          => "SDR",            -- "SDR" or "DDR" 
--      DELAY_SRC          => "IDATAIN",        -- "IO", "ODATAIN" or "IDATAIN" 
--      SERDES_MODE        => "NONE", 			-- <NONE>, MASTER, SLAVE
--      IDELAY_TYPE        => "VARIABLE_FROM_ZERO",
--      IDELAY_VALUE     	=> 0                -- Amount of taps for fixed input delay (0-255)
--      --SIM_TAPDELAY_VALUE=> 10               -- Per tap delay used for simulation in ps
--      )
--    port map (
--      BUSY     => s_busy_idelay_p,      -- 1-bit output: Busy output after CAL
--      DATAOUT  => s_Data_i_d_p,     -- 1-bit output: Delayed data output to ISERDES/input register
--      DATAOUT2 => open,             -- 1-bit output: Delayed data output to general FPGA fabric
--      DOUT     => open,             -- 1-bit output: Delayed data output
--      TOUT     => open,             -- 1-bit output: Delayed 3-state output
--      CAL      => s_cal,      		-- 1-bit input: Initiate calibration input
--      CE       => '0',              -- 1-bit input: Enable INC input
--      CLK      => fabricClk_i,      -- 1-bit input: Clock input
--      IDATAIN  => data_i,           -- 1-bit input: Data input (connect to top-level port or I/O buffer)
--      INC      => '0',              -- 1-bit input: Increment / decrement input
--      IOCLK0   => fastClk_i,        -- 1-bit input: Input from the I/O clock network
--      IOCLK1   => '0',              -- 1-bit input: Input from the I/O clock network
--      ODATAIN  => '0',              -- 1-bit input: Output data input from output register or OSERDES2.
--      RST      => s_rst_cal,            -- 1-bit input: reset_i to 1/2 of total delay period
--      T        => '1'               -- 1-bit input: 3-state input signal
--      );
    
    s_busy_idelay_p <= (prompt_val(0) XOR  prompt_out(0)) OR (prompt_val(1) XOR  prompt_out(1)) OR (prompt_val(2) XOR  prompt_out(2)) OR (prompt_val(3) XOR  prompt_out(3)) OR (prompt_val(4) XOR  prompt_out(4));
	status_o(1) <= s_busy_idelay_p;

--    iodelay_delay : delayIO
--    port map 
--    ( 
--        data_in_from_pins_p(0) => data_i_pos,
--        data_in_from_pins_n(0) => data_i_neg,
--        data_in_to_device(0) => s_Data_i_d_d,
--        delay_clk => fabricClk_i,
--        in_delay_reset => '0',                    
--        in_delay_data_ce(0) => '1',      
--        in_delay_data_inc(0) => '0',     
        
--        delay_locked => open,                      
--        ref_clock => fabricClk_i,                         
--        clk_in => fastClk_i,                            
--        clock_enable => '1',
--        clk_out => open,
--        io_reset => s_rst_cal
--    );

    -- This should be configurable via IPBus. For now fixed value. The tap value is 200 MHz (5 ns). We want
    -- a quarter of the 320 MHz clock (3.125 ns) so 0.78125 ns, corresponding to 6 taps.
    delay_val <= "00110";
    --delay_val <= "00000";
    
    IDELAY2_Delayed : IDELAYE2
    generic map (
        --IDELAY_TYPE => "VARIABLE",
        IDELAY_TYPE => "VAR_LOAD",
        DELAY_SRC => "IDATAIN",
        SIGNAL_PATTERN => "DATA"
    )
    port map (
        CNTVALUEOUT=> delayed_out,--5-bitoutput:Countervalueoutput
        DATAOUT=> s_Data_i_d_d,    --1-bitoutput:Delayeddataoutput
        C=> fabricClk_i,    --1-bitinput:Clockinput
        CE=> '0',    --1-bitinput:Activehighenableincrement/decrementinput
        CINVCTRL=> '0' ,--1-bitinput:Dynamicclockinversioninput
        CNTVALUEIN=> delay_val,--5-bitinput:Countervalueinput
        DATAIN=> '0',    --1-bitinput:Internaldelaydatainput
--        IDATAIN=> data_i,    --1-bitinput:DatainputfromtheI/O
        IDATAIN => data_i_pos,
        INC=> '0',    --1-bitinput:Increment/Decrementtapdelayinput
        LD=> '1',    --1-bitinput:LoadIDELAY_VALUEinput
        LDPIPEEN=> '0',--1-bitinput:EnablePIPELINEregistertoloaddatainput
        REGRST=> s_rst_cal    --1-bitinput:Active-highresettap-delayinput
    );
        

--    IODELAY2_Delayed : IODELAY2
--    generic map (
--        COUNTER_WRAPAROUND => "STAY_AT_LIMIT",  -- "STAY_AT_LIMIT" or "WRAPAROUND" 
--        DATA_RATE          => "SDR",         -- "SDR" or "DDR" 
--        DELAY_SRC          => "IDATAIN",     -- "IO", "ODATAIN" or "IDATAIN" 
--        SERDES_MODE        => "NONE", 			-- <NONE>, MASTER, SLAVE
--        IDELAY_TYPE        => "VARIABLE_FROM_HALF_MAX",
--        IDELAY_VALUE       => 0,             -- Amount of taps for fixed input delay (0-255)
--        IDELAY2_VALUE      => 0             	-- Delay value when IDELAY_MODE="PCI" (0-255)
--    --SIM_TAPDELAY_VALUE => 10              -- Per tap delay used for simulation in ps
--    )
--    port map (
--        BUSY     => s_busy_idelay_d,      -- 1-bit output: Busy output after CAL
--        DATAOUT  => s_Data_i_d_d,     -- 1-bit output: Delayed data output to ISERDES/input register
--        DATAOUT2 => open,             -- 1-bit output: Delayed data output to general FPGA fabric
--        DOUT     => open,             -- 1-bit output: Delayed data output
--        TOUT     => open,             -- 1-bit output: Delayed 3-state output
--        CAL      => s_cal,      		-- 1-bit input: Initiate calibration input
--        CE       => '0',              -- 1-bit input: Enable INC input
--        CLK      => fabricClk_i,      -- 1-bit input: Clock input
--        IDATAIN  => data_i,           -- 1-bit input: Data input (connect to top-level port or I/O buffer)
--        INC      => '0',              -- 1-bit input: Increment / decrement input
--        IOCLK0   => fastClk_i,        -- 1-bit input: Input from the I/O clock network
--        IOCLK1   => '0',              -- 1-bit input: Input from the I/O clock network
--        ODATAIN  => '0',              -- 1-bit input: Output data input from output register or OSERDES2.
--        RST      => s_rst_cal,          -- 1-bit input: reset_i to zero
--        T        => '1'               -- 1-bit input: 3-state input signal
--    );


    --I must check that the CNTVALUEOUT and CNTVALUEIN are the same. TO DO
	--status_o(0) <= s_busy_idelay_d;
	s_busy_idelay_d <= (delay_val(0) XOR  delayed_out(0)) OR (delay_val(1) XOR  delayed_out(1)) OR (delay_val(2) XOR  delayed_out(2)) OR (delay_val(3) XOR  delayed_out(3)) OR (delay_val(4) XOR  delayed_out(4));
	status_o(0) <= s_busy_idelay_d;
	s_busy <= s_busy_idelay_p or s_busy_idelay_d;


-----------------------------------------------------
--ISERDES2 replaced by ISERDESE2 in Series 7
--  ISERDES2_Prompt : ISERDES2
--  generic map (
--    BITSLIP_ENABLE => FALSE,         -- Enable Bitslip Functionality (TRUE/FALSE)
--    DATA_RATE      => "SDR",         -- Data-rate ("SDR" or "DDR")
--    DATA_WIDTH     => 4,           -- Parallel data width selection (2-8)
--    INTERFACE_TYPE => "RETIMED",     -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
--    SERDES_MODE    => "NONE"         -- "NONE", "MASTER" or "SLAVE" 
--   )
--  port map (
--    -- Q1 - Q4: 1-bit (each) output Registered outputs to FPGA logic
--    Q1     => s_Data_o(1),         -- Oldest data
--    Q2     => s_Data_o(3),
--    Q3     => s_Data_o(5),
--    Q4     => s_Data_o(7),         -- most recent data
--    --SHIFTOUT => SHIFTOUTsig,       -- 1-bit output Cascade output signal for master/slave I/O
--    VALID   => open,                 -- 1-bit output Output status of the phase detector
--    BITSLIP => '0',                  -- 1-bit input Bitslip enable input
--    CE0     => '1',                  -- 1-bit input Clock enable input
--    CLK0    => fastClk_i,            -- 1-bit input I/O clock network input
--    CLK1    => '0',                  -- 1-bit input Secondary I/O clock network input
--    CLKDIV  => fabricClk_i,          -- 1-bit input FPGA logic domain clock input
--    D       => s_Data_i_d_p,         -- 1-bit input Input data
--    IOCE    => strobe_i,             -- 1-bit input Data strobe_i input
--    RST     => reset_i,              -- 1-bit input Asynchronous reset_i input
--    SHIFTIN => '0'                   -- 1-bit input Cascade input signal for master/slave I/O
--   );

    ISERDESE2_Prompt: ISERDESE2 --Used to replace ISERDES2. Best of luck with it.
    generic map (
        DATA_RATE => "DDR",
        DATA_WIDTH => 4,
        INTERFACE_TYPE=> "NETWORKING", --Not sure this is correct
        IOBDELAY => "BOTH", --same as above
        SERDES_MODE => "MASTER",
        NUM_CE => 1
    )
    port map (
        O => open,
        Q4     => s_Data_o(1), -- Oldest data
        Q3     => s_Data_o(3),
        Q2     => s_Data_o(5),
        Q1     => s_Data_o(7),
        BITSLIP => '0',
        CE1 => '1',
        CE2 => '1',
        CLKDIVP => '0',
        CLK  => fastClk_i,            -- 1-bit input I/O clock network input
        CLKB  => not fastClk_i, --should be a unique phase shifted clock
        CLKDIV => fabricClk_i,
        DDLY=> s_Data_i_d_p,
        D=> '0', -- data_i
        RST=> reset_i,
        SHIFTIN1 => '0',
        SHIFTIN2 => '0',
        DYNCLKDIVSEL=> '0',
        DYNCLKSEL=> '0', 
        --OCLK => strobe_i,
        OCLK => '0',
        OCLKB => '0',
        OFB=> '0'
    );

--  ISERDES2_Delayed : ISERDES2
--  generic map (
--    BITSLIP_ENABLE => FALSE,       -- Enable Bitslip Functionality (TRUE/FALSE)
--    DATA_RATE      => "SDR",       -- Data-rate ("SDR" or "DDR")
--    DATA_WIDTH     => 4,         -- Parallel data width selection (2-8)
--    INTERFACE_TYPE => "RETIMED",   -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
--    SERDES_MODE    => "NONE"       -- "NONE", "MASTER" or "SLAVE" 
--   )
--  port map (
--	-- Q1 - Q4: 1-bit (each) output Registered outputs to FPGA logic
--    Q1     => s_Data_o(0),           -- oldest data
--    Q2     => s_Data_o(2),
--    Q3     => s_Data_o(4),
--    Q4     => s_Data_o(6),           -- most recent data
--    --SHIFTOUT => SHIFTOUTsig,     -- 1-bit output Cascade output signal for master/slave I/O
--    VALID   => open,               -- 1-bit output Output status of the phase detector
--    BITSLIP => '0',                -- 1-bit input Bitslip enable input
--    CE0     => '1',                -- 1-bit input Clock enable input
--    CLK0    => fastClk_i,          -- 1-bit input I/O clock network input
--    CLK1    => '0',                -- 1-bit input Secondary I/O clock network input
--    CLKDIV  => fabricClk_i,        -- 1-bit input FPGA logic domain clock input
--    D       => s_Data_i_d_d,       -- 1-bit input Input data
--    IOCE    => strobe_i,           -- 1-bit input Data strobe_i input
--    RST     => reset_i,            -- 1-bit input Asynchronous reset_i input
--    SHIFTIN => '0'                 -- 1-bit input Cascade input signal for master/slave I/O
--   );
   
   
   ISERDESE2_Delayed: ISERDESE2 --Used to replace ISERDES2. Best of luck with it.
       generic map (
           DATA_RATE => "DDR",
           DATA_WIDTH => 4,
           INTERFACE_TYPE=> "NETWORKING", --Not sure this is correct
           IOBDELAY => "BOTH", --same as above
           SERDES_MODE => "MASTER",
           NUM_CE => 1
       )
       port map (
           O => open,
           Q4     => s_Data_o(0),           -- oldest data
           Q3     => s_Data_o(2),
           Q2     => s_Data_o(4),
           Q1     => s_Data_o(6), 
           BITSLIP => '0',
           CE1 => '1',
           CE2 => '1',
           CLKDIVP => '0',
           CLK  => fastClk_i,            -- 1-bit input I/O clock network input
           CLKB  => not fastClk_i, --should be a unique phase shifted clock
           CLKDIV => fabricClk_i,
           DDLY=> s_Data_i_d_d,
           D=> '0', -- data_i
           RST=> reset_i,
           SHIFTIN1 => '0',
           SHIFTIN2 => '0',
           DYNCLKDIVSEL=> '0',
           DYNCLKSEL=> '0', 
           OCLK => strobe_i,
           OCLKB => '0',
           OFB=> '0'
       );
-----------------------------------------------------



reg_out : process(fabricClk_i)
begin
  if rising_edge(fabricClk_i) then
    Data_o <= s_Data_o;
  end if;
end process;

END ARCHITECTURE rtl;

