library ieee;
use ieee.std_logic_1164.all;
 
entity Led_Driver is
  port (
    i_Sel0  : in  std_logic;
    i_Sel1  : in  std_logic;
    i_Sel2  : in  std_logic;
    i_Sel3  : in  std_logic;
    o_Data0 : out std_logic;
    o_Data1 : out std_logic;
    o_Data2 : out std_logic;
    o_Data3 : out std_logic);
end entity;
 
architecture RTL of Led_Driver is
begin
  o_Data0 <= '1' when i_Sel0 = '1' else '0';
  o_Data1 <= '1' when i_Sel1 = '1' else '0';
  o_Data2 <= '1' when i_Sel2 = '1' else '0';
  o_Data3 <= '1' when i_Sel3 = '1' else '0';
end architecture;
