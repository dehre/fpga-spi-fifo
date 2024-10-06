library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- TODO LORIS: maybe work directly with BCD values, and let
--      this counter count to 9 as already done. Create a type
--      for the BCD number?

entity RisingEdgeDecimalCounter is
  port (
    i_clk  : in  std_logic;
    o_display0_digit: out t_decimal_digit;
    o_display1_digit: out t_decimal_digit);
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

      -- if count==99:
      if r_display0_count = 9 and r_display1_count = 9 then
        r_display0_count <= 0;
        r_display1_count <= 0;

      -- if count%10==9:
      elsif r_display0_count = 9 then
        r_display0_count <= 0;
        r_display1_count <= r_display1_count + 1;

      -- else:
      else 
        r_display0_count <= r_display0_count + 1;

      end if;
    end if;
  end process;

  process(r_display0_count)
  begin
    case r_display0_count is
      when 0 =>
        o_display0_digit <= t_decimal_digit'(ZERO);
      when 1 =>
        o_display0_digit <= t_decimal_digit'(ONE);
      when 2 =>
        o_display0_digit <= t_decimal_digit'(TWO);
      when 3 =>
        o_display0_digit <= t_decimal_digit'(THREE);
      when 4 =>
        o_display0_digit <= t_decimal_digit'(FOUR);
      when 5 =>
        o_display0_digit <= t_decimal_digit'(FIVE);
      when 6 =>
        o_display0_digit <= t_decimal_digit'(SIX);
      when 7 =>
        o_display0_digit <= t_decimal_digit'(SEVEN);
      when 8 =>
        o_display0_digit <= t_decimal_digit'(EIGHT);
      when 9 =>
        o_display0_digit <= t_decimal_digit'(NINE);
    end case;
  end process;

  process(r_display1_count)
  begin
    case r_display1_count is
      when 0 =>
        o_display1_digit <= t_decimal_digit'(ZERO);
      when 1 =>
        o_display1_digit <= t_decimal_digit'(ONE);
      when 2 =>
        o_display1_digit <= t_decimal_digit'(TWO);
      when 3 =>
        o_display1_digit <= t_decimal_digit'(THREE);
      when 4 =>
        o_display1_digit <= t_decimal_digit'(FOUR);
      when 5 =>
        o_display1_digit <= t_decimal_digit'(FIVE);
      when 6 =>
        o_display1_digit <= t_decimal_digit'(SIX);
      when 7 =>
        o_display1_digit <= t_decimal_digit'(SEVEN);
      when 8 =>
        o_display1_digit <= t_decimal_digit'(EIGHT);
      when 9 =>
        o_display1_digit <= t_decimal_digit'(NINE);
    end case;
  end process;

end architecture;
