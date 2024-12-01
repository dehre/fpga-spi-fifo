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

entity SPIFIFO is
  -- Inputs/Outputs for the top module.
  port (
    -- Debugging Outputs
    o_debug_a  : out std_logic;
    o_debug_b  : out std_logic;
    o_debug_c  : out std_logic;

    -- Control/Data Signals
    i_rst      : in  std_logic;     -- FPGA Reset
    i_clk      : in  std_logic;     -- FPGA Clock

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
  constant CMD_READ   : std_logic_vector(7 downto 0) := x"FB";
  constant CMD_WRITE  : std_logic_vector(7 downto 0) := x"FC";

  -- Constants for SPI commands - Outputs
  constant ACK         : std_logic_vector(7 downto 0) := x"AA";
  constant NACK        : std_logic_vector(7 downto 0) := x"BB";
  constant FIFO_EMPTY  : std_logic_vector(7 downto 0) := x"FE";
  constant FIFO_FULL   : std_logic_vector(7 downto 0) := x"FF";

  -- Signals for SPI Slave
  signal r_spi_din      : std_logic_vector(7 downto 0); -- Data to send via SPI
  signal r_spi_din_vld  : std_logic;
  signal w_spi_din_rdy  : std_logic;
  signal w_spi_dout     : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_spi_dout_vld : std_logic;

  -- Signals for FIFO
  signal r_fifo_wr_en   : std_logic;
  signal r_fifo_rd_en   : std_logic;
  signal r_fifo_wr_data : std_logic_vector(7 downto 0);
  signal w_fifo_rd_data : std_logic_vector(7 downto 0);
  signal w_fifo_full    : std_logic;
  signal w_fifo_empty   : std_logic;

-- TODO LORIS: keep track of number of items in fifo,
-- or maybe just expose the count register in the FIFO.
-- signal r_fifo_count : natural range 0 to 99;

  -- Internal states for managing SPI commands
  type StateType is (IDLE, STATUS, WRITE, READ);
  signal r_state : StateType;

begin

  -- Avoid picking up noise
  o_debug_a <= '0';
  o_debug_b <= '0';
  o_debug_c <= '0';

  -- Instantiate SPI Slave
  SPISlaveInstance : entity work.SPISlave
    generic map (WORD_SIZE => WORD_SIZE)
    port map (
      i_clk      => i_clk,
      i_rst      => i_rst,
      i_spi_clk  => i_spi_clk,
      i_spi_cs_n => i_spi_cs_n,
      i_spi_mosi => i_spi_mosi,
      o_spi_miso => o_spi_miso,
      i_din      => r_spi_din,          -- Data to send to SPI master
      i_din_vld  => r_spi_din_vld,      -- Valid signal for transmitted data
      o_din_rdy  => w_spi_din_rdy,      -- Ready signal for new transmit data
      o_dout     => w_spi_dout,         -- Data received from SPI master
      o_dout_vld => w_spi_dout_vld      -- Valid signal for received data
    );

  FIFOInstance : entity work.module_fifo_regs_no_flags
    generic map(g_WIDTH => WORD_SIZE, g_DEPTH => 100)
    port map (
      i_rst_sync => i_rst,
      i_clk      => i_clk,
      i_wr_data  => r_fifo_wr_data,
      i_wr_en    => r_fifo_wr_en,
      o_rd_data  => w_fifo_rd_data,
      i_rd_en    => r_fifo_rd_en,
      o_full     => w_fifo_full,
      o_empty    => w_fifo_empty);

  -- Main process to control SPI commands
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        -- Reset state
        r_state <= IDLE;
        r_spi_din <= (others => '0');
        r_spi_din_vld <= '0';
        r_fifo_wr_data <= (others => '0');
        r_fifo_wr_en <= '0';
        r_fifo_rd_en <= '0';

      else
        case r_state is

          when IDLE =>
            if w_spi_din_rdy = '1' then
              case w_spi_dout is
                when CMD_STATUS =>
                  r_state <= STATUS;
                  -- TODO LORIS: abstract to function
                  r_spi_din_vld <= '1';
                  if w_fifo_full = '1' then
                    r_spi_din <= FIFO_FULL;
                  elsif w_fifo_empty = '1' then
                    r_spi_din <= FIFO_EMPTY;
                  else
                    r_spi_din <= ACK;
                  end if;
                when CMD_WRITE =>
                  r_state <= WRITE;
                  -- TODO LORIS: abstract to function
                  r_spi_din_vld <= '1';
                  if w_fifo_full = '1' then
                    r_spi_din <= FIFO_FULL;
                  elsif w_fifo_empty = '1' then
                    r_spi_din <= FIFO_EMPTY;
                  else
                    r_spi_din <= ACK;
                  end if;
                when CMD_READ =>
                  r_state <= READ;
                  r_fifo_rd_en <= '1'; -- Prefetch next data
                  -- TODO LORIS: abstract to function
                  r_spi_din_vld <= '1';
                  if w_fifo_full = '1' then
                    r_spi_din <= FIFO_FULL;
                  elsif w_fifo_empty = '1' then
                    r_spi_din <= FIFO_EMPTY;
                  else
                    r_spi_din <= ACK;
                  end if;
                when others =>
                  r_state <= IDLE; -- Unknown command, remain to IDLE
                  r_spi_din <= NACK;
                  r_spi_din_vld <= '1';
              end case;
            else
              r_spi_din_vld <= '0';
            end if;

          when STATUS =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
            else
              if w_spi_din_rdy = '1' then
                -- TODO LORIS: use real data
                r_spi_din <= std_logic_vector(to_unsigned(74, 8));
                r_spi_din_vld <= '1';
              else
                r_spi_din_vld <= '0';
              end if;
            end if;

          when WRITE =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
            else
              if w_spi_din_rdy = '1' then
                -- TODO LORIS: almost-full or full instead
                if w_fifo_full = '1' then
                  r_spi_din <= FIFO_FULL;
                  r_spi_din_vld <= '1';
                else
                  r_spi_din <= ACK;
                  r_spi_din_vld <= '1';
                  r_fifo_wr_data <= w_spi_dout;
                  r_fifo_wr_en <= '1';
                end if;
              else
                r_spi_din_vld <= '0';
                r_fifo_wr_en <= '0';
              end if;
            end if;

          -- TODO LORIS: considering that we prefetch the READ data, one byte
          -- is always lost if the master terminates the communication before
          -- before all bytes are read.
          when READ =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
            else
              if w_spi_din_rdy = '1' then
                if w_fifo_empty = '1' then
                  r_spi_din <= FIFO_EMPTY;
                  r_spi_din_vld <= '1';
                else
                  r_spi_din <= w_fifo_rd_data;
                  r_spi_din_vld <= '1';
                  r_fifo_rd_en <= '1'; -- Prefetch next data
                end if;
              else
                r_fifo_rd_en <= '0'; -- Deassert read enable (read complete)
                r_spi_din_vld <= '0';
              end if;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture;
