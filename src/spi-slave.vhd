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
    i_rst_n    : in  std_logic;    -- FPGA Reset, active low
    i_clk      : in  std_logic;    -- FPGA Clock
    o_rx_dv    : out std_logic;    -- Data Valid pulse (1 clock cycle)
    o_rx_byte  : out std_logic_vector(7 downto 0);  -- Byte received on MOSI
    i_tx_dv    : in  std_logic;    -- Data Valid pulse to register i_TX_Byte
    i_tx_byte  : in  std_logic_vector(7 downto 0);  -- Byte to serialize to MISO
    
    -- SPI Interface
    i_spi_clk  : in  std_logic;
    o_spi_miso : out std_logic;
    i_spi_mosi : in  std_logic;
    i_spi_cs_n : in  std_logic   -- active low
  );
end entity;

architecture RTL of SPISlave is

  -- RECEIVE SIGNALS
  signal r_rx_byte : std_logic_vector(7 downto 0);
  signal r1_rx_done : std_logic; -- spi-clock domain
  signal r2_rx_done : std_logic; -- fpga-clock domain
  signal r3_rx_done : std_logic; -- fpga-clock domain

  -- TRANSMIT SIGNALS
  signal r_tx_byte : std_logic_vector(7 downto 0);

begin

  --
  -- RECEIVING BLOCKS
  --

  -- Receive RX Byte in SPI-Clock Domain
  process(i_spi_cs_n, i_spi_clk)
    variable v_rx_bit_count : natural range 0 to 8;
  begin
    if i_spi_cs_n = '1' then
      v_rx_bit_count := 0;
      r_rx_byte <= (others => '0');
    elsif rising_edge(i_spi_clk) then
      r_rx_byte <= r_rx_byte(6 downto 0) & i_spi_mosi;
      v_rx_bit_count := v_rx_bit_count + 1;
    end if;

    if v_rx_bit_count = 8 then
      r1_rx_done <= '1';
      o_debug_a <= '1';
    else
      r1_rx_done <= '0';
      o_debug_a <= '0';
    end if;
  end process;

  -- Signal RX Done in FPGA-Clock Domain
  process(i_clk)
  begin
    if rising_edge(i_clk) then
      r2_rx_done <= r1_rx_done;
      r3_rx_done <= r2_rx_done;
      if r3_rx_done = '0' and r2_rx_done = '1' then
        o_rx_byte <= r_rx_byte;
        o_rx_dv <= '1';
        o_debug_b <= '1';
      else
        o_rx_dv <= '0';
        o_debug_b <= '0';
      end if;
    end if;
  end process;

  --
  -- TRANSMITTING BLOCKS
  --

  -- Register TX_Byte when TX_DV is set
  -- TODO LORIS: eventually handle reset signal
  process(i_clk)
  begin
    if falling_edge(i_clk) then
      if i_tx_dv = '1' then
        r_tx_byte <= i_tx_byte;
      end if;
    end if;
  end process;

  -- Send over TX_Byte on falling_edge of SPI Clock
  process(i_spi_cs_n, i_spi_clk)
    variable v_tx_bit_count : natural range 0 to 7;
  begin
    if i_spi_cs_n = '1' then
      v_tx_bit_count := 7;
    elsif falling_edge(i_spi_clk) then
      v_tx_bit_count := v_tx_bit_count - 1;
    end if;
  
    o_spi_miso <= r_tx_byte(v_tx_bit_count);
  end process;

  -- TODO LORIS: tristate MISO when not communicating

end architecture;
