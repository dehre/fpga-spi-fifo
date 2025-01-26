-- Testbench to exercise the DisplayDriver entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity DisplayDriver_TB is
end entity DisplayDriver_TB;

architecture RTL of DisplayDriver_TB is
  signal r_bcd       : std_logic_vector(3 downto 0) := (others => '0');
  signal w_segment_a : std_logic;
  signal w_segment_b : std_logic;
  signal w_segment_c : std_logic;
  signal w_segment_d : std_logic;
  signal w_segment_e : std_logic;
  signal w_segment_f : std_logic;
  signal w_segment_g : std_logic;

  type SegmentsArrayType is array(0 to 15) of std_logic_vector(6 downto 0);
  constant EXPECTED : SegmentsArrayType := (
    "0000001", -- 0
    "1001111", -- 1
    "0010010", -- 2
    "0000110", -- 3
    "1001100", -- 4
    "0100100", -- 5
    "0100000", -- 6
    "0001111", -- 7
    "0000000", -- 8
    "0000100", -- 9
    "0001000", -- 10
    "1100000", -- 11
    "0110001", -- 12
    "1000010", -- 13
    "0110000", -- 14
    "0111000"  -- 15
  );
begin

  -- Unit Under Test
  UUT : entity work.DisplayDriver
    port map (
      i_bcd       => r_bcd,
      o_segment_a => w_segment_a,
      o_segment_b => w_segment_b,
      o_segment_c => w_segment_c,
      o_segment_d => w_segment_d,
      o_segment_e => w_segment_e,
      o_segment_f => w_segment_f,
      o_segment_g => w_segment_g
    );

  -- Exercise the UUT
  process is
    variable v_segments : std_logic_vector(6 downto 0);
  begin
    for i in 0 to 15 loop
      r_bcd <= std_logic_vector(to_unsigned(i, 4));
      wait for 1 ns; -- allow propagation delay

      v_segments := w_segment_a & w_segment_b & w_segment_c & w_segment_d & w_segment_e & w_segment_f & w_segment_g;
      assert (v_segments = EXPECTED(i))
        report "Test failed for value: " & integer'image(i)
        severity failure;
    end loop;

    wait for 5 ns;
    report "DisplayDriver Testbench passed!" severity note;
    finish;
  end process;
end architecture;
