library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pwm_digital_top is
end tb_pwm_digital_top;

architecture testbench of tb_pwm_digital_top is

  constant pwm_bit        : integer := 14;
  constant message_length : integer := 17;
  constant address_length : integer := 2;

  component PWM_digital_top_E is
    generic(message_length : integer := 17;
            pwm_bit        : integer := 14;
            address_length : integer := 2);
    port (                              -- general signals
      reset_n                         : in  std_logic;
      clk                             : in  std_logic;
      -- SPI interface
      sclk                            : in  std_logic;
      cs_n                            : in  std_logic;
      din                             : in  std_logic;
      -- PWM output
      pwm_out1, pwm_out2, pwm_n_sleep : out std_logic);
  end component;

  signal reset_n, clk, SPIclk_enable, start, send : std_logic := '0';
  signal cs_n_S, din_S, sclk_S, SPIclk            : std_logic := '1';
  signal pwm_out1_S, pwm_out2_S, pwm_n_sleep_S    : std_logic;
  signal message                                  : std_logic_vector(message_length-1 downto 0);
  signal debug_counter                            : integer;



begin
  dut : PWM_digital_top_E generic map(message_length, pwm_bit, address_length)
    port map (
      reset_n     => reset_n,
      clk         => clk,
      sclk        => SPIclk,
      cs_n        => cs_n_S,
      din         => din_S,
      pwm_out1    => pwm_out1_S,
      pwm_out2    => pwm_out2_S,
      pwm_n_sleep => pwm_n_sleep_S);

  reset_n <= '1' after 100 ns;
  clk     <= not clk after 5 ns;        -- clk rate 100 MHz

  SPIclk <= sclk_S when SPIclk_enable = '1' else '1';

  SPIclk_P : process
  begin
    -- if SPIclk_enable = '1' then
    sclk_S <= '0';
    wait for 100 ns;
    sclk_S <= '1';
    wait for 100 ns;
    -- else
    -- sclk_S <= '1';
    --wait until rising_edge(clk);
    --end if;
  end process;

  Data_P : process
  begin
    message                                           <= (others => '0');
    wait for 500 ns;
    message(message_length-1 downto message_length-3) <= "010";  -- write to base register 
    message(8)                                        <= '1';  -- set base value to 256
    message(1 downto 0)                               <= "11";  -- invert& enable
    start                                             <= '1';
    wait until send = '1';
    start                                             <= '0';
    wait until send = '0';
    message(message_length-1 downto message_length-3) <= "100";  -- write to duty register 
    message(8 downto 7)                               <= "01";  -- set duty value to 128
    message(1 downto 0)                               <= "11";  -- invert& enable
    start                                             <= '1';
    wait until send = '1';
    start                                             <= '0';
    wait until send = '0';
    message(message_length-1 downto message_length-3) <= "110";  -- write to control register 
    message(8 downto 7)                               <= "00";
    message(1 downto 0)                               <= "11";  -- invert& enable
    start                                             <= '1';
    wait until send = '1';
    start                                             <= '0';
    wait until send = '0';

    wait;
  end process;

  Send_P : process
--    variable counter : integer range 0 to message_length;
  begin
    debug_counter <= -1;
    din_S         <= message(message_length-1);
    if start = '0' then
      wait until start = '1';
    end if;
    din_S         <= message(message_length-1);
--      wait until rising_edge(sclk_S); 
    --counter := message_length-1;
    send          <= '1';
    SPIclk_enable <= '1';
    cs_n_S        <= '0';
    wait until rising_edge(sclk_S);
    for I in message_length-2 downto 0 loop
      debug_counter <= I;
      din_S         <= message(I);
      wait until rising_edge(sclk_S);
    end loop;
    --wait until rising_edge(sclk_S);   
    debug_counter <= -3;
    cs_n_S        <= '1';
    send          <= '0';
    SPIclk_enable <= '0';
    wait until rising_edge(sclk_S);

  end process;

end testbench;