--! @file T0_Shutter_Iface_rtl.vhd
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

USE work.ipbus.all;

use work.ipbus_reg_types.all;

--! @brief Simple module to generate T0 and shutter signals under IPBus control
--! Similar interface to TPx3_iface_rtl.vhd
--
--! @details
--! \n \n IPBus address map:
--! \li 00 - shutter. Bit 0. Output shutter = value of bit-0
--! \li 01 - T0 write to pulse T0.
--
--! @author David Cussans

entity T0_Shutter_Iface is

  port (
    clk_4x_i      : in  std_logic;    --! system clock
    clk_4x_strobe : in  std_logic;    --! strobes high for one cycle every 4 of clk_4x
    T0_o          : out std_logic;    --! T0 signal retimed onto system clock
    shutter_o          : out std_logic;    --! shutter signal retimed onto system clock

    ipbus_clk_i            : IN     std_logic; --! IPBus system clock
    ipbus_i                : IN     ipb_wbus;
    ipbus_o                : OUT    ipb_rbus
          
    );     

end entity T0_Shutter_Iface;

architecture rtl of T0_Shutter_Iface is

  signal s_T0 , s_T0_d1 , s_T0_d2 , s_stretch_T0_in: std_logic := '0';  -- signal after IBufDS and sampled onto clk_4x
  signal s_stretch_T0_in_sr : std_logic_vector(2 downto 0) := "111"; --! Gets shifted out by clk_4x logic. Loaded by T0ger_i
  signal s_T0_out_sr : std_logic_vector(2 downto 0) := "111"; --! Gets shifted out by clk_4x logic. Loaded by strobe_4x_logic

  signal s_shutter , s_shutter_d1 , s_shutter_d2 : std_logic := '0';  -- signal after IBufDS and sampled onto clk_4x

  signal s_T0_ipbus , s_T0_ipbus_d1 , s_T0_ipbus_d2: std_logic := '0';  -- Signals that get combined with incoming hardware signals from TPIx3 telescope
  signal s_shutter_ipbus , s_shutter_ipbus_d1 , s_shutter_ipbus_d2: std_logic := '0';  -- Signals that get combined with incoming hardware signals from TPIx3 telescope
                                                                             
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
                when others => null;
            end case;
        end if;
        s_ipbus_ack <= ipbus_i.ipb_strobe and not s_ipbus_ack;
    end if;
    end process ipbus_write;

    ipbus_o.ipb_ack <= s_ipbus_ack;
    ipbus_o.ipb_err <= '0';


    ------------------
    p_T0_retime: process (clk_4x_i , clk_4x_strobe , s_T0) is
    begin  -- process p_T0_retime
    if rising_edge(clk_4x_i)  then
        -- Register IPBus clocked signals onto clk 4x. So clk4x must be faster
        -- than ipbus_clk for this to work.
        s_T0_ipbus_d1 <= s_T0_ipbus;
        s_T0_ipbus_d2 <= s_T0_ipbus_d1;
        -- Shutter is a DC level, so clock speeds don't matter.
        s_shutter_ipbus_d1 <= s_shutter_ipbus;
        s_shutter_ipbus_d2 <= s_shutter_ipbus_d1;
        -- Stretch T0_i pulse to 4 clock cycles on clk4x
        if ( s_T0_ipbus_d2 = '1' ) then
            s_stretch_T0_in <= '1';
            s_stretch_T0_in_sr <= "111";
        else
            s_stretch_T0_in <= s_stretch_T0_in_sr(0);
            s_stretch_T0_in_sr <= '0' & s_stretch_T0_in_sr(s_stretch_T0_in_sr'left downto 1);
        end if;
 
        if (clk_4x_strobe  = '1') and ( s_stretch_T0_in = '1' ) then
            T0_o <= '1';
            s_T0_out_sr <= "111";
        else
            T0_o <= s_T0_out_sr(0);
            s_T0_out_sr <= '0' & s_T0_out_sr(s_T0_out_sr'left downto 1);
        end if;
    end if;
    end process p_T0_retime;
    
  -- Just retime onto the 4x clock. Probably should retime onto 1x clock.
    p_shutter_retime: process (s_shutter , clk_4x_i) is
    begin  -- process p_shutter_retime
    if rising_edge(clk_4x_i)  then
        s_shutter_d1 <= ( s_shutter_ipbus );
        s_shutter_d2 <= s_shutter_d1;
        shutter_o    <= s_shutter_d2;
    end if;
    end process p_shutter_retime;

end architecture rtl;
