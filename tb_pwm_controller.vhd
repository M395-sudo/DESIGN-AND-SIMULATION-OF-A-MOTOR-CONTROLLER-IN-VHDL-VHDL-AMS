library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pwm_controller is
end tb_pwm_controller;

architecture testbench of tb_pwm_controller is

  constant pwm_bit        : integer := 14;
  constant message_length : integer := 17;
  constant address_length : integer := 2;

  signal reset_n, clk, new_data_S, pwm_cycle_done_s : std_logic := '0';
  signal regwrite_n_S                               : std_logic := '0';
  signal regnr_S                                    : std_logic_vector(address_length-1 downto 0) := "00";
  signal regcontent_S                               : std_logic_vector (pwm_bit-1 downto 0);
  signal pwm_base_S, pwm_duty_S                     : integer range 0 to 2**(pwm_bit)-1;
  signal pwm_control_S                              : std_logic_vector(7 downto 0) := "00000000";

  component PWM_controller_E is
    generic(message_length : integer := 17;
            pwm_bit        : integer := 14;
            address_length : integer := 2
            );
    port(                               -- general inputs
      reset_n    : in std_logic;
      clk        : in std_logic;
      -- from SPI controller
      new_data   : in std_logic;        -- new data available
      regnr      : in std_logic_vector (address_length-1 downto 0);  -- register address
      regcontent : in std_logic_vector (pwm_bit-1 downto 0);  -- register write value
      regwrite_n : in std_logic;        -- write access?

      -- from/to pwm_driver
      pwm_cycle_done  : in  std_logic;  -- new values at inputs are now used
      pwm_control     : out std_logic_vector(7 downto 0);
      pwm_base_period : out integer range 0 to 2**(pwm_bit)-1;
      pwm_duty_cycle  : out integer range 0 to 2**(pwm_bit)-1
      );
  end component;

begin

-- ADD AN INSTANCE OF THE PWM CONTROLLER AND CONNECT ALL THE PORTS WITH THE
-- CORESSPONDING SIGNALS:
	DUT:PWM_controller_E 
	port map(
		reset_n => reset_n, clk=> clk,
		new_data => new_data_S,
		regnr => regnr_S,
		regcontent => regcontent_S,
		regwrite_n => regwrite_n_S,
		pwm_cycle_done => pwm_cycle_done_s,
		pwm_control => pwm_control_S,
		pwm_base_period => pwm_base_S,
		pwm_duty_cycle => pwm_duty_S
	);


-- reset generation for the PWM controller
  
    reset_n <= '1' after 100 ns;
    
-- generation of pwm_cycle_done after each PWM cycle
  ack_gen_P : process
  begin
    pwm_cycle_done_s <= '1';
    wait for 10 ns;
    pwm_cycle_done_s <= '0';
    wait for pwm_base_s * 10 ns;
    --wait for 10 ns;
  end process;

-- ADD CLOCK GENERATION FOR THE PWM CONTROLLER
	clk <= not clk after 5ns;

  PWM_test : process
  begin
    -- ADD TEST CASES FOR THE PWM CONTROLLER:
	regcontent_S <= "11111111111111";
	regwrite_n_S <= '1';
	wait for 30ns;
	new_data_S <= '1';
	wait for 10ns;
	regwrite_n_S <= '0';
	regnr_S <= "01" ;
	wait for 100ns;
	regnr_S <= "10";
	wait for 10ns;
	regnr_S <= "11";
		
	wait for 100 ms;
	
	regcontent_S <= "00000000000000";
	
	regnr_S <= "01";
	wait for 10ns;
	regnr_S <= "10";
	wait for 10ns;
	regnr_S <= "11";
	wait;
  end process;
end testbench;