library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPIFIFO is
  port (
    -- Debugging Outputs
    o_debug_a  : out std_logic;
    o_debug_b  : out std_logic;
    o_debug_c  : out std_logic;

    -- Control/Data Signals
    i_rst      : in  std_logic;     -- FPGA Reset
    i_clk_dbl  : in  std_logic;     -- FPGA Clock

    -- SPI Interface
    i_spi_clk  : in  std_logic;     -- SPI Clock
    o_spi_miso : out std_logic;     -- Master In, Slave Out
    i_spi_mosi : in  std_logic;     -- Master Out, Slave In
    i_spi_cs_n : in  std_logic);    -- Chip Select, active low
end entity;

architecture RTL of SPIFIFO is

  constant WORD_SIZE   : integer := 8;

  -- Constants for SPI commands - Inputs
  constant CMD_STATUS : std_logic_vector(7 downto 0) := x"FA";

  -- Constants for SPI commands - Outputs
  constant ACK         : std_logic_vector(7 downto 0) := x"AA";
  constant NACK        : std_logic_vector(7 downto 0) := x"BB";

  -- Halve the clock for debugging
  signal i_clk : std_logic;

  -- Signals for SPI Slave
  signal r_spi_din      : std_logic_vector(7 downto 0); -- Data to send via SPI
  signal r_spi_din_vld  : std_logic;
  signal w_spi_din_rdy  : std_logic;
  signal w_spi_dout     : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_spi_dout_vld : std_logic;

begin

  process(i_clk_dbl)
  begin
    if rising_edge(i_clk_dbl) then
      i_clk <= not i_clk;
    end if;
  end process;

  -- Instantiate SPI Slave
  SPISlaveInstance : entity work.SPI_SLAVE
    generic map (WORD_SIZE => WORD_SIZE)
    port map (
      CLK      => i_clk,
      RST      => i_rst,
      SCLK  => i_spi_clk,
      CS_N => i_spi_cs_n,
      MOSI => i_spi_mosi,
      MISO => o_spi_miso,
      DIN      => r_spi_din,          -- Data to send to SPI master
      DIN_VLD  => r_spi_din_vld,      -- Valid signal for transmitted data
      DIN_RDY  => w_spi_din_rdy,      -- Ready signal for new transmit data
      DOUT     => w_spi_dout,         -- Data received from SPI master
      DOUT_VLD => w_spi_dout_vld      -- Valid signal for received data
    );

  -- Main process to control SPI commands
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        -- Reset state
        r_spi_din <= (others => '0');
        r_spi_din_vld <= '0';
        o_debug_c <= '0';

      else

        if w_spi_dout_vld = '1' then
          case w_spi_dout is
            when CMD_STATUS =>
              o_debug_c <= '1';
              r_spi_din <= ACK;
              r_spi_din_vld <= '1';
            when others =>
              o_debug_c <= '1';
              r_spi_din <= NACK;
              r_spi_din_vld <= '1';
          end case;
        elsif w_spi_din_rdy = '1' then
          r_spi_din_vld <= '0';
          o_debug_c <= '0';
        else
          r_spi_din_vld <= r_spi_din_vld;
        end if;

      end if; -- if i_rst = '1'
    end if; -- if rising_edge(i_clk)
  end process;

  o_debug_a <= w_spi_din_rdy;
  o_debug_b <= w_spi_dout_vld;

end architecture;
