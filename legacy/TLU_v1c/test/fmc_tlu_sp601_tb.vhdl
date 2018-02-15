--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:24:12 02/25/2011
-- Design Name:   
-- Module Name:   /afs/phy.bris.ac.uk/cad/designs/fmc-mtlu/trunk/firmware/synthesis/ise/mTLU/fmc_tlu_sp601_tb.vhd
-- Project Name:  mTLU
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fmc_tlu_sp601
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

use IEEE.Math_real.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY fmc_tlu_sp601_tb IS
END fmc_tlu_sp601_tb;
 
ARCHITECTURE behavior OF fmc_tlu_sp601_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
  COMPONENT fmc_tlu_sp601
    PORT(
      SYSCLK_N : IN  std_logic;
      SYSCLK_P : IN  std_logic;
      D : IN  std_logic;
      Q : OUT  std_logic;
      RST: in std_logic;
      pulse_length : IN  std_logic_vector(3 downto 0)
      );
  END COMPONENT;
    
  component pulse_shaper_scorer
    port (
      clk_i       : in std_logic;         -- ! system clock
      pulse_in_a_i  : in std_logic;         -- ! input ( unstretched) pulse
      pulse_out_a_i : in std_logic; -- ! stretched pulse (output of pulse_stretcher)
      pulse_length_i : in std_logic_vector      --! Parameter to pulse_strecher
      );  
  end component;
  
  --min and max can be swapped quite happily
  procedure rand_int( variable seed1, seed2 : inout positive;
                      min, max : in integer;
                      result : out integer) is
    variable rand     : real;
  begin
    uniform(seed1, seed2, rand);
    result := integer(real(min) + (rand * (real(max)-real(min)) ) );
  end procedure;

   --Inputs
    signal SYSCLK_N : std_logic := '0';
    signal SYSCLK_P : std_logic := '0';
    signal SYSCLK : std_logic := '0';
    signal D : std_logic := '0';
  signal RST : std_logic := '0';
    signal pulse_length : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
    signal Q : std_logic;
 
    constant sysclk_period : time := 10.0 ns;
 
    constant averagePulseWidth : real := 3.0;
    constant averagePulseLow : real := 500.0;
	
BEGIN

  --! set pulse length to 7(?) clock cycles + internal
--	pulse_length <= "0100" ; 
  --! set pulse length to 5 clock cycles + internal
	pulse_length <= "0001" ; 
	
	-- Instantiate the Unit Under Test (UUT)
        uut: fmc_tlu_sp601 PORT MAP (
          SYSCLK_N => SYSCLK_N,
          SYSCLK_P => SYSCLK_P,
          D => D,
          Q => Q,
          RST => RST,
          pulse_length => pulse_length
        );

        --! Instantiate "scorer" process
        --! Examine signals and check for errors
        scorer: pulse_shaper_scorer
          port map (
            clk_i       => sysclk , 
            pulse_in_a_i  => D,
            pulse_out_a_i => Q,
            pulse_length_i => pulse_length
            );  
        
   -- Clock process definitions
   sysclk_process :process
   begin
		sysclk <= '0';
		wait for sysclk_period/2;
		sysclk <= '1';
		wait for sysclk_period/2;
   end process;
	sysclk_n <= not sysclk;
	sysclk_p <= sysclk;
 

   -- Stimulus process
   stim_proc: process
	variable seed1 , seed2 : POSITIVE;
	variable PulseWidth , PulseLow : time ;
	variable Rand : real;
	
   begin
     D <= '0';
     RST <= '1';
      -- hold reset state for 100 ns.
     wait for 100 ns;	
     RST <= '0';
     
     wait for sysclk_period*10;

     -- insert stimulus here 
     for I in 1 to 50 loop
       D<= '1';
       -- wait for random pulse width
       uniform(seed1, seed2, Rand);
       PulseWidth := Rand * averagePulseWidth * sysclk_period;
       wait for PulseWidth;
       D<= '0';
       -- wait for random gap between pulses
       uniform(seed1, seed2, Rand);
       PulseLow := Rand * averagePulseLow * sysclk_period;
       wait for PulseLow;
     end loop;
     wait;
   end process;

END;
