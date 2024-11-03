  -- Get SPI Byte in SPI Clock Domain
  process (i_SPI_Clk, i_SPI_CS_n)
  begin
    if i_SPI_CS_n = '1' then
      r_RX_Bit_Count <= (others => '0');
      r_RX_Done <= '0';
    elsif rising_edge(i_SPI_Clk) then
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
