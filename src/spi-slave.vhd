-- Adapted from:
-- https://github.com/jakubcabal/spi-fpga/tree/d8240ff3f59fdeeadd87692333aeafb69b0b88a1
-- 
-- THE SPI SLAVE MODULE SUPPORT ONLY SPI MODE 0 (CPOL=0, CPHA=0).
--
-- Changes:
-- * set o_spi_miso to high impedance state when inactive;
-- * make i_rst asynchronous;
-- * delay o_din_rdy and w_load_data_en to give the FSM time to process the request.
--
-- Updated Usage:
-- ```
-- if o_dout_vld = '1' then
--   -- new data available on o_dout
--   r_buffer <= o_dout;
-- elsif o_din_rdy = '1' then
--   -- ready to set response on i_din
--   i_din <= x"55";
--   i_din_vld <= '1';
-- else
--   -- default state
--   i_din_vld <= '0';
-- end if;
-- ```

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity SPISlave is
  generic (WORD_SIZE : natural := 8); -- size of transfer word in bits, must be power of two
  port (
    i_rst      : in  std_logic;  -- high active asynchronous reset
    i_clk      : in  std_logic;  -- system clock

    -- SPI Slave Interface
    i_spi_clk  : in  std_logic;  -- SPI clock
    i_spi_cs_n : in  std_logic;  -- SPI chip select, active in low
    i_spi_mosi : in  std_logic;  -- SPI serial data from master to slave
    o_spi_miso : out std_logic;  -- SPI serial data from slave to master

    -- User Interface
    i_din      : in  std_logic_vector(WORD_SIZE-1 downto 0); -- data for transmission to SPI master
    i_din_vld  : in  std_logic;  -- when i_din_vld = 1, data for transmission are valid
    o_din_rdy  : out std_logic;  -- when o_din_rdy = 1, SPI slave is ready to accept valid data for transmission
    o_dout     : out std_logic_vector(WORD_SIZE-1 downto 0); -- received data from SPI master
    o_dout_vld : out std_logic); -- when o_dout_vld = 1, received data are valid
end entity;

architecture RTL of SPISlave is

  constant BIT_CNT_WIDTH : natural := natural(ceil(log2(real(WORD_SIZE))));

  signal r_spi_clk_meta     : std_logic;
  signal r_spi_cs_n_meta    : std_logic;
  signal r_spi_mosi_meta    : std_logic;
  signal r1_spi_clk         : std_logic;
  signal r_spi_cs_n         : std_logic;
  signal r_spi_mosi         : std_logic;
  signal r2_spi_clk         : std_logic;
  signal w_spi_clk_redge_en : std_logic;
  signal w_spi_clk_fedge_en : std_logic;
  signal r_bit_cnt          : unsigned(BIT_CNT_WIDTH-1 downto 0);
  signal w_bit_cnt_max      : std_logic;
  signal r_last_bit_en      : std_logic;
  signal w_load_data_en     : std_logic;
  signal r_data_shreg       : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_slave_ready      : std_logic;
  signal r1_slave_ready     : std_logic;
  signal r2_slave_ready     : std_logic;
  signal r_shreg_busy       : std_logic;
  signal w_rx_data_vld      : std_logic;
  signal r_spi_miso         : std_logic;

