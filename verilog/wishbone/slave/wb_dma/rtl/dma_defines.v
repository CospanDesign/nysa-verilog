`ifndef __DMA_DEFINES__
`define __DMA_DEFINES__

//These don't do anything yet but in the future this could be used in
// Generate statements to procedurally generate the number of ports
`define SOURCE_COUNT          4
`define SINK_COUNT            4
`define WB_MASTER_COUNT       1

`define CTRL_DMA_ENABLE       6
`define CTRL_SINK_ADDR_TOP    1
`define CTRL_SINK_ADDR_BOT    0

`define CTRL_IP_ADDR_TOP      7
`define CTRL_IP_ADDR_BOT      4

`define STS_ERR_CONFLICT_SINK 2
`define STS_FIN               1
`define STS_BUSY              0

`endif
