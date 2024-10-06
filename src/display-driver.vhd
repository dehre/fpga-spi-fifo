library ieee;
use ieee.std_logic_1164.all;
use work.types.all;
 
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
      when t_decimal_digit'(ZERO) =>
        r_hex_encoding <= not x"3F"; -- invert needed on Go board
      when t_decimal_digit'(ONE) =>
        r_hex_encoding <= not x"06";
      when t_decimal_digit'(TWO) =>
        r_hex_encoding <= not x"5B";
      when t_decimal_digit'(THREE) =>
        r_hex_encoding <= not x"4F";
      when t_decimal_digit'(FOUR) =>
        r_hex_encoding <= not x"66";
      when t_decimal_digit'(FIVE) =>
        r_hex_encoding <= not x"6D";
      when t_decimal_digit'(SIX) =>
        r_hex_encoding <= not x"7D";
      when t_decimal_digit'(SEVEN) =>
        r_hex_encoding <= not x"07";
      when t_decimal_digit'(EIGHT) =>
        r_hex_encoding <= not x"7F";
      when t_decimal_digit'(NINE) =>
        r_hex_encoding <= not x"67";
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
