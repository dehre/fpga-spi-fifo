-- PROJECT TOP.
-- Counts the number of rising edges on pin 1 of the PMOD connector,
-- displaying the count (0-99) on two 7-segment displays.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPIPingPong is
  port (
    -- DEBUGGING OUTPUTS
    io_pmod_7    : out  std_logic;  -- Shows if r_RX_Bit_Count ever goes to 111
    io_pmod_8    : out  std_logic;  -- Toggles on quarter FPGA clock
    io_pmod_9    : out  std_logic;  -- Toggles on half FPGA clock

    -- Control/Data Signals

    -- TODO LORIS: add pull-up resistor to schematics
    -- i_Rst_L    : in  std_logic;    -- FPGA Reset, active low
    io_pmod_10    : in  std_logic;  -- FPGA Reset, active low

    i_Clk      : in  std_logic;    -- FPGA Clock

    -- SPI Interface

    -- i_SPI_Clk  : in  std_logic;
    io_pmod_1  : in  std_logic; -- SPI Clock

    -- o_SPI_MISO : out std_logic     -- Master In, Slave Out
    io_pmod_2 : out std_logic;     -- Master In, Slave Out

    -- i_SPI_MOSI : in  std_logic;    -- Master Out, Slave In
    io_pmod_3 : in  std_logic;    -- Master Out, Slave In

    -- i_SPI_CS_n : in  std_logic;    -- Chip Select, active low
    io_pmod_4 : in  std_logic);    -- Slave Select, active low
end entity;

architecture RTL of SPIPingPong is

  -- Wires for renaming pmod pins
  -- TODO LORIS: maybe rename pin-constraints directly
  signal i_Rst_L: std_logic;
  signal i_SPI_Clk: std_logic;
  signal o_SPI_MISO: std_logic;
  signal i_SPI_MOSI: std_logic;
  signal i_SPI_CS_n: std_logic;

  -- Internal signals
  -- TODO LORIS: prepend w_
  signal o_RX_DV    : std_logic;
  signal o_RX_Byte  : std_logic_vector(7 downto 0);
  signal i_TX_DV    : std_logic := '0';
  signal i_TX_Byte  : std_logic_vector(7 downto 0) := (others => '0');

  signal r_Clk_Half : std_logic;
  signal r_Clk_Quarter : std_logic;

begin

  -- Renaming inputs/outputs for clarity
  i_Rst_L    <= io_pmod_10;
  i_SPI_Clk  <= io_pmod_1;
  o_SPI_MISO <= io_pmod_2;
  i_SPI_MOSI <= io_pmod_3;
  i_SPI_CS_n <= io_pmod_4;

  -- Instantiate the SPI_Slave component
  SpiSlaveInstance: entity work.SPI_Slave
    generic map (SPI_MODE => 0)
    port map (
      o_logicanalyzer_a => io_pmod_7,
      -- o_logicanalyzer_b => io_pmod_8,
      i_Rst_L    => i_Rst_L,
      i_Clk      => r_Clk_Half,
      o_RX_DV    => o_RX_DV,
      o_RX_Byte  => o_RX_Byte,
      i_TX_DV    => i_TX_DV,
      i_TX_Byte  => i_TX_Byte,
      i_SPI_Clk  => i_SPI_Clk,
      o_SPI_MISO => o_SPI_MISO,
      i_SPI_MOSI => i_SPI_MOSI,
      i_SPI_CS_n => i_SPI_CS_n);

  process (i_Clk, r_Clk_Half)
  begin
    if rising_edge(i_Clk) then
      r_Clk_Half <= not r_Clk_Half;
      io_pmod_9 <= not io_pmod_9;
    end if;
  end process;

  process (r_Clk_Half, r_Clk_Quarter)
  begin
    if rising_edge(r_Clk_Half) then
      r_Clk_Quarter <= not r_Clk_Quarter;
      io_pmod_8 <= not io_pmod_8;
    end if;
  end process;

  -- Main process that sends received data back to the SPI master
  process (r_Clk_Half)
  begin
    if rising_edge(r_Clk_Half) then
      if o_RX_DV = '1' then
        -- When a byte is received, set TX Data Valid and load received byte into the TX register
        -- io_pmod_9 <= '1';
        i_TX_DV <= '1';
        i_TX_Byte <= o_RX_Byte;  -- Echo received byte back to master
      else
        -- io_pmod_9 <= '0';
        i_TX_DV <= '0';  -- Clear TX Data Valid when not in use
      end if;
    end if;
  end process;

