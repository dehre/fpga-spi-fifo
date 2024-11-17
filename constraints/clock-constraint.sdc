# Go Board Clock Constraints File
#
# iCEcube SDC Version: 2020.12.27943
# Family & Device:     iCE40HX1K
# Package:             VQ100

create_clock  -period 40.00   -name {i_clk}     [get_ports {i_clk}]
create_clock  -period 2000.00 -name {i_spi_clk} [get_ports {i_spi_clk}]
