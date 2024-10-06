-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector.
-- With each rising edge, it turns on the next onboard LED in sequence,
-- continuously cycling from D1 to D4.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- TODO LORIS: rename pins for segment0 and segment1

-- TODO LORIS: segment1 and segment2 are display1 and display0

-- TODO LORIS: rename top entity
entity LedCounter is
  -- Inputs/Outputs for the top module.
  port (
    io_pmod_1    : in  std_logic;  -- Clock signal from PMOD pin 1
    o_led_1      : out std_logic;  -- Output to onboard LED 1
    o_led_2      : out std_logic;  -- Output to onboard LED 2
    o_led_3      : out std_logic;  -- Output to onboard LED 3
    o_led_4      : out std_logic;  -- Output to onboard LED 4
    o_segment1_a : out std_logic;
    o_segment1_b : out std_logic;
    o_segment1_c : out std_logic;
    o_segment1_d : out std_logic;
    o_segment1_e : out std_logic;
    o_segment1_f : out std_logic;
    o_segment1_g : out std_logic;
    o_segment2_a : out std_logic;
    o_segment2_b : out std_logic;
    o_segment2_c : out std_logic;
    o_segment2_d : out std_logic;
    o_segment2_e : out std_logic;
    o_segment2_f : out std_logic;
    o_segment2_g : out std_logic);
end entity;

architecture RTL of LedCounter is

  -- Wires connecting the two modules RisingEdgeCounter and DisplayDriver.
  signal w_segment0_digit : t_decimal_digit;
  signal w_segment1_digit : t_decimal_digit;

begin
  -- Module tracking the number of rising edges on pmod_1 in a local
  -- register, and activating the corresponding output signals.
  RisingEdgeCounterInstance: entity work.RisingEdgeCounter
    port map (
      i_clk  => io_pmod_1,
      o_segment0_digit => w_segment0_digit,
      o_segment1_digit => w_segment1_digit);

  -- Module activating the correct LED based on the control signals.
  -- A module is overkill here, but I wanted to experiment with wires.
  -- TODO LORIS: refactor comment
  Display0DriverInstance: entity work.DisplayDriver
    port map (
      i_decimal_digit => w_segment0_digit,
      o_segment_a     => o_segment1_a,
      o_segment_b     => o_segment1_b,
      o_segment_c     => o_segment1_c,
      o_segment_d     => o_segment1_d,
      o_segment_e     => o_segment1_e,
      o_segment_f     => o_segment1_f,
      o_segment_g     => o_segment1_g);

  Display1DriverInstance: entity work.DisplayDriver
    port map (
      i_decimal_digit => w_segment1_digit,
      o_segment_a     => o_segment2_a,
      o_segment_b     => o_segment2_b,
      o_segment_c     => o_segment2_c,
      o_segment_d     => o_segment2_d,
      o_segment_e     => o_segment2_e,
      o_segment_f     => o_segment2_f,
      o_segment_g     => o_segment2_g);

end architecture;
