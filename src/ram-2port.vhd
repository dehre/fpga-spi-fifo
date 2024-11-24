-- Russell Merrick - http://www.nandland.com
--
-- Creates a Dual (2) Port RAM (Random Access Memory)
-- Single port RAM has one port, so can only access one memory location at a time.
-- Dual port RAM can read and write to different memory locations at the same time.
-- 
-- Generic: WIDTH sets the width of the Memory created.
-- Generic: DEPTH sets the depth of the Memory created.
-- Likely tools will infer Block RAM if WIDTH/DEPTH is large enough.
-- If small, tools will infer register-based memory.
-- 
-- Can be used in two different clock domains, or can tie i_wr_clk 
-- and i_rd_clk to same clock for operation in a single clock domain.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_2Port is
  generic (
    WIDTH : integer := 16;
    DEPTH : integer := 256
    );
  port (
    -- Write signals
    i_wr_clk  : in  std_logic;
    i_wr_addr : in  std_logic_vector; -- Gets sized at higher level
    i_wr_dv   : in  std_logic;
    i_wr_data : in  std_logic_vector(WIDTH-1 downto 0);
    -- Read signals
    i_rd_clk  : in  std_logic;
    i_rd_addr : in  std_logic_vector; -- Gets sized at higher level
    i_rd_en   : in  std_logic;
    o_rd_dv   : out std_logic;
    o_rd_data : out std_logic_vector(WIDTH-1 downto 0)
    );
end RAM_2Port;

architecture RTL of RAM_2Port is

  -- Create Memory that is DEPTH x WIDTH
  type t_Mem is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal r_mem : t_Mem;

begin

  -- Purpose: Control Writes to Memory.
  process (i_wr_clk)
  begin
    if rising_edge(i_wr_clk) then
      if i_wr_dv = '1' then
        r_mem(to_integer(unsigned(i_wr_addr))) <= i_wr_data;
      end if;
    end if;
  end process;

  -- Purpose: Control Reads From Memory.
  process (i_rd_clk)
  begin
    if rising_edge(i_rd_clk) then
      o_rd_data <= r_mem(to_integer(unsigned(i_rd_addr)));
      o_rd_dv   <= i_rd_en;
    end if;
  end process;

end RTL;
