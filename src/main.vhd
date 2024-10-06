-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector.
-- With each rising edge, it turns on the next onboard LED in sequence,
-- continuously cycling from D1 to D4.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- TODO LORIS: rename top entity
entity LedCounter is
  -- Inputs/Outputs for the top module.
  port (
    io_pmod_1    : in  std_logic;  -- Clock signal from PMOD pin 1
    o_led_1      : out std_logic;  -- Output to onboard LED 1
    o_led_2      : out std_logic;  -- Output to onboard LED 2
    o_led_3      : out std_logic;  -- Output to onboard LED 3
    o_led_4      : out std_logic;  -- Output to onboard LED 4
    o_segment0_a : out std_logic;
    o_segment0_b : out std_logic;
    o_segment0_c : out std_logic;
    o_segment0_d : out std_logic;
    o_segment0_e : out std_logic;
    o_segment0_f : out std_logic;
    o_segment0_g : out std_logic;
    o_segment1_a : out std_logic;
    o_segment1_b : out std_logic;
    o_segment1_c : out std_logic;
    o_segment1_d : out std_logic;
    o_segment1_e : out std_logic;
    o_segment1_f : out std_logic;
    o_segment1_g : out std_logic);
end entity;

architecture RTL of LedCounter is

  -- Wires connecting the two modules RisingEdgeCounter and DisplayDriver.
  signal w_digit0 : t_decimal_digit;
  signal w_digit1 : t_decimal_digit;

begin
  -- Module tracking the number of rising edges on pmod_1 in a local
  -- register, and activating the corresponding output signals.
  RisingEdgeCounterInstance: entity work.RisingEdgeCounter
    port map (
      i_clk  => io_pmod_1,
      o_digit0 => w_digit0,
      o_digit1 => w_digit1);

  -- Module activating the correct LED based on the control signals.
  -- A module is overkill here, but I wanted to experiment with wires.
  -- TODO LORIS: refactor comment
  Display0DriverInstance: entity work.DisplayDriver
    port map (
      i_decimal_digit => w_digit0,
      o_segment_a     => o_segment0_a,
      o_segment_b     => o_segment0_b,
      o_segment_c     => o_segment0_c,
      o_segment_d     => o_segment0_d,
      o_segment_e     => o_segment0_e,
      o_segment_f     => o_segment0_f,
      o_segment_g     => o_segment0_g);

  Display1DriverInstance: entity work.DisplayDriver
    port map (
      i_decimal_digit => w_digit1,
      o_segment_a     => o_segment1_a,
      o_segment_b     => o_segment1_b,
      o_segment_c     => o_segment1_c,
      o_segment_d     => o_segment1_d,
      o_segment_e     => o_segment1_e,
      o_segment_f     => o_segment1_f,
      o_segment_g     => o_segment1_g);

end architecture;