begin

  -- -------------------------------------------------------------------------
  --  INPUT SYNCHRONIZATION REGISTERS
  -- -------------------------------------------------------------------------

  -- Synchronization registers to eliminate possible metastability.
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      r_spi_clk_meta <= i_spi_clk;
      r_spi_cs_n_meta <= i_spi_cs_n;
      r_spi_mosi_meta <= i_spi_mosi;
      r1_spi_clk  <= r_spi_clk_meta;
      r_spi_cs_n  <= r_spi_cs_n_meta;
      r_spi_mosi  <= r_spi_mosi_meta;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  --  SPI CLOCK REGISTER
  -- -------------------------------------------------------------------------

  -- The SPI clock register is necessary for clock edge detection.
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      r2_spi_clk <= '0';
    elsif rising_edge(i_clk) then
      r2_spi_clk <= r1_spi_clk;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  --  SPI CLOCK EDGES FLAGS
  -- -------------------------------------------------------------------------

  -- Falling edge is detect when r1_spi_clk=0 and r2_spi_clk=1.
  w_spi_clk_fedge_en <= not r1_spi_clk and r2_spi_clk;
  -- Rising edge is detect when r1_spi_clk=1 and r2_spi_clk=0.
  w_spi_clk_redge_en <= r1_spi_clk and not r2_spi_clk;

  -- -------------------------------------------------------------------------
  --  RECEIVED BITS COUNTER
  -- -------------------------------------------------------------------------

  -- The counter counts received bits from the master. Counter is enabled when
  -- falling edge of SPI clock is detected and not asserted r_spi_cs_n.
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_bit_cnt <= (others => '0');
    elsif rising_edge(i_clk) then
      if w_spi_clk_fedge_en = '1' and r_spi_cs_n = '0' then
        if w_bit_cnt_max = '1' then
          r_bit_cnt <= (others => '0');
        else
          r_bit_cnt <= r_bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- The flag of maximal value of the bit counter.
  w_bit_cnt_max <= '1' when (r_bit_cnt = WORD_SIZE-1) else '0';

  -- -------------------------------------------------------------------------
  --  LAST BIT FLAG REGISTER
  -- -------------------------------------------------------------------------

  -- The flag of last bit of received byte is only registered the flag of
  -- maximal value of the bit counter.
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_last_bit_en <= '0';
    elsif rising_edge(i_clk) then
      r_last_bit_en <= w_bit_cnt_max;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  --  RECEIVED DATA VALID FLAG
  -- -------------------------------------------------------------------------

  -- Received data from master are valid when falling edge of SPI clock is
  -- detected and the last bit of received byte is detected.
  w_rx_data_vld <= w_spi_clk_fedge_en and r_last_bit_en;

  -- -------------------------------------------------------------------------
  --  SHIFT REGISTER BUSY FLAG REGISTER
  -- -------------------------------------------------------------------------

  -- Data shift register is busy until it sends all input data to SPI master.
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_shreg_busy <= '0';
    elsif rising_edge(i_clk) then
      if i_din_vld = '1' and (r_spi_cs_n = '1' or w_rx_data_vld = '1') then
        r_shreg_busy <= '1';
      elsif w_rx_data_vld = '1' then
        r_shreg_busy <= '0';
      else
        r_shreg_busy <= r_shreg_busy;
      end if;
    end if;
  end process;

  -- The SPI slave is ready for accept new input data when r_spi_cs_n is assert and
  -- shift register not busy or when received data are valid.
  w_slave_ready <= (r_spi_cs_n and not r_shreg_busy) or w_rx_data_vld;

  -- Stretch `w_slave_ready` to another two clock cycles.
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      r1_slave_ready <= w_slave_ready;
      r2_slave_ready <= r1_slave_ready;
    end if;
  end process;

  -- The new input data is loaded into the shift register when the SPI slave
  -- is ready and input data are valid.
  w_load_data_en <= r2_slave_ready and i_din_vld;

  -- -------------------------------------------------------------------------
  --  DATA SHIFT REGISTER
  -- -------------------------------------------------------------------------

  -- The shift register holds data for sending to master, capture and store
  -- incoming data from master.
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if w_load_data_en = '1' then
        r_data_shreg <= i_din;
      elsif w_spi_clk_redge_en = '1' and r_spi_cs_n = '0' then
        r_data_shreg <= r_data_shreg(WORD_SIZE-2 downto 0) & r_spi_mosi;
      end if;
    end if;
  end process;

  -- -------------------------------------------------------------------------
  --  MISO REGISTER
  -- -------------------------------------------------------------------------

  -- The output MISO register ensures that the bits are transmit to the master
  -- when is not assert r_spi_cs_n and falling edge of SPI clock is detected.
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if w_load_data_en = '1' then
        r_spi_miso <= i_din(WORD_SIZE-1);
      elsif w_spi_clk_fedge_en = '1' and r_spi_cs_n = '0' then
        r_spi_miso <= r_data_shreg(WORD_SIZE-1);
      end if;
    end if;
  end process;

  -- Tri-state MISO when r_spi_cs_n is high
  o_spi_miso <= 'Z' when r_spi_cs_n = '1' else r_spi_miso;

  -- -------------------------------------------------------------------------
  --  ASSIGNING OUTPUT SIGNALS
  -- -------------------------------------------------------------------------

  o_din_rdy  <= r1_slave_ready;
  o_dout     <= r_data_shreg;
  o_dout_vld <= w_rx_data_vld;

end architecture;
