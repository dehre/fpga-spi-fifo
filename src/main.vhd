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
    -- DEBUGGING OUTPUTS
    io_pmod_7    : out  std_logic; 
    io_pmod_8    : out  std_logic;
    io_pmod_9    : out  std_logic;

    -- Control/Data Signals

    -- i_Rst_L    : in  std_logic;    -- FPGA Reset, active low
    io_pmod_10    : in  std_logic;  -- FPGA Reset, active low

    i_clk      : in  std_logic;    -- FPGA Clock

    -- SPI Interface

    -- i_SPI_Clk  : in  std_logic;
    io_pmod_1  : in  std_logic; -- SPI Clock

    -- o_SPI_MISO : out std_logic     -- Master In, Slave Out
    io_pmod_2 : out std_logic;     -- Master In, Slave Out

    -- i_SPI_MOSI : in  std_logic;    -- Master Out, Slave In
    io_pmod_3 : in  std_logic;    -- Master Out, Slave In

    -- i_SPI_CS_n : in  std_logic;    -- Chip Select, active low
    io_pmod_4 : in  std_logic);    -- Slave Select, active low
end entity;

architecture RTL of SpiFollower is

  -- Wires for renaming pmod pins
  -- TODO LORIS: maybe rename pin-constraints directly
  signal wi_Rst_L: std_logic;
  signal wi_SPI_Clk: std_logic;
  signal wo_SPI_MISO: std_logic;
  signal wi_SPI_MOSI: std_logic;
  signal wi_SPI_CS_n: std_logic;

  -- Internal signals
  signal w_RX_DV    : std_logic := '0';
  signal w_RX_Byte  : std_logic_vector(7 downto 0) := (others => '0');
  signal w_TX_DV    : std_logic := '0';
  signal w_TX_Byte  : std_logic_vector(7 downto 0) := (others => '0');

  -- Debugging
  signal r_clk_half : std_logic;

begin

  -- Renaming inputs/outputs for clarity
  wi_Rst_L    <= io_pmod_10;
  wi_SPI_Clk  <= io_pmod_1;
  io_pmod_2 <= wo_SPI_MISO;
  wi_SPI_MOSI <= io_pmod_3;
  wi_SPI_CS_n <= io_pmod_4;

  process (i_clk, r_clk_half)
  begin
    if rising_edge(i_clk) then
      r_clk_half <= not r_clk_half;
    end if;
  end process;

  -- Instantiate the SPI_Slave component
  SpiSlaveInstance: entity work.SPI_Slave
    generic map (SPI_MODE => 0)
    port map (
      o_debug_a => io_pmod_7,
      o_debug_b => io_pmod_8,
      o_debug_c => io_pmod_9,

      i_Clk      => i_clk,
      i_Rst_L    => wi_Rst_L,
      i_SPI_Clk  => wi_SPI_Clk,
      o_SPI_MISO => wo_SPI_MISO,
      i_SPI_MOSI => wi_SPI_MOSI,
      i_SPI_CS_n => wi_SPI_CS_n,
      o_RX_DV    => w_RX_DV,
      o_RX_Byte  => w_RX_Byte,
      i_TX_DV    => w_TX_DV,
      i_TX_Byte  => w_TX_Byte);

    
    process(i_clk)
    begin
      if rising_edge(i_clk) then
        if w_RX_DV = '1' then
          w_TX_Byte <= w_RX_Byte;
          w_TX_DV   <= '1';
        else
          w_TX_DV   <= '0';
        end if;
      end if;
    end process;

end architecture;
