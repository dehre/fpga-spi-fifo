library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity FIFO is 
  generic (
    WIDTH : natural := 8;
    DEPTH : natural := 256);
  port (
    i_rst          : in std_logic;
    i_clk          : in std_logic;

    -- Write signals
    i_wr_en        : in  std_logic;
    i_wr_data      : in  std_logic_vector(WIDTH-1 downto 0);

    -- Read signals
    i_rd_en        : in  std_logic;
    i_rd_undo      : in  std_logic; -- undo last read operation
    o_rd_data      : out std_logic_vector(WIDTH-1 downto 0);

    -- Flags and Count
    o_full         : out std_logic;
    o_almost_full  : out std_logic;
    o_almost_empty : out std_logic;
    o_empty        : out std_logic;
    o_count        : out natural range 0 to DEPTH);
end entity;

architecture RTL of FIFO is 
  
  -- Number of bits required to store DEPTH words
  constant DEPTH_BITS : natural := natural(ceil(log2(real(DEPTH))));

  signal r_count   : natural range 0 to DEPTH;
  signal r_wr_idx  : natural range 0 to DEPTH-1;
  signal r_rd_idx  : natural range 0 to DEPTH-1;
  signal w_wr_addr : std_logic_vector(DEPTH_BITS-1 downto 0);
  signal w_rd_addr : std_logic_vector(DEPTH_BITS-1 downto 0);

begin

  w_wr_addr <= std_logic_vector(to_unsigned(r_wr_idx, DEPTH_BITS));
  w_rd_addr <= std_logic_vector(to_unsigned(r_rd_idx, DEPTH_BITS));

  -- Dual Port RAM used for storing FIFO data
  RamInstance : entity work.RAM
    generic map(
      WIDTH => WIDTH,
      DEPTH => DEPTH)
    port map(
      i_wr_clk  => i_clk,
      i_wr_addr => w_wr_addr,
      i_wr_en   => i_wr_en,
      i_wr_data => i_wr_data,
      i_rd_clk  => i_clk,
      i_rd_addr => w_rd_addr,
      i_rd_en   => i_rd_en,
      o_rd_data => o_rd_data);

  process (i_clk, i_rst) is
  begin
    if i_rst = '1' then
      r_wr_idx <= 0;
      r_rd_idx <= 0;
      r_count   <= 0;
    elsif rising_edge(i_clk) then
      
      -- Write
      if i_wr_en = '1' then
        if r_wr_idx = DEPTH-1 then
          r_wr_idx <= 0;
        else
          r_wr_idx <= r_wr_idx + 1;
        end if;
      end if;

      -- Read
      if i_rd_en = '1' then
        if r_rd_idx = DEPTH-1 then
          r_rd_idx <= 0;
        else
          r_rd_idx <= r_rd_idx + 1;
        end if;
      end if;

      -- Undo Read
      if i_rd_undo = '1' then
        if r_rd_idx = 0 then
          r_rd_idx <= DEPTH-1;
        else
          r_rd_idx <= r_rd_idx - 1;
        end if;
      end if;

      -- Keeps track of number of words in FIFO
      if i_rd_en = '1' then
        if (r_count /= 0) then
          r_count <= r_count - 1;
        end if;
      elsif i_wr_en = '1' or i_rd_undo = '1' then
        if r_count /= DEPTH then
          r_count <= r_count + 1;
        end if;
      end if;

    end if;
  end process;

  o_full <= '1'
    when (r_count = DEPTH) or (r_count = DEPTH-1 and i_wr_en = '1')
    else '0';

  o_almost_full <= '1'
    when (r_count >= DEPTH-1) or (r_count >= DEPTH-2 and i_wr_en = '1')
    else '0';

  o_almost_empty <= '1'
    when (r_count <= 1) or (r_count <= 2 and i_rd_en = '1')
    else '0';

  o_empty <= '1'
    when (r_count = 0) or (r_count = 1 and i_rd_en = '1')
    else '0';

  o_count <= r_count;

end architecture;
