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

entity SPI_Slave is
  generic (
    SPI_MODE : integer := 0
  );
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
end SPI_Slave;

architecture Behavioral of SPI_Slave is

  -- SPI Interface signals - they aren't needed if using a single SPI mode
  -- TODO LORIS: add comment: reading on rising edge, writing on falling edge
  signal w_CPOL : std_logic;     -- Clock polarity
  signal w_CPHA : std_logic;     -- Clock phase
  signal w_SPI_Clk : std_logic;  -- Inverted/non-inverted depending on settings
  signal w_SPI_MISO_Mux : std_logic;

  -- Internal registers and signals
  signal r_RX_Bit_Count : unsigned(2 downto 0) := (others => '0');
  signal r_Temp_RX_Byte : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_Byte : std_logic_vector(7 downto 0) := (others => '0');

  -- TODO LORIS: this somehow adds some delay to setting RX_DV to 1,
  -- with the goal of setting o_RX_DV up for one clock cycle.
  -- Look at the paper you wrote, r3 isn't needed anymore.
  signal r_RX_Done, r2_RX_Done, r3_RX_Done : std_logic := '0';

begin

  -- CPOL: Clock Polarity
  -- CPOL=0 means clock idles at 0, leading edge is rising edge.
  -- CPOL=1 means clock idles at 1, leading edge is falling edge.
  w_CPOL <= '1' when SPI_MODE = 2 or SPI_MODE = 3 else '0';

  -- CPHA: Clock Phase
  -- CPHA=0 means the "out" side changes the data on trailing edge of clock
  --              the "in" side captures data on leading edge of clock
  -- CPHA=1 means the "out" side changes the data on leading edge of clock
  --              the "in" side captures data on the trailing edge of clock
  w_CPHA <= '1' when SPI_MODE = 1 or SPI_MODE = 3 else '0';

  -- SPI Clock depending on CPHA
  w_SPI_Clk <= not i_SPI_Clk when w_CPHA = '1' else i_SPI_Clk;

  --
  -- RECEIVING BLOCKS
  --

  -- Get SPI Byte in SPI Clock Domain
  process (w_SPI_Clk, i_SPI_CS_n)
  begin
    if i_SPI_CS_n = '1' then
      r_RX_Bit_Count <= (others => '0');
      r_RX_Done <= '0';
    elsif rising_edge(w_SPI_Clk) then
      r_RX_Bit_Count <= r_RX_Bit_Count + 1; -- Rolls back to '000' eventually
      r_Temp_RX_Byte <= r_Temp_RX_Byte(6 downto 0) & i_SPI_MOSI;

      if r_RX_Bit_Count = "111" then
        r_RX_Done <= '1';
        r_RX_Byte <= r_Temp_RX_Byte(6 downto 0) & i_SPI_MOSI;

      -- TODO LORIS: just else?
      -- it seems r_RX_Done is kept high for a few cycles just to make sure we
      -- can catch it in the FPGA-clock domain and correctly pulse o_RX_DV when done.
      -- TODO LORIS: with the alternative you wrote on the paper, you reset
      -- r_RX_Done in the other block, not here (but write a comment here above when
      -- you set it to 1).
      elsif r_RX_Bit_Count = "010" then
        r_RX_Done <= '0';
      end if;
    end if;
  end process;

  -- Cross from SPI Clock Domain to FPGA clock domain.
  -- Goal: pulse o_RX_DV when done receiving.
  -- The additional r2_RX_Done and r3_RX_Done add a two *FPGA-clock* delay
  -- to setting o_RX_DV to 1: when r2 goes high, RX_DV goes high, when r3 goes
  -- high, RX_DV goes low again.
  -- TODO LORIS: check better, probably two registers are for crossing
  -- clock-domains, not for rising and falling edge.
  process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      r2_RX_Done <= '0';
      r3_RX_Done <= '0';
      o_RX_DV <= '0';
      o_RX_Byte <= (others => '0');
    elsif rising_edge(i_Clk) then
      r2_RX_Done <= r_RX_Done;
      r3_RX_Done <= r2_RX_Done;

      if r3_RX_Done = '0' and r2_RX_Done = '1' then
        o_RX_DV <= '1';  -- Pulse Data Valid 1 clock cycle
        o_RX_Byte <= r_RX_Byte;
      else
        o_RX_DV <= '0';
      end if;
    end if;
  end process;

  --
  -- TRANSMITTING BLOCKS
  --

end Behavioral;
