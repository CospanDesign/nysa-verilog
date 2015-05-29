`ifndef __wb_sata_defines__
`define __wb_sata_defines__

`define BIT_HD_COMMAND_RESET            0
`define BIT_EN_INT_HD_INTERRUPT         2
`define BIT_EN_INT_DMA_ACTIVATE_STB     3
`define BIT_EN_INT_D2H_REG_STB          4
`define BIT_EN_INT_PIO_SETUP_STB        5
`define BIT_EN_INT_D2H_DATA_STB         6
`define BIT_EN_INT_DMA_SETUP_STB        7
`define BIT_EN_INT_SET_DEVICE_BITS_STB  9


//Status
`define BIT_PLATFORM_READY              0
`define BIT_PLATFORM_ERROR              1
`define BIT_LINKUP                      2
`define BIT_COMMAND_LAYER_READY         3
`define BIT_SATA_BUSY                   4
`define BIT_PHY_READY                   5
`define BIT_LINK_LAYER_READY            6
`define BIT_TRANSPORT_LAYER_READY       7
`define BIT_HARD_DRIVE_ERROR            8
`define BIT_PIO_DATA_READY              9


//Hard Drive Status
`define BIT_D2H_INTERRUPT               0
`define BIT_D2H_NOTIFICATION            1
`define BIT_D2H_PMULT_LOW               4
`define BIT_D2H_PMULT_HIGH              7
`define BIT_D2H_STATUS_LOW              16
`define BIT_D2H_STATUS_HIGH             23
`define BIT_D2H_ERROR_LOW               24
`define BIT_D2H_ERROR_HIGH              31

`endif
