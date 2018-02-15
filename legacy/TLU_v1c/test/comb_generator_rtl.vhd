--@file
--
--@brief Generates a series of "10" bits followed by a run of "0". The number
-- of "10" is the same as the output bit plus one.
--
--@detailed i.e. output(0) has "1000......0010......" etc.
-- output(1) has "1010.......001010......" etc. and so on.
--
-- David Cussans, February 2011
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;


entity comb_generator is
  
  generic (
    g_SEQUENCE_LENGTH : positive := 4;  -- --! Length of sequence before repeat = 2^g_SEQUENCE_LENGTH
    g_N_OUTPUT_BITS   : positive := 5);  -- --! Number of bits in output. g_N_OUTPUT_BITS<2^g_SEQUENCE_LENGTH

  port (
    clk_i   : in  std_logic;            -- --! Rising edge active
    reset_i : in  std_logic;            -- --! Active high. Synchronous
    data_o  : out std_logic_vector(g_N_OUTPUT_BITS-1 downto 0));  --! Output pattern

  subtype t_COMB_ARRAY is std_logic_vector( 2**g_SEQUENCE_LENGTH -1 downto 0);
  -- Function to generate a "10101010" pattern. 
  function f_GenerateComb ( v_Length : positive ) return t_COMB_ARRAY is
    variable v_Comb : t_COMB_ARRAY ;
    begin
      for v_bit in v_Comb'range loop
        if ((v_bit mod 2) = 0) then
          v_Comb(v_bit) := '0';
        else
          v_Comb(v_bit) := '1';
        end if;
      end loop;
      return v_Comb;
    end f_GenerateComb;
    
end entity comb_generator;

architecture rtl of comb_generator is

  signal s_counter : unsigned( g_SEQUENCE_LENGTH-1 downto 0) := ( others => '0');  -- --! roll over of the counter sets the sequence length
  constant c_SEQUENCE_WIDTH : positive := 2**g_SEQUENCE_LENGTH;  -- generate a constant to make code easier to read...
  constant c_ZEROS : std_logic_vector(c_SEQUENCE_WIDTH-1 downto 0) := (others => '0');  --! a vector of zeros to pad out sequence
  constant c_COMB : std_logic_vector(c_SEQUENCE_WIDTH-1 downto 0)  := f_GenerateComb(1);  -- --! Pattern of 1 and 0
  subtype t_sequence is std_logic_vector(c_SEQUENCE_WIDTH-1 downto 0);
  type t_patternArray is array(g_N_OUTPUT_BITS-1 downto 0) of t_sequence;
  signal s_pattern : t_patternArray := ( others => ( others => '0'));  --! Array of patterns. One for each output bit.
  
begin  -- architecture rtl

  gen_bits: for v_bitNumber in 1 to g_N_OUTPUT_BITS generate

    -- purpose: Generates the comb pattern. Different for each bit
    -- type   : sequential
    -- inputs : clk_i, reset_i, s_counter
    -- outputs: data_o(v_bitNumber)
    p_genPattern: process (clk_i, reset_i) is
    begin  -- process p_genPattern
      if rising_edge(clk_i) then  -- rising clock edge
        if reset_i = '1' then             -- synchronous reset (active high)
          s_counter <= ( others => '0');
        else
          
          s_counter <= s_counter + 1 ;
          data_o(v_bitNumber-1) <= s_pattern(v_bitNumber-1)(0);
          
          if ( s_counter = 0 ) then
            s_pattern(v_bitNumber-1) <= c_COMB( (v_bitNumber*2)-1 downto 0) & c_ZEROS( c_SEQUENCE_WIDTH - (v_bitNumber*2)-1 downto 0);
          else
            s_pattern(v_bitNumber-1) <= '0' & s_pattern(v_bitNumber-1)(c_SEQUENCE_WIDTH-1 downto 1);
          end if;
        end if;
      end if;
    end process p_genPattern;
    
  end generate gen_bits;
  


end architecture rtl;




