library ieee;
use ieee.std_logic_1164.all;
use work.custom_types.all;
 
entity DisplayDriver is
  port (
    i_decimal_digit : in  t_decimal_digit;
    o_segment_a     : out std_logic;
    o_segment_b     : out std_logic;
    o_segment_c     : out std_logic;
    o_segment_d     : out std_logic;
    o_segment_e     : out std_logic;
    o_segment_f     : out std_logic;
    o_segment_g     : out std_logic);
end entity;
 
architecture RTL of DisplayDriver is

signal r_hex_encoding : std_logic_vector(7 downto 0);

begin

  process(i_decimal_digit)
  begin
    case i_decimal_digit is
      when ZERO =>
        r_hex_encoding <= not X"3F";
      when ONE =>
        r_hex_encoding <= not X"06";
      when TWO =>
        r_hex_encoding <= not X"5B";
      when THREE =>
        r_hex_encoding <= not X"4F";
      when FOUR =>
        r_hex_encoding <= not X"66";
      when FIVE =>
        r_hex_encoding <= not X"6D";
      when SIX =>
        r_hex_encoding <= not X"7D";
      when SEVEN =>
        r_hex_encoding <= not X"07";
      when EIGHT =>
        r_hex_encoding <= not X"7F";
      when NINE =>
        r_hex_encoding <= not X"67";
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
