nysa-sdio-device
================

SDIO device stack written in Verilog

Status: TLDR Version: Still designing and writing verilog cores

Designed to interface with SDIO Hosts. The associate Linux driver is at:
https://github.com/CospanDesign/nysa-sdio-linux-driver


Code Organization:

  sdio_configuration.json (Project configuration)

  rtl/
    sdio_stack.v (Top File that applications interface with)
    sdio_defines.v (Set defines for the stack are here)

    generic/ (Small modules that are used throughout the code are here)
      crc7.v (7-bit CRC Generator)
      crc16.v (16-bit CRC Generator)

    control/ (SDIO Card Controller)
      sdio_card_control.v

    cia/ (Common Information Area)
      sdio_cia.v  (This is where the SDIO card gets configured and contains
                    information for the host)
      sdio_cccr.v (Card Common Control Register)
      sdio_csi.v  (Card Information Structure)
      sdio_fbr.v  (Function Basic Registers)

    function/ (Function templates are here, use the function template to write
              your own interface)
      my_function/
        my_function.v         (Demo Function Interface)
        my_function_defines.v (Demo Function Interface Defines)

    phy/ (Physical level interface, these toggle the pins for both the command
          and data lines)
      sdio_phy.v (Main phy interface, all other phys are called through here)
      sdio_phy_sd_1_bit.v (1 data bit used with SD protocol)
      sdio_phy_sd_4_bit.v (4 data bits used with SD protocol)
      sdio_phy_spi.v      (SPI based interface on SD protocol)

  functions/
    my_function/
      my_function.v (SDIO Function that is a nysa host interface)
      my_function_defines.v (Defines)


  sim/
    sdio_host/
      sdio_host.v (Used to exercise the sdio_device stack, this will
                  eventually become it's own repo)


Instructions:
  To generate your own SDIO device
  1. Fork this repository

  2. Modify the configuration file 'sdio_configuration.json' The file is
      already populated but you must modify it to suit your design
    a. Select a vendor id to use... this sucks because you have to pay for this :(
    b. Select a product id to use... see sucky note above
    c. Populate your function behavior within the configuration file

  3. Write your specific functions  


