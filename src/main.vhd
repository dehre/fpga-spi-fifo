-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector.
-- With each rising edge, it turns on the next onboard LED in sequence,
-- continuously cycling from D1 to D4.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- TODO LORIS: rename pins for segment0 and segment1

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
    o_segment1_g : out std_logic);
end entity;

architecture RTL of LedCounter is

  -- Count up to 4 (the number of onboard LEDs).
  constant COUNT_LIMIT : natural := 4;

  -- Wires connecting the two modules RisingEdgeCounter and LedDriver.
  signal w_sel0 : std_logic;
  signal w_sel1 : std_logic;
  signal w_sel2 : std_logic;
  signal w_sel3 : std_logic;

begin
  -- Module tracking the number of rising edges on pmod_1 in a local
  -- register, and activating the corresponding output signals.
  RisingEdgeCounterInstance: entity work.RisingEdgeCounter
    generic map (COUNT_LIMIT => COUNT_LIMIT)
    port map (
      i_clk  => io_pmod_1,
      o_sel0 => w_sel0,
      o_sel1 => w_sel1,
      o_sel2 => w_sel2,
      o_sel3 => w_sel3);

  -- Module activating the correct LED based on the control signals.
  -- A module is overkill here, but I wanted to experiment with wires.
  LedDriverInstance: entity work.LedDriver
    port map (
      i_sel0  => w_sel0,
      i_sel1  => w_sel1,
      i_sel2  => w_sel2,
      i_sel3  => w_sel3,
      o_data0 => o_led_1,
      o_data1 => o_led_2,
      o_data2 => o_led_3,
      o_data3 => o_led_4);

  DisplayDriverInstance: entity work.DisplayDriver
    port map (
      i_decimal_digit => t_decimal_digit'(SEVEN),
      o_segment_a     => o_segment1_a,
      o_segment_b     => o_segment1_b,
      o_segment_c     => o_segment1_c,
      o_segment_d     => o_segment1_d,
      o_segment_e     => o_segment1_e,
      o_segment_f     => o_segment1_f,
      o_segment_g     => o_segment1_g);

end architecture;
