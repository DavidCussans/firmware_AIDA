--! @file TPx3_iface_rtl.vhd
--! @brief Simple module to interface AIDA TLU to LHCb TimePix3 telescope.
--! Accepts T0 sync signal and shutter signal from telescope and re-transmits.
--! @details
--! IPBus address map:
--! 00 - shutter. Bit 0. Output shutter = external shutter XOR ipbus shutter
--! 01 - T0 write to pulse T0.
--! @author David Cussans

LIBRARY ieee;
USE ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

USE work.ipbus.all;

use work.ipbus_reg_types.all;


entity TPx3_iface is

  port (
    clk_4x_i      : in  std_logic;    --! system clock
    clk_4x_strobe : in  std_logic;    --! strobes high for one cycle every 4 of clk_4x
    T0_p_i          : in  std_logic;  --! T0 signal from timepix telescope clk/sync system
    T0_n_i          : in  std_logic;  --! T0 signal from timepix telescope clk/sync system
    T0_o          : out std_logic;    --! T0 signal retimed onto system clock
    shutter_p_i          : in  std_logic;  --! shutter signal from timepix telescope clk/sync system
    shutter_n_i          : in  std_logic;  --! shutter signal from timepix telescope clk/sync system
    shutter_o          : out std_logic;    --! shutter signal retimed onto system clock

    ipbus_clk_i            : IN     std_logic; --! IPBus system clock
    ipbus_i                : IN     ipb_wbus;
    ipbus_o                : OUT    ipb_rbus
          
    );     

end entity TPx3_iface;

architecture rtl of TPx3_iface is

  signal s_T0 , s_T0_d1 , s_T0_d2 , s_stretch_T0_in: std_logic := '0';  -- signal after IBufDS and sampled onto clk_4x
  signal s_stretch_T0_in_sr : std_logic_vector(2 downto 0) := "111"; --! Gets shifted out by clk_4x logic. Loaded by T0ger_i
  signal s_T0_out_sr : std_logic_vector(2 downto 0) := "111"; --! Gets shifted out by clk_4x logic. Loaded by strobe_4x_logic

  signal s_shutter , s_shutter_d1 , s_shutter_d2 : std_logic := '0';  -- signal after IBufDS and sampled onto clk_4x

  signal s_T0_ipbus , s_T0_ipbus_d1 , s_T0_ipbus_d2: std_logic := '0';  -- Signals that get combined with incoming hardware signals from TPIx3 telescope
  signal s_shutter_ipbus , s_shutter_ipbus_d1 , s_shutter_ipbus_d2: std_logic := '0';  -- Signals that get combined with incoming hardware signals from TPIx3 telescope
  signal s_external_signal_mask : std_logic_vector(ipbus_i.ipb_wdata'range) := ( others => '0'); --! Set bits to mask external signals : 0 to mask external T0 , set bit 1 to mask external shutter
  signal s_maskExternalShutter , s_maskExternalT0 : std_logic := '0';  -- ! Set to 1 to mask external signals
                                                                             
  signal s_ipbus_ack      : std_logic := '0';  -- used to produce a delayed IPBus ack signal
  
begin  -- architecture rtl

  --------------------
  ipbus_write: process (ipbus_clk_i)
  begin  -- process ipb_clk_i
    if rising_edge(ipbus_clk_i) then

      s_T0_ipbus <= '0';
      if (ipbus_i.ipb_strobe = '1' and ipbus_i.ipb_write = '1') then

        case ipbus_i.ipb_addr(1 downto 0) is
          when "00" => s_shutter_ipbus <= ipbus_i.ipb_wdata(0) ; -- Set IPBus shutter
          when "01" => s_T0_ipbus <= '1';
          when "10" => s_external_signal_mask <= ipbus_i.ipb_wdata;
          when others => null;
        end case;
          
       end if;

       s_ipbus_ack <= ipbus_i.ipb_strobe and not s_ipbus_ack;
       
    end if;
  end process ipbus_write;

  ipbus_o.ipb_ack <= s_ipbus_ack;
  ipbus_o.ipb_err <= '0';


    ------------------
    
  cmp_IBUFDS_T0 : IBUFDS
      generic map (
        DIFF_TERM => TRUE, -- Differential Termination 
        IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD => "LVDS_25")
      port map (
        O =>  s_T0,  -- Buffer output
        I =>  T0_p_i,  -- Diff_p buffer input (connect directly to top-level port)
        IB => T0_n_i -- Diff_n buffer input (connect directly to top-level port)
      );
        
    p_T0_retime: process (clk_4x_i , clk_4x_strobe , s_T0) is
  begin  -- process p_T0_retime
    if rising_edge(clk_4x_i)  then

      s_maskExternalShutter <= s_external_signal_mask(1);
      s_maskExternalT0 <= s_external_signal_mask(0);
        
      s_T0_d1 <= s_T0;
      s_T0_d2 <= s_T0_d1;

      -- Register IPBus clocked signals onto clk 4x. So clk4x must be faster
      -- than ipbus_clk for this to work.
      s_T0_ipbus_d1 <= s_T0_ipbus;
      s_T0_ipbus_d2 <= s_T0_ipbus_d1;

      -- Shutter is a DC level, so clock speeds don't matter.
      s_shutter_ipbus_d1 <= s_shutter_ipbus;
      s_shutter_ipbus_d2 <= s_shutter_ipbus_d1;
      
      
      -- Stretch T0_i pulse to 4 clock cycles on clk4x
      if ( (( s_T0_d2 = '1' ) and ( s_maskExternalT0 = '0')) or ( s_T0_ipbus_d2 = '1' )) then
        s_stretch_T0_in <= '1';
        s_stretch_T0_in_sr <= "111";
      else
        s_stretch_T0_in <= s_stretch_T0_in_sr(0);
        s_stretch_T0_in_sr <= '0' & s_stretch_T0_in_sr(s_stretch_T0_in_sr'left downto 1);
      end if;

      -- 
      if (clk_4x_strobe  = '1') and ( s_stretch_T0_in = '1' ) then
        T0_o <= '1';
        s_T0_out_sr <= "111";
      else
        T0_o <= s_T0_out_sr(0);
        s_T0_out_sr <= '0' & s_T0_out_sr(s_T0_out_sr'left downto 1);
      end if;

      
    end if;
  end process p_T0_retime;
    
  cmp_IBUFDS_shutter : IBUFDS
      generic map (
        DIFF_TERM => TRUE, -- Differential Termination 
        IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD => "LVDS_25")
      port map (
        O =>  s_shutter,  -- Buffer output
        I =>  shutter_p_i,  -- Diff_p buffer input (connect directly to top-level port)
        IB => shutter_n_i -- Diff_n buffer input (connect directly to top-level port)
      );

  -- Just retime onto the 4x clock. Probably should retime onto 1x clock.
  p_shutter_retime: process (s_shutter , clk_4x_i) is
  begin  -- process p_shutter_retime
    if rising_edge(clk_4x_i)  then
      s_shutter_d1 <= ( ( s_shutter and not s_maskExternalShutter ) xor s_shutter_ipbus );
      s_shutter_d2 <= s_shutter_d1;
      shutter_o    <= s_shutter_d2;
    end if;
  end process p_shutter_retime;

end architecture rtl;
