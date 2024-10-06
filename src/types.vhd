library ieee;
use ieee.std_logic_1164.all;

package types is

    -- Enumerated type for decimal digits (0-9)
    -- TODO LORIS: remove
    type t_decimal_digit is (ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE);

    -- Binary Coded Decimal
    subtype t_bcd is std_logic_vector(3 downto 0);

end package;
