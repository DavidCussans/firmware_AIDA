--=============================================================================
--! @file synchronizeRegisters_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture worklib.synchronizeRegisters.rtl
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.ipbus_reg_types.all;

--! @brief Regularly transfers the input to the output.
--! One clock for input , one clock for output
--! Can't just put entire bus through a couple of register stages,
--! Since this will just swap meta-stability issues for race issues.
--!
--! @author David Cussans , David.Cussans@bristol.ac.uk
--!
--! @date 24/Nov/12
--!
--! @version v0.1
--!
--! @details A six stage "ring oscillator" is used to generate two strobes.
--! One reads data into a register. The other registers the data to the output
--! Three stages are clocked on clk_write_i , three stages are clocked on clk_read_i
--! The time taken for an edge to travel round the complete loop is
--! 2 cycles of clk_read_i and 2 cycles of clk_write_i plus two intervals
--! that depend on the relative phase of clk_read_i and clk_write_i
--!
--! Based on registerCounters
--!
--! <b>Modified by:</b>\n
--! Author:
--! David Cussans, 26/2/14 - Added registers to output to aid timing closure.

entity synchronizeRegisters is
  
  generic (
    --g_DATA_WIDTH : positive := 15;
    g_NUM_REGISTERS : positive := 1);     --! Number of registers to synchronize

  port (
    clk_input_i : in std_logic;         --! clock for input
    data_i      : in ipb_reg_v(g_NUM_REGISTERS-1 downto 0);  --! array of registers to transfer to output
    data_o     : out ipb_reg_v(g_NUM_REGISTERS-1 downto 0);  --! Data now in clk_output_i domain
    clk_output_i  : in std_logic);        --! clock for output

end synchronizeRegisters;

architecture rtl of synchronizeRegisters is
  signal s_ring_d0 , s_ring_d1 , s_ring_d2 , s_ring_d3 , s_ring_d4, s_ring_d5: std_logic := '0';  -- stages in "ring oscillator" used to generate strobes
  signal s_registered_data : ipb_reg_v(data_i'range) := ( others => ( others => '0'));  --! Register to store data between clock domains

  signal s_read_strobe , s_write_strobe : std_logic := '0';  --! Strobes high to register data from input and to output
  
begin  -- rtl

  --! purpose: part of "ring oscillator" transfering strobe between clock domains
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

  s_read_strobe <= s_ring_d1 xor s_ring_d2; --! Generate a strobe (with width one clk_read_i) that captures data at input
  
  --! purpose: part of "ring oscillator" transfering strobe between clock domains
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

  s_write_strobe <= s_ring_d4 xor s_ring_d5; --! Generate the strobe that causes data to be written to output

end rtl;
