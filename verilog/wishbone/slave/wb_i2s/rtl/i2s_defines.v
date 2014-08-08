`ifndef __I2S_DEFINES__
`define __I2S_DEFINES__


`timescale 1 ns/1 ps
//Initially 2MB data chunk
`define DEFAULT_MEM_0_BASE        32'h00000000
//`ifndef SIMULATION
`define DEFAULT_MEM_1_BASE        32'h00200000
//`else
//  `define DEFAULT_MEM_1_BASE        32'h00000008
//`endif


//control bit definition
`define CONTROL_ENABLE            0
`define CONTROL_ENABLE_INTERRUPT  1
`define CONTROL_POST_FIFO_WAVE    2
`define CONTROL_PRE_FIFO_WAVE     3


//status bit definition
`define STATUS_MEMORY_0_EMPTY     0
`define STATUS_MEMORY_1_EMPTY     1 

`define AUDIO_RATE                44100
`define AUDIO_BITS                24
`define AUDIO_CHANNELS            2

`endif
