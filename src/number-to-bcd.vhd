-- Converts a natural number (0 to 99) into its two-digit BCD representation.
-- 
-- The conversion is based on the "double-dabble" algorithm.
-- Useful article:
-- https://vhdlguru.blogspot.com/2010/04/8-bit-binary-to-bcd-converter-double.html
-- 
-- A simpler implementation, such as:
-- ```
-- o_ones_bcd <= std_logic_vector(to_unsigned(i_number mod 10, o_ones_bcd'length));
-- o_tens_bcd <= std_logic_vector(to_unsigned(i_number / 10  , o_tens_bcd'length));
-- ```
-- was discarded to avoid combinational loops during synthesis.

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

  signal w_binary : unsigned(7 downto 0);
  signal w_bcd    : unsigned(7 downto 0);

  function f_binary_to_bcd (w_binary : unsigned(7 downto 0))
  return unsigned is
    variable v_idx : integer := 0;
    variable v_bcd : unsigned(7 downto 0) := (others => '0'); -- 2-digits BCD
  begin
    for v_idx in 7 downto 1 loop
      -- left shift the bits
      v_bcd := v_bcd(6 downto 0) & w_binary(v_idx);

      -- adjust ones-digit if greater than 4
      if v_bcd(3 downto 0) > 4 then
        v_bcd(3 downto 0) := v_bcd(3 downto 0) + 3;
      end if;

      -- adjust tens-digit if greater than 4
      if v_bcd(7 downto 4) > 4 then
        v_bcd(7 downto 4) := v_bcd(7 downto 4) + 3;
      end if;
    end loop;

    -- final shift for the last bit
    v_bcd := v_bcd(6 downto 0) & w_binary(0);

    -- return the result
    return v_bcd;
  end function;

begin

  w_binary   <= to_unsigned(i_number, 8);
  w_bcd      <= f_binary_to_bcd(w_binary);
  o_ones_bcd <= std_logic_vector(w_bcd(3 downto 0));
  o_tens_bcd <= std_logic_vector(w_bcd(7 downto 4));

end architecture;
