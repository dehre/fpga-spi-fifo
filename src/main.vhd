-- PROJECT TOP.
-- This module receives data (bytes) from an SPI master and echoes it back
-- on the subsequent SPI transaction, functioning as an SPI loopback device.
-- 
-- It's recommended to reset the FPGA before starting the communication to
-- properly initialize its internal registers and ensure synchronization.
-- To reset the FPGA, assert `i_rst`, then pulse `i_spi_clk`.

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
  constant FIFO_DEPTH  : integer := 5;

  -- Constants for incoming commands
  constant CMD_COUNT : std_logic_vector(WORD_SIZE-1 downto 0) := x"F0";
  constant CMD_WRITE : std_logic_vector(WORD_SIZE-1 downto 0) := x"F1";
  constant CMD_READ  : std_logic_vector(WORD_SIZE-1 downto 0) := x"F2";

  -- Constants for outcoming replies
  constant ACK        : std_logic_vector(WORD_SIZE-1 downto 0) := x"FA";
  constant NACK       : std_logic_vector(WORD_SIZE-1 downto 0) := x"FB";
  constant FIFO_EMPTY : std_logic_vector(WORD_SIZE-1 downto 0) := x"FE";
  constant FIFO_FULL  : std_logic_vector(WORD_SIZE-1 downto 0) := x"FF";

  -- Signals for SPISlave
  signal r_spi_din      : std_logic_vector(WORD_SIZE-1 downto 0);
  signal r_spi_din_vld  : std_logic;
  signal w_spi_din_rdy  : std_logic;
  signal w_spi_dout     : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_spi_dout_vld : std_logic;

  -- Signals for FIFO
  signal r_fifo_wr_en        : std_logic;
  signal r_fifo_rd_en        : std_logic;
  signal r_fifo_rd_undo      : std_logic;
  signal r_fifo_wr_data      : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_fifo_rd_data      : std_logic_vector(WORD_SIZE-1 downto 0);

  -- FIFO Flags
  signal w_fifo_full         : std_logic;
  signal w_fifo_empty        : std_logic;
  signal w_fifo_almost_full  : std_logic;
  signal w_fifo_almost_empty : std_logic;

  -- Signals for FSM
  signal r_cmd      : std_logic_vector(WORD_SIZE-1 downto 0);
  signal r_spi_cs_n : std_logic;

  -- After CMD_WRITE, the first byte received should be skipped
  -- (i.e. it shouldn't be added to the FIFO)
  signal r_first_write_skipped : std_logic;

  -- When CMD_READ is received, bytes are removed from the FIFO and
  -- latched into the SPI module for transmission in the next response.
  -- However, if the master asserts `i_spi_cs_n` before the FIFO is
  -- empty, the last byte fetched from the FIFO will not be transmitted.
  -- To ensure this byte isn't lost, it must be placed back into the FIFO.
  signal r_read_prefetched      : std_logic;

-- TODO LORIS: keep track of number of items in fifo,
-- or maybe just expose the count register in the FIFO.
-- signal r_fifo_count : natural range 0 to 99;

  -- FSM States
  type StateType is (IDLE, COUNT, WRITE, READ);
  signal r_state : StateType;

  -- Abstract logic for responding to a command
  function f_acknowledge_cmd (
    w_fifo_full  : std_logic;
    w_fifo_empty : std_logic)
  return std_logic_vector is
  begin
    if w_fifo_full = '1' then
      return FIFO_FULL;
    elsif w_fifo_empty = '1' then
      return FIFO_EMPTY;
    else
      return ACK;
    end if;
  end function;

begin

  -- Debugging outputs set to low to avoid picking up noise
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

  FIFOInstance : entity work.FIFO
    generic map(
      WIDTH => WORD_SIZE,
      DEPTH => FIFO_DEPTH)
    port map (
      i_rst_l => not i_rst,
      i_clk   => i_clk,
      -- Write Side
      i_wr_dv    => r_fifo_wr_en,
      i_wr_data  => r_fifo_wr_data,
      i_af_level => 1, -- TODO LORIS: generics
      o_af_flag  => w_fifo_almost_full,
      o_full     => w_fifo_full,
      -- Read Side
      i_rd_en    => r_fifo_rd_en,
      i_rd_undo  => r_fifo_rd_undo,
      o_rd_data  => w_fifo_rd_data,
      i_ae_level => 1,
      o_ae_flag  => w_fifo_almost_empty,
      o_empty    => w_fifo_empty);

  -- Used by the READ state to stretch the cleanup operation
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      r_spi_cs_n <= i_spi_cs_n;
    end if;
  end process;

  -- Main process to control the Finite State Machine
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        r_cmd <= (others => '0');
        r_state <= IDLE;
        r_spi_din <= (others => '0');
        r_spi_din_vld <= '0';
        r_fifo_wr_data <= (others => '0');
        r_fifo_wr_en <= '0';
        r_fifo_rd_en <= '0';
        r_fifo_rd_undo <= '0';
        r_first_write_skipped <= '0';
        r_read_prefetched <= '0';

      else
        case r_state is

          when IDLE =>
            -- if new data received:
            if w_spi_dout_vld = '1' then
              r_cmd <= w_spi_dout;

            -- if ready to send response:
            elsif w_spi_din_rdy = '1' then
              case r_cmd is
                when CMD_COUNT =>
                  r_state <= COUNT;
                  r_spi_din <= f_acknowledge_cmd(w_fifo_full, w_fifo_empty);
                  r_spi_din_vld <= '1';
                when CMD_WRITE =>
                  r_state <= WRITE;
                  r_spi_din <= f_acknowledge_cmd(w_fifo_full, w_fifo_empty);
                  r_spi_din_vld <= '1';
                when CMD_READ =>
                  r_state <= READ;
                  r_spi_din <= f_acknowledge_cmd(w_fifo_full, w_fifo_empty);
                  r_spi_din_vld <= '1';
                when others =>
                  r_state <= IDLE; -- Unknown command, remain to IDLE
                  r_spi_din <= NACK;
                  r_spi_din_vld <= '1';
              end case;

            else
              r_spi_din_vld <= '0';
            end if;


          when COUNT =>
            -- if requested to leave COUNT state:
            if i_spi_cs_n = '1' then
              r_state <= IDLE;

            -- if ready to send response:
            elsif w_spi_din_rdy = '1' then
              -- TODO LORIS: use real data
              r_spi_din <= std_logic_vector(to_unsigned(74, r_spi_din'length));
              r_spi_din_vld <= '1';

            else
              r_spi_din_vld <= '0';
            end if;


          when WRITE =>
            -- if requested to leave WRITE state:
            if i_spi_cs_n = '1' then
              r_first_write_skipped <= '0';
              r_state <= IDLE;

            -- if new data received:
            elsif w_spi_dout_vld = '1' then
              r_first_write_skipped <= '1';
              if r_first_write_skipped = '1' and w_fifo_full = '0' then
                r_fifo_wr_data <= w_spi_dout;
                r_fifo_wr_en <= '1';
              end if;

            -- if ready to send response:
            elsif w_spi_din_rdy = '1' then
              r_fifo_wr_en <= '0';
              r_spi_din_vld <= '1';
              if w_fifo_full = '1' then
                r_spi_din <= NACK;
              elsif w_fifo_almost_full = '1' then
                r_spi_din <= FIFO_FULL;
              else
                r_spi_din <= ACK;
              end if;

            else
              r_spi_din_vld <= '0';
            end if;


          when READ =>
            -- if requested to leave READ state:
            if i_spi_cs_n = '1' and r_spi_cs_n = '0' then
              if r_read_prefetched = '1' then
                r_read_prefetched <= '0';
                r_fifo_rd_undo <= '1';
              end if;
            elsif r_spi_cs_n = '1' then
              r_fifo_rd_undo <= '0';
              r_state <= IDLE;

            -- if new data received:
            elsif w_spi_dout_vld = '1' then
              if w_fifo_empty = '1' then
                r_read_prefetched <= '0';
              else
                r_fifo_rd_en <= '1';
                r_read_prefetched <= '1';
              end if;

            -- if ready to send response:
            elsif w_spi_din_rdy = '1' then
              r_fifo_rd_en <= '0';
              r_spi_din_vld <= '1';
              if r_read_prefetched = '1' then
                r_spi_din <= w_fifo_rd_data;
              else
                r_spi_din <= FIFO_EMPTY;
              end if;

            else
              r_spi_din_vld <= '0';
            end if;


        end case; --         end case r_state
      end if;     --       end if i_rst = '1'
    end if;       --     end if rising_edge(i_clk)
  end process;    --   end process (i_clk)
end architecture; -- end architecture RTL of SPIFIFO
