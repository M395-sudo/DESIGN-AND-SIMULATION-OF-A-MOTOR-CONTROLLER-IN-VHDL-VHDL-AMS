library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM_digital_top_E is
  generic(message_length : integer   := 17;
          pwm_bit        : integer   := 14;
          address_length : integer   := 2);
  port (                                -- general signals
    reset_n                         : in  std_logic;
    clk                             : in  std_logic;
    -- SPI interface
    sclk                            : in  std_logic;
    cs_n                            : in  std_logic;
    din                             : in  std_logic;
    -- PWM output
    pwm_out1, pwm_out2, pwm_n_sleep : out std_logic);
end entity PWM_digital_top_E;

architecture struct of PWM_digital_top_E is

--ADD DECLARATION FOR THE NECESSARY COMPONENTS
component PWM_controller_E 
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
end component PWM_controller_E;

component SPI 
  port (                                -- general signals
    reset_n    : in  std_logic;
    clk        : in  std_logic;
    -- SPI interface
    sclk       : in  std_logic;
    cs_n       : in  std_logic;
    din        : in  std_logic;
    -- internal interface
    new_data   : out std_logic;         -- new data available
    regnr      : out std_logic_vector (address_length-1 downto 0);  -- register address
    regcontent : out std_logic_vector (pwm_bit-1 downto 0);  -- register write value
    regwrite_n : out std_logic          -- write access?
    );
end component SPI;

component PWM_driver_E 
  port(
    reset_n                         : in  std_logic;
    clk                             : in  std_logic;
    pwm_base_period                 : in  integer range 0 to 2**(pwm_bit)-1;
    pwm_duty_cycle                  : in  integer range 0 to 2**(pwm_bit)-1;
    pwm_control                     : in  std_logic_vector(7 downto 0);
    pwm_cycle_done                  : out std_logic;  -- new values at inputs are now used
    pwm_out1, pwm_out2, pwm_n_sleep : out std_logic);
end component PWM_driver_E;
--ADD NECESSARY SIGNALS
--signal    reset_n_s         :   std_logic;
--signal    clk_s             :   std_logic;
-- from SPI controller
signal    new_data_s        :   std_logic;    -- new data available
signal    regnr_s           :   std_logic_vector (address_length-1 downto 0);  -- register address
signal    regcontent_s      :   std_logic_vector (pwm_bit-1 downto 0);  -- register write value
signal    regwrite_n_s      :   std_logic; 
-- from/to pwm_driver
signal    pwm_cycle_done_s  :   std_logic;    -- new values at inputs are now used
signal    pwm_control_s     :   std_logic_vector(7 downto 0);
signal    pwm_base_period_s :   integer range 0 to 2**(pwm_bit)-1;
signal    pwm_duty_cycle_s  :   integer range 0 to 2**(pwm_bit)-1;

-- SPI input interfaces
--signal    sclk_s            :  std_logic;
--signal    cs_n_s            :  std_logic;
--signal    din_s             :  std_logic;
-- PWM output
--signal    pwm_out1_s, pwm_out2_s, pwm_n_sleep_s :  std_logic;

begin

--ADD INSTANCES OF THE DIFFERENT COMPONENTS
SPI_comp:SPI port map (
    reset_n => reset_n,
    clk => clk,
    sclk => sclk,
    cs_n => cs_n,
    din => din,
    new_data => new_data_s,
    regnr => regnr_s,
    regcontent => regcontent_s,
    regwrite_n => regwrite_n_s);

PWM_controller:PWM_controller_E port map(
    reset_n => reset_n,
    clk => clk,
    new_data => new_data_s,
    regnr => regnr_s,
    regcontent => regcontent_s,
    regwrite_n => regwrite_n_s,
    pwm_cycle_done => pwm_cycle_done_s,
    pwm_control => pwm_control_s,
    pwm_base_period => pwm_base_period_s,
    pwm_duty_cycle  => pwm_duty_cycle_s);

PWM_driver: PWM_driver_E port map(
    reset_n => reset_n,
    clk => clk,
    pwm_base_period => pwm_base_period_s,
    pwm_duty_cycle  => pwm_duty_cycle_s,
    pwm_control => pwm_control_s,
    pwm_cycle_done => pwm_cycle_done_s,
    pwm_out1 => pwm_out1, 
    pwm_out2 => pwm_out2, 
    pwm_n_sleep => pwm_n_sleep);
 
end struct;