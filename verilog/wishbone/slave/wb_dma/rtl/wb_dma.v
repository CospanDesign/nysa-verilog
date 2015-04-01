//wb_dma.v
/*
Distributed under the MIT license.
Copyright (c) 2015 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
  Set the Vendor ID (Hexidecimal 64-bit Number)
  SDB_VENDOR_ID:0x800000000000C594

  Set the Device ID (Hexcidecimal 32-bit Number)
  SDB_DEVICE_ID:0x800000000000C594

  Set the version of the Core XX.XXX.XXX Example: 01.000.000
  SDB_CORE_VERSION:00.000.001

  Set the Device Name: 19 UNICODE characters
  SDB_NAME:wb_dma

  Set the class of the device (16 bits) Set as 0
  SDB_ABI_CLASS:0

  Set the ABI Major Version: (8-bits)
  SDB_ABI_VERSION_MAJOR:13

  Set the ABI Minor Version (8-bits)
  SDB_ABI_VERSION_MINOR:0

  Set the Module URL (63 Unicode Characters)
  SDB_MODULE_URL:http://www.example.com

  Set the date of module YYYY/MM/DD
  SDB_DATE:2015/03/27

  Device is executable (True/False)
  SDB_EXECUTABLE:True

  Device is readable (True/False)
  SDB_READABLE:True

  Device is writeable (True/False)
  SDB_WRITEABLE:True

  Device Size: Number of Registers
  SDB_SIZE:3
*/

