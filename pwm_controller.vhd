library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM_controller_E is
  generic(message_length : integer := 17;
          pwm_bit        : integer := 14;
          address_length : integer := 2
          );
  port(                                 -- general inputs
    reset_n         : in  std_logic;
    clk             : in  std_logic;
    -- from SPI controller
    new_data        : in  std_logic;    -- new data available
    regnr           : in  std_logic_vector (address_length-1 downto 0);  -- register address
    regcontent      : in  std_logic_vector (pwm_bit-1 downto 0);  -- register write value
    regwrite_n      : in  std_logic;    -- write access?
    -- from/to pwm_driver
    pwm_cycle_done  : in  std_logic;    -- new values at inputs are now used
    pwm_control     : out std_logic_vector(7 downto 0);
    pwm_base_period : out integer range 0 to 2**(pwm_bit)-1;
    pwm_duty_cycle  : out integer range 0 to 2**(pwm_bit)-1
    );
end PWM_controller_E;

architecture rtl of PWM_controller_E is
  signal current_pwm_duty_cycle, current_pwm_base_period : integer range 0 to 2**(pwm_bit)-1;
  signal reg_pwm_base_period                             : std_logic_vector (pwm_bit-1 downto 0);  -- Register 01
  signal reg_pwm_duty_cycle                              : std_logic_vector (pwm_bit-1 downto 0);  -- Register 10
  signal reg_pwm_control                                 : std_logic_vector(7 downto 0);  -- Register 11

begin
  pwm_duty_cycle  <= current_pwm_duty_cycle;
  pwm_base_period <= current_pwm_base_period;

  register_readwrite_P : process(reset_n, clk)
  begin
    if reset_n = '0' then
      reg_pwm_base_period    <= (others => '0');  -- set to 2
      reg_pwm_base_period(1) <= '1';
      reg_pwm_duty_cycle     <= (others => '0');
      reg_pwm_control        <= (others => '0');
    elsif clk'event and clk = '1' then
      if new_data = '1' then
        if regnr = "01" then
          if regwrite_n = '0' then
            reg_pwm_base_period <= regcontent;
            
          end if;
        elsif regnr = "10" then
          if regwrite_n = '0' then
            reg_pwm_duty_cycle <= regcontent;
            
          end if;
        elsif regnr = "11" then
          if regwrite_n = '0' then
            reg_pwm_control <= regcontent(7 downto 0);
            
          end if;
        end if;
      end if;
    end if;
  end process;

  pwm_generator_P : process(reset_n, clk)
  begin
    if reset_n = '0' then
      current_pwm_duty_cycle  <= 0;     -- slow start
      current_pwm_base_period <= to_integer(unsigned(reg_pwm_base_period));
    elsif rising_edge(clk) then
      if pwm_cycle_done = '1' then
        -- change in base period
        if (to_integer(unsigned(reg_pwm_base_period)) < current_pwm_base_period) and ((current_pwm_base_period) < 31) then
          current_pwm_base_period <= 0;
        elsif to_integer(unsigned(reg_pwm_base_period)) < current_pwm_base_period then
          current_pwm_base_period <= current_pwm_base_period - 31;
        elsif (to_integer(unsigned(reg_pwm_base_period)) > current_pwm_base_period) and ((current_pwm_base_period) > (2**(pwm_bit)-65)) then
          current_pwm_base_period <= (2**(pwm_bit)-1);
        elsif to_integer(unsigned(reg_pwm_base_period)) > current_pwm_base_period then
          current_pwm_base_period <= current_pwm_base_period + 64;
        end if;
                                        -- change in duty cycle
        if (to_integer(unsigned(reg_pwm_duty_cycle)) < current_pwm_duty_cycle) and ((current_pwm_duty_cycle) < 31) then
          current_pwm_duty_cycle <= 0;
        elsif to_integer(unsigned(reg_pwm_duty_cycle)) < current_pwm_duty_cycle then
          current_pwm_duty_cycle <= current_pwm_duty_cycle - 31;
        elsif (to_integer(unsigned(reg_pwm_duty_cycle)) > current_pwm_duty_cycle) and ((current_pwm_duty_cycle) > (2**(pwm_bit)-33)) then
          current_pwm_duty_cycle <= (2**(pwm_bit)-1);
        elsif to_integer(unsigned(reg_pwm_duty_cycle)) > current_pwm_duty_cycle then
          current_pwm_duty_cycle <= current_pwm_duty_cycle + 32;
        end if;
                                        -- change in configuration register
        pwm_control <= reg_pwm_control;
      end if;
    end if;
  end process;
end rtl;