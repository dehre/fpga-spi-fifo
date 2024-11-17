-- PROJECT TOP.
-- This module receives data (bytes) from an SPI master and echoes it back
-- on the subsequent SPI transaction, functioning as an SPI loopback device.
-- 
-- It's recommended to reset the FPGA before starting the communication to
-- properly initialize its internal registers and ensure synchronization.
-- To reset the FPGA, assert both `i_spi_cs_n` and `i_rst` , then pulse `i_spi_clk`.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPIRepeater is
  -- Inputs/Outputs for the top module.
  port (
    -- Control/Data Signals
    i_rst      : in  std_logic;     -- FPGA Reset
    i_clk      : in  std_logic;     -- FPGA Clock

    -- SPI Interface
    i_spi_clk  : in  std_logic;     -- SPI Clock
    o_spi_miso : out std_logic;     -- Master In, Slave Out
    i_spi_mosi : in  std_logic;     -- Master Out, Slave In
    i_spi_cs_n : in  std_logic);    -- Chip Select, active low
end entity;

architecture RTL of SPIRepeater is

  constant WORD_SIZE : integer := 8; -- SPI word size, 8 bits
  signal r_din       : std_logic_vector(WORD_SIZE-1 downto 0); -- Data to send to master
  signal r_din_vld   : std_logic;    -- Data valid signal for SPI slave
  signal w_din_rdy   : std_logic;    -- Ready signal from SPI slave
  signal w_dout      : std_logic_vector(WORD_SIZE-1 downto 0); -- Data received from master
  signal w_dout_vld  : std_logic;    -- Data valid signal from SPISlave

begin

  -- Module handling the SPI interface.
  SPISlaveInstance : entity work.SPISlave
    generic map (WORD_SIZE => WORD_SIZE)
    port map (
      i_clk      => i_clk,
      i_rst      => i_rst,
      i_spi_clk  => i_spi_clk,
      i_spi_cs_n => i_spi_cs_n,
      i_spi_mosi => i_spi_mosi,
      o_spi_miso => o_spi_miso,
      i_din      => r_din,
      i_din_vld  => r_din_vld,
      o_din_rdy  => w_din_rdy,
      o_dout     => w_dout,
      o_dout_vld => w_dout_vld);

    process(i_clk)
    begin
      if rising_edge(i_clk) then
        if i_rst = '1' then
          r_din     <= (others => '0');
          r_din_vld <= '0';
        else
          -- Load received data into the transmit buffer for the next transaction.
          if w_dout_vld = '1' then
            r_din <= w_dout;
            r_din_vld <= '1';
          elsif w_din_rdy = '1' then
            -- Clear r_din_vld once SPISlave is ready to accept new data.
            r_din_vld <= '0';
          end if;
        end if;
      end if;
    end process;

end architecture;
