library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RisingEdgeCounter is
  generic (COUNT_LIMIT : natural);
  port (
    i_clk  : in  std_logic;
    o_sel0 : out std_logic;
    o_sel1 : out std_logic;
    o_sel2 : out std_logic;
    o_sel3 : out std_logic);
end entity;

architecture RTL of RisingEdgeCounter is

  -- Register storing the number of rising edges,
  -- from 0 to (<onboard-leds-count> - 1).
  signal r_count : natural range 0 to COUNT_LIMIT - 1;

begin
  process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if r_count = COUNT_LIMIT - 1 then
          r_count <= 0;
      else
          r_count <= r_count + 1;
      end if;
    end if;
  end process;

  o_sel0 <= '1' when r_count = 0 else '0';
  o_sel1 <= '1' when r_count = 1 else '0';
  o_sel2 <= '1' when r_count = 2 else '0';
  o_sel3 <= '1' when r_count = 3 else '0';

end architecture;