--   -- Main process that sends received data back to the SPI master
--   process (i_Clk, i_Rst_L)
--   begin
--     if i_Rst_L = '0' then
--       -- Reset state
--       i_TX_DV <= '0';
--       i_TX_Byte <= (others => '0');
--     elsif rising_edge(i_Clk) then
--       if o_RX_DV = '1' then
--         -- When a byte is received, set TX Data Valid and load received byte into the TX register
--         i_TX_DV <= '1';
--         i_TX_Byte <= o_RX_Byte;  -- Echo received byte back to master
--       else
--         i_TX_DV <= '0';  -- Clear TX Data Valid when not in use
--       end if;
--     end if;
--   end process;

end architecture;

-- 
-- OLD STUFF
-- 

-- entity DisplayCounter is
--   -- Inputs/Outputs for the top module.
--   port (
--     io_pmod_1    : in  std_logic;  -- Clock signal from PMOD pin 1
--     o_display0_a : out std_logic;  -- Display 0, segment A
--     o_display0_b : out std_logic;  -- Display 0, segment B
--     o_display0_c : out std_logic;  -- Display 0, segment C
--     o_display0_d : out std_logic;  -- Display 0, segment D
--     o_display0_e : out std_logic;  -- Display 0, segment E
--     o_display0_f : out std_logic;  -- Display 0, segment F
--     o_display0_g : out std_logic;  -- Display 0, segment G
--     o_display1_a : out std_logic;  -- Display 1, segment A
--     o_display1_b : out std_logic;  -- Display 1, segment B
--     o_display1_c : out std_logic;  -- Display 1, segment C
--     o_display1_d : out std_logic;  -- Display 1, segment D
--     o_display1_e : out std_logic;  -- Display 1, segment E
--     o_display1_f : out std_logic;  -- Display 1, segment F
--     o_display1_g : out std_logic); -- Display 1, segment G
-- end entity;

-- architecture RTL of DisplayCounter is

--   -- Wires connecting the two modules RisingEdgeDecimalCounter and DisplayDriver.
--   signal w_ones_bcd : std_logic_vector(3 downto 0);
--   signal w_tens_bcd : std_logic_vector(3 downto 0);

-- begin
--   -- Module counting the number of rising edges on pmod_1.
--   -- Outputs a 2-digits BCD value (0 to 99).
--   RisingEdgeDecimalCounterInstance: entity work.RisingEdgeDecimalCounter
--     port map (
--       i_clk      => io_pmod_1,
--       o_ones_bcd => w_ones_bcd,
--       o_tens_bcd => w_tens_bcd);

--   -- Modules driving the two 7-segments displays.
--   Display0DriverInstance: entity work.DisplayDriver
--     port map (
--       i_bcd       => w_ones_bcd,
--       o_segment_a => o_display0_a,
--       o_segment_b => o_display0_b,
--       o_segment_c => o_display0_c,
--       o_segment_d => o_display0_d,
--       o_segment_e => o_display0_e,
--       o_segment_f => o_display0_f,
--       o_segment_g => o_display0_g);

--   Display1DriverInstance: entity work.DisplayDriver
--     port map (
--       i_bcd       => w_tens_bcd,
--       o_segment_a => o_display1_a,
--       o_segment_b => o_display1_b,
--       o_segment_c => o_display1_c,
--       o_segment_d => o_display1_d,
--       o_segment_e => o_display1_e,
--       o_segment_f => o_display1_f,
--       o_segment_g => o_display1_g);

-- end architecture;
