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

  -- Constants for SPI commands
  constant CMD_STATUS : std_logic_vector(7 downto 0) := x"FA";
  constant CMD_READ   : std_logic_vector(7 downto 0) := x"FB";
  constant CMD_WRITE  : std_logic_vector(7 downto 0) := x"FC";

  constant EMPTY_BYTE : std_logic_vector(7 downto 0) := x"FE";
  constant FULL_BYTE  : std_logic_vector(7 downto 0) := x"FF";

  -- Signals for SPI Slave
  constant WORD_SIZE    : integer := 8;
  signal w_din_rdy      : std_logic;
  signal w_dout         : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_dout_vld     : std_logic;
  signal r_preload_miso : std_logic; -- Indicates first byte to be sent after command

  -- Signals for FIFO
  signal r_fifo_wr_en : std_logic;
  signal r_fifo_rd_en : std_logic;
  signal r_fifo_data_in : std_logic_vector(7 downto 0);
  signal w_fifo_rd_dv : std_logic;
  signal w_fifo_data_out : std_logic_vector(7 downto 0);
  signal w_fifo_empty : std_logic;
  signal w_fifo_full  : std_logic;

-- TODO LORIS: keep track of number of items in fifo
-- signal r_fifo_count : natural range 0 to 99;

  -- State Tracking
  signal r_command : std_logic_vector(7 downto 0);
  signal r_tx_data : std_logic_vector(7 downto 0); -- Data to send via SPI
  signal r_tx_valid : std_logic;

  -- Internal states for managing SPI commands
  type StateType is (IDLE, PROCESS_CMD, STATUS, WRITE, READ);
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
      i_din      => r_tx_data,      -- Data to send to SPI master
      i_din_vld  => r_tx_valid,     -- Valid signal for transmitted data
      o_din_rdy  => w_din_rdy,      -- Ready signal for new transmit data
      o_dout     => w_dout,         -- Data received from SPI master
      o_dout_vld => w_dout_vld      -- Valid signal for received data
    );

  -- Instantiate FIFO
  FIFOInstance : entity work.FIFO
    generic map (WIDTH => WORD_SIZE, DEPTH => 99)
    port map (
      i_rst_l    => not i_rst, -- FIFO reset is active low
      i_clk      => i_clk,
      i_wr_dv    => r_fifo_wr_en,
      i_wr_data  => r_fifo_data_in,
      i_af_level => 98,
      o_af_flag  => open,
      o_full     => w_fifo_full,
      i_rd_en    => r_fifo_rd_en,
      o_rd_dv    => w_fifo_rd_dv,
      o_rd_data  => w_fifo_data_out,
      i_ae_level => 1,
      o_ae_flag  => open,
      o_empty    => w_fifo_empty
    );

  -- Main process to control SPI commands
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        -- Reset state
        r_preload_miso <= '0';
        r_state <= IDLE;
        r_command <= (others => '0');
        r_tx_data <= (others => '0');
        r_tx_valid <= '0';
        r_fifo_data_in <= (others => '0');
        r_fifo_wr_en <= '0';
        r_fifo_rd_en <= '0';

      else
        case r_state is

          when IDLE =>
            if w_dout_vld = '1' then
              r_command <= w_dout;
              r_state <= PROCESS_CMD;
            end if;

          when PROCESS_CMD =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
            else
              case r_command is
                when CMD_STATUS =>
                  r_state <= STATUS;
                  r_preload_miso <= '1';
                when CMD_WRITE =>
                  r_state <= WRITE;
                when CMD_READ =>
                  r_state <= READ;
                when others =>
                  r_state <= IDLE; -- Unknown command, go back to IDLE
              end case;
            end if;

          when STATUS =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
              r_tx_valid <= '0';
            else
              if r_preload_miso = '1' then
                r_preload_miso <= '0';
                -- TODO LORIS: use real data
                r_tx_data <= std_logic_vector(to_unsigned(74, 8));
                r_tx_valid <= '1';
              elsif w_dout_valid = '1' then
                -- TODO LORIS: use real data
                -- TODO LORIS: remove duplicate, or just send zeroes thereafter?
                r_tx_data <= std_logic_vector(to_unsigned(74, 8));
                r_tx_valid <= '1';
              else
                r_tx_valid <= '0';
              end if;
            end if;

          when WRITE =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
              r_fifo_wr_en <= '0'; -- Disable write enable when exiting
            else
              if w_dout_vld = '1' then
                if w_fifo_full = '1' then
                  r_tx_data <= FULL_BYTE;
                  r_tx_valid <= '1';
                else
                  r_fifo_wr_en <= '1';
                  r_fifo_data_in <= w_dout;
                end if;
              else
                r_fifo_wr_en <= '0';
              end if;
            end if;

          when READ =>
            if i_spi_cs_n = '1' then
              r_state <= IDLE; -- Return to IDLE if transaction ends
              r_tx_valid <= '0'; -- Disable transmit valid when exiting
              r_fifo_rd_en <= '0'; -- Disable read enable when exiting
            else
              if w_din_rdy = '1' then
                if w_fifo_empty = '1' then
                  r_fifo_rd_en <= '0'; -- No read enable since FIFO is empty
                  r_tx_data <= EMPTY_BYTE;
                  r_tx_valid <= '1'; -- Signal SPI slave that data is valid to send
                else
                  if w_fifo_rd_dv = '1' then
                    r_fifo_rd_en <= '0'; -- Deassert read enable (read complete)
                    r_tx_data <= w_fifo_data_out; -- Transmit valid FIFO data
                    r_tx_valid <= '1'; -- Signal SPI slave that data is valid to send
                  else
                    r_fifo_rd_en <= '1'; -- Request next data from FIFO
                    r_tx_valid <= '0'; -- Signal SPI slave that data is not yet valid to send
                  end if;
                end if;
              else
                r_tx_valid <= '0'; -- No valid data for SPI slave
                r_fifo_rd_en <= '0'; -- Deassert read enable
              end if;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture;
