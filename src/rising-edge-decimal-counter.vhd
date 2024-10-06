library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- TODO LORIS: rename display0 to lsb and display1 to msb
-- and explain in comment
entity RisingEdgeDecimalCounter is
  port (
    i_clk  : in  std_logic;
    o_display0_bcd: out t_bcd;
    o_display1_bcd: out t_bcd);
end entity;

architecture RTL of RisingEdgeDecimalCounter is

  -- TODO LORIS: update comment
  -- Register storing the number of rising edges,
  -- from 0 to (<onboard-leds-count> - 1).
  signal r_display0_count : natural range 0 to 9;
  signal r_display1_count : natural range 0 to 9;

begin
  process(i_clk) is
  begin
    if rising_edge(i_clk) then

      -- if count == 99:
      if r_display0_count = 9 and r_display1_count = 9 then
        r_display0_count <= 0;
        r_display1_count <= 0;

      -- if count%10 == 9:
      elsif r_display0_count = 9 then
        r_display0_count <= 0;
        r_display1_count <= r_display1_count + 1;

      -- else:
      else 
        r_display0_count <= r_display0_count + 1;

      end if;
    end if;
  end process;

  -- TODO LORIS: to I need this to_unsigned?
  -- TODO LORIS: can I take the length of the type instead?
  o_display0_bcd <= std_logic_vector(to_unsigned(r_display0_count, o_display0_bcd'length));
  o_display1_bcd <= std_logic_vector(to_unsigned(r_display1_count, o_display1_bcd'length));

end architecture;
