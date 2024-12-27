library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
  generic (
    WIDTH : integer := 8;
    DEPTH : integer := 256);
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
    o_rd_data : out std_logic_vector(WIDTH-1 downto 0)
    );
end RAM;

architecture RTL of RAM is

  -- Create memory that is DEPTH x WIDTH.
  -- Block RAM will be likely inferred by the synthesizer.
  -- TODO LORIS: do I need a separate type?
  type MemoryType is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal r_memory : MemoryType;

begin

  process (i_wr_clk)
  begin
    if rising_edge(i_wr_clk) then
      if i_wr_dv = '1' then
        r_memory(to_integer(unsigned(i_wr_addr))) <= i_wr_data;
      end if;
    end if;
  end process;

  process (i_rd_clk)
  begin
    if rising_edge(i_rd_clk) then
      -- TODO LORIS: try adding if i_Rd_En = '1' then
      o_rd_data <= r_memory(to_integer(unsigned(i_rd_addr)));
    end if;
  end process;

end architecture;
