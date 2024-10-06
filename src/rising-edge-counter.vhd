library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- TODO LORIS: rename RisingEdgeDecimalCounter
-- TODO LORIS: maybe work directly with BCD values, and let
--      this counter count to 9 as already done. Create a type
--      for the BCD number?

-- TODO LORIS: rename o_display0_digit
entity RisingEdgeCounter is
  port (
    i_clk  : in  std_logic;
    o_segment0_digit: out t_decimal_digit;
    o_segment1_digit: out t_decimal_digit);
end entity;

architecture RTL of RisingEdgeCounter is

  -- TODO LORIS: update comment
  -- Register storing the number of rising edges,
  -- from 0 to (<onboard-leds-count> - 1).
  signal r_count_segment0 : natural range 0 to 9;
  signal r_count_segment1 : natural range 0 to 9;

begin
  process(i_clk) is
  begin
    if rising_edge(i_clk) then

      -- if count==99:
      if r_count_segment0 = 9 and r_count_segment1 = 9 then
        r_count_segment0 <= 0;
        r_count_segment1 <= 0;

      -- if count%10==9:
      elsif r_count_segment0 = 9 then
        r_count_segment0 <= 0;
        r_count_segment1 <= r_count_segment1 + 1;

      -- else:
      else 
        r_count_segment0 <= r_count_segment0 + 1;

      end if;
    end if;
  end process;

  process(r_count_segment0)
  begin
    case r_count_segment0 is
      when 0 =>
        o_segment0_digit <= t_decimal_digit'(ZERO);
      when 1 =>
        o_segment0_digit <= t_decimal_digit'(ONE);
      when 2 =>
        o_segment0_digit <= t_decimal_digit'(TWO);
      when 3 =>
        o_segment0_digit <= t_decimal_digit'(THREE);
      when 4 =>
        o_segment0_digit <= t_decimal_digit'(FOUR);
      when 5 =>
        o_segment0_digit <= t_decimal_digit'(FIVE);
      when 6 =>
        o_segment0_digit <= t_decimal_digit'(SIX);
      when 7 =>
        o_segment0_digit <= t_decimal_digit'(SEVEN);
      when 8 =>
        o_segment0_digit <= t_decimal_digit'(EIGHT);
      when 9 =>
        o_segment0_digit <= t_decimal_digit'(NINE);
    end case;
  end process;

  process(r_count_segment1)
  begin
    case r_count_segment1 is
      when 0 =>
        o_segment1_digit <= t_decimal_digit'(ZERO);
      when 1 =>
        o_segment1_digit <= t_decimal_digit'(ONE);
      when 2 =>
        o_segment1_digit <= t_decimal_digit'(TWO);
      when 3 =>
        o_segment1_digit <= t_decimal_digit'(THREE);
      when 4 =>
        o_segment1_digit <= t_decimal_digit'(FOUR);
      when 5 =>
        o_segment1_digit <= t_decimal_digit'(FIVE);
      when 6 =>
        o_segment1_digit <= t_decimal_digit'(SIX);
      when 7 =>
        o_segment1_digit <= t_decimal_digit'(SEVEN);
      when 8 =>
        o_segment1_digit <= t_decimal_digit'(EIGHT);
      when 9 =>
        o_segment1_digit <= t_decimal_digit'(NINE);
    end case;
  end process;

end architecture;
