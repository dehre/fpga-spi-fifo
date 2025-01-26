-- Testbench to exercise the FIFO entity
library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity FIFO_TB is
end entity FIFO_TB;

architecture RTL of FIFO_TB is
  constant WORD_SIZE    : natural := 8;
  constant DEPTH        : natural := 4;

  signal r_rst          : std_logic := '0';
  signal r_clk          : std_logic := '0';
  signal r_wr_en        : std_logic := '0';
  signal r_wr_data      : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
  signal r_rd_en        : std_logic := '0';
  signal r_rd_undo      : std_logic := '0';
  signal w_rd_data      : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_full         : std_logic;
  signal w_almost_full  : std_logic;
  signal w_almost_empty : std_logic;
  signal w_empty        : std_logic;
  signal w_count        : natural range 0 to DEPTH;

  procedure f_fifo_reset(
    signal r_clk     : in std_logic;
    signal r_rst     : out std_logic
  ) is
  begin
    r_rst <= '1';
    wait until rising_edge(r_clk);
    r_rst <= '0';
    wait until rising_edge(r_clk);
  end procedure;

  procedure f_fifo_write(
    constant i_data  : in std_logic_vector;
    signal r_clk     : in std_logic;
    signal r_wr_en   : out std_logic;
    signal r_wr_data : out std_logic_vector
  ) is
  begin
    r_wr_data <= i_data;
    r_wr_en <= '1';
    wait until rising_edge(r_clk);
    r_wr_en <= '0';
    wait until rising_edge(r_clk);
  end procedure;

  procedure f_fifo_read(
    signal r_clk     : in std_logic;
    signal r_rd_en   : out std_logic
  ) is
  begin
    r_rd_en <= '1';
    wait until rising_edge(r_clk);
    r_rd_en <= '0';
    wait until rising_edge(r_clk);
  end procedure;

  procedure f_fifo_read_undo(
    signal r_clk     : in std_logic;
    signal r_rd_undo : out std_logic
  ) is
  begin
    r_rd_undo <= '1';
    wait until rising_edge(r_clk);
    r_rd_undo <= '0';
    wait until rising_edge(r_clk);
  end procedure;
begin

  -- Generate clock
  r_clk <= not r_clk after 1 ns;
 
  -- Unit Under Test
  UUT : entity work.FIFO
    generic map(
      WIDTH => WORD_SIZE,
      DEPTH => DEPTH)
    port map (
      i_rst          => r_rst,
      i_clk          => r_clk,
      i_wr_en        => r_wr_en,
      i_wr_data      => r_wr_data,
      i_rd_en        => r_rd_en,
      i_rd_undo      => r_rd_undo,
      o_rd_data      => w_rd_data,
      o_full         => w_full,
      o_almost_full  => w_almost_full,
      o_almost_empty => w_almost_empty,
      o_empty        => w_empty,
      o_count        => w_count);

  -- Exercise the UUT
  process is 
  begin

    -- Reset
    f_fifo_reset(r_clk, r_rst);
    assert(w_empty = '1') severity failure;
    assert(w_almost_empty = '1') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 0) severity failure;

    -- Write four items -> FIFO FULL
    f_fifo_write(x"10", r_clk, r_wr_en, r_wr_data);
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '1') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 1) severity failure;

    f_fifo_write(x"20", r_clk, r_wr_en, r_wr_data);
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '0') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 2) severity failure;

    f_fifo_write(x"30", r_clk, r_wr_en, r_wr_data);
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '0') severity failure;
    assert(w_almost_full = '1') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 3) severity failure;

    f_fifo_write(x"40", r_clk, r_wr_en, r_wr_data);
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '0') severity failure;
    assert(w_almost_full = '1') severity failure;
    assert(w_full = '1') severity failure;
    assert(w_count = 4) severity failure;

    -- Read four items -> FIFO EMPTY
    f_fifo_read(r_clk, r_rd_en);
    assert(w_rd_data = x"10") severity failure;
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '0') severity failure;
    assert(w_almost_full = '1') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 3) severity failure;

    f_fifo_read(r_clk, r_rd_en);
    assert(w_rd_data = x"20") severity failure;
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '0') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 2) severity failure;

    f_fifo_read(r_clk, r_rd_en);
    assert(w_rd_data = x"30") severity failure;
    assert(w_empty = '0') severity failure;
    assert(w_almost_empty = '1') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 1) severity failure;

    f_fifo_read(r_clk, r_rd_en);
    assert(w_rd_data = x"40") severity failure;
    assert(w_empty = '1') severity failure;
    assert(w_almost_empty = '1') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 0) severity failure;

    -- Undo last read
    f_fifo_read_undo(r_clk, r_rd_undo);
    assert(w_empty = '0') severity failure;
    assert(w_count = 1) severity failure;

    -- Reread last item
    f_fifo_read(r_clk, r_rd_en);
    assert(w_rd_data = x"40") severity failure;
    assert(w_empty = '1') severity failure;
    assert(w_almost_empty = '1') severity failure;
    assert(w_almost_full = '0') severity failure;
    assert(w_full = '0') severity failure;
    assert(w_count = 0) severity failure;

    -- End simulation
    wait for 5 ns;
    report "FIFO Testbench passed!" severity note;
    finish;
  end process;
end architecture;
