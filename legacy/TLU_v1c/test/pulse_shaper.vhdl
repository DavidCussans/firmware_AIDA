--=============================================================================
--! @file pulse_shaper.vhdl
--=============================================================================

--! Standard library
Library IEEE;

--! Standard logic package
use IEEE.STD_LOGIC_1164.all;

--! Xilinx library
Library UNISIM;

--! Xilinx component
use UNISIM.vcomponents.all;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group --
-- --
-------------------------------------------------------------------------------
--
-- unit name: pulse_shaper
--
--! @brief  Output goes high when input goes high ( asyncnronous to system clock).
--! Output goes low again a controllable number of clock cycles later,
--! synchronous with the rising edge of the clock.
--! Gap of at least one clock cycle before output goes high again.
--
--! @author David.Cussans@bristol.ac.uk
--
--! @date 7/May/2011
--
--! @version 0.1
--
--! @details Output won't retrigger if input is still high at end of pulse.
--! Length of pulse (in clock cycles) is pulse_length+4
--
--! <b>Dependencies:</b>\n
--! dtype_fdpe
--! dtype_fdr
--! dtype_fds
--!
--! <b>References:</b>\n
--! <reference one> \n
--! <reference two>
--!
--! <b>Modified by:</b>\n
--! Author: <name>
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! <date> <initials> <log>\n
--! <extended description>
--
-------------------------------------------------------------------------------
--! @todo Broaden pulse fed into set/reset flip-flop \n
--
-------------------------------------------------------------------------------

entity pulse_shaper is
  port (
    D_a_i                   : in  std_logic;         --! Input pulse
    Q_a_o                   : out std_logic;         --! output pulse
    CLK_i                 : in  std_logic;         --! Clock , rising edge active
    RST_i                 : in std_logic;         --! Hold high for PULSE_LENGTH+4 
    PULSE_LENGTH_i        : in  std_logic_vector(3 downto 0) --! length of output pulse
    );  

end pulse_shaper;

architecture rtl of pulse_shaper is

  component dtype_fdpe
    port(
      Q : out std_logic;      --! Output
      CLK   : in std_logic;   --! Clock - rising edge active
      D   : in std_logic;     --! Input
      CE  : in std_logic;     --! Clock enable
      PRE : in std_logic      --! Asynchronous preload
      );
  end component;

  
  component dtype_fd
    port(
      Q : out std_logic;     --! Output
      CLK   : in std_logic;  --! Clock - rising edge active
      D   : in std_logic     --! Input
      );
  end component;
  
  component dtype_fds
    port(
      Q : out std_logic;     --! Output
      CLK   : in std_logic;  --! Clock - rising edge active
      SET : in std_logic;    --! Active high. Synchronous
      D   : in std_logic     --! Input
      );
  end component;

    component dtype_fdr
    port(
      Q : out std_logic;     --! Output
      CLK   : in std_logic;  --! Clock - rising edge active
      RST : in std_logic;    --! Active high. Synchronous
      D   : in std_logic     --! Input
      );
  end component;

  signal s_vetoed_pulse_a : std_logic := '0';  --! input signal after internal veto

  signal s_async_pulse_a : std_logic := '0';  -- ! Output from pre-settable D-type
  
  signal s_srl_ce , s_srl_d , s_srl_q : std_logic := '0';  -- ! Input, output from shift reg.

  signal s_Q_d1 , s_Q_d2 , s_Q_d3 : std_logic := '0';       --! Output, delayed by one clock. Used to form veto.

  signal s_D_d1 , s_D_d2  : std_logic := '0';       --! Input, delayed by one clock. Used to form veto.
  
begin  -- rtl

  --! Input to SRL16 pulses high for one cycle on rising edge. Goes high on RST
  s_srl_d <= s_Q_d2 and (not s_Q_d3);         

  --! Clock the SRL if the output is high ( or if the output of the SRL is high.... )
  s_srl_ce <= s_Q_d2 or s_srl_q ;
  
  SRL16E_inst : SRL16E
    generic map (
      INIT => X"0000")
    port map (
      Q => S_SRL_Q, -- SRL data output
      A0 => PULSE_LENGTH_i(0), -- Select[0] input
      A1 => PULSE_LENGTH_i(1), -- Select[1] input
      A2 => PULSE_LENGTH_i(2), -- Select[2] input
      A3 => PULSE_LENGTH_i(3), -- Select[3] input
      CE => S_SRL_CE, -- Clock enable input
      CLK => CLK_i, --Clock input
      D => S_SRL_D -- SRL data input
      );

  --! In order for a pulse to get to the PREset input, the output must be low
  --! and the input must be low. Goes low on RST high
  s_vetoed_pulse_a <= D_a_i and (not s_Q_d2) and (not s_D_d2);
  
  Q_a_o <= s_async_pulse_a;                     --! Connect output of FDPE to output.

  --! Async. set, sync clear.
  async_reg: dtype_fdpe
    port map (
      Q   => s_async_pulse_a,
      D   => '0',                       --! Clock in zero when shift reg. spits out a '1'
      CLK => CLK_i,
      CE  => S_SRL_Q,
      PRE => s_vetoed_pulse_a ) ;
    
  q_reg1 : dtype_fdr                     --! Delay the output signal
    port map (
      Q   => s_Q_d1,
      D   => s_async_pulse_a,
      RST => RST_i,
      CLK => CLK_i
      ) ;

  --! Delay the output signal
  q_reg2 : dtype_fds                     
    port map (
      Q   => s_Q_d2,
      D   => s_Q_d1,
      SET => RST_i, --! Take high on reset.
      CLK => CLK_i
      ) ;

  --! Delay the output signal
  q_reg3 : dtype_fdr                     
    port map (
      Q   => s_Q_d3,
      D   => s_Q_d2,
      RST => RST_i, --! Take low on reset
      CLK => CLK_i
      ) ;

  d_reg1 : dtype_fd                     --! Delay the input
    port map (
      Q   => s_D_d1,
      D   => D_a_i,     
      CLK => CLK_i
      ) ;

  d_reg2 : dtype_fds                     --! Delay the input
    port map (
      Q   => s_D_d2,
      D   => s_D_d1,
      SET => RST_i,
      CLK => CLK_i
      ) ;


  
end rtl;
