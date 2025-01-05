-- Testbench to exercise the NumberToBCD module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity NumberToBCD_TB is
end entity NumberToBCD_TB;

architecture RTL of NumberToBCD_TB is
  signal r_number   : natural range 0 to 99 := 0;
  signal w_ones_bcd : std_logic_vector(3 downto 0) := (others => '0');
  signal w_tens_bcd : std_logic_vector(3 downto 0) := (others => '0');
begin

  -- Unit Under Test
  UUT : entity work.NumberToBCD
    port map (
      i_number   => r_number,
      o_ones_bcd => w_ones_bcd,
      o_tens_bcd => w_tens_bcd);

  -- Exercise the UUT
  process is
  begin

    r_number <= 0;
    wait for 1 ns;
    assert(w_ones_bcd = x"0") severity failure;
    assert(w_tens_bcd = x"0") severity failure;

    r_number <= 99;
    wait for 1 ns;
    assert(w_ones_bcd = x"9") severity failure;
    assert(w_tens_bcd = x"9") severity failure;

    r_number <= 18;
    wait for 1 ns;
    assert(w_ones_bcd = x"8") severity failure;
    assert(w_tens_bcd = x"1") severity failure;

    r_number <= 37;
    wait for 1 ns;
    assert(w_ones_bcd = x"7") severity failure;
    assert(w_tens_bcd = x"3") severity failure;

    finish;
  end process;
end architecture;
