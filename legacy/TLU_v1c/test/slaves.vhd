-- The ipbus slaves live in this entity - modify according to requirements
--
-- Ports can be added to give ipbus slaves access to the chip top level.
--
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.ALL;
use work.emac_hostbus_decl.all;

entity slaves is port(
	ipb_clk, rst : in STD_LOGIC;
	ipb_in : in ipb_wbus;
	ipb_out : out ipb_rbus;
-- Top level ports from here
	hostbus_out: out emac_hostbus_in;
	hostbus_in: in emac_hostbus_out;

        -- GPIO
        gpio : out STD_LOGIC_VECTOR(3 downto 0);
	-- Main I2C signals
	i2c_scl_i: in std_logic;
	i2c_scl_oen_o: out std_logic;
	i2c_sda_i: in std_logic;
	i2c_sda_oen_o: out std_logic;
        -- CBC I2C signals
	cbc_i2c_sda_enb_o: out std_logic;  --! Active low. SDA pulled low when enb is high 
	cbc_i2c_scl_o: out std_logic;     --! I2C Clock output.
	cbc_i2c_sda_i : in std_logic;
	-- CBC "fast" signals
	cbc_trg_o, ext_trg_o, cbc_reset_o: out std_logic;
	cbc_data_i: in std_logic
        
	);

end slaves;

architecture rtl of slaves is

	constant NSLV: positive := 7;
	signal ipbw: ipb_wbus_array(NSLV-1 downto 0);
	signal ipbr, ipbr_d: ipb_rbus_array(NSLV-1 downto 0);

	signal cbc_i2c_scl_o_int: std_logic;
        signal ctrl_reg: std_logic_vector(31 downto 0);
        signal s_pulse_reg : std_logic_vector(31 downto 0);  -- ! pulsed control signals

        signal s_cbc_reset : std_logic := '0';  -- ! Active high. Driven from cbcstuff

        signal s_cap_trg : std_logic := '0';  -- ! Starts capture of incoming data into capture buffer

begin

  fabric: entity work.ipbus_fabric
    generic map(NSLV => NSLV)
    port map(
      ipb_clk => ipb_clk,
      rst => rst,
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Slave 0: version register

  slave0: entity work.ipbus_ver
    port map(
      ipbus_in => ipbw(0),
      ipbus_out => ipbr(0));

  -- Slave 1: 32b register
  slave1: entity work.ipbus_reg
    generic map(addr_width => 0)
    port map(
      clk => ipb_clk,
      reset => rst,
      ipbus_in => ipbw(1),
      ipbus_out => ipbr(1),
      q => ctrl_reg
      );

  s_cbc_reset <= ctrl_reg(16);
  cbc_reset_o <= s_cbc_reset;

  -- Slave 2: 32b pulser
  slave2: entity work.ipbus_pulser
    port map(
      clk_i => ipb_clk,
      reset_i => rst,
      ipbus_i => ipbw(2),
      ipbus_o => ipbr(2),
      q_o => s_pulse_reg
      );

  -- CBC clock and trigger signals. Connected to slave-1 ( 32 bit register )
  cbcstuff: entity work.cbc_logic
    port map(
      clk_i => ipb_clk,
      cbc_trg_o => cbc_trg_o,
      ext_trg_o => ext_trg_o,
      cap_trg_o => s_cap_trg,
      go_p_i => s_pulse_reg(0),
      delay_i => unsigned(ctrl_reg(31 downto 24)),
      trg_patt_i => ctrl_reg(22 downto 20)
      );


  -- Slave 3: I2C core connected to CBC

  slave3: entity work.i2c_master_top
    generic map (
      ARST_LVL => 0
      )
    port map(
      wb_clk_i => ipb_clk,
      wb_rst_i => rst,
      arst_i => '1', --! Active low reset.
      wb_adr_i => ipbw(3).ipb_addr(2 downto 0),
      wb_dat_i => ipbw(3).ipb_wdata(7 downto 0),
      wb_dat_o => ipbr(3).ipb_rdata(7 downto 0),
      wb_we_i => ipbw(3).ipb_write,
      wb_stb_i => ipbw(3).ipb_strobe,
      wb_cyc_i => '1',
      wb_ack_o => ipbr(3).ipb_ack,
      wb_inta_o => open,
      scl_pad_i => cbc_i2c_scl_o_int,
      scl_pad_o => open,
      scl_padoen_o => cbc_i2c_scl_o_int,
      sda_pad_i => cbc_i2c_sda_i,
      sda_pad_o => open,
      sda_padoen_o => cbc_i2c_sda_enb_o
      );

	
  cbc_i2c_scl_o <= cbc_i2c_scl_o_int;
  
  ipbr(3).ipb_rdata(31 downto 8) <= (others => '0');


  -- Slave 4: I2C core connected to main I2C
  slave4: entity work.i2c_master_top
    generic map (
      ARST_LVL => 0
      )
    port map(
      wb_clk_i => ipb_clk,
      wb_rst_i => rst,
      arst_i => '1', --! Active low reset.
      wb_adr_i => ipbw(4).ipb_addr(2 downto 0),
      wb_dat_i => ipbw(4).ipb_wdata(7 downto 0),
      wb_dat_o => ipbr(4).ipb_rdata(7 downto 0),
      wb_we_i => ipbw(4).ipb_write,
      wb_stb_i => ipbw(4).ipb_strobe,
      wb_cyc_i => '1',
      wb_ack_o => ipbr(4).ipb_ack,
      wb_inta_o => open,
      scl_pad_i => i2c_scl_i,
      scl_pad_o => open,
      scl_padoen_o => i2c_scl_oen_o,
      sda_pad_i => i2c_sda_i,
      sda_pad_o => open,
      sda_padoen_o => i2c_sda_oen_o
      );
  ipbr(4).ipb_rdata(31 downto 8) <= (others => '0');
  
  -- Slave 5: Capture register.
  slave5 : entity work.ipbus_capture_buffer
    generic map (
      g_DATA_WIDTH  => 32,  --! Width of WB bus
      g_RAM_ADDRESS_WIDTH => 3)  --! size of RAM = 2^ram_address_width
    port map (
      -- Wishbone signals
      ipbus_clk_i => ipb_clk,
      ipbus_i    => ipbw(5),
      ipbus_o    => ipbr(5),
      -- Data to capture.
      reset_i => s_cbc_reset,
      cap_clk_i => ipb_clk,
      cap_d_i => cbc_data_i,
      cap_go_i  => s_cap_trg,
      cap_edge_i => ctrl_reg(8)
      );

  
-- Slave 6: MAC host interface

  slave6: entity work.ipbus_emac_hostbus
    port map(
      clk => ipb_clk,
      reset => rst,
      ipbus_in => ipbw(6),
      ipbus_out => ipbr(6),
      hostbus_out => hostbus_out,
      hostbus_in => hostbus_in);

end rtl;
