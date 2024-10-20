-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector.
-- With each rising edge, it turns on the next onboard LED in sequence,
-- continuously cycling from D1 to D4.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DisplayCounter is
  -- Inputs/Outputs for the top module.
  port (
    io_pmod_1    : in  std_logic;  -- Clock signal from PMOD pin 1
    o_display0_a : out std_logic;  -- Output to segment_a of display_0
    o_display0_b : out std_logic;  -- TODO LORIS
    o_display0_c : out std_logic;  -- Output to onboard LED 4
    o_display0_d : out std_logic;
    o_display0_e : out std_logic;
    o_display0_f : out std_logic;
    o_display0_g : out std_logic;
    o_display1_a : out std_logic;
    o_display1_b : out std_logic;
    o_display1_c : out std_logic;
    o_display1_d : out std_logic;
    o_display1_e : out std_logic;
    o_display1_f : out std_logic;
    o_display1_g : out std_logic);
end entity;

architecture RTL of DisplayCounter is

  -- Wires connecting the two modules RisingEdgeDecimalCounter and DisplayDriver.
  signal w_ones_bcd : std_logic_vector(3 downto 0);
  signal w_tens_bcd : std_logic_vector(3 downto 0);

begin
  -- Module tracking the number of rising edges on pmod_1 in a local
  -- register, and activating the corresponding output signals.
  RisingEdgeDecimalCounterInstance: entity work.RisingEdgeDecimalCounter
    port map (
      i_clk      => io_pmod_1,
      o_ones_bcd => w_ones_bcd,
      o_tens_bcd => w_tens_bcd);

  -- Module activating the correct LED based on the control signals.
  -- A module is overkill here, but I wanted to experiment with wires.
  -- TODO LORIS: refactor comment
  Display0DriverInstance: entity work.DisplayDriver
    port map (
      i_bcd       => w_ones_bcd,
      o_segment_a => o_display0_a,
      o_segment_b => o_display0_b,
      o_segment_c => o_display0_c,
      o_segment_d => o_display0_d,
      o_segment_e => o_display0_e,
      o_segment_f => o_display0_f,
      o_segment_g => o_display0_g);

  Display1DriverInstance: entity work.DisplayDriver
    port map (
      i_bcd       => w_tens_bcd,
      o_segment_a => o_display1_a,
      o_segment_b => o_display1_b,
      o_segment_c => o_display1_c,
      o_segment_d => o_display1_d,
      o_segment_e => o_display1_e,
      o_segment_f => o_display1_f,
      o_segment_g => o_display1_g);

end architecture;
