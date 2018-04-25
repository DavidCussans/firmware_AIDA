--=============================================================================
--! @file counterWithResetPreset_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: counterWithResetPreset (counterWithResetPreset / rtl)
--
--============================================================================
--! Entity declaration for counterWithResetPreset
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

--! @brief Simple counter with synchronous reset and top-bit preload
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date Feb\2012
--
--! @version v0.1
--
-------------------------------------------------------------------------------
--! @details
--! \n\n<b>Last changes:</b>\n
--! 5/Mar/12  DGC Changed to use numeric_std\n
--! 26/Feb/14 DGC Added registers to output to aid timing closure.
--!



ENTITY counterWithResetPreset IS
  GENERIC (g_COUNTER_WIDTH : integer := 32; --! Number of bits
           g_OUTPUT_REGISTERS : integer := 4 --! Number of output registers. Minumum =1. Aids timing closure.
           );
  PORT
    (
      clock_i: 	IN STD_LOGIC;  --! rising edge active clock
      reset_i:  IN STD_LOGIC;  --! Active high. synchronous with rising clk. Takes output to 0
      preset_i: IN STD_LOGIC;  --! Active high. synchronous with rising clk. Takes highest bit to 1
      enable_i: IN STD_LOGIC;  --! counts when enable=1
      result_o:	OUT STD_LOGIC_VECTOR ( g_COUNTER_WIDTH-1 downto 0) --! Unsigned integer output

      );
END counterWithResetPreset;

ARCHITECTURE rtl OF counterWithResetPreset IS
  type t_register_array is array(natural range <>) of UNSIGNED ( g_COUNTER_WIDTH-1 downto 0) ;  -- --! Array of arrays for output register...
  signal s_output_registers : t_register_array(g_OUTPUT_REGISTERS downto 0) := ( others => ( others => '0'));  -- --! Output registers.

BEGIN

  --! Process to count up from zero when enable_i is high.
  p_counter: PROCESS (clock_i)
  BEGIN
    IF rising_edge(clock_i) THEN
      IF (reset_i = '1') THEN
        s_output_registers(0) <= (others => '0');
      ELSIF (preset_i='1') THEN
        s_output_registers(0)(g_COUNTER_WIDTH-1) <= '1'; -- Preload highest bit to '1'
      ELSIF (enable_i='1') THEN
        s_output_registers(0) <= s_output_registers(0) + 1;
      END IF;
    END IF;
  END PROCESS p_counter;

  --! Generate some output registers. Number controlled by g_OUTPUT_REGISTERS
  generate_registers: for v_register in 1 to g_OUTPUT_REGISTERS generate

    --! An individual register
    p_outputRegister: process (clock_i)
    begin  -- process p_outputRegister
      if rising_edge(clock_i) then
        s_output_registers( v_register) <=
        s_output_registers( v_register-1);
      end if;
    end process p_outputRegister;

  end generate generate_registers;  -- v_register

  --! Copy the (registered) result to the output
  result_o <= STD_LOGIC_VECTOR(s_output_registers(g_OUTPUT_REGISTERS));

END rtl;
