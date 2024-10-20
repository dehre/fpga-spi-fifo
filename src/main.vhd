-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector,
-- displaying the count (0-99) on two 7-segment displays.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DisplayCounter is
  -- Inputs/Outputs for the top module.
  port (
    io_pmod_1    : in  std_logic;  -- Clock signal from PMOD pin 1
    o_display0_a : out std_logic;  -- Segment A output for display 0
    o_display0_b : out std_logic;  -- Segment B output for display 0
    o_display0_c : out std_logic;  -- Segment C output for display 0
    o_display0_d : out std_logic;  -- Segment D output for display 0
    o_display0_e : out std_logic;  -- Segment E output for display 0
    o_display0_f : out std_logic;  -- Segment F output for display 0
    o_display0_g : out std_logic;  -- Segment G output for display 0
    o_display1_a : out std_logic;  -- Segment A output for display 1
    o_display1_b : out std_logic;  -- Segment B output for display 1
    o_display1_c : out std_logic;  -- Segment C output for display 1
    o_display1_d : out std_logic;  -- Segment D output for display 1
    o_display1_e : out std_logic;  -- Segment E output for display 1
    o_display1_f : out std_logic;  -- Segment F output for display 1
    o_display1_g : out std_logic); -- Segment G output for display 1
end entity;

architecture RTL of DisplayCounter is

  -- Wires connecting the two modules RisingEdgeDecimalCounter and DisplayDriver.
  signal w_ones_bcd : std_logic_vector(3 downto 0);
  signal w_tens_bcd : std_logic_vector(3 downto 0);

begin
  -- Module counting the number of rising edges on pmod_1.
  -- Outputs a 2-digits BCD value (0 to 99).
  RisingEdgeDecimalCounterInstance: entity work.RisingEdgeDecimalCounter
    port map (
      i_clk      => io_pmod_1,
      o_ones_bcd => w_ones_bcd,
      o_tens_bcd => w_tens_bcd);

  -- Modules driving the two 7-segments displays.
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
