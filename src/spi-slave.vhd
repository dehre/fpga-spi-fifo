-------------------------------------------------------------------------------
-- Description: SPI (Serial Peripheral Interface) Slave
--              Creates slave based on input configuration.
--              Receives a byte one bit at a time on MOSI
--              Will also push out byte data one bit at a time on MISO.  
--              Any data on input byte will be shipped out on MISO.
--              Supports multiple bytes per transaction when CS_n is kept 
--              low during the transaction.
--
-- Note:        i_Clk must be at least 4x faster than i_SPI_Clk
--              MISO is tri-stated when not communicating.  Allows for multiple
--              SPI Slaves on the same interface.
--
-- Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
--              Can be configured in one of 4 modes:
--              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
--               0   |             0             |        0
--               1   |             0             |        1
--               2   |             1             |        0
--               3   |             1             |        1
--              More info: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPISlave is
  port (
    -- Debugging
    o_debug_a : out std_logic;
    o_debug_b : out std_logic;
    o_debug_c : out std_logic;

    -- Control/Data Signals, so that other VHDL modules can use it
    i_Rst_L    : in  std_logic;    -- FPGA Reset, active low
    i_Clk      : in  std_logic;    -- FPGA Clock
    o_RX_DV    : out std_logic;    -- Data Valid pulse (1 clock cycle)
    o_RX_Byte  : out std_logic_vector(7 downto 0);  -- Byte received on MOSI
    i_TX_DV    : in  std_logic;    -- Data Valid pulse to register i_TX_Byte
    i_TX_Byte  : in  std_logic_vector(7 downto 0);  -- Byte to serialize to MISO
    
    -- SPI Interface
    i_SPI_Clk  : in  std_logic;
    o_SPI_MISO : out std_logic;
    i_SPI_MOSI : in  std_logic;
    i_SPI_CS_n : in  std_logic   -- active low
  );
end entity;

architecture RTL of SPISlave is

  -- RECEIVE SIGNALS
  signal r_RX_Byte : std_logic_vector(7 downto 0);
  signal r_RX_Done : std_logic;

  -- TRANSMIT SIGNALS
  signal r_TX_Byte : std_logic_vector(7 downto 0);

begin

  --
  -- RECEIVING BLOCKS
  --

  process(i_SPI_CS_n, i_SPI_Clk)
    variable v_RX_Bit_Count : integer := -1;
  begin

    if i_SPI_CS_n = '1' then
      v_RX_Bit_Count := -1;
    elsif rising_edge(i_SPI_Clk) then
      v_RX_Bit_Count := v_RX_Bit_Count + 1;
    end if;

    if v_RX_Bit_Count = 7 then
      r_RX_Done <= '1';
    elsif v_RX_Bit_Count = 2 then -- TODO LORIS: needed? otherwise just reset
      r_RX_Done <= '0';
    end if;

    r_RX_Byte(v_RX_Bit_Count) <= i_SPI_MOSI;

  end process;

  --
  -- TRANSMITTING BLOCKS
  --

  -- Register TX_Byte when TX_DV is set
  -- TODO LORIS: eventually handle reset signal
  process(i_Clk)
  begin
    if falling_edge(i_Clk) then
      if i_TX_DV = '1' then
        r_TX_Byte <= i_TX_Byte;
      end if;
    end if;
  end process;

  -- Send over TX_Byte on falling_edge of SPI Clock
  process(i_SPI_CS_n, i_SPI_Clk)
    variable v_TX_Bit_Count : integer := 7;
  begin
    if i_SPI_CS_n = '1' then
      v_TX_Bit_Count := 7;
    elsif falling_edge(i_SPI_Clk) then
      v_TX_Bit_Count := v_TX_Bit_Count - 1;
    end if;
  
    o_SPI_MISO <= r_TX_Byte(v_TX_Bit_Count);
  end process;

  -- TODO LORIS: tristate MISO when not communicating

end architecture;
