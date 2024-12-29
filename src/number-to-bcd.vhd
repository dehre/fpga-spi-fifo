-- Converts a natural number (0 to 99) into its two-digit BCD representation.
-- For inputs outside the valid range, the module outputs 0xFF as a fail-safe.
-- 
-- TODO LORIS:
-- Warning: Found 1 combinational loops!
-- @W: BN137 :"c:\users\marce\desktop\new folder\src\number-to-bcd.vhd":26:16:26:28
-- Found combinational loop during mapping at net NumberToBCDInstance.mult1_un54_sum_i[5]

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
  signal w_tens : natural range 0 to 15;
  signal w_ones : natural range 0 to 15;
begin
  w_ones <= i_number mod 10 when i_number <= 99 else 15;
  w_tens <= i_number / 10   when i_number <= 99 else 15;

  o_ones_bcd <= std_logic_vector(to_unsigned(w_ones, o_ones_bcd'length));
  o_tens_bcd <= std_logic_vector(to_unsigned(w_tens, o_tens_bcd'length));
end architecture;
