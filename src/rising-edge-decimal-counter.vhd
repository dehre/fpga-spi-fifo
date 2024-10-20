library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RisingEdgeDecimalCounter is
  port (
    i_clk     : in  std_logic;
    o_ones_bcd: out std_logic_vector(3 downto 0);
    o_tens_bcd: out std_logic_vector(3 downto 0));
end entity;

architecture RTL of RisingEdgeDecimalCounter is

  -- Registers storing the number of rising edges from 0 to 99.
  -- Ones and tens has been kept separate to ease their conversion
  -- into BCD-values.
  signal r_ones_count : natural range 0 to 9;
  signal r_tens_count : natural range 0 to 9;

begin
  process(i_clk) is
  begin
    if rising_edge(i_clk) then

      -- if count == 99:
      if r_ones_count = 9 and r_tens_count = 9 then
        r_ones_count <= 0;
        r_tens_count <= 0;

      -- if count%10 == 9:
      elsif r_ones_count = 9 then
        r_ones_count <= 0;
        r_tens_count <= r_tens_count + 1;

      -- else:
      else 
        r_ones_count <= r_ones_count + 1;

      end if;
    end if;
  end process;

  o_ones_bcd <= std_logic_vector(to_unsigned(r_ones_count, o_ones_bcd'length));
  o_tens_bcd <= std_logic_vector(to_unsigned(r_tens_count, o_tens_bcd'length));

end architecture;
