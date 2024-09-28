library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Rising_Edge_Counter is
  generic (COUNT_LIMIT : natural);
  port (
    i_Clk    : in  std_logic;
    o_Sel0   : out std_logic;
    o_Sel1   : out std_logic;
    o_Sel2   : out std_logic;
    o_Sel3   : out std_logic);
end entity;

architecture RTL of Rising_Edge_Counter is

  -- Create the signal to do the actual counting
  -- Subtract 1, since counter starts at 0
  signal r_Counter : natural range 0 to COUNT_LIMIT - 1;

begin
  -- This process increments the counter at rising edges
  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if r_Counter = COUNT_LIMIT - 1 then
          r_Counter <= 0;
      else
          r_Counter <= r_Counter + 1;
      end if;
    end if;
  end process;

  o_Sel0 <= '1' when r_Counter = 0 else '0';
  o_Sel1 <= '1' when r_Counter = 1 else '0';
  o_Sel2 <= '1' when r_Counter = 2 else '0';
  o_Sel3 <= '1' when r_Counter = 3 else '0';

end architecture;
