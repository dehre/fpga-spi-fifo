library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SpiFollower is
  port (
    -- Debugging Outputs
    o_debug_a    : out  std_logic; 
    o_debug_b    : out  std_logic;
    o_debug_c    : out  std_logic;

    -- Control/Data Signals
    i_rst_n    : in  std_logic;    -- FPGA Reset, active low
    i_clk      : in  std_logic;    -- FPGA Clock

    -- SPI Interface
    i_spi_clk  : in  std_logic;
    o_spi_miso : out std_logic;     -- Master In, Slave Out
    i_spi_mosi : in  std_logic;     -- Master Out, Slave In
    i_spi_cs_n : in  std_logic);    -- Chip Select, active low
end entity;

architecture RTL of SpiFollower is

  -- Internal signals
  signal w_rx_dv    : std_logic := '0';
  signal w_rx_byte  : std_logic_vector(7 downto 0) := (others => '0');
  signal w_tx_dv    : std_logic := '0';
  signal w_tx_byte  : std_logic_vector(7 downto 0) := (others => '0');

  -- Debugging
  signal r_clk_half : std_logic;

begin

  -- Debugging
  process (i_clk, r_clk_half)
  begin
    if rising_edge(i_clk) then
      r_clk_half <= not r_clk_half;
    end if;
  end process;

  -- Instantiate the SPISlave component
  SpiSlaveInstance: entity work.SPISlave
    port map (
      o_debug_a => o_debug_a,
      o_debug_b => o_debug_b,
      o_debug_c => o_debug_c,

      i_clk      => i_clk,
      i_rst_n    => i_rst_n,
      i_spi_clk  => i_spi_clk,
      o_spi_miso => o_spi_miso,
      i_spi_mosi => i_spi_mosi,
      i_spi_cs_n => i_spi_cs_n,
      o_rx_dv    => w_rx_dv,
      o_rx_byte  => w_rx_byte,
      i_tx_dv    => w_tx_dv,
      i_tx_byte  => w_tx_byte);

    process(i_clk)
    begin
      if rising_edge(i_clk) then
        if w_rx_dv = '1' then
          -- w_tx_byte <= w_rx_byte;
          w_tx_byte <= "10101010";
          w_tx_dv   <= '1';
        else
          w_tx_dv   <= '0';
        end if;
      end if;
    end process;

end architecture;
