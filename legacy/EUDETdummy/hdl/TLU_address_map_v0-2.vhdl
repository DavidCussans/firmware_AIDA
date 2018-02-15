--
-- TLU_address_map_v0-2.vhdl
--
--
-- Generated on Mon Feb  8 18:18:05 2010
--
--
-- package containg address map and type definitions for JRA1 TLU
--
-- Generated by script make_tlu_address_map.pl
--
-- Do not edit by hand! 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package TLU_Address_Map_v02 is
  
  constant NUMBER_OF_DUT : integer := 6; -- how many devices
                                  -- (including telescope devices)
                                  -- in system
											 
  constant BEAM_TRIGGER_MASK_WIDTH : integer := 12; -- should be three times the # trigger
  constant NUMBER_OF_BEAM_TRIGGERS : integer := 4;
  
  constant TIMESTAMP_WIDTH : integer := 64;
  constant TIMESTAMP_OUTPUT_WIDTH : integer := 16;
  constant NUMBER_WORDS_IN_TIMESTAMP : integer := 4;
  constant TRIGGER_COUNTER_WIDTH : integer := 32;
  constant TRIGGER_DATA_WIDTH : integer := 32;
  constant STROBE_COUNTER_WIDTH : integer := 32;  -- width for recurring strobe pulses.
  constant BUFFER_POINTER_WIDTH : integer := 16;    --  width of pointer
  constant BUFFER_COUNTER_WIDTH : integer := 12;  -- this is the width of
                                                    -- the counter,
                                                    -- *NOT* the pointer
                                                    -- ( which has to be
                                                    -- an integer number
                                                    -- of bytes )
  constant OUTPUT_BUFFER_COUNTER_WIDTH : integer := BUFFER_COUNTER_WIDTH+2;  -- pointer into 16-bit output of DPR
  constant BUFFER_DEPTH : integer := 4096;          -- 2^BUFFER_COUNTER_WIDTH
  constant BUFFER_HEADROOM : integer := 16; -- leave this many entries in 
                                            -- buffer when siganlling full
  constant NUM_WORDS_IN_LONGLONG : integer := 4;  -- Number of 16-bit words in a 64-bit word
  
  -----------------------------------------------------------------------------
  -- define which bits in RESET_REGISTER reset which counters/pointers...
  -----------------------------------------------------------------------------
  constant TIMESTAMP_RESET_BIT : integer := 0;
  constant TRIGGER_COUNTER_RESET_BIT : integer := 1;
  constant BUFFER_POINTER_RESET_BIT : integer := 2;
  constant TRIGGER_FSM_RESET_BIT : integer := 3;
  constant BEAM_TRIGGER_FSM_RESET_BIT : integer := 4;
  constant DMA_CONTROLLER_RESET_BIT : integer := 5;
  constant TRIGGER_SCALERS_RESET_BIT : integer := 6;
  constant CLOCK_GEN_RESET_BIT : integer := 7;

  constant ENABLE_DMA_BIT : integer := 0;
  constant RESET_DMA_COUNTER_BIT : integer := 1;
  
  -----------------------------------------------------------------------------
  -- Constants for internal trigger generation
  -----------------------------------------------------------------------------
  constant CALIBRATION_TRIGGER_COUNTER_WIDTH : integer := 8;
  constant SLOW_CLOCK_COUNTER_WIDTH : integer := 16;  -- needs to store 48000
  --constant SLOW_CLOCK_RATIO : std_logic_vector (SLOW_CLOCK_COUNTER_WIDTH-1 downto 0) := "1011101110000000";  -- ratio between 48MHz and 1kHz
  -- hack for Santos...
  constant SLOW_CLOCK_RATIO : std_logic_vector (SLOW_CLOCK_COUNTER_WIDTH-1 downto 0) :=   "0000000111100000";  -- ratio between 48MHz and 100kHz

  -----------------------------------------------------------------------------
  -- define sub-types for internal trigger scalers.
  -----------------------------------------------------------------------------
  constant SCALER_NUMBER_OF_BYTES : integer := 2;
  subtype TRIGGER_SCALER is std_logic_vector(8*SCALER_NUMBER_OF_BYTES - 1 downto 0);
  type TRIGGER_SCALER_ARRAY is array ( NUMBER_OF_BEAM_TRIGGERS-1 downto 0) of TRIGGER_SCALER;
  
  -----------------------------------------------------------------------------
  -- define which bits for I2C lines
  -----------------------------------------------------------------------------
  constant I2C_SDA_OUT_BIT : integer := 0;
  constant I2C_SDA_IN_BIT : integer := 1;
  constant I2C_SCL_OUT_BIT : integer := 2;
  constant I2C_SCL_IN_BIT : integer := 3;
  constant WIDTH_OF_I2C_SELECT_PORT : integer := 2;

  -- I2C bus numbers ( write to register to select )
  constant I2C_BUS_MOTHERBOARD  : integer := 3;  
  constant I2C_BUS_HDMI         : integer := 2;
  constant I2C_BUS_LEMO         : integer := 1;
  constant I2C_BUS_DISPLAY         : integer := 0;

  -- List I2C PCA9555 devices.
  constant I2C_BUS_MOTHERBOARD_LED_IO : integer := 0;
  constant I2C_BUS_MOTHERBOARD_TRIGGER_ENABLE_IPSEL_IO : integer := 1;
  constant I2C_BUS_MOTHERBOARD_RESET_ENABLE_IO : integer := 2;
  constant I2C_BUS_MOTHERBOARD_FRONT_PANEL_IO : integer := 3;
  constant I2C_BUS_MOTHERBOARD_LCD_IO : integer := 4;

  constant I2C_BUS_LEMO_RELAY_IO : integer := 0;

  -- This is a bit of a cock-up. The PCA9555 attached to the LEDs changed address between version "b" ( = 1 ) and version "c" (= 0) 
  constant I2C_BUS_LEMO_LED_IO_VB : integer := 1;
  
  constant I2C_BUS_LEMO_LED_IO : integer := 0;
  constant I2C_BUS_LEMO_ADC : integer := 2;

  -----------------------------------------------------------------------------
    -- mapping of IO pins onto signals in design.
  -----------------------------------------------------------------------------
  type beam_trigger_inputs is array ( 0 to 3 ) of integer;
  -- Assumes Bonn discriminator board ( ie 1,0,3,2)
  constant BEAM_TRIG_IN_BIT : beam_trigger_inputs := (9,6,11,8);
  
  type dut_io is array ( 0 to NUMBER_OF_DUT-1 ) of integer;
  constant TRIGGER_OUTPUT_BIT : dut_io := (1,0,3,2,5,4);
  constant DUT_RESET_BIT : dut_io := (13,12,15,14,17,16);
  constant DUT_BUSY_BIT : dut_io := (27,26,29,28,31,30);
  constant DUT_CLOCK_BIT : dut_io := (38,41,43,42,44,46);

 -- constant DUT_LED_BIT : dut_io := (18,21,20,23,22,25);
  type i2c_select_array is array ( 0 to WIDTH_OF_I2C_SELECT_PORT-1)of integer ;
  constant I2C_BUS_SELECT_IO_BITS : i2c_select_array := ( 25 , 22 );
  constant I2C_SCL_OUT_IO_BIT : integer := 18;
  constant I2C_SDA_OUT_IO_BIT : integer := 21;
  constant I2C_SCL_IN_IO_BIT : integer := 20;
  constant I2C_SDA_IN_IO_BIT : integer := 23;

  constant I2C_FRONT_PANEL_INTERRUPT : integer := 32;
  
  type gpio is array (0 to 3) of integer;  -- mapping for gpio bits
  constant GPIO_BIT : gpio := (37,36,35,34);
  -----------------------------------------------------------------------------
  constant FIRMWARE_ID : std_logic_vector(7 downto 0) := "01000100" ;
