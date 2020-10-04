-------------------------------------------------------------------------------
-- Title      : DHS ADC
-- Project    : 
-------------------------------------------------------------------------------
-- File       : control.vhd
-- Author     : Marcel Putsche  <...@hrz.tu-chemnitz.de>
-- Company    : TU-Chemmnitz, SSE
-- Created    : 2018-04-10
-- Last update: 2019-04-11
-- Platform   : x86_64-redhat-linux
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: SPI part of the ADC in DHS practical lab
-------------------------------------------------------------------------------
-- Copyright (c) 2018 TU-Chemmnitz, SSE
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-10  1.0      mput    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPI is
  generic(message_length : integer   := 17;
          pwm_bit        : integer   := 14;
          address_length : integer   := 2);
         
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
end entity SPI;

architecture RTL of SPI is
  --ADD TYPE FOR STATE MACHINE
type state_type is (new_cycle, fetch_data, write_data, end_spi);
  --ADD SIGNALS
signal state, next_state : state_type;
signal count : integer range 0 to 17;
signal temp_data : std_logic_vector (message_length-1 downto 0);

begin

--ADD PROCESSES FOR THE STATE MACHINE WHICH CONTROLS THE SPI, COUNTER FOR SPI
state_reg: process (clk, reset_n)
begin
if reset_n = '0' then
    state <= new_cycle;
elsif (clk'event and clk='1') then
    state <= next_state;
end if;
end process;     


state_change : process (cs_n, state, count)
begin
    --count <= 0;
    next_state <= state;
    case state is 
        when new_cycle =>
            if cs_n = '0' then
                next_state <= fetch_data;
            end if;
        when fetch_data =>
            if count = 17 then
                next_state <= write_data;
            end if;
        when write_data =>next_state <= end_spi;
        when end_spi =>
            if cs_n = '1' then 
                next_state <= new_cycle;    
            end if;
        when others => next_state <= new_cycle;
    end case;
end process;

--AND OUTPUT REGISTERS
output_reg : process (sclk, reset_n, state)
begin
    if reset_n='0' then
        temp_data <= (others =>'0'); 
        regnr <= (others =>'0');
        regwrite_n <= '1'; 
        regcontent <= (others =>'0');
        count <= 0;
    elsif state = fetch_data then 
        if count < 17 then 
            if (falling_edge (sclk)) then
                temp_data <= temp_data (message_length-2 downto 0) & din;
                count <= count + 1;
            end if;
        end if;
    elsif state = write_data then
        count <= 0;
        new_data <= '1';
        regnr <= temp_data(message_length - 1 downto message_length - address_length);
        regwrite_n <= temp_data(message_length - address_length - 1);
        regcontent <= temp_data(pwm_bit - 1 downto 0);
    elsif state = end_spi then
        new_data <= '0'; 
    elsif state = new_cycle then
        count <= 0;
        new_data <= '0';
        --regnr <= temp_data(message_length - 1 downto message_length - address_length);
        --regwrite_n <= temp_data(message_length - address_length - 1);
        --regcontent <= temp_data(pwm_bit - 1 downto 0);
    end if;
end process;             
-- counter synchronous to SPI clock?
end architecture RTL;