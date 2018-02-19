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



entity synchronizeRegisters_fifo is
  
  generic (
    --g_DATA_WIDTH : positive := 15;
    g_NUM_REGISTERS : positive := 1);     --! Number of registers to synchronize

  port (
    clk_input_i : in std_logic;         --! clock for input
    data_i      : in ipb_reg_v(g_NUM_REGISTERS-1 downto 0);  --! array of registers to transfer to output
    data_o     : out ipb_reg_v(g_NUM_REGISTERS-1 downto 0);  --! Data now in clk_output_i domain
    clk_output_i  : in std_logic);        --! clock for output

end synchronizeRegisters_fifo;

architecture rtl of synchronizeRegisters_fifo is
  signal s_ring_d0 , s_ring_d1 , s_ring_d2 , s_ring_d3 , s_ring_d4, s_ring_d5: std_logic := '0';  -- stages in "ring oscillator" used to generate strobes
  signal s_registered_data : ipb_reg_v(data_i'range) := ( others => ( others => '0'));  --! Register to store data between clock domains

  signal s_read_strobe , s_write_strobe : std_logic := '0';  --! Strobes high to register data from input and to output
  
  COMPONENT sync_fifo
    PORT (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC
    );
  END COMPONENT;
  
begin  -- rtl

  --! purpose: part of "ring oscillator" transfering strobe between clock domains
  -- type   : combinational
  -- inputs : clk_read_i
  -- outputs: 
  gen_syncReg: for v_reg in 0 to g_NUM_REGISTERS-1 generate
      mySynchReg : sync_fifo
        PORT MAP (
          rst => '0',
          wr_clk => clk_input_i,
          rd_clk => clk_output_i,
          din => data_i(v_reg),
          wr_en => '1',
          rd_en => '1',
          dout => data_o(v_reg),
          full => open,
          empty => open
        );
  end generate gen_syncReg;
  
--  p_gen_capture_strobe: process (clk_input_i)
--  begin  -- process p_gen_capture_strobe
--    if rising_edge(clk_input_i) then
--      s_ring_d0 <= not s_ring_d5;
--      s_ring_d1 <= s_ring_d0;
--      s_ring_d2 <= s_ring_d1;

--      if s_read_strobe = '1' then
--        s_registered_data <= data_i;
--      end if;
--    end if;    
--  end process p_gen_capture_strobe;

--  s_read_strobe <= s_ring_d1 xor s_ring_d2; --! Generate a strobe (with width one clk_read_i) that captures data at input
  
--  --! purpose: part of "ring oscillator" transfering strobe between clock domains
--  -- type   : combinational
--  -- inputs : clk_output_i
--  -- outputs: 
--  p_gen_output_strobe: process (clk_output_i)
--  begin  -- process p_gen_output_strobe
--    if rising_edge(clk_output_i) then
--      s_ring_d3 <= s_ring_d2;
--      s_ring_d4 <= s_ring_d3;
--      s_ring_d5 <= s_ring_d4;

--      if s_write_strobe = '1' then
--        data_o <= s_registered_data;
--      end if;
--    end if;    
--  end process p_gen_output_strobe;

--  s_write_strobe <= s_ring_d4 xor s_ring_d5; --! Generate the strobe that causes data to be written to output

end rtl;
