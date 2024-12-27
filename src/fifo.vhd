-- Russell Merrick - http://www.nandland.com
--
-- Infers a Dual Port RAM (DPRAM) Based FIFO using a single clock
-- Uses a Dual Port RAM but automatically handles read/write addresses.
-- To use Almost Full/Empty Flags (dynamic)
-- Set i_AF_Level to number of words away from full when o_AF_Flag goes high
-- Set i_AE_Level to number of words away from empty when o_AE goes high
--   o_AE_Flag is high when this number OR LESS is in FIFO.
--
-- Generics: 
-- WIDTH     - Width of the FIFO
-- DEPTH     - Max number of items able to be stored in the FIFO
--
-- This FIFO cannot be used to cross clock domains, because in order to keep count
-- correctly it would need to handle all metastability issues. 
-- If crossing clock domains is required, use FIFO primitives directly from the vendor.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- TODO LORIS: positive type
entity FIFO is 
  generic (
    WIDTH     : integer := 8;
    DEPTH     : integer := 256);
  port (
    i_rst_l : in std_logic;
    i_clk   : in std_logic;
    -- Write Side
    i_wr_dv    : in  std_logic;
    i_wr_data  : in  std_logic_vector(WIDTH-1 downto 0);
    i_af_level : in  integer;
    o_af_flag  : out std_logic;
    o_full     : out std_logic;
    -- Read Side
    i_rd_en    : in  std_logic;
    i_rd_undo  : in  std_logic;
    o_rd_data  : out std_logic_vector(WIDTH-1 downto 0);
    i_ae_level : in  integer;
    o_ae_flag  : out std_logic;
    o_empty    : out std_logic);
end entity FIFO;

architecture RTL of FIFO is 
  
  -- Number of bits required to store DEPTH words
  constant DEPTH_BITS : integer := integer(ceil(log2(real(DEPTH))));

  signal r_wr_addr, r_rd_addr : natural range 0 to DEPTH-1;
  signal r_count : natural range 0 to DEPTH;

  signal w_wr_addr, w_rd_addr : std_logic_vector(DEPTH_BITS-1 downto 0);

begin

  w_wr_addr <= std_logic_vector(to_unsigned(r_wr_addr, DEPTH_BITS));
  w_rd_addr <= std_logic_vector(to_unsigned(r_rd_addr, DEPTH_BITS));

  -- Dual Port RAM used for storing FIFO data
  RamInstance : entity work.RAM
    generic map(
      WIDTH => WIDTH,
      DEPTH => DEPTH)
    port map(
      -- Write Port
      i_wr_clk  => i_clk,
      i_wr_addr => w_wr_addr,
      i_wr_dv   => i_wr_dv,
      i_wr_data => i_wr_data,

      -- Read Port
      i_rd_clk  => i_clk,
      i_rd_addr => w_rd_addr,
      i_rd_en   => i_rd_en,
      o_rd_data => o_rd_data);

  -- Main process to control address and counters for FIFO
  -- TODO LORIS: positive reset line
  -- TODO LORIS: reset on rising_edge(i_clk)
  process (i_clk, i_rst_l) is
  begin
    if i_rst_l = '0' then
      r_wr_addr <= 0;
      r_rd_addr <= 0;
      r_count   <= 0;
    elsif rising_edge(i_clk) then
      
      -- Write
      if i_wr_dv = '1' then
        if r_wr_addr = DEPTH-1 then
          r_wr_addr <= 0;
        else
          r_wr_addr <= r_wr_addr + 1;
        end if;
      end if;

      -- Read
      if i_rd_en = '1' then
        if r_rd_addr = DEPTH-1 then
          r_rd_addr <= 0;
        else
          r_rd_addr <= r_rd_addr + 1;
        end if;
      end if;

      -- Undo Read
      if i_rd_undo = '1' then
        if r_rd_addr = 0 then
          r_rd_addr <= DEPTH-1;
        else
          r_rd_addr <= r_rd_addr - 1;
        end if;
      end if;

      -- TODO LORIS: simplify
      -- Keeps track of number of words in FIFO
      -- Read with no write
      if i_rd_en = '1' and i_wr_dv = '0' and i_rd_undo = '0' then
        if (r_count /= 0) then
          r_count <= r_count - 1;
        end if;
      -- write with no read
      elsif i_wr_dv = '1' and i_rd_en = '0' and i_rd_undo = '0' then
        if r_count /= DEPTH then
          r_count <= r_count + 1;
        end if;
      -- Undo read
      elsif i_rd_undo = '1' and i_wr_dv = '0' and i_rd_en = '0' then
        if r_count /= DEPTH then
          r_count <= r_count + 1;
        end if;
      end if;

    end if;
  end process;

  -- TODO LORIS: if r_Count=0 or r_Count=1 and i_Rd_En=1
  -- TODO LORIS: clean up parentheses
  o_full <= '1' when ((r_count=DEPTH) or (r_count=DEPTH-1 and i_wr_dv='1')) else '0';
  o_empty <= '1' when (r_count = 0) else '0';
  o_af_flag <= '1' when ((r_count>=(DEPTH-i_af_level)) or (r_count>=(DEPTH-1-i_af_level) and i_wr_dv='1')) else '0';
  o_ae_flag <= '1' when (r_count <= i_ae_level) else '0';

end architecture;
