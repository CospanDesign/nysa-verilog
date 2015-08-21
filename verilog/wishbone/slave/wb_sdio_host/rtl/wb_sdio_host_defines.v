`ifndef WB_SDIO_HOST_DEFINES
`define WB_SDIO_HOST_DEFINES

`timescale 1 ns/1 ps

`define DEFAULT_MEM_0_BASE        32'h00000000
`define DEFAULT_MEM_1_BASE        32'h00100000

//control bit definition
`define CONTROL_ENABLE            0
`define CONTROL_ENABLE_INTERRUPT  1

//status bit definition
`define STATUS_MEMORY_0_FINISHED  0
`define STATUS_MEMORY_1_FINISHED  1
`define STATUS_BUSY               3
`define STATUS_ENABLE             5
`define STATUS_MEMORY_0_EMPTY     6
`define STATUS_MEMORY_1_EMPTY     7


`endif WB_SDIO_HOST_DEFNES