`include "dma_defines.v"


module wb_dma #(
  parameter START_ENABLED       = 1,
  parameter WISHBONE_BUS_COUNT  = 1
)(
  input               clk,
  input               rst,

  //Add signals to control your device here

  //Wishbone Bus Signals
  input               i_wbs_we,
  input               i_wbs_cyc,
  input       [3:0]   i_wbs_sel,
  input       [31:0]  i_wbs_dat,
  input               i_wbs_stb,
  output  reg         o_wbs_ack,
  output  reg [31:0]  o_wbs_dat,
  input       [31:0]  i_wbs_adr,

  //Source 0
  input       [31:0]  i_src0_address,
  input               i_src0_start,
  output              o_src0_finished,
  output              o_src0_busy,

  output              o_src0_if_strobe,
  output      [31:0]  i_src0_if_data,
  input               i_src0_if_ready,
  output              o_src0_if_activate,
  input       [23:0]  i_src0_if_size,
  input               i_src0_if_starved,

  //Source 1
  input       [31:0]  i_src1_address,
  input               i_src1_start,
  output              o_src1_finished,
  output              o_src1_busy,

  output              o_src1_if_strobe,
  output      [31:0]  i_src1_if_data,
  input               i_src1_if_ready,
  output              o_src1_if_activate,
  input       [23:0]  i_src1_if_size,
  input               i_src1_if_starved,

  //Source 2
  input       [31:0]  i_src2_address,
  input               i_src2_start,
  output              o_src2_finished,
  output              o_src2_busy,

  output              o_src2_if_strobe,
  output      [31:0]  i_src2_if_data,
  input               i_src2_if_ready,
  output              o_src2_if_activate,
  input       [23:0]  i_src2_if_size,
  input               i_src2_if_starved,

  //Source 3
  input       [31:0]  i_src3_address,
  input               i_src3_start,
  output              o_src3_finished,
  output              o_src3_busy,

  output              o_src3_if_strobe,
  output      [31:0]  i_src3_if_data,
  input               i_src3_if_ready,
  output              o_src3_if_activate,
  input       [23:0]  i_src3_if_size,
  input               i_src3_if_starved,

  //Sink 0
  output              o_snk0_address,
  output              o_snk0_valid,

  output              o_snk0_strobe,
  input       [1:0]   i_snk0_ready,
  output      [1:0]   o_snk0_activate,
  input       [23:0]  i_snk0_size,
  input       [31:0]  o_snk0_data,

  //Sink 1
  output              o_snk1_address,
  output              o_snk1_valid,

  output              o_snk1_strobe,
  input       [1:0]   i_snk1_ready,
  output      [1:0]   o_snk1_activate,
  input       [23:0]  i_snk1_size,
  input       [31:0]  o_snk1_data,

  //Sink 2
  output              o_snk2_address,
  output              o_snk2_valid,

  output              o_snk2_strobe,
  input       [1:0]   i_snk2_ready,
  output      [1:0]   o_snk2_activate,
  input       [23:0]  i_snk2_size,
  input       [31:0]  o_snk2_data,

  //Sink 3
  output              o_snk3_address,
  output              o_snk3_valid,

  output              o_snk3_strobe,
  input       [1:0]   i_snk3_ready,
  output      [1:0]   o_snk3_activate,
  input       [23:0]  i_snk3_size,
  input       [31:0]  o_snk3_data,

  //Wishbone Bus Master
  output              wbm_o_we,
  output              wbm_o_stb,
  output              wbm_o_cyc,
  output      [3:0]   wbm_o_sel,
  output      [31:0]  wbm_o_adr,
  output      [31:0]  wbm_o_dat,
  input       [31:0]  wbm_i_dat,
  input               wbm_i_ack,
  input               wbm_i_int,

  //This interrupt can be controlled from this module or a submodule
  output  reg         o_wbs_int
  //output              o_wbs_int
);

//Local Parameters
localparam      CONTROL_ADDR            = 32'h00000000;
localparam      STATUS_ADDR             = 32'h00000001;
localparam      SOURCE_COUNT_ADDR       = 32'h00000002;
localparam      SINK_COUNT_ADDR         = 32'h00000003;
localparam      WB_BUS_COUNT_ADDR       = 32'h00000004;
localparam      SNK0_CONTROL_ADDR       = 32'h00000005;
localparam      SNK1_CONTROL_ADDR       = 32'h00000006;
localparam      SNK2_CONTROL_ADDR       = 32'h00000007;
localparam      SNK3_CONTROL_ADDR       = 32'h00000008;
localparam      SRC0_CONTROL_ADDR       = 32'h00000009;
localparam      SRC1_CONTROL_ADDR       = 32'h0000000A;
localparam      SRC2_CONTROL_ADDR       = 32'h0000000B;
localparam      SRC3_CONTROL_ADDR       = 32'h0000000C;
localparam      WB_CONTROL_ADDR         = 32'h0000000D;

localparam      PARAM_SRC_ADDR_LOW0     = 32'h00000010;
localparam      PARAM_SRC_ADDR_HIDH0    = 32'h00000011;
localparam      PARAM_DEST_ADDR_LOW0    = 32'h00000012;
localparam      PARAM_DEST_ADDR_HIDH0   = 32'h00000013;
localparam      PARAM_COUNT0            = 32'h00000014;
localparam      PARAM_CNT0              = 32'h00000016;

localparam      PARAM_SRC_ADDR_LOW1     = 32'h00000020;
localparam      PARAM_SRC_ADDR_HIDH1    = 32'h00000021;
localparam      PARAM_DEST_ADDR_LOW1    = 32'h00000022;
localparam      PARAM_DEST_ADDR_HIDH1   = 32'h00000023;
localparam      PARAM_COUNT1            = 32'h00000024;
localparam      PARAM_CNT1              = 32'h00000026;

localparam      PARAM_SRC_ADDR_LOW2     = 32'h00000030;
localparam      PARAM_SRC_ADDR_HIDH2    = 32'h00000031;
localparam      PARAM_DEST_ADDR_LOW2    = 32'h00000032;
localparam      PARAM_DEST_ADDR_HIDH2   = 32'h00000033;
localparam      PARAM_COUNT2            = 32'h00000034;
localparam      PARAM_CNT2              = 32'h00000036;

localparam      PARAM_SRC_ADDR_LOW3     = 32'h00000040;
localparam      PARAM_SRC_ADDR_HIDH3    = 32'h00000041;
localparam      PARAM_DEST_ADDR_LOW3    = 32'h00000042;
localparam      PARAM_DEST_ADDR_HIDH3   = 32'h00000043;
localparam      PARAM_COUNT3            = 32'h00000044;
localparam      PARAM_CNT3              = 32'h00000046;

localparam      PARAM_SRC_ADDR_LOW4     = 32'h00000050;
localparam      PARAM_SRC_ADDR_HIDH4    = 32'h00000051;
localparam      PARAM_DEST_ADDR_LOW4    = 32'h00000052;
localparam      PARAM_DEST_ADDR_HIDH4   = 32'h00000053;
localparam      PARAM_COUNT4            = 32'h00000054;
localparam      PARAM_CNT4              = 32'h00000056;

localparam      PARAM_SRC_ADDR_LOW5     = 32'h00000060;
localparam      PARAM_SRC_ADDR_HIDH5    = 32'h00000061;
localparam      PARAM_DEST_ADDR_LOW5    = 32'h00000062;
localparam      PARAM_DEST_ADDR_HIDH5   = 32'h00000063;
localparam      PARAM_COUNT5            = 32'h00000064;
localparam      PARAM_CNT5              = 32'h00000066;

localparam      PARAM_SRC_ADDR_LOW6     = 32'h00000070;
localparam      PARAM_SRC_ADDR_HIDH6    = 32'h00000071;
localparam      PARAM_DEST_ADDR_LOW6    = 32'h00000072;
localparam      PARAM_DEST_ADDR_HIDH6   = 32'h00000073;
localparam      PARAM_COUNT6            = 32'h00000074;
localparam      PARAM_CNT6              = 32'h00000076;

localparam      PARAM_SRC_ADDR_LOW7     = 32'h00000080;
localparam      PARAM_SRC_ADDR_HIDH7    = 32'h00000081;
localparam      PARAM_DEST_ADDR_LOW7    = 32'h00000082;
localparam      PARAM_DEST_ADDR_HIDH7   = 32'h00000083;
localparam      PARAM_COUNT7            = 32'h00000084;
localparam      PARAM_CNT7              = 32'h00000086;




localparam      CNTL_DMA_ENABLE     = 0;

//Local Registers/Wires
reg   [31:0]          control;
wire                  dma_enable;
reg   [31:0]          snk0_control;
reg   [31:0]          snk1_control;
reg   [31:0]          snk2_control;
reg   [31:0]          snk3_control;

wire  [31:0]          snk0_status;
wire  [31:0]          snk1_status;
wire  [31:0]          snk2_status;
wire  [31:0]          snk3_status;

reg   [31:0]          src0_control;
reg   [31:0]          src1_control;
reg   [31:0]          src2_control;
reg   [31:0]          src3_control;

wire  [31:0]          src0_status;
wire  [31:0]          src1_status;
wire  [31:0]          src2_status;
wire  [31:0]          src3_status;

//8 Commands

reg   [63:0]          cmd_src_address0;
reg   [63:0]          cmd_dest_address0;
reg   [31:0]          cmd_count0;
reg   [15:0]          cmd_flags0;
reg   [15:0]          cmd_cross_src_port0;
reg   [15:0]          cmd_cross_dest_port0;
reg   [2:0]           cmd_next0;

reg   [63:0]          cmd_src_address1;
reg   [63:0]          cmd_dest_address1;
reg   [31:0]          cmd_count1;
reg   [15:0]          cmd_flags1;
reg   [15:0]          cmd_cross_src_port1;
reg   [15:0]          cmd_cross_dest_port1;
reg   [2:0]           cmd_next1;

reg   [63:0]          cmd_src_address2;
reg   [63:0]          cmd_dest_address2;
reg   [31:0]          cmd_count2;
reg   [15:0]          cmd_flags2;
reg   [15:0]          cmd_cross_src_port2;
reg   [15:0]          cmd_cross_dest_port2;
reg   [2:0]           cmd_next2;

reg   [63:0]          cmd_src_address3;
reg   [63:0]          cmd_dest_address3;
reg   [31:0]          cmd_count3;
reg   [15:0]          cmd_flags3;
reg   [15:0]          cmd_cross_src_port3;
reg   [15:0]          cmd_cross_dest_port3;
reg   [2:0]           cmd_next3;

reg   [63:0]          cmd_src_address4;
reg   [63:0]          cmd_dest_address4;
reg   [31:0]          cmd_count4;
reg   [15:0]          cmd_flags4;
reg   [15:0]          cmd_cross_src_port4;
reg   [15:0]          cmd_cross_dest_port4;
reg   [2:0]           cmd_next4;

reg   [63:0]          cmd_src_address5;
reg   [63:0]          cmd_dest_address5;
reg   [31:0]          cmd_count5;
reg   [15:0]          cmd_flags5;
reg   [15:0]          cmd_cross_src_port5;
reg   [15:0]          cmd_cross_dest_port5;
reg   [2:0]           cmd_next5;

reg   [63:0]          cmd_src_address6;
reg   [63:0]          cmd_dest_address6;
reg   [31:0]          cmd_count6;
reg   [15:0]          cmd_flags6;
reg   [15:0]          cmd_cross_src_port6;
reg   [15:0]          cmd_cross_dest_port6;
reg   [2:0]           cmd_next6;

reg   [63:0]          cmd_src_address7;
reg   [63:0]          cmd_dest_address7;
reg   [31:0]          cmd_count7;
reg   [15:0]          cmd_flags7;
reg   [15:0]          cmd_cross_src_port7;
reg   [15:0]          cmd_cross_dest_port7;
reg   [2:0]           cmd_next7;


//Submodules
dma #(
  .WISHBONE_BUS_COUNT(WISHBONE_BUS_COUNT )
) dmacntrl(

  .clk                  (clk                  ),
  .rst                  (rst                  ),
  .enable               (dma_enable           ),

  .snk0_control         (snk0_control         ),
  .snk1_control         (snk1_control         ),
  .snk2_control         (snk2_control         ),
  .snk3_control         (snk3_control         ),

  .src0_control         (src0_control         ),
  .src1_control         (src1_control         ),
  .src2_control         (src2_control         ),
  .src3_control         (src3_control         ),


  .i_src0_address       (i_src0_address       ),
  .i_src0_start         (i_src0_start         ),
  .o_src0_finished      (o_src0_finished      ),
  .o_src0_busy          (o_src0_busy          ),

  .o_src0_strobe        (o_src0_if_strobe     ),
  .i_src0_data          (i_src0_if_data       ),
  .i_src0_ready         (i_src0_if_ready      ),
  .o_src0_activate      (o_src0_if_activate   ),
  .i_src0_size          (i_src0_if_size       ),
  .i_src0_starved       (i_src0_if_starved    ),


  .i_src1_address       (i_src1_address       ),
  .i_src1_start         (i_src1_start         ),
  .o_src1_finished      (o_src1_finished      ),
  .o_src1_busy          (o_src1_busy          ),

  .o_src1_strobe        (o_src1_if_strobe     ),
  .i_src1_data          (i_src1_if_data       ),
  .i_src1_ready         (i_src1_if_ready      ),
  .o_src1_activate      (o_src1_if_activate   ),
  .i_src1_size          (i_src1_if_size       ),
  .i_src1_starved       (i_src1_if_starved    ),


  .i_src2_address       (i_src2_address       ),
  .i_src2_start         (i_src2_start         ),
  .o_src2_finished      (o_src2_finished      ),
  .o_src2_busy          (o_src2_busy          ),

  .o_src2_strobe        (o_src2_if_strobe     ),
  .i_src2_data          (i_src2_if_data       ),
  .i_src2_ready         (i_src2_if_ready      ),
  .o_src2_activate      (o_src2_if_activate   ),
  .i_src2_size          (i_src2_if_size       ),
  .i_src2_starved       (i_src2_if_starved    ),


  .i_src3_address       (i_src3_address       ),
  .i_src3_start         (i_src3_start         ),
  .o_src3_finished      (o_src3_finished      ),
  .o_src3_busy          (o_src3_busy          ),

  .o_src3_strobe        (o_src3_if_strobe     ),
  .i_src3_data          (i_src3_if_data       ),
  .i_src3_ready         (i_src3_if_ready      ),
  .o_src3_activate      (o_src3_if_activate   ),
  .i_src3_size          (i_src3_if_size       ),
  .i_src3_starved       (i_src3_if_starved    ),


  .o_snk0_address       (o_snk0_address       ),
  .o_snk0_valid         (o_snk0_valid         ),

  .o_snk0_strobe        (o_snk0_strobe        ),
  .i_snk0_ready         (i_snk0_ready         ),
  .o_snk0_activate      (o_snk0_activate      ),
  .i_snk0_size          (i_snk0_size          ),
  .o_snk0_data          (o_snk0_data          ),


  .o_snk1_address       (o_snk1_address       ),
  .o_snk1_valid         (o_snk1_valid         ),

  .o_snk1_strobe        (o_snk1_strobe        ),
  .i_snk1_ready         (i_snk1_ready         ),
  .o_snk1_activate      (o_snk1_activate      ),
  .i_snk1_size          (i_snk1_size          ),
  .o_snk1_data          (o_snk1_data          ),


  .o_snk2_address       (o_snk2_address       ),
  .o_snk2_valid         (o_snk2_valid         ),

  .o_snk2_strobe        (o_snk2_strobe        ),
  .i_snk2_ready         (i_snk2_ready         ),
  .o_snk2_activate      (o_snk2_activate      ),
  .i_snk2_size          (i_snk2_size          ),
  .o_snk2_data          (o_snk2_data          ),


  .o_snk3_address       (o_snk3_address       ),
  .o_snk3_valid         (o_snk3_valid         ),

  .o_snk3_strobe        (o_snk3_strobe        ),
  .i_snk3_ready         (i_snk3_ready         ),
  .o_snk3_activate      (o_snk3_activate      ),
  .i_snk3_size          (i_snk3_size          ),
  .o_snk3_data          (o_snk3_data          ),

  .cmd_src_address0     (cmd_src_address0     ),
  .cmd_dest_address0    (cmd_dest_address0    ),
  .cmd_count0           (cmd_count0           ),
  .cmd_flags0           (cmd_flags0           ),
  .cmd_cross_src_port0  (cmd_cross_src_port0  ),
  .cmd_cross_dest_port0 (cmd_cross_dest_port0 ),
  .cmd_next0            (cmd_next0            ),

  .cmd_src_address1     (cmd_src_address1     ),
  .cmd_dest_address1    (cmd_dest_address1    ),
  .cmd_count1           (cmd_count1           ),
  .cmd_flags1           (cmd_flags1           ),
  .cmd_cross_src_port1  (cmd_cross_src_port1  ),
  .cmd_cross_dest_port1 (cmd_cross_dest_port1 ),
  .cmd_next1            (cmd_next1            ),

  .cmd_src_address2     (cmd_src_address2     ),
  .cmd_dest_address2    (cmd_dest_address2    ),
  .cmd_count2           (cmd_count2           ),
  .cmd_flags2           (cmd_flags2           ),
  .cmd_cross_src_port2  (cmd_cross_src_port2  ),
  .cmd_cross_dest_port2 (cmd_cross_dest_port2 ),
  .cmd_next2            (cmd_next2            ),

  .cmd_src_address3     (cmd_src_address3     ),
  .cmd_dest_address3    (cmd_dest_address3    ),
  .cmd_count3           (cmd_count3           ),
  .cmd_flags3           (cmd_flags3           ),
  .cmd_cross_src_port3  (cmd_cross_src_port3  ),
  .cmd_cross_dest_port3 (cmd_cross_dest_port3 ),
  .cmd_next3            (cmd_next3            ),

  .cmd_src_address4     (cmd_src_address4     ),
  .cmd_dest_address4    (cmd_dest_address4    ),
  .cmd_count4           (cmd_count4           ),
  .cmd_flags4           (cmd_flags4           ),
  .cmd_cross_src_port4  (cmd_cross_src_port4  ),
  .cmd_cross_dest_port4 (cmd_cross_dest_port4 ),
  .cmd_next4            (cmd_next4            ),

  .cmd_src_address5     (cmd_src_address5     ),
  .cmd_dest_address5    (cmd_dest_address5    ),
  .cmd_count5           (cmd_count5           ),
  .cmd_flags5           (cmd_flags5           ),
  .cmd_cross_src_port5  (cmd_cross_src_port5  ),
  .cmd_cross_dest_port5 (cmd_cross_dest_port5 ),
  .cmd_next5            (cmd_next5            ),

  .cmd_src_address6     (cmd_src_address6     ),
  .cmd_dest_address6    (cmd_dest_address6    ),
  .cmd_count6           (cmd_count6           ),
  .cmd_flags6           (cmd_flags6           ),
  .cmd_cross_src_port6  (cmd_cross_src_port6  ),
  .cmd_cross_dest_port6 (cmd_cross_dest_port6 ),
  .cmd_next6            (cmd_next6            ),

  .cmd_src_address7     (cmd_src_address7     ),
  .cmd_dest_address7    (cmd_dest_address7    ),
  .cmd_count7           (cmd_count7           ),
  .cmd_flags7           (cmd_flags7           ),
  .cmd_cross_src_port7  (cmd_cross_src_port7  ),
  .cmd_cross_dest_port7 (cmd_cross_dest_port7 ),
  .cmd_next7            (cmd_next7            ),

  .wbm_o_we             (wbm_o_we             ),
  .wbm_o_stb            (wbm_o_stb            ),
  .wbm_o_cyc            (wbm_o_cyc            ),
  .wbm_o_sel            (wbm_o_sel            ),
  .wbm_o_adr            (wbm_o_adr            ),
  .wbm_o_dat            (wbm_o_dat            ),
  .wbm_i_dat            (wbm_i_dat            ),
  .wbm_i_ack            (wbm_i_ack            ),
  .wbm_i_int            (wbm_i_int            ),

  .interrupt            (interrupt            )
);

//Asynchronous Logic
assign  dma_enable    = control[0];
//Synchronous Logic

always @ (posedge clk) begin
  if (rst) begin
    o_wbs_dat                     <= 32'h0;
    o_wbs_ack                     <= 0;
    o_wbs_int                     <= 0;

    control                       <= 0;
    control[CNTL_DMA_ENABLE]      <= START_ENABLED;

    snk0_control                  <= 0;
    snk1_control                  <= 0;
    snk2_control                  <= 0;
    snk3_control                  <= 0;

    src0_control                  <= 0;
    src1_control                  <= 0;
    src2_control                  <= 0;
    src3_control                  <= 0;

    cmd_src_address0              <= 0;
    cmd_dest_address0             <= 0;
    cmd_count0                    <= 0;
    cmd_flags0                    <= 0;
    cmd_cross_src_port0           <= 0;
    cmd_cross_dest_port0          <= 0;
    cmd_next0                     <= 0;

    cmd_src_address1              <= 0;
    cmd_dest_address1             <= 0;
    cmd_count1                    <= 0;
    cmd_flags1                    <= 0;
    cmd_cross_src_port1           <= 0;
    cmd_cross_dest_port1          <= 0;
    cmd_next1                     <= 0;

    cmd_src_address2              <= 0;
    cmd_dest_address2             <= 0;
    cmd_count2                    <= 0;
    cmd_flags2                    <= 0;
    cmd_cross_src_port2           <= 0;
    cmd_cross_dest_port2          <= 0;
    cmd_next2                     <= 0;

    cmd_src_address3              <= 0;
    cmd_dest_address3             <= 0;
    cmd_count3                    <= 0;
    cmd_flags3                    <= 0;
    cmd_cross_src_port3           <= 0;
    cmd_cross_dest_port3          <= 0;
    cmd_next3                     <= 0;

    cmd_src_address4              <= 0;
    cmd_dest_address4             <= 0;
    cmd_count4                    <= 0;
    cmd_flags4                    <= 0;
    cmd_cross_src_port4           <= 0;
    cmd_cross_dest_port4          <= 0;
    cmd_next4                     <= 0;

    cmd_src_address5              <= 0;
    cmd_dest_address5             <= 0;
    cmd_count5                    <= 0;
    cmd_flags5                    <= 0;
    cmd_cross_src_port5           <= 0;
    cmd_cross_dest_port5          <= 0;
    cmd_next5                     <= 0;

    cmd_src_address6              <= 0;
    cmd_dest_address6             <= 0;
    cmd_count6                    <= 0;
    cmd_flags6                    <= 0;
    cmd_cross_src_port6           <= 0;
    cmd_cross_dest_port6          <= 0;
    cmd_next6                     <= 0;

    cmd_src_address7              <= 0;
    cmd_dest_address7             <= 0;
    cmd_count7                    <= 0;
    cmd_flags7                    <= 0;
    cmd_cross_src_port7           <= 0;
    cmd_cross_dest_port7          <= 0;
    cmd_next7                     <= 0;



  end
  else begin
    //when the master acks our ack, then put our ack down
    if (o_wbs_ack && ~i_wbs_stb)begin
      o_wbs_ack <= 0;
    end

    if (i_wbs_stb && i_wbs_cyc) begin
      //master is requesting somethign
      if (!o_wbs_ack) begin
        if (i_wbs_we) begin
          //write request
          case (i_wbs_adr)
            CONTROL_ADDR: begin
              control   <=  i_wbs_dat;
            end
            SNK0_CONTROL_ADDR: begin
              snk0_control   <=  i_wbs_dat;
            end
            SNK1_CONTROL_ADDR: begin
              snk1_control   <=  i_wbs_dat;
            end
            SNK2_CONTROL_ADDR: begin
              snk2_control   <=  i_wbs_dat;
            end
            SNK3_CONTROL_ADDR: begin
              snk3_control   <=  i_wbs_dat;
            end
            SRC0_CONTROL_ADDR: begin
              src0_control   <=  i_wbs_dat;
            end
            SRC1_CONTROL_ADDR: begin
              src1_control   <=  i_wbs_dat;
            end
            SRC2_CONTROL_ADDR: begin
              src2_control   <=  i_wbs_dat;
            end
            SRC3_CONTROL_ADDR: begin
              src3_control   <=  i_wbs_dat;
            end

            //Address 0
            PARAM_SRC_ADDR_LOW0: begin
              cmd_src_address0[31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH0: begin
              cmd_src_address0[63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW0: begin
              cmd_dest_address0[31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH0: begin
              cmd_dest_address0[63:32] <= i_wbs_dat;
            end
            PARAM_COUNT0: begin
              cmd_count0               <= i_wbs_dat;
            end
            PARAM_CNT0: begin
              cmd_flags0               <= i_wbs_dat[15:0];
              cmd_next0                <= i_wbs_dat[19:16];
              cmd_cross_src_port0      <= i_wbs_dat[23:20];
              cmd_cross_dest_port0     <= i_wbs_dat[27:24];
            end



            //Address 1
            PARAM_SRC_ADDR_LOW1: begin
              cmd_src_address1 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH1: begin
              cmd_src_address1 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW1: begin
              cmd_dest_address1 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH1: begin
              cmd_dest_address1 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT1: begin
              cmd_count1               <= i_wbs_dat;
            end
            PARAM_CNT1: begin
              cmd_flags1               <= i_wbs_dat[15:0];
              cmd_next1                <= i_wbs_dat[19:16];
              cmd_cross_src_port1      <= i_wbs_dat[23:20];
              cmd_cross_dest_port1     <= i_wbs_dat[27:24];
            end

            //Address 2
            PARAM_SRC_ADDR_LOW2: begin
              cmd_src_address2 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH2: begin
              cmd_src_address2 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW2: begin
              cmd_dest_address2 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH2: begin
              cmd_dest_address2 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT2: begin
              cmd_count2               <= i_wbs_dat;
            end
            PARAM_CNT2: begin
              cmd_flags2               <= i_wbs_dat[15:0];
              cmd_next2                <= i_wbs_dat[19:16];
              cmd_cross_src_port2      <= i_wbs_dat[23:20];
              cmd_cross_dest_port2     <= i_wbs_dat[27:24];
            end

            //Address 3
            PARAM_SRC_ADDR_LOW3: begin
              cmd_src_address3 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH3: begin
              cmd_src_address3 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW3: begin
              cmd_dest_address3 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH3: begin
              cmd_dest_address3 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT3: begin
              cmd_count3               <= i_wbs_dat;
            end
            PARAM_CNT3: begin
              cmd_flags3               <= i_wbs_dat[15:0];
              cmd_next3                <= i_wbs_dat[19:16];
              cmd_cross_src_port3      <= i_wbs_dat[23:20];
              cmd_cross_dest_port3     <= i_wbs_dat[27:24];
            end

            //Address 4
            PARAM_SRC_ADDR_LOW4: begin
              cmd_src_address4 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH4: begin
              cmd_src_address4 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW4: begin
              cmd_dest_address4 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH4: begin
              cmd_dest_address4 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT4: begin
              cmd_count4               <= i_wbs_dat;
            end
            PARAM_CNT4: begin
              cmd_flags4               <= i_wbs_dat[15:0];
              cmd_next4                <= i_wbs_dat[19:16];
              cmd_cross_src_port4      <= i_wbs_dat[23:20];
              cmd_cross_dest_port4     <= i_wbs_dat[27:24];
            end

            //Address 5
            PARAM_SRC_ADDR_LOW5: begin
              cmd_src_address5 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH5: begin
              cmd_src_address5 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW5: begin
              cmd_dest_address5 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH5: begin
              cmd_dest_address5 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT5: begin
              cmd_count5               <= i_wbs_dat;
            end
            PARAM_CNT5: begin
              cmd_flags5               <= i_wbs_dat[15:0];
              cmd_next5                <= i_wbs_dat[19:16];
              cmd_cross_src_port5      <= i_wbs_dat[23:20];
              cmd_cross_dest_port5     <= i_wbs_dat[27:24];
            end

            //Address 6
            PARAM_SRC_ADDR_LOW6: begin
              cmd_src_address6 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH6: begin
              cmd_src_address6 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW6: begin
              cmd_dest_address6 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH6: begin
              cmd_dest_address6 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT6: begin
              cmd_count6               <= i_wbs_dat;
            end
            PARAM_CNT6: begin
              cmd_flags6               <= i_wbs_dat[15:0];
              cmd_next6                <= i_wbs_dat[19:16];
              cmd_cross_src_port6      <= i_wbs_dat[23:20];
              cmd_cross_dest_port6     <= i_wbs_dat[27:24];
            end

            //Address 7
            PARAM_SRC_ADDR_LOW7: begin
              cmd_src_address7 [31:0]   <= i_wbs_dat;
            end
            PARAM_SRC_ADDR_HIDH7: begin
              cmd_src_address7 [63:32]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_LOW7: begin
              cmd_dest_address7 [31:0]  <= i_wbs_dat;
            end
            PARAM_DEST_ADDR_HIDH7: begin
              cmd_dest_address7 [63:32] <= i_wbs_dat;
            end
            PARAM_COUNT7: begin
              cmd_count7               <= i_wbs_dat;
            end
            PARAM_CNT7: begin
              cmd_flags7               <= i_wbs_dat[15:0];
              cmd_next7                <= i_wbs_dat[19:16];
              cmd_cross_src_port7      <= i_wbs_dat[23:20];
              cmd_cross_dest_port7     <= i_wbs_dat[27:24];
            end
            default: begin
            end
          endcase
        end
        else begin
          //read request
          case (i_wbs_adr)
            CONTROL_ADDR: begin
              o_wbs_dat <= control;
            end
            STATUS_ADDR: begin
              o_wbs_dat <= 32'h00000000;
            end
            SOURCE_COUNT_ADDR: begin
              o_wbs_dat <= `SOURCE_COUNT;
            end
            SINK_COUNT_ADDR: begin
              o_wbs_dat <= `SINK_COUNT;
            end
            WB_BUS_COUNT_ADDR: begin
              o_wbs_dat <= `WB_MASTER_COUNT;
            end
             SNK0_CONTROL_ADDR: begin
              o_wbs_dat <= snk0_status;
            end
             SNK1_CONTROL_ADDR: begin
              o_wbs_dat <= snk1_status;
            end
             SNK2_CONTROL_ADDR: begin
              o_wbs_dat <= snk2_status;
            end
             SNK0_CONTROL_ADDR: begin
              o_wbs_dat <= snk3_status;
            end
             SRC0_CONTROL_ADDR: begin
              o_wbs_dat <= src0_status;
            end
             SRC1_CONTROL_ADDR: begin
              o_wbs_dat <= src1_status;
            end
             SRC2_CONTROL_ADDR: begin
              o_wbs_dat <= src2_status;
            end
             SRC3_CONTROL_ADDR: begin
              o_wbs_dat <= src3_status;
            end

            //Address 0
            PARAM_SRC_ADDR_LOW0: begin
              o_wbs_dat  <=  cmd_src_address0[31:0];
            end
            PARAM_SRC_ADDR_HIDH0: begin
              o_wbs_dat  <=  cmd_src_address0[63:32];
            end
            PARAM_DEST_ADDR_LOW0: begin
              o_wbs_dat  <=  cmd_dest_address0[31:0];
            end
            PARAM_DEST_ADDR_HIDH0: begin
              o_wbs_dat  <=  cmd_dest_address0[63:32];
            end
            PARAM_COUNT0: begin
              o_wbs_dat  <=  cmd_count0;
            end
            PARAM_CNT0: begin
              o_wbs_dat[15:0]     <=  cmd_flags0;
              o_wbs_dat[19:16]    <=  cmd_next0;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port0;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port0;
            end
            //Address 1
            PARAM_SRC_ADDR_LOW1: begin
              o_wbs_dat  <=  cmd_src_address1 [31:0];
            end
            PARAM_SRC_ADDR_HIDH1: begin
              o_wbs_dat  <=  cmd_src_address1 [63:32];
            end
            PARAM_DEST_ADDR_LOW1: begin
              o_wbs_dat  <=  cmd_dest_address1 [31:0];
            end
            PARAM_DEST_ADDR_HIDH1: begin
              o_wbs_dat  <=  cmd_dest_address1 [63:32];
            end
            PARAM_COUNT1: begin
              o_wbs_dat  <=  cmd_count1;
            end
            PARAM_CNT1: begin
              o_wbs_dat[15:0]     <=  cmd_flags1;
              o_wbs_dat[19:16]    <=  cmd_next1;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port1;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port1;
            end
            //Address 2
            PARAM_SRC_ADDR_LOW2: begin
              o_wbs_dat  <=  cmd_src_address2 [31:0];
            end
            PARAM_SRC_ADDR_HIDH2: begin
              o_wbs_dat  <=  cmd_src_address2 [63:32];
            end
            PARAM_DEST_ADDR_LOW2: begin
              o_wbs_dat  <=  cmd_dest_address2 [31:0];
            end
            PARAM_DEST_ADDR_HIDH2: begin
              o_wbs_dat  <=  cmd_dest_address2 [63:32];
            end
            PARAM_COUNT2: begin
              o_wbs_dat  <=  cmd_count2;
            end
            PARAM_CNT2: begin
              o_wbs_dat[15:0]     <=  cmd_flags2;
              o_wbs_dat[19:16]    <=  cmd_next2;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port2;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port2;
            end
            //Address 3
            PARAM_SRC_ADDR_LOW3: begin
              o_wbs_dat  <=  cmd_src_address3 [31:0];
            end
            PARAM_SRC_ADDR_HIDH3: begin
              o_wbs_dat  <=  cmd_src_address3 [63:32];
            end
            PARAM_DEST_ADDR_LOW3: begin
              o_wbs_dat  <=  cmd_dest_address3 [31:0];
            end
            PARAM_DEST_ADDR_HIDH3: begin
              o_wbs_dat  <=  cmd_dest_address3 [63:32];
            end
            PARAM_COUNT3: begin
              o_wbs_dat  <=  cmd_count3;
            end
            PARAM_CNT3: begin
              o_wbs_dat[15:0]     <=  cmd_flags3;
              o_wbs_dat[19:16]    <=  cmd_next3;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port3;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port3;
            end
            //Address 4
            PARAM_SRC_ADDR_LOW4: begin
              o_wbs_dat  <=  cmd_src_address4 [31:0];
            end
            PARAM_SRC_ADDR_HIDH4: begin
              o_wbs_dat  <=  cmd_src_address4 [63:32];
            end
            PARAM_DEST_ADDR_LOW4: begin
              o_wbs_dat  <=  cmd_dest_address4 [31:0];
            end
            PARAM_DEST_ADDR_HIDH4: begin
              o_wbs_dat  <=  cmd_dest_address4 [63:32];
            end
            PARAM_COUNT4: begin
              o_wbs_dat  <=  cmd_count4;
            end
            PARAM_CNT4: begin
              o_wbs_dat[15:0]     <=  cmd_flags4;
              o_wbs_dat[19:16]    <=  cmd_next4;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port4;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port4;
            end
            //Address 5
            PARAM_SRC_ADDR_LOW5: begin
              o_wbs_dat  <=  cmd_src_address5 [31:0];
            end
            PARAM_SRC_ADDR_HIDH5: begin
              o_wbs_dat  <=  cmd_src_address5 [63:32];
            end
            PARAM_DEST_ADDR_LOW5: begin
              o_wbs_dat  <=  cmd_dest_address5 [31:0];
            end
            PARAM_DEST_ADDR_HIDH5: begin
              o_wbs_dat  <=  cmd_dest_address5 [63:32];
            end
            PARAM_COUNT5: begin
              o_wbs_dat  <=  cmd_count5;
            end
            PARAM_CNT5: begin
              o_wbs_dat[15:0]     <=  cmd_flags5;
              o_wbs_dat[19:16]    <=  cmd_next5;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port5;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port5;
            end
            //Address 6
            PARAM_SRC_ADDR_LOW6: begin
              o_wbs_dat  <=  cmd_src_address6 [31:0];
            end
            PARAM_SRC_ADDR_HIDH6: begin
              o_wbs_dat  <=  cmd_src_address6 [63:32];
            end
            PARAM_DEST_ADDR_LOW6: begin
              o_wbs_dat  <=  cmd_dest_address6 [31:0];
            end
            PARAM_DEST_ADDR_HIDH6: begin
              o_wbs_dat  <=  cmd_dest_address6 [63:32];
            end
            PARAM_COUNT6: begin
              o_wbs_dat  <=  cmd_count6;
            end
            PARAM_CNT6: begin
              o_wbs_dat[15:0]     <=  cmd_flags6;
              o_wbs_dat[19:16]    <=  cmd_next6;
              o_wbs_dat[23:20]    <=  cmd_cross_src_port6;
              o_wbs_dat[27:24]    <=  cmd_cross_dest_port6;
            end
            //Address 7
            PARAM_SRC_ADDR_LOW7: begin
              o_wbs_dat  <=  cmd_src_address7 [31:0];
            end
            PARAM_SRC_ADDR_HIDH7: begin
              o_wbs_dat  <=  cmd_src_address7 [63:32];
            end
            PARAM_DEST_ADDR_LOW7: begin
              o_wbs_dat  <=  cmd_dest_address7 [31:0];
            end
            PARAM_DEST_ADDR_HIDH7: begin
              o_wbs_dat  <=  cmd_dest_address7 [63:32];
            end
            PARAM_COUNT7: begin
              o_wbs_dat  <=  cmd_count7;
            end
            PARAM_CNT7: begin
              o_wbs_dat[15:0]   <=  cmd_flags7;
              o_wbs_dat[19:16]  <=  cmd_next7;
              o_wbs_dat[23:20]  <=  cmd_cross_src_port7;
              o_wbs_dat[27:24]  <=  cmd_cross_dest_port7;
            end
            default: begin
            end
          endcase
        end
      o_wbs_ack <= 1;
    end
    end
  end
end

endmodule
