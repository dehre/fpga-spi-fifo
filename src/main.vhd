-- PROJECT TOP.
-- 
-- This module implements a Finite State Machine (FSM) around a FIFO queue.
-- Communication with the FPGA is performed using SPI in MODE 0.
-- 
-- The following commands are available to the SPI master:
-- * CMD_COUNT: Retrieve the number of items currently in the FIFO.
-- * CMD_WRITE: Write data bytes into the FIFO.
-- * CMD_READ : Read data bytes from the FIFO.
-- Refer to the timing diagram in the README for details.
-- 
-- It's recommended to assert `i_rst` to reset the FPGA to a known state
-- before starting the communication.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPIFIFO is
  -- Inputs/Outputs for the FPGA
  port (
    -- Debugging Outputs (PMOD Connector)
    o_debug_a  : out std_logic;
    o_debug_b  : out std_logic;
    o_debug_c  : out std_logic;

    -- Control/Data Signals (PMOD Connector)
    i_rst      : in  std_logic;     -- FPGA Reset
    i_clk      : in  std_logic;     -- FPGA Clock

    -- SPI Interface (PMOD Connector)
    i_spi_clk  : in  std_logic;     -- SPI Clock
    o_spi_miso : out std_logic;     -- Master In, Slave Out
    i_spi_mosi : in  std_logic;     -- Master Out, Slave In
    i_spi_cs_n : in  std_logic;     -- Chip Select, active low

    -- 7-Segment Displays (Onboard)
    o_display0_a : out std_logic;   -- Display 0, segment A
    o_display0_b : out std_logic;   -- Display 0, segment B
    o_display0_c : out std_logic;   -- Display 0, segment C
    o_display0_d : out std_logic;   -- Display 0, segment D
    o_display0_e : out std_logic;   -- Display 0, segment E
    o_display0_f : out std_logic;   -- Display 0, segment F
    o_display0_g : out std_logic;   -- Display 0, segment G
    o_display1_a : out std_logic;   -- Display 1, segment A
    o_display1_b : out std_logic;   -- Display 1, segment B
    o_display1_c : out std_logic;   -- Display 1, segment C
    o_display1_d : out std_logic;   -- Display 1, segment D
    o_display1_e : out std_logic;   -- Display 1, segment E
    o_display1_f : out std_logic;   -- Display 1, segment F
    o_display1_g : out std_logic);  -- Display 1, segment G
end entity;

