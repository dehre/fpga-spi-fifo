library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity NumberToBCD is
  port (
    i_number   : in  natural range 0 to 99;
    o_ones_bcd : out std_logic_vector(3 downto 0);
    o_tens_bcd : out std_logic_vector(3 downto 0));
end entity;

architecture RTL of NumberToBCD is
  signal r_tens : natural range 0 to 9;
  signal r_ones : natural range 0 to 9;
begin
  process(i_number)
  begin
    r_ones <= i_number mod 10;
    r_tens <= i_number / 10;
  end process;

  o_ones_bcd <= std_logic_vector(to_unsigned(r_ones, o_ones_bcd'length));
  o_tens_bcd <= std_logic_vector(to_unsigned(r_tens, o_tens_bcd'length));
end architecture;
