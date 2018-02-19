------------------------------------------------------------------------------/
-- Copyright (c) 2009 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
------------------------------------------------------------------------------/
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor: Xilinx
-- \   \   \/    Version: 1.0
--  \   \        Filename: top_nto1_ddr_diff_rx.vhd
--  /   /        Date Last Modified:  November 5 2009
-- /___/   /\    Date Created: June 1 2009
-- \   \  /  \
--  \___\/\___\
-- 
--Device:   Spartan 6
--Purpose:    Example differential input receiver for DDR clock and data using 2 x BUFIO2
--    Serdes factor and number of data lines are set by constants in the code
--Reference:
--    
--Revision History:
--    Rev 1.0 - First created (nicks)
--
------------------------------------------------------------------------------/
--
--  Disclaimer: 
--
--    This disclaimer is not a license and does not grant any rights to the materials 
--              distributed herewith. Except as otherwise provided in a valid license issued to you 
--              by Xilinx, and to the maximum extent permitted by applicable law: 
--              (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, 
--              AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, 
--              INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR 
--              FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether in contract 
--              or tort, including negligence, or under any other theory of liability) for any loss or damage 
--              of any kind or nature related to, arising under or in connection with these materials, 
--              including for any direct, or any indirect, special, incidental, or consequential loss 
--              or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered 
--              as a result of any action brought by a third party) even if such damage or loss was 
--              reasonably foreseeable or Xilinx had been advised of the possibility of the same.
--
--  Critical Applications:
--
--    Xilinx products are not designed or intended to be fail-safe, or for use in any application 
--    requiring fail-safe performance, such as life-support or safety devices or systems, 
--    Class III medical devices, nuclear facilities, applications related to the deployment of airbags,
--    or any other applications that could lead to death, personal injury, or severe property or 
--    environmental damage (individually and collectively, "Critical Applications"). Customer assumes 
--    the sole risk and liability of any use of Xilinx products in Critical Applications, subject only 
--    to applicable laws and signalulations governing limitations on product liability.
--
--  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
------------------------------------------------------------------------------
-------------------------------------------------------
--! @file
--! @brief Serdes 1 to n SDR
--! @author Alvaro Dosil
-------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

entity serdes_1_to_n_SDR is 
generic ( g_S : integer := 4);       --! Parameter to set the serdes factor 1..8
port( clk_i  : in std_logic;         --! Fast clock to sample data (640MHz)
      hclk_i   : in std_logic;       --! A quarter frequency clock (160MHz)
      reset_i  : in std_logic;       --! reset signal
      Data_i   : in std_logic;       --! 1-Bit Input data
      strobe_i : in std_logic;       --! Iserdes strobe_i
      Data_o   : out std_logic_vector(2*g_S-1 downto 0)  --! data output
		);
    
end serdes_1_to_n_SDR;


architecture Behavioral of serdes_1_to_n_SDR is

signal s_Data_i_d_m  : std_logic;     -- Data_i delayed master
signal s_Data_i_d_2m : std_logic;     -- Data_i delayed master second signal
signal s_Data_i_d_s  : std_logic;     -- Data_i delayed slave
signal s_Data_i_d_2s : std_logic;     -- Data_i delayed slave second signal
signal s_Data_o      : std_logic_vector(2*g_S-1 downto 0);

--signal s_clk_b       : std_logic;
--signal s_ISERDES_STROBE : std_logic;

begin
	
