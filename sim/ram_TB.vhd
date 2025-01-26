-- Testbench to exercise the RAM entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity RAM_TB is
end entity RAM_TB;

architecture RTL of RAM_TB is
  constant WORD_SIZE : natural := 8;
  constant DEPTH     : natural := 15;

  signal r_wr_clk    : std_logic := '0';
  signal r_wr_addr   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_wr_en     : std_logic := '0';
  signal r_wr_data   : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');

  signal r_rd_clk    : std_logic := '0';
  signal r_rd_addr   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_rd_en     : std_logic := '0';
  signal w_rd_data   : std_logic_vector(WORD_SIZE-1 downto 0);
begin

  -- Generate clock
  r_wr_clk <= not r_wr_clk after 1 ns;
  r_rd_clk <= not r_rd_clk after 1 ns;

  -- Unit Under Test
  UUT : entity work.RAM
    generic map (
      WIDTH => WORD_SIZE,
      DEPTH => DEPTH
    )
    port map (
      i_wr_clk  => r_wr_clk,
      i_wr_addr => r_wr_addr,
      i_wr_en   => r_wr_en,
      i_wr_data => r_wr_data,
      i_rd_clk  => r_rd_clk,
      i_rd_addr => r_rd_addr,
      i_rd_en   => r_rd_en,
      o_rd_data => w_rd_data
    );

  -- Exercise the UUT
  process is
  begin

    -- Write 0xAA to address 0x03
    r_wr_addr <= x"03";
    r_wr_data <= x"AA";
    r_wr_en <= '1';
    wait until rising_edge(r_wr_clk);
    r_wr_en <= '0';
    wait until rising_edge(r_wr_clk);

    -- Write 0xBB to address 0x08
    r_wr_addr <= x"08";
    r_wr_data <= x"BB";
    r_wr_en <= '1';
    wait until rising_edge(r_wr_clk);
    r_wr_en <= '0';
    wait until rising_edge(r_wr_clk);

    -- Read data back from address 0x03
    r_rd_addr <= x"03";
    r_rd_en <= '1';
    wait until rising_edge(r_rd_clk);
    r_rd_en <= '0';
    wait until rising_edge(r_rd_clk);
    assert(w_rd_data = x"AA") severity failure;

    -- Read data back from address 0x08
    r_rd_addr <= x"08";
    r_rd_en <= '1';
    wait until rising_edge(r_rd_clk);
    r_rd_en <= '0';
    wait until rising_edge(r_rd_clk);
    assert(w_rd_data = x"BB") severity failure;

    -- End simulation
    wait for 5 ns;
    report "RAM Testbench passed!" severity note;
    finish;
  end process;
end architecture;
