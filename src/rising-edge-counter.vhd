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

  -- Create the signal to do the actual counting
  -- Subtract 1, since counter starts at 0
  signal r_counter : natural range 0 to COUNT_LIMIT - 1;

begin
  -- This process increments the counter at rising edges
  process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if r_counter = COUNT_LIMIT - 1 then
          r_counter <= 0;
      else
          r_counter <= r_counter + 1;
      end if;
    end if;
  end process;

  o_sel0 <= '1' when r_counter = 0 else '0';
  o_sel1 <= '1' when r_counter = 1 else '0';
  o_sel2 <= '1' when r_counter = 2 else '0';
  o_sel3 <= '1' when r_counter = 3 else '0';

end architecture;
