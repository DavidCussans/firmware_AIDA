--=============================================================================
--! @file 
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.ipbus.all;
use work.ipbus_reg_types.all;

--! @brief IPBus registers synchronzied onto logic clock
--!
--! @details Uses DMN ipbus_ctrlreg_v - originally tried to use
--! ipbus_ctrlreg_sync, but had poor results and added own synchronzier.

entity synchronizedIPBusCtrlRegV_rtl is
	generic(
		N_CTRL: positive := 1;
		N_STAT: positive := 1
	);
	port(
		ipbus_clk_i: in std_logic;
		ipbus_reset_i: in std_logic;
		ipbus_i: in ipb_wbus;
		ipbus_o: out ipb_rbus;
                logic_clk_i: in std_logic;
		status_to_ipbus_i: in ipb_reg_v(N_STAT - 1 downto 0); --! Synchronized to logic_clk_i       
		sync_control_from_ipbus_o: out ipb_reg_v(N_CTRL - 1 downto 0); --! Synchronized to logic_clk_i
		stb_o: out std_logic_vector(N_CTRL - 1 downto 0) --! high when change made to a control register. Broken ( needs to be retimed )
	);
	
end synchronizedIPBusCtrlRegV_rtl;


architecture rtl of synchronizedIPBusCtrlRegV_rtl is

  signal s_sync_status_to_ipbus : ipb_reg_v(c_N_STAT-1 downto 0);
  signal s_control_from_ipbus   : ipb_reg_v(c_N_CTRL-1 downto 0);
 
begin  -- architecture rtl

  
  ipbus_registers: entity work.ipbus_ctrlreg_v
    generic map(
      N_CTRL => c_N_CTRL,
      N_STAT => c_N_STAT
      )
    port map(
      clk => ipbus_clk_i,
      reset=> ipbus_reset_i ,
      ipbus_in=>  ipbus_i,
      ipbus_out=> ipbus_o,
      d=>  s_sync_status_to_ipbus,
      q=>  s_control_from_ipbus,
      stb=>  stb_o
      );

  -- Synchronize registers from logic clock to ipbus.
    sync_status: entity work.synchronizeRegisters
    generic map (
      g_NUM_REGISTERS => c_N_STAT )
    port map (
      clk_input_i => clk_4x_logic_i,
      data_i      =>  status_to_ipbus_i,
      data_o      => s_sync_status_to_ipbus,
      clk_output_i => ipbus_clk_i);

    -- Synchronize registers from logic clock to ipbus.
    sync_ctrl: entity work.synchronizeRegisters
    generic map (
      g_NUM_REGISTERS => c_N_CTRL )
    port map (
      clk_input_i => ipbus_clk_i,
      data_i      =>  s_control_from_ipbus,
      data_o      => sync_control_from_ipbus_o,
      clk_output_i => clk_4x_logic_i);

end architecture rtl;
