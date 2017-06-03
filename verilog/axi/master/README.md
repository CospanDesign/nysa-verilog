# AXI Master

## Working with Xilinx Tools

Xilinx only allows 32-bit to 64-bit master so in order to interface with the master using an 8-bit there is a second core called

    axi_byte_master

It should behave the same as the 32-bit/64-bit master
