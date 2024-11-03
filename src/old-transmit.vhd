  -- Control preload signal for transmitting data
  -- Basically you set w_SPI_MISO_Mux to r_TX_Byte(7) before SPI_CS goes low.
  -- This is done because in mode CPHA=0, the MISO bit has to be ready as soon
  -- as the CS bit goes low.
  -- TODO LORIS: move this block closer to where r_Preload_MISO is used, and
  -- keep the above comment.
  process (w_SPI_Clk, i_SPI_CS_n)
  begin
    if i_SPI_CS_n = '1' then
      r_Preload_MISO <= '1';
    elsif rising_edge(w_SPI_Clk) then
      r_Preload_MISO <= '0';
    end if;
  end process;

  -- Transmits 1 SPI Byte whenever SPI clock is toggling,
  -- eventually over and over if not stopped.
  process (w_SPI_Clk, i_SPI_CS_n)
  begin
    if i_SPI_CS_n = '1' then
      -- TODO LORIS: maybe just natural numbers
      r_TX_Bit_Count <= "111";  -- Send MSb first
      r_SPI_MISO_Bit <= r_TX_Byte(7);  -- Reset to MSb
    elsif rising_edge(w_SPI_Clk) then
      r_TX_Bit_Count <= r_TX_Bit_Count - 1; -- Rolls back to '111' eventually
      r_SPI_MISO_Bit <= r_TX_Byte(to_integer(unsigned(r_TX_Bit_Count)));
    end if;
  end process;

  -- Register TX Byte when DV pulse comes.
  -- We're working on the FPGA-clock domain.
  -- When we get a *pulse* at i_TX_DV, we load r_TX_Byte with i_TX_Byte.
  -- It's assumed that, once a TX byte is transmitted (snipped above),
  -- either the master interrupts the communication, or a new TX byte
  -- is ready to be sent.
  process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      r_TX_Byte <= (others => '0');
    elsif rising_edge(i_Clk) then
      if i_TX_DV = '1' then
        r_TX_Byte <= i_TX_Byte;
      end if;
    end if;
  end process;

  -- Preload MISO with top bit of send data when preload selector is high.
  w_SPI_MISO_Mux <= r_TX_Byte(7) when r_Preload_MISO = '1' else r_SPI_MISO_Bit;

  -- Tri-state MISO when CS is high
  o_SPI_MISO <= 'Z' when i_SPI_CS_n = '1' else w_SPI_MISO_Mux;
