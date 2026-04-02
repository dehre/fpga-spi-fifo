library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity DisplayDriver is
  port (
    i_bcd       : in  std_logic_vector(3 downto 0);
    o_segment_a : out std_logic;
    o_segment_b : out std_logic;
    o_segment_c : out std_logic;
    o_segment_d : out std_logic;
    o_segment_e : out std_logic;
    o_segment_f : out std_logic;
    o_segment_g : out std_logic);
end entity;
 
architecture RTL of DisplayDriver is

  signal r_hex_encoding : std_logic_vector(7 downto 0);

  -- Infer LUT implementation when using Synplify Pro; see:
  -- https://www.latticesemi.com/support/answerdatabase/3/8/5/3853
  attribute syn_romstyle : string;
  attribute syn_romstyle of r_hex_encoding : signal is "logic";

begin

  -- Table: https://hosteng.com/dmdhelp/content/instruction_set/SEG_Hex_BCD_to_7_Segment_Display.htm
  process(i_bcd)
  begin
    case to_integer(unsigned(i_bcd)) is
      when 0 =>
        r_hex_encoding <= not x"3F"; -- invert needed on Go board
      when 1 =>
        r_hex_encoding <= not x"06";
      when 2 =>
        r_hex_encoding <= not x"5B";
      when 3 =>
        r_hex_encoding <= not x"4F";
      when 4 =>
        r_hex_encoding <= not x"66";
      when 5 =>
        r_hex_encoding <= not x"6D";
      when 6 =>
        r_hex_encoding <= not x"7D";
      when 7 =>
        r_hex_encoding <= not x"07";
      when 8 =>
        r_hex_encoding <= not x"7F";
      when 9 =>
        r_hex_encoding <= not x"6F";
      when 10 =>
        r_hex_encoding <= not x"77";
      when 11 =>
        r_hex_encoding <= not x"7c";
      when 12 =>
        r_hex_encoding <= not x"39";
      when 13 =>
        r_hex_encoding <= not x"5E";
      when 14 =>
        r_hex_encoding <= not x"79";
      when 15 =>
        r_hex_encoding <= not x"71";
      when others =>
        r_hex_encoding <= (others => '0'); -- should not happen
    end case;
  end process;

  o_segment_a <= r_hex_encoding(0);
  o_segment_b <= r_hex_encoding(1);
  o_segment_c <= r_hex_encoding(2);
  o_segment_d <= r_hex_encoding(3);
  o_segment_e <= r_hex_encoding(4);
  o_segment_f <= r_hex_encoding(5);
  o_segment_g <= r_hex_encoding(6);
  -- r_hex_encoding(7) is unused

end architecture;
