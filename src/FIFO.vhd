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
    i_Rst_L : in std_logic;
    i_Clk   : in std_logic;
    -- Write Side
    i_Wr_DV    : in  std_logic;
    i_Wr_Data  : in  std_logic_vector(WIDTH-1 downto 0);
    i_AF_Level : in  integer;
    o_AF_Flag  : out std_logic;
    o_Full     : out std_logic;
    -- Read Side
    i_Rd_En    : in  std_logic;
    i_Rd_Undo  : in  std_logic;
    o_Rd_Data  : out std_logic_vector(WIDTH-1 downto 0);
    i_AE_Level : in  integer;
    o_AE_Flag  : out std_logic;
    o_Empty    : out std_logic);
end entity FIFO;

architecture RTL of FIFO is 
  
  -- Number of bits required to store DEPTH words
  constant DEPTH_BITS : integer := integer(ceil(log2(real(DEPTH))));

  signal r_Wr_Addr, r_Rd_Addr : natural range 0 to DEPTH-1;
  signal r_Count : natural range 0 to DEPTH;  -- 1 extra to go to DEPTH

  signal w_Wr_Addr, w_Rd_Addr : std_logic_vector(DEPTH_BITS-1 downto 0);

begin

  w_Wr_Addr <= std_logic_vector(to_unsigned(r_Wr_Addr, DEPTH_BITS));
  w_Rd_Addr <= std_logic_vector(to_unsigned(r_Rd_Addr, DEPTH_BITS));

  -- Dual Port RAM used for storing FIFO data
  Memory_Inst : entity work.RAM_2Port
    generic map(
      WIDTH => WIDTH,
      DEPTH => DEPTH)
    port map(
      -- Write Port
      i_Wr_Clk  => i_Clk,
      i_Wr_Addr => w_Wr_Addr,
      i_Wr_DV   => i_Wr_DV,
      i_Wr_Data => i_Wr_Data,

      -- Read Port
      i_Rd_Clk  => i_Clk,
      i_Rd_Addr => w_Rd_Addr,
      i_Rd_En   => i_Rd_En,
      o_Rd_Data => o_Rd_Data);

  -- Main process to control address and counters for FIFO
  process (i_Clk, i_Rst_L) is
  begin
    if i_Rst_L = '0' then
      r_Wr_Addr <= 0;
      r_Rd_Addr <= 0;
      r_Count   <= 0;
    elsif rising_edge(i_Clk) then
      
      -- Write
      if i_Wr_DV = '1' then
        if r_Wr_Addr = DEPTH-1 then
          r_Wr_Addr <= 0;
        else
          r_Wr_Addr <= r_Wr_Addr + 1;
        end if;
      end if;

      -- Read
      if i_Rd_En = '1' then
        if r_Rd_Addr = DEPTH-1 then
          r_Rd_Addr <= 0;
        else
          r_Rd_Addr <= r_Rd_Addr + 1;
        end if;
      end if;

      -- Undo Read
      if i_Rd_Undo = '1' then
        if r_Rd_Addr = 0 then
          r_Rd_Addr <= DEPTH-1;
        else
          r_Rd_Addr <= r_Rd_Addr - 1;
        end if;
      end if;

      -- TODO LORIS: simplify
      -- Keeps track of number of words in FIFO
      -- Read with no write
      if i_Rd_En = '1' and i_Wr_DV = '0' and i_Rd_Undo = '0' then
        if (r_Count /= 0) then
          r_Count <= r_Count - 1;
        end if;
      -- Write with no read
      elsif i_Wr_DV = '1' and i_Rd_En = '0' and i_Rd_Undo = '0' then
        if r_Count /= DEPTH then
          r_Count <= r_Count + 1;
        end if;
      -- Undo read
      elsif i_Rd_Undo = '1' and i_Wr_DV = '0' and i_Rd_En = '0' then
        if r_Count /= DEPTH then
          r_Count <= r_Count + 1;
        end if;
      end if;

    end if;
  end process;

  -- TODO LORIS: if r_Count=0 or r_Count=1 and i_Rd_En=1
  -- TODO LORIS: clean up parentheses
  o_Full <= '1' when ((r_Count=DEPTH) or (r_Count=DEPTH-1 and i_Wr_DV='1')) else '0';
  o_Empty <= '1' when (r_Count = 0) else '0';
  o_AF_Flag <= '1' when ((r_Count>=(DEPTH-i_AF_Level)) or (r_Count>=(DEPTH-1-i_AF_Level) and i_Wr_DV='1')) else '0';
  o_AE_Flag <= '1' when (r_Count <= i_AE_Level) else '0';

  ----------------------------------------------------------------------------
  -- ASSERTION CODE, NOT SYNTHESIZED
  -- synthesis translate_off
  -- Ensures that we never read from empty FIFO or write to full FIFO.
  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if (i_Rd_En = '1' and i_Wr_DV = '0' and r_Count = 0) then
        assert false report "Error! Reading Empty FIFO";
      end if;

      if (i_Wr_DV = '1' and i_Rd_En = '0' and r_Count = DEPTH) then
        assert false report "Error! Writing Full FIFO";
      end if;
    end if;
  end process;
  -- synthesis translate_on
  ----------------------------------------------------------------------------
  
end RTL;
