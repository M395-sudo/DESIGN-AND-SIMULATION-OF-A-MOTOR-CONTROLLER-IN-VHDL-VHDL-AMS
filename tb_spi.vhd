library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pwm_spi is
end tb_pwm_spi;

architecture testbench of tb_pwm_spi is

  constant pwm_bit        : integer   := 14;
  constant message_length : integer   := 17;
  constant address_length : integer   := 2;

  component SPI is
    generic(pwm_bit        : integer   := 21;
            message_length : integer   := 24;
            address_length : integer   := 2);
    port (                              -- general signals
      reset_n    : in  std_logic;
      clk        : in  std_logic;
      -- SPI interface
      sclk       : in  std_logic;
      cs_n       : in  std_logic;
      din        : in  std_logic;
      -- internal interface
      new_data   : out std_logic;       -- new data available
      regnr      : out std_logic_vector (address_length-1 downto 0);  -- register address
      regcontent : out std_logic_vector (pwm_bit-1 downto 0);  -- register write value
      regwrite_n : out std_logic        -- write access?

      );
  end component;

  signal reset_n, clk, SPIclk_enable, start, send : std_logic := '0';
  signal cs_n_S, din_S, sclk_S, SPIclk            : std_logic := '1';
  signal new_data_S, regwrite_n_S         : std_logic;
  signal regnr_S                                  : std_logic_vector (address_length-1 downto 0);
  signal regcontent_S                             : std_logic_vector (pwm_bit-1 downto 0);
  signal message                                  : std_logic_vector(message_length-1 downto 0);
  alias regnr                                     : std_logic_vector (address_length-1 downto 0) is message(message_length - 1 downto message_length - address_length);
  alias regwrite_n                                : std_logic is message(message_length-address_length-2);
  alias regcontent                                : std_logic_vector(pwm_bit-1 downto 0) is message (pwm_bit - 1 downto 0);
  signal debug_counter                            : integer;



begin
  dut : SPI generic map(pwm_bit, message_length, address_length)
    port map (
      reset_n    => reset_n,
      clk        => clk,
      sclk       => SPIclk,
      cs_n       => cs_n_S,
      din        => din_S,
      new_data   => new_data_S,
      regnr      => regnr_S,
      regcontent => regcontent_S,
      regwrite_n => regwrite_n_S
      );

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
    regnr                  <= (others => '0');
    regwrite_n             <= '0';
    regcontent             <= (others => '0');
    message                <= (others => '0');
    wait for 500 ns;
    regnr                  <= "01";     -- write to base register 
    regwrite_n             <= '1';      -- set base value to 256
    start                  <= '1';
    wait until send = '1';
    start                  <= '0';
    wait until send = '0';
    regnr                  <= "10";     -- write to duty register 
    regcontent(8 downto 7) <= "01";     -- set duty value to 128
    start                  <= '1';
    wait until send = '1';
    start                  <= '0';
    wait until send = '0';
    regnr                  <= "11";     -- write to control register 
    regcontent             <= "00000000000011";
    start                  <= '1';
    wait until send = '1';
    start                  <= '0';
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
    --counter := message_length-1;
    send          <= '1';
    SPIclk_enable <= '1';
    cs_n_S        <= '0';
    for I in message_length-1 downto 0 loop
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