-- FIRMWARE_ID = 68

 constant BASE_ADDRESS : std_logic_vector(15 downto 0) := "0010000000000000" ;
-- BASE_ADDRESS = 8192

  constant NUMBER_OF_BITS_TO_DECODE : integer := 7 ;  -- how many bits of the address should be decoded?
  constant FIRMWARE_ID_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000000" ;
  constant DUT_BUSY_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000001" ;
  constant DUT_RESET_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000010" ;
  constant DUT_TRIGGER_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000011" ;
  constant DUT_MASK_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000100" ;
  constant TRIG_INHIBIT_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000101" ;
  constant RESET_REGISTER_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000110" ;
  constant INITIATE_READOUT_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0000111" ;
  constant STATE_CAPTURE_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001000" ;
  constant TRIGGER_FSM_STATUS_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001001" ;
  constant BEAM_TRIGGER_FSM_STATUS_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001010" ;
  constant DMA_STATUS_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001011" ;
  constant REGISTERED_BUFFER_POINTER_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001100" ;
  constant REGISTERED_BUFFER_POINTER_ADDRESS_BYTES : integer := 2 ;
  constant REGISTERED_BUFFER_POINTER_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001100" ;
  constant REGISTERED_BUFFER_POINTER_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001101" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001110" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_BYTES : integer := 8 ;
  constant REGISTERED_TIMESTAMP_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001110" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0001111" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010000" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010001" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_4 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010010" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_5 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010011" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_6 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010100" ;
  constant REGISTERED_TIMESTAMP_ADDRESS_7 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010101" ;
  constant REGISTERED_TRIGGER_COUNTER_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010110" ;
  constant REGISTERED_TRIGGER_COUNTER_ADDRESS_BYTES : integer := 4 ;
  constant REGISTERED_TRIGGER_COUNTER_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010110" ;
  constant REGISTERED_TRIGGER_COUNTER_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0010111" ;
  constant REGISTERED_TRIGGER_COUNTER_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011000" ;
  constant REGISTERED_TRIGGER_COUNTER_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011001" ;
  constant BUFFER_POINTER_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011010" ;
  constant BUFFER_POINTER_ADDRESS_BYTES : integer := 2 ;
  constant BUFFER_POINTER_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011010" ;
  constant BUFFER_POINTER_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011011" ;
  constant TIMESTAMP_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011100" ;
  constant TIMESTAMP_ADDRESS_BYTES : integer := 8 ;
  constant TIMESTAMP_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011100" ;
  constant TIMESTAMP_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011101" ;
  constant TIMESTAMP_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011110" ;
  constant TIMESTAMP_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0011111" ;
  constant TIMESTAMP_ADDRESS_4 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100000" ;
  constant TIMESTAMP_ADDRESS_5 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100001" ;
  constant TIMESTAMP_ADDRESS_6 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100010" ;
  constant TIMESTAMP_ADDRESS_7 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100011" ;
  constant TRIGGER_COUNTER_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100100" ;
  constant TRIGGER_COUNTER_ADDRESS_BYTES : integer := 4 ;
  constant TRIGGER_COUNTER_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100100" ;
  constant TRIGGER_COUNTER_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100101" ;
  constant TRIGGER_COUNTER_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100110" ;
  constant TRIGGER_COUNTER_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0100111" ;
  constant BEAM_TRIGGER_AMASK_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101000" ;
  constant BEAM_TRIGGER_OMASK_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101001" ;
  constant BEAM_TRIGGER_VMASK_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101010" ;
  constant INTERNAL_TRIGGER_INTERVAL : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101011" ;
  constant BEAM_TRIGGER_IN_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101100" ;
  constant DUT_RESET_DEBUG_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101101" ;
  constant DUT_DEBUG_TRIGGER_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101110" ;
  constant DUT_CLOCK_DEBUG_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0101111" ;
  constant DUT_I2C_BUS_SELECT_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110000" ;
  constant DUT_I2C_BUS_DATA_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110001" ;
  constant CLOCK_SOURCE_SELECT_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110010" ;
  constant TRIGGER_IN0_COUNTER_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110011" ;
  constant TRIGGER_IN0_COUNTER_BYTES : integer := 2 ;
  constant TRIGGER_IN0_COUNTER_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110011" ;
  constant TRIGGER_IN0_COUNTER_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110100" ;
  constant TRIGGER_IN1_COUNTER_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110101" ;
  constant TRIGGER_IN1_COUNTER_BYTES : integer := 2 ;
  constant TRIGGER_IN1_COUNTER_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110101" ;
  constant TRIGGER_IN1_COUNTER_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110110" ;
  constant TRIGGER_IN2_COUNTER_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110111" ;
  constant TRIGGER_IN2_COUNTER_BYTES : integer := 2 ;
  constant TRIGGER_IN2_COUNTER_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0110111" ;
  constant TRIGGER_IN2_COUNTER_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111000" ;
  constant TRIGGER_IN3_COUNTER_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111001" ;
  constant TRIGGER_IN3_COUNTER_BYTES : integer := 2 ;
  constant TRIGGER_IN3_COUNTER_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111001" ;
  constant TRIGGER_IN3_COUNTER_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111010" ;
  constant REGISTERED_PARTICLE_COUNTER_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111011" ;
  constant REGISTERED_PARTICLE_COUNTER_ADDRESS_BYTES : integer := 4 ;
  constant REGISTERED_PARTICLE_COUNTER_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111011" ;
  constant REGISTERED_PARTICLE_COUNTER_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111100" ;
  constant REGISTERED_PARTICLE_COUNTER_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111101" ;
  constant REGISTERED_PARTICLE_COUNTER_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111110" ;
  constant REGISTERED_AUX_COUNTER_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111111" ;
  constant REGISTERED_AUX_COUNTER_ADDRESS_BYTES : integer := 4 ;
  constant REGISTERED_AUX_COUNTER_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "0111111" ;
  constant REGISTERED_AUX_COUNTER_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000000" ;
  constant REGISTERED_AUX_COUNTER_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000001" ;
  constant REGISTERED_AUX_COUNTER_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000010" ;
  constant HANDSHAKE_MODE_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000011" ;
  constant BUFFER_STOP_MODE_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000100" ;
  constant WRITE_TRIGGER_BITS_MODE_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000101" ;
  constant TRIGGER_PATTERN_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000110" ;
  constant TRIGGER_PATTERN_ADDRESS_BYTES : integer := 2 ;
  constant TRIGGER_PATTERN_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000110" ;
  constant TRIGGER_PATTERN_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1000111" ;
  constant AUX_PATTERN_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001000" ;
  constant AUX_PATTERN_ADDRESS_BYTES : integer := 2 ;
  constant AUX_PATTERN_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001000" ;
  constant AUX_PATTERN_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001001" ;
  constant STROBE_WIDTH_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001010" ;
  constant STROBE_WIDTH_ADDRESS_BYTES : integer := 4 ;
  constant STROBE_WIDTH_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001010" ;
  constant STROBE_WIDTH_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001011" ;
  constant STROBE_WIDTH_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001100" ;
  constant STROBE_WIDTH_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001101" ;
  constant STROBE_PERIOD_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001110" ;
  constant STROBE_PERIOD_ADDRESS_BYTES : integer := 4 ;
  constant STROBE_PERIOD_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001110" ;
  constant STROBE_PERIOD_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1001111" ;
  constant STROBE_PERIOD_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010000" ;
  constant STROBE_PERIOD_ADDRESS_3 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010001" ;
  constant STROBE_ENABLE_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010010" ;
  constant TRIGGER_FSM_STATUS_VALUE_ADDRESS_BASE : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010011" ;
  constant TRIGGER_FSM_STATUS_VALUE_ADDRESS_BYTES : integer := 3 ;
  constant TRIGGER_FSM_STATUS_VALUE_ADDRESS_0 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010011" ;
  constant TRIGGER_FSM_STATUS_VALUE_ADDRESS_1 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010100" ;
  constant TRIGGER_FSM_STATUS_VALUE_ADDRESS_2 : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010101" ;
  constant ENABLE_DUT_VETO_ADDRESS : std_logic_vector(NUMBER_OF_BITS_TO_DECODE-1 downto 0) := "1010110" ;

  constant ADDRESS_MAP_SIZE : integer := 87 ;

end package TLU_Address_Map_v02 ;