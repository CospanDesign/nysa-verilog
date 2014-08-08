//device_rom_table.v

/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

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
  META DATA

  DRT_ID:0004C594
  version info 0.0.04
  ID: C594
*/


/*
 *use defparam in the instantiating module in order to set the
 * number of items in the ROM
 * defparam DRT_NUM_OF_DEVICES = 2;
 */

`timescale 1 ns/1 ps

`include "project_defines.v"
//`define DRT_NUM_OF_DEVICES 1
`define DRT_SIZE_OF_HEADER  8
`define DRT_SIZE_OF_DEV   8


module device_rom_table (
input               clk,
input               rst,

//wishbone slave signals
input               i_wbs_we,
input               i_wbs_stb,
input               i_wbs_cyc,
input       [3:0]   i_wbs_sel,
input       [31:0]  i_wbs_adr,
input       [31:0]  i_wbs_dat,
output reg  [31:0]  o_wbs_dat,
output reg          o_wbs_ack,
output reg          o_wbs_int
);

//parameter DRT_NUM_OF_DEVICES = 1;

parameter DRT_ID_ADR      = 32'h00000000;
parameter DRT_NUM_DEV_ADR = 32'h00000001;
parameter DRT_RFU_1_ADR   = 32'h00000002;
parameter DRT_RFU_2_ADR   = 32'h00000003;
parameter DRT_RFU_3_ADR   = 32'h00000004;
parameter DRT_RFU_4_ADR   = 32'h00000005;
parameter DRT_RFU_5_ADR   = 32'h00000006;
parameter DRT_RFU_6_ADR   = 32'h00000007;

//parameters that go into the ROM
parameter DRT_ID          = 16'h0001;
parameter DRT_VERSION     = 16'h0001;
parameter DRT_RFU_1       = 32'h00000000;
parameter DRT_RFU_2       = 32'h00000000;
parameter DRT_RFU_3       = 32'h00000000;
parameter DRT_RFU_4       = 32'h00000000;
parameter DRT_RFU_5       = 32'h00000000;
parameter DRT_RFU_6       = 32'h00000000;
parameter DRT_RFU_7       = 32'h00000000;

parameter DRT_DEV_OFF_ADR = 32'h00000004;
parameter DRT_DEV_SIZE    = 4'h4;

parameter DEV_ID_OFF      = 4'h0;
parameter DEV_INFO_OFF    = 4'h1;
parameter DEV_MEM_OFF_OFF = 4'h2;
parameter DEV_SIZE_OFF    = 4'h3;

//registers
parameter DRT_SIZE        = `DRT_SIZE_OF_HEADER + (`DRT_NUM_OF_DEVICES * `DRT_SIZE_OF_DEV);
//reg [DRT_SIZE:0][31:0] drt;
reg [31:0] drt [(DRT_SIZE - 1):0];

initial begin
  $readmemh(`DRT_INPUT_FILE, drt, 0, DRT_SIZE - 1);
end

always @ (posedge clk) begin
  if (rst) begin
    o_wbs_dat <= 32'h0;
    o_wbs_ack <= 0;
    o_wbs_int <= 0;
  end
  else begin
    //when the master acks our ack, then put our ack down
    if (o_wbs_ack & ~ i_wbs_stb)begin
      o_wbs_ack <= 0;
    end
    if (i_wbs_stb & i_wbs_cyc) begin
      //master is requesting somethign
      if (i_wbs_we) begin
        //ROMS can't be written to
      end
      else begin
        //read request
        o_wbs_dat <= drt[i_wbs_adr];
      end
      o_wbs_ack <= 1;
    end
  end
end
endmodule
