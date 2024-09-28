-- Count the number of rising edges on pin 1 of the PMOD connector.
-- At each rising edge, light up the next onboard-led, from D1 to D4 and
-- then back to D1.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LedCounter is
  -- Inputs/Outputs for the top module.
  port (
    io_pmod_1 : in  std_logic;
    o_led_1   : out std_logic;
    o_led_2   : out std_logic;
    o_led_3   : out std_logic;
    o_led_4   : out std_logic
  );
end entity;

architecture RTL of LedCounter is

  -- Count up to 4 (the number of onboard-leds).
  constant COUNT_LIMIT : natural := 4;

  -- Wires connecting the two modules RisingEdgeCounter and LedDriver.
  signal w_sel0 : std_logic;
  signal w_sel1 : std_logic;
  signal w_sel2 : std_logic;
  signal w_sel3 : std_logic;

begin
  -- Module storing the number of rising edges in a local register, and
  -- selecting the correct output based on the count.
  RisingEdgeCounterInstance: entity work.RisingEdgeCounter
    generic map (COUNT_LIMIT => COUNT_LIMIT)
    port map (
      i_clk  => io_pmod_1,
      o_sel0 => w_sel0,
      o_sel1 => w_sel1,
      o_sel2 => w_sel2,
      o_sel3 => w_sel3);

  -- Module selecting the correct onboard-led to light up based on the
  -- selection. A module is totally overkill here, but I wanted to
  -- experiment with wires.
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

end architecture;
