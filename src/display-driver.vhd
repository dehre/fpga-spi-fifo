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
    o_segment_f     : out std_logic);
end entity;
 
architecture RTL of DisplayDriver is

signal r_hex_encoding : std_logic_vector(7 downto 0);

begin

  process(i_decimal_digit)
  begin
    case i_decimal_digit is
      when ZERO =>
        r_hex_encoding <= X"7E";
      when ONE =>
        r_hex_encoding <= X"30";
      when TWO =>
        r_hex_encoding <= X"6D";
      when THREE =>
        r_hex_encoding <= X"79";
      when FOUR =>
        r_hex_encoding <= X"33";
      when FIVE =>
        r_hex_encoding <= X"5B";
      when SIX =>
        r_hex_encoding <= X"5F";
      when SEVEN =>
        r_hex_encoding <= X"70";
      when EIGHT =>
        r_hex_encoding <= X"7F";
      when NINE =>
        r_hex_encoding <= X"7B";
    end case;
  end process;

  -- r_Hex_Encoding(7) is unused
  o_segment_a <= r_hex_encoding(6);
  o_segment_b <= r_hex_encoding(5);
  o_segment_c <= r_hex_encoding(4);
  o_segment_d <= r_hex_encoding(3);
  o_segment_e <= r_hex_encoding(2);
  o_segment_f <= r_hex_encoding(1);

end architecture;
