library ieee;
use ieee.std_logic_1164.all;

entity tb_pwm_driver is

end tb_pwm_driver;

architecture behav of tb_pwm_driver is

  constant pwm_bit : integer := 14;

  component pwm_driver_E is
    generic(
      pwm_bit : integer
      );
    port(
      reset_n                         : in  std_logic;
      clk                             : in  std_logic;
      pwm_base_period                 : in  integer range 0 to 2**(pwm_bit)-1;
      pwm_duty_cycle                  : in  integer range 0 to 2**(pwm_bit)-1;
      pwm_control                     : in  std_logic_vector(7 downto 0);  -- control signals
      pwm_cycle_done                  : out std_logic;  -- new values at inputs are now used
      pwm_out1, pwm_out2, pwm_n_sleep : out std_logic);
  end component;

  signal reset_n, clk                         : std_logic                         := '0';
  signal pwm_duty_S                           : integer range 0 to 2**(pwm_bit)-1 := 511;
  signal pwm_base_S                           : integer range 0 to 2**(pwm_bit)-1 := 1023;
  signal pwm1_S, pwm2_S, pwm_n_sleep_S, ack_S : std_logic;
  signal pwm_control_S                        : std_logic_vector(7 downto 0)      := "00000000";

begin

  dut : pwm_driver_E generic map (pwm_bit)
    port map (reset_n, clk, pwm_base_S, pwm_duty_S, pwm_control_S, ack_S, pwm1_S, pwm2_S, pwm_n_sleep_S);

  reset_n <= '1' after 100 ns;
  clk     <= not clk after 5 ns;        -- clk rate 100 MHz

  pwm_P : process
  begin
    wait for 100 us;
    pwm_control_S <= "00000001";
    pwm_base_S    <= 2047;
    pwm_duty_S    <= 512;
    wait until ack_S = '1';
    wait for 100 us;
    pwm_duty_S    <= 0;
    wait until ack_S = '1';
    wait for 100 us;
    pwm_duty_S    <= 1024;
    wait until ack_S = '1';
    wait for 100 us;
    pwm_duty_S    <= 2047;
    wait until ack_S = '1';
    wait for 100 us;
    pwm_control_S <= "00000011";
    wait until ack_S = '1';

    wait for 100 us;
    pwm_control_S <= "00000111";
    wait until ack_S = '1';

    wait for 100 us;
    pwm_control_S <= "00000000";
    wait until ack_S = '1';

    wait;


  end process;

end behav;