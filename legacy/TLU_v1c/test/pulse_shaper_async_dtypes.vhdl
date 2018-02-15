----- CELL pulse_shaper                       -----
--
--@file
--
--@brief Output goes high when input goes high ( asyncnronous to system clock).
--! Output goes low again a controllable number of clock cycles later,
--! synchronous with the rising edge of the clock.
--! Gap of at least one clock cycle before output goes high again.
--! Pile-up will result in timing errors ( veto-cleared sync. with clock )
--
--! Output won't retrigger if input is still high at end of pulse.
--
--! Fill top bits of PULSE_MASK
--! For example for a pulse width of 4.X clock cycles load '1111000000000000'
--
-- David Cussans, Feb 2011
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity pulse_shaper_async_dtypes is
  generic (
    MASK_WIDTH : integer := 16);  --! Width of shift register and hence maximum width of pulse
  port (
    D          : in  std_logic;         --! Input pulse
    Q          : out std_logic;         --! output pulse
    CLK        : in  std_logic;         --! Clock , rising edge active
    PULSE_MASK : in  std_logic_vector(MASK_WIDTH-1 downto 0));  -- ! preload for shift-register. Fill with number of '1's that the ouput pulse should be

end pulse_shaper_async_dtypes;

architecture rtl of pulse_shaper_async_dtypes is

  component dtype_fdpe
    port(
      Q : out std_logic;      --! Output
      CLK   : in std_logic;   --! Clock - rising edge active
      D   : in std_logic;     --! Input
      CE  : in std_logic;     --! Clock enable
      PRE : in std_logic      --! Asynchronous preload
      );
  end component;
  
  signal shift_reg : std_logic_vector(MASK_WIDTH downto 0) := ( others => '0' );  --! shift register holding '1's to be shifted out

    signal preload : std_logic_vector(MASK_WIDTH-1 downto 0) := ( others => '0' ); --! Mask register holding '1's to be shifted out

  signal vetoed_pulse : std_logic := '0';  --! input signal after internal veto

  signal Q_R1 , Q_R2 , D_R1 : std_logic := '0';       --! Output, input  delayed by one clock. Used
                                        --to form veto.
  
begin  -- rtl

  shift_reg(0) <= '0';   --! Shift in zero at start of SReg.

  --! Generate a shift register out of flip-flops.
  --! Unfortunately SRL16 , SRL32 don't have async. load.
  SR : for bit in 0 to MASK_WIDTH-1 generate
    preload(bit) <=  (vetoed_pulse and pulse_mask(bit));
    dtype : dtype_fdpe
      port map (
        Q   => shift_reg(bit+1),
        D   => shift_reg(bit),
        CLK => CLK,
        CE  => '1',
        PRE => preload(bit)) ;
  end generate SR ;

  Q <= shift_reg(MASK_WIDTH);           --! Take output from end of SR.

  q_reg : dtype_fdpe                     --! Delay the output signal
    port map (
      Q   => Q_R1,
      D   => shift_reg(MASK_WIDTH),     
      CLK => CLK,
      CE  => '1',
      PRE => '0') ;

  d_reg : dtype_fdpe                     --! Delay the input signal
    port map (
      Q   => D_R1,
      D   => D,     
      CLK => CLK,
      CE  => '1',
      PRE => '0') ;

  --! Arrgh... problems with glitching if veto immediately.
  -- put in a transparent latch or something to force some delay???
  vetoed_pulse <= D and (not shift_reg(MASK_WIDTH) ) and (not Q_R1) and (not D_R1);
  
end rtl;