architecture RTL of SPIFIFO is

  constant WORD_SIZE   : natural := 8;
  constant FIFO_DEPTH  : natural := 99;

  -- Constants for incoming commands
  constant CMD_COUNT  : std_logic_vector(WORD_SIZE-1 downto 0) := x"F0";
  constant CMD_WRITE  : std_logic_vector(WORD_SIZE-1 downto 0) := x"F1";
  constant CMD_READ   : std_logic_vector(WORD_SIZE-1 downto 0) := x"F2";

  -- Constants for outcoming replies
  constant ACK        : std_logic_vector(WORD_SIZE-1 downto 0) := x"FA";
  constant NACK       : std_logic_vector(WORD_SIZE-1 downto 0) := x"FB";
  constant FIFO_EMPTY : std_logic_vector(WORD_SIZE-1 downto 0) := x"FE";
  constant FIFO_FULL  : std_logic_vector(WORD_SIZE-1 downto 0) := x"FF";

  -- Signals for DisplayDrivers
  signal w_fifo_count        : natural range 0 to FIFO_DEPTH;
  signal w_ones_bcd          : std_logic_vector(3 downto 0);
  signal w_tens_bcd          : std_logic_vector(3 downto 0);

  -- Signals for SPISlave
  signal r_spi_din           : std_logic_vector(WORD_SIZE-1 downto 0);
  signal r_spi_din_vld       : std_logic;
  signal w_spi_din_rdy       : std_logic;
  signal w_spi_dout          : std_logic_vector(WORD_SIZE-1 downto 0);
  signal w_spi_dout_vld      : std_logic;

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

  -- FSM States
  type StateType is (IDLE, COUNT, WRITE, READ);
  signal r_state : StateType;

  -- Signals for FSM
  signal r_cmd      : std_logic_vector(WORD_SIZE-1 downto 0);
  signal r_spi_cs_n : std_logic;

  -- Tracks whether the first byte received after CMD_WRITE should
  -- be skipped (not added to the FIFO); see timing diagram
  signal r_first_write_skipped : std_logic;

  -- Tracks whether a byte was prefetched from the FIFO for CMD_READ
  -- but not transmitted: if the READ operation is aborted before
  -- the FIFO is empty, this byte is returned to the queue
  signal r_read_prefetched : std_logic;

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

  -- Debugging outputs set to output low to avoid picking up noise
  o_debug_a <= '0';
  o_debug_b <= '0';
  o_debug_c <= '0';

  -- Entity converting FIFO count to BCD values for the 7-segment displays
  NumberToBCDInstance: entity work.NumberToBCD
    port map (
      i_number   => w_fifo_count,
      o_ones_bcd => w_ones_bcd,
      o_tens_bcd => w_tens_bcd);

  -- Feed the FIFO count to the 7-segment displays
  Display0DriverInstance: entity work.DisplayDriver
    port map (
      i_bcd       => w_ones_bcd,
      o_segment_a => o_display0_a,
      o_segment_b => o_display0_b,
      o_segment_c => o_display0_c,
      o_segment_d => o_display0_d,
      o_segment_e => o_display0_e,
      o_segment_f => o_display0_f,
      o_segment_g => o_display0_g);
  Display1DriverInstance: entity work.DisplayDriver
    port map (
      i_bcd       => w_tens_bcd,
      o_segment_a => o_display1_a,
      o_segment_b => o_display1_b,
      o_segment_c => o_display1_c,
      o_segment_d => o_display1_d,
      o_segment_e => o_display1_e,
      o_segment_f => o_display1_f,
      o_segment_g => o_display1_g);

  -- Handle the SPI communication
  SPISlaveInstance : entity work.SPISlave
    generic map (WORD_SIZE => WORD_SIZE)
    port map (
      i_rst      => i_rst,
      i_clk      => i_clk,
      i_spi_clk  => i_spi_clk,
      i_spi_cs_n => i_spi_cs_n,
      i_spi_mosi => i_spi_mosi,
      o_spi_miso => o_spi_miso,
      i_din      => r_spi_din,
      i_din_vld  => r_spi_din_vld,
      o_din_rdy  => w_spi_din_rdy,
      o_dout     => w_spi_dout,
      o_dout_vld => w_spi_dout_vld
    );

  -- Instantiate the FIFO queue
  FIFOInstance : entity work.FIFO
    generic map(
      WIDTH => WORD_SIZE,
      DEPTH => FIFO_DEPTH)
    port map (
      i_rst          => i_rst,
      i_clk          => i_clk,
      i_wr_en        => r_fifo_wr_en,
      i_wr_data      => r_fifo_wr_data,
      i_rd_en        => r_fifo_rd_en,
      i_rd_undo      => r_fifo_rd_undo,
      o_rd_data      => w_fifo_rd_data,
      o_full         => w_fifo_full,
      o_almost_full  => w_fifo_almost_full,
      o_almost_empty => w_fifo_almost_empty,
      o_empty        => w_fifo_empty,
      o_count        => w_fifo_count);

  -- Register r_spi_cs_n is used by the READ state to stretch the cleanup operation
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      r_spi_cs_n <= i_spi_cs_n;
    end if;
  end process;

  -- Main process to control the FSM
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_spi_din <= (others => '0');
      r_spi_din_vld <= '0';
      r_fifo_wr_data <= (others => '0');
      r_fifo_wr_en <= '0';
      r_fifo_rd_en <= '0';
      r_fifo_rd_undo <= '0';
      r_cmd <= (others => '0');
      r_state <= IDLE;
      r_first_write_skipped <= '0';
      r_read_prefetched <= '0';
    elsif rising_edge(i_clk) then
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
          -- default:
          else
            r_spi_din_vld <= '0';
          end if;


        when COUNT =>
          -- if requested to leave COUNT state:
          if i_spi_cs_n = '1' then
            r_state <= IDLE;
          -- if ready to send response:
          elsif w_spi_din_rdy = '1' then
            r_spi_din <= std_logic_vector(to_unsigned(w_fifo_count, r_spi_din'length));
            r_spi_din_vld <= '1';
          -- default:
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
          -- default:
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
          -- default:
          else
            r_spi_din_vld <= '0';
          end if;

      end case;   --       end case r_state
    end if;       --     end if i_rst = '1' ... elsif rising_edge(i_clk)
  end process;    --   end process (i_clk, i_rst)
end architecture; -- end architecture RTL of SPIFIFO