---- Generate the ISERDES strobe signal
--
--   BUFPLL_inst : BUFPLL
--   generic map (
--      DIVIDE => 4)
--   port map (
--      IOCLK => s_clk_b,                -- 1-bit output: Output I/O clock
--      LOCK => open,                     -- 1-bit output: Synchronized LOCK output
--      SERDESSTROBE => s_ISERDES_STROBE, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
--      GCLK => hclk_i,                     -- 1-bit input: BUFG clock input
--      LOCKED => locked_pll_i,                  -- 1-bit input: LOCKED input from PLL
--      PLLIN => clk_i                -- 1-bit input: Clock input from PLL
--   );
	

  IODELAY2_M : IODELAY2
  generic map (
    COUNTER_WRAPAROUND => "WRAPAROUND",     -- "STAY_AT_LIMIT" or "WRAPAROUND" 
    DATA_RATE          => "SDR",            -- "SDR" or "DDR" 
    DELAY_SRC          => "IDATAIN",        -- "IO", "ODATAIN" or "IDATAIN" 
    IDELAY_MODE        => "NORMAL",         -- "NORMAL" or "PCI" 
    IDELAY_TYPE        => "FIXED",          -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                              --  or "DIFF_PHASE_DETECTOR" 
    IDELAY_VALUE     => 0,                -- Amount of taps for fixed input delay (0-255)
    IDELAY2_VALUE    => 0,                -- Delay value when IDELAY_MODE="PCI" (0-255)
    ODELAY_VALUE     => 0,                -- Amount of taps fixed output delay (0-255)
    SERDES_MODE      => "NONE"            -- "NONE", "MASTER" or "SLAVE" 
--    SIM_TAPDELAY_VALUE=> 43                -- Per tap delay used for simulation in ps
   )
  port map (
    BUSY     => open,          -- 1-bit output: Busy output after CAL
    DATAOUT  => s_Data_i_d_m,     -- 1-bit output: Delayed data output to ISERDES/input register
    DATAOUT2 => s_Data_i_d_2m,    -- 1-bit output: Delayed data output to general FPGA fabric
    DOUT     => open,          -- 1-bit output: Delayed data output
    TOUT     => open,          -- 1-bit output: Delayed 3-state output
    CAL      => '0',           -- 1-bit input: Initiate calibration input
    CE       => '0',           -- 1-bit input: Enable INC input
    CLK      => '0',           -- 1-bit input: Clock input
    IDATAIN  => Data_i,        -- 1-bit input: Data input (connect to top-level port or I/O buffer)
    INC      => '0',           -- 1-bit input: Increment / decrement input
    IOCLK0   => '0',           -- 1-bit input: Input from the I/O clock network
    IOCLK1   => '0',           -- 1-bit input: Input from the I/O clock network
    ODATAIN  => '0',           -- 1-bit input: Output data input from output register or OSERDES2.
    RST      => reset_i,         -- 1-bit input: reset_i to zero or 1/2 of total delay period
    T        => '0'            -- 1-bit input: 3-state input signal
   );


  IODELAY2_S : IODELAY2
  generic map (
    COUNTER_WRAPAROUND => "WRAPAROUND",  -- "STAY_AT_LIMIT" or "WRAPAROUND" 
    DATA_RATE          => "SDR",         -- "SDR" or "DDR" 
    DELAY_SRC          => "IDATAIN",     -- "IO", "ODATAIN" or "IDATAIN" 
    IDELAY_MODE        => "NORMAL",      -- "NORMAL" or "PCI" 
    IDELAY_TYPE        => "FIXED",       -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                              --  or "DIFF_PHASE_DETECTOR" 
    IDELAY_VALUE       => 10,--29,            -- Amount of taps for fixed input delay (0-255) 10->0.75nS, 11->0.825nS
    IDELAY2_VALUE      => 0,             -- Delay value when IDELAY_MODE="PCI" (0-255)
    ODELAY_VALUE       => 0,             -- Amount of taps fixed output delay (0-255)
    SERDES_MODE        => "NONE"         -- "NONE", "MASTER" or "SLAVE" 
    --SIM_TAPDELAY_VALUE => 43              -- Per tap delay used for simulation in ps
   )
  port map (
    BUSY     => open,             -- 1-bit output: Busy output after CAL
    DATAOUT  => s_Data_i_d_s,        -- 1-bit output: Delayed data output to ISERDES/input register
    DATAOUT2 => s_Data_i_d_2s,       -- 1-bit output: Delayed data output to general FPGA fabric
    DOUT     => open,             -- 1-bit output: Delayed data output
    TOUT     => open,             -- 1-bit output: Delayed 3-state output
    CAL      => '0',              -- 1-bit input: Initiate calibration input
    CE       => '0',              -- 1-bit input: Enable INC input
    CLK      => '0',              -- 1-bit input: Clock input
    IDATAIN  => Data_i,           -- 1-bit input: Data input (connect to top-level port or I/O buffer)
    INC      => '0',              -- 1-bit input: Increment / decrement input
    IOCLK0   => '0',              -- 1-bit input: Input from the I/O clock network
    IOCLK1   => '0',              -- 1-bit input: Input from the I/O clock network
    ODATAIN  => '0',              -- 1-bit input: Output data input from output register or OSERDES2.
    RST      => reset_i,            -- 1-bit input: reset_i to zero or 1/2 of total delay period
    T        => '0'               -- 1-bit input: 3-state input signal
   );


  ISERDES2_M : ISERDES2
  generic map (
    BITSLIP_ENABLE => FALSE,         -- Enable Bitslip Functionality (TRUE/FALSE)
    DATA_RATE      => "SDR",         -- Data-rate ("SDR" or "DDR")
    DATA_WIDTH     => g_S,             -- Parallel data width selection (2-8)
    INTERFACE_TYPE => "NETWORKING_PIPELINED", -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
    SERDES_MODE    => "NONE"         -- "NONE", "MASTER" or "SLAVE" 
   )
  port map (
    -- Q1 - Q4: 1-bit (each) output Registered outputs to FPGA logic
    Q1     => s_Data_o(1),
    Q2     => s_Data_o(3),
    Q3     => s_Data_o(5),
    Q4     => s_Data_o(7), 
    --SHIFTOUT => SHIFTOUTsig,       -- 1-bit output Cascade output signal for master/slave I/O
    VALID   => open,                 -- 1-bit output Output status of the phase detector
    BITSLIP => '0',                  -- 1-bit input Bitslip enable input
    CE0     => '1',                  -- 1-bit input Clock enable input
	 CLK0    => clk_i,                -- 1-bit input I/O clock network input
    CLK1    => '0',                  -- 1-bit input Secondary I/O clock network input
    CLKDIV  => hclk_i,               -- 1-bit input FPGA logic domain clock input
    D       => s_Data_i_d_m,         -- 1-bit input Input data
    IOCE    => strobe_i,             -- 1-bit input Data strobe_i input
    RST     => reset_i,              -- 1-bit input Asynchronous reset_i input
    SHIFTIN => '0'                   -- 1-bit input Cascade input signal for master/slave I/O
   );

  ISERDES2_S : ISERDES2
  generic map (
    BITSLIP_ENABLE => FALSE,          -- Enable Bitslip Functionality (TRUE/FALSE)
    DATA_RATE      => "SDR",       -- Data-rate ("SDR" or "DDR")
    DATA_WIDTH     => g_S,             -- Parallel data width selection (2-8)
    INTERFACE_TYPE => "NETWORKING_PIPELINED", -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
    SERDES_MODE    => "NONE"          -- "NONE", "MASTER" or "SLAVE" 
   )
  port map (
    -- Q1 - Q4: 1-bit (each) output Registered outputs to FPGA logic
    Q1     => s_Data_o(0),
    Q2     => s_Data_o(2),
    Q3     => s_Data_o(4),
    Q4     => s_Data_o(6),
    --SHIFTOUT => SHIFTOUTsig,     -- 1-bit output Cascade output signal for master/slave I/O
    VALID   => open,               -- 1-bit output Output status of the phase detector
    BITSLIP => '0',                -- 1-bit input Bitslip enable input
    CE0     => '1',                -- 1-bit input Clock enable input
	 CLK0    => clk_i,              -- 1-bit input I/O clock network input
    CLK1    => '0',                -- 1-bit input Secondary I/O clock network input
    CLKDIV  => hclk_i,             -- 1-bit input FPGA logic domain clock input
    D       => s_Data_i_d_s,       -- 1-bit input Input data
    IOCE    => strobe_i,           -- 1-bit input Data strobe_i input
    RST     => reset_i,            -- 1-bit input Asynchronous reset_i input
    SHIFTIN => '0'                 -- 1-bit input Cascade input signal for master/slave I/O
   );

reg_out : process(hclk_i)
begin
  if rising_edge(hclk_i) then
    Data_o <= s_Data_o;
  end if;
end process;

end Behavioral;
