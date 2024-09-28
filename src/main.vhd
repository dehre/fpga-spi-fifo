-- Top of Demux and Count Demonstration
-- Instantiates a Counter, which generates a ~1 second toggling signal
-- 
-- User can select which LED is illuminated with this toggling signal 
-- by using using S1 and S2 to drive select bits of a demux.
-- Demonstrates demuxing of this toggling signal to one of 4 LED outputs.

-- TODO LORIS: better naming convention and formatting?

library ieee;
use ieee.std_logic_1164.all;

entity LedCounter is
  port (
    io_pmod_1  : in  std_logic;
    o_led_1    : out std_logic;
    o_led_2    : out std_logic;
    o_led_3    : out std_logic;
    o_led_4    : out std_logic
  );
end entity;

architecture RTL of LedCounter is

  -- Count up to <number-of-onboard-leds>
  constant COUNT_LIMIT : integer := 4;

  signal w_sel0: std_logic;
  signal w_sel1: std_logic;
  signal w_sel2: std_logic;
  signal w_sel3: std_logic;

begin
  RisingEdgeCounterInstance: entity work.RisingEdgeCounter
    generic map (COUNT_LIMIT => COUNT_LIMIT)
    port map (
      i_clk    => io_pmod_1,
      o_sel0   => w_sel0,
      o_sel1   => w_sel1,
      o_sel2   => w_sel2,
      o_sel3   => w_sel3);

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
