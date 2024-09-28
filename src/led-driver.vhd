library ieee;
use ieee.std_logic_1164.all;
 
entity LedDriver is
  port (
    i_sel0  : in  std_logic;
    i_sel1  : in  std_logic;
    i_sel2  : in  std_logic;
    i_sel3  : in  std_logic;
    o_data0 : out std_logic;
    o_data1 : out std_logic;
    o_data2 : out std_logic;
    o_data3 : out std_logic);
end entity;
 
architecture RTL of LedDriver is
begin
  o_data0 <= '1' when i_sel0 = '1' else '0';
  o_data1 <= '1' when i_sel1 = '1' else '0';
  o_data2 <= '1' when i_sel2 = '1' else '0';
  o_data3 <= '1' when i_sel3 = '1' else '0';
end architecture;
