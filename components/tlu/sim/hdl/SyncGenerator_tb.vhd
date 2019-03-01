library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity syncGenerator_tb is
end;

architecture bench of syncGenerator_tb is

  constant g_NUM_TRIG_SOURCES : positive := 6;
  constant g_IPBUS_WIDTH : positive := 32;
  constant g_COUNTER_WIDTH : positive := 20;

  
  signal clock_i: STD_LOGIC;
  signal reset_i: STD_LOGIC;
  signal strobe_i: STD_LOGIC;
  signal trigger_sources_i: STD_LOGIC_VECTOR(g_NUM_TRIG_SOURCES-1 downto 0) := ( others => '0');
  signal trigger_source_select_i: STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0);
  signal threshold_t1_i, threshold_t2_i, threshold_t3_i: STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0);
  signal enable_sequence_i: std_logic;
  signal enable_internal_cycle_i: std_logic;
  signal internal_cycle_length_i: STD_LOGIC_VECTOR(g_IPBUS_WIDTH-1 downto 0);
  signal shutter_o: STD_LOGIC;
  signal trigger_veto_o: STD_LOGIC ;

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

  signal s_strobe_counter  : natural := 0;  -- cycles through 0-3
  signal s_cycle_counter  : natural := 0;  -- cycles through 0-3
  
begin

  -- Insert values for generic parameters !!
  uut: entity work.syncGenerator generic map ( g_COUNTER_WIDTH         => g_COUNTER_WIDTH  ,
                                   g_IPBUS_WIDTH           =>  g_IPBUS_WIDTH,
                                   g_NUM_TRIG_SOURCES      =>   g_NUM_TRIG_SOURCES )
                        port map ( clock_i                 => clock_i,
                                   reset_i                 => reset_i,
                                   strobe_i                => strobe_i,
                                   trigger_sources_i       => trigger_sources_i,
                                   trigger_source_select_i => trigger_source_select_i,
                                   threshold_t1_i          => threshold_t1_i,
                                   threshold_t2_i          => threshold_t2_i,
                                   threshold_t3_i          => threshold_t3_i,
                                   enable_sequence_i       => enable_sequence_i,
                                   enable_internal_cycle_i => enable_internal_cycle_i,
                                   internal_cycle_length_i => internal_cycle_length_i,
                                   shutter_o               => shutter_o,
                                   trigger_veto_o          => trigger_veto_o );

  stimulus: process
  begin

    trigger_source_select_i <= std_logic_vector(to_unsigned(5,trigger_source_select_i'length));
    threshold_t1_i <= std_logic_vector(to_unsigned(100, threshold_t1_i'length));
    threshold_t2_i <= std_logic_vector(to_unsigned(200, threshold_t2_i'length));
    threshold_t3_i <= std_logic_vector(to_unsigned(300, threshold_t3_i'length));

    internal_cycle_length_i <= std_logic_vector(to_unsigned(1024, internal_cycle_length_i'length));

    enable_sequence_i <= '1';
    enable_internal_cycle_i <='0';
    
                                
    -- Put initialisation code here
    reset_i <= '1';
    wait for clock_period*4;
    reset_i <= '0';

    

    -- Put test bench stimulus code here
    wait for clock_period * 1000000;
    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clock_i <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

  p_strobe: process (clock_i)
  begin  -- process p_strobe
    if rising_edge(clock_i) then
      s_cycle_counter <= (s_cycle_counter + 1 );
    end if;
  end process p_strobe;


strobe_i <= '1' when (s_strobe_counter mod 4) = 0 else '0';

trigger_sources_i(5) <= '1' when s_strobe_counter mod 51 = 0 else '0';


end;
