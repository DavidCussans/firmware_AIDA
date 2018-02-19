--=============================================================================
--! @file registerCounter_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture worklib.registerCounter.rtl
--
--! @brief Regularly transfers the input to the output.\n
--! One clock for input , one clock for output\n
--! Can't just put entire bus through a couple of register stages,\n
--! Since this will just swap meta-stability issues for race issues.
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 24/Nov/12
--
--! @version v0.1
--
--! @details A six stage "ring oscillator" is used to generate two strobes.
--! One reads data into a register. The other registers the data to the output
--! Three stages are clocked on clk_write_i , three stages are clocked on clk_read_i
--! We could use gray-scale and put through registers, but this method
--! should work well enough at the expense of latency.\n
--! \n
--! The time taken for an edge to travel round the complete loop is
--! 2 cycles of clk_read_i and 2 cycles of clk_write_i plus two intervals
--! that depend on the relative phase of clk_read_i and clk_write_i
--!
--!
--!
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--!
--! <b>Modified by:</b>\n
--! Author:
--! David Cussans, 26/2/14 - Added registers to output to aid timing closure.
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity registerCounter is
  
  generic (
    g_DATA_WIDTH : positive := 15);     -- ! Width of counter

  port (
    clk_input_i : in std_logic;         -- ! clock for input
    data_i      : in std_logic_vector(g_DATA_WIDTH-1 downto 0);  -- ! data to transfer to output
    data_o     : out std_logic_vector(g_DATA_WIDTH-1 downto 0);  -- ! Data now in clk_read_i domain
    clk_output_i  : in std_logic);        -- ! clock for output

end registerCounter;

architecture rtl of registerCounter is
  signal s_ring_d0 , s_ring_d1 , s_ring_d2 , s_ring_d3 , s_ring_d4, s_ring_d5: std_logic := '0';  -- stages in "ring oscillator" used to generate strobes
  signal s_registered_data : std_logic_vector(data_i'range) := ( others => '0');  -- ! Register to store data between clock domains

  signal s_read_strobe , s_write_strobe : std_logic := '0';  -- ! Strobes high to register data from input and to output
  
begin  -- rtl

  -- purpose: part of "ring oscillator" transfering strobe between clock domains
  -- type   : combinational
  -- inputs : clk_read_i
  -- outputs: 
  p_gen_capture_strobe: process (clk_input_i)
  begin  -- process p_gen_capture_strobe
    if rising_edge(clk_input_i) then
      s_ring_d0 <= not s_ring_d5;
      s_ring_d1 <= s_ring_d0;
      s_ring_d2 <= s_ring_d1;

      if s_read_strobe = '1' then
        s_registered_data <= data_i;
      end if;
    end if;    
  end process p_gen_capture_strobe;

  s_read_strobe <= s_ring_d1 xor s_ring_d2;  --! Generate a strobe with
                                                --width one clk_read_i
  
  -- purpose: part of "ring oscillator" transfering strobe between clock domains
  -- type   : combinational
  -- inputs : clk_output_i
  -- outputs: 
  p_gen_output_strobe: process (clk_output_i)
  begin  -- process p_gen_output_strobe
    if rising_edge(clk_output_i) then
      s_ring_d3 <= s_ring_d2;
      s_ring_d4 <= s_ring_d3;
      s_ring_d5 <= s_ring_d4;

      if s_write_strobe = '1' then
        data_o <= s_registered_data;
      end if;
    end if;    
  end process p_gen_output_strobe;

  s_write_strobe <= s_ring_d4 xor s_ring_d5;  --! Generate a strobe
                                                  --
end rtl;
