library ieee;
use ieee.std_logic_1164.all;

entity PWM_driver_E is
  generic(
    pwm_bit : integer := 14
    );
  port(
    reset_n                         : in  std_logic;
    clk                             : in  std_logic;
    pwm_base_period                 : in  integer range 0 to 2**(pwm_bit)-1;
    pwm_duty_cycle                  : in  integer range 0 to 2**(pwm_bit)-1;
    pwm_control                     : in  std_logic_vector(7 downto 0);
    pwm_cycle_done                  : out std_logic;  -- new values at inputs are now used
    pwm_out1, pwm_out2, pwm_n_sleep : out std_logic);
end PWM_driver_E;

architecture rtl of PWM_driver_E is
--ADD SIGNALS
signal pwm_base_period_s                 :  integer range 0 to 2**(pwm_bit)-1 := 0;
signal pwm_duty_cycle_s                  :  integer range 0 to 2**(pwm_bit)-1 := 0; 
signal count : integer range 0 to 2**(pwm_bit)-1 := 0;
signal pwm_out : std_logic;
begin
--ADD THE FUNCTIONALITY FOR THE PWM DRIVER
process (reset_n, clk)
begin
    if reset_n = '0' then
        count <= 0;
        pwm_out1 <= 'Z';
        pwm_out2 <= 'Z';
        pwm_n_sleep <= '0';
        pwm_cycle_done <= '1';
        pwm_base_period_s <= pwm_base_period;
        pwm_duty_cycle_s <= pwm_duty_cycle;
    elsif clk'event and clk = '1' then
        if count >= pwm_base_period_s-1 then 
            count <= 0;
            pwm_base_period_s <= pwm_base_period;
            pwm_duty_cycle_s <= pwm_duty_cycle;
            pwm_cycle_done <= '1';
        else
            pwm_cycle_done <= '0';
            count <= count +1;
            if count < pwm_duty_cycle_s then 
                pwm_out <= '1';
            else 
                pwm_out <= '0';
            end if;
        end if;
        
        if pwm_control(2) = '1' then
               pwm_n_sleep <= '1';
               pwm_out1 <= '1';
               pwm_out2 <= '1';
        elsif pwm_control(2) = '0' then
            if pwm_control(0) = '0' then 
                pwm_out1 <= 'Z';
                pwm_out2 <= 'Z';
                pwm_n_sleep <= '0'; 
            
            else
                if pwm_control(1) = '0' then
                   pwm_n_sleep <= '1';
                   pwm_out1 <= pwm_out;
                   pwm_out2 <= pwm_out;
                elsif pwm_control(1) = '1' then
                   pwm_n_sleep <= '1';
                   pwm_out1 <= pwm_out;
                   pwm_out2 <= not pwm_out;
                end if;
             end if;
                  
        end if;
    end if;    
end process;        
end rtl;