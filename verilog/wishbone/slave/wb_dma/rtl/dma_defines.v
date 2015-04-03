`ifndef __DMA_DEFINES__
`define __DMA_DEFINES__

//These don't do anything yet but in the future this could be used in
// Generate statements to procedurally generate the number of ports
`define SOURCE_COUNT              4
`define SINK_COUNT                4
`define INST_COUNT                8

`define CTRL_DMA_ENABLE           0

//Bit locations for the sink address location
`define CTRL_SINK_ADDR_TOP        5
`define CTRL_SINK_ADDR_BOT        4

//Bit location for the instruction pointers
`define CTRL_IP_ADDR_TOP          10
`define CTRL_IP_ADDR_BOT          8

//Command Bits

//When Set, resets the address to the address in the instruction, otherwise the address is not changed
`define CMD_BOND_ADDR_TOP         15
`define CMD_BOND_ADDR_BOT         13

`define CMD_EGRESS_BOND           8
`define CMD_INGRESS_BOND          7
`define CMD_DEST_ADDR_RST_ON_CMD  6
`define CMD_DEST_DATA_QUANTUM     5
`define CMD_DEST_ADDR_INC         4
`define CMD_DEST_ADDR_DEC         3
`define CMD_SRC_ADDR_RST_ON_CMD   2
`define CMD_SRC_ADDR_INC          1
`define CMD_SRC_ADDR_DEC          0

//Status Bits
`define STS_ERR_CONFLICT_SINK     3
`define STS_FIN                   2
`define STS_BUSY                  1

`endif
