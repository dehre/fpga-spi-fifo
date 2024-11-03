-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector,
-- displaying the count (0-99) on two 7-segment displays.
-- TODO LORIS: write Reset_L should be ONLY at the very beginning and very end.
-- TODO LORIS: MISO bit should be set on falling edge.

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
  signal w_RX_DV    : std_logic := '0';
  signal w_RX_Byte  : std_logic_vector(7 downto 0) := (others => '0');
  signal w_TX_DV    : std_logic := '0';
  signal w_TX_Byte  : std_logic_vector(7 downto 0) := (others => '0');

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
    generic map (SPI_MODE => 0)
    port map (
      o_debug_a => o_debug_a,
      o_debug_b => o_debug_b,
      o_debug_c => o_debug_c,

      i_Clk      => i_clk,
      i_Rst_L    => i_rst_n,
      i_SPI_Clk  => i_spi_clk,
      o_SPI_MISO => o_spi_miso,
      i_SPI_MOSI => i_spi_mosi,
      i_SPI_CS_n => i_spi_cs_n,
      o_RX_DV    => w_RX_DV,
      o_RX_Byte  => w_RX_Byte,
      i_TX_DV    => w_TX_DV,
      i_TX_Byte  => w_TX_Byte);

    
    process(i_clk)
    begin
      if rising_edge(i_clk) then
        if w_RX_DV = '1' then
          -- w_TX_Byte <= w_RX_Byte;
          w_TX_Byte <= "10101010";
          w_TX_DV   <= '1';
        else
          w_TX_DV   <= '0';
        end if;
      end if;
    end process;

end architecture;
