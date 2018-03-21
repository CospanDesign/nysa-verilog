/*
Distributed under the MIT license.
Copyright (c) 2018 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Author:
 * Description:
 *
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

`timescale 1ps / 1ps

`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   (x <= 32)    ? 5 :  \
   (x <= 64)    ? 6 :  \
   (x <= 128)   ? 7 :  \
   (x <= 256)   ? 8 :  \
   (x <= 512)   ? 9 :  \
   (x <= 1024)  ? 10 : \
   (x <= 2048)  ? 11 : \
   (x <= 4096)  ? 12 : \
   -1



module axis_to_bram #(
  parameter     BRAM_DATA_WIDTH       = 32,
  parameter     BRAM_ADDR_WIDTH       = 10,
  parameter     AXI_DATA_WIDTH       = 32,
  parameter     AXI_STROBE_WIDTH     = (AXI_DATA_WIDTH >> 3),
  parameter     AXI_MAX_BURST_LENGTH = 256,
  parameter     AXI_BRAM_BYTE_DEPTH  = `CLOG2(AXI_MAX_BURST_LENGTH)
)(
  input                                      clk,
  input                                      rst,

  //Command
  input       [AXI_BRAM_BYTE_DEPTH - 1: 0]   i_byte_read_size,
  input                                      i_en,
  output  reg                                o_ack,

  //BRAM Interface
  input       [BRAM_ADDR_WIDTH - 1: 0]       i_bram_size,
  output  reg [BRAM_DATA_WIDTH - 1: 0]       o_bram_data,
  output  reg [BRAM_ADDR_WIDTH - 1: 0]       o_bram_addr,
  output  reg                                o_bram_wea,

  //AXIS Interface
  input                                      i_axis_valid,
  output  reg                                o_axis_ready,
  input       [AXI_DATA_WIDTH - 1: 0]        i_axis_data,
  input       [AXI_STROBE_WIDTH - 1: 0]      i_axis_strobe

);
//local parameters
localparam                        AXI_BYTE_WIDTH = `CLOG2(AXI_DATA_WIDTH);
localparam                        BRAM_BYTE_WIDTH = `CLOG2(BRAM_DATA_WIDTH);
localparam                        IDLE            = 0;
localparam                        READ_AXI_DATA  = 1;
localparam                        BRAM_WRITE      = 2;
localparam                        READ_FIN        = 3;

localparam                        AB_RATIO    = (AXI_DATA_WIDTH / BRAM_DATA_WIDTH);
localparam                        BA_RATIO    = (BRAM_DATA_WIDTH / AXI_DATA_WIDTH);

//registes/wires
reg [3:0]                           state;
reg   [AXI_BRAM_BYTE_DEPTH - 1: 0]  r_byte_count;
//Account for byte sizes for 4096
wire  [9: 0]                        w_bram_inc;
wire  [9: 0]                        w_axis_inc;

//submodules
//asynchronous logic
assign                              w_bram_inc    = BRAM_BYTE_WIDTH;
assign                              w_axis_inc    = AXI_BYTE_WIDTH;

//synchronous logic
/*****************************************************************************/
if (BRAM_DATA_WIDTH == AXI_DATA_WIDTH) begin

always @ (posedge clk) begin
  o_ack         <=  0;
  o_bram_wea    <=  0;
  o_axis_ready  <=  0;
  if (rst) begin
    o_bram_addr <=  0;
    state       <=  IDLE;
  end
  else begin
    case (state)
      IDLE: begin
        r_byte_count    <=  0;
        o_bram_addr     <=  0;
        if (i_en) begin
          state         <=  BRAM_WRITE;
        end
      end
      BRAM_WRITE: begin
        if ((r_byte_count + w_axis_inc) >= i_byte_read_size) begin
          state         <=  READ_FIN;
        end
        else begin
          o_axis_ready  <=  1;
          if (i_axis_valid) begin
            o_bram_data <=  i_axis_data;
            o_bram_addr <=  o_bram_addr + 1;
            r_byte_count<=  r_byte_count + w_axis_inc;
          end
        end
      end
      READ_FIN: begin
        o_ack         <=  1;
        if (!o_ack) begin
          state       <=  IDLE;
        end
      end
    endcase
  end
end
end
/*****************************************************************************/
else if (BRAM_DATA_WIDTH < AXI_DATA_WIDTH) begin
reg   [AB_RATIO - 1: 0]         r_ab_count;
wire  [BRAM_DATA_WIDTH - 1: 0]  w_ab_data[0:AB_RATIO];

genvar gd;
for (gd = 0; gd < AB_RATIO; gd = gd + 1) begin: BRAM_DATA_GEN
  assign  w_ab_data[gd] =  i_axis_data[((gd + 1) * BRAM_DATA_WIDTH) - 1: (gd * BRAM_DATA_WIDTH)];
end

always @ (posedge clk) begin
  o_ack           <=  0;
  o_bram_wea      <=  0;
  o_axis_ready    <=  0;
  if (rst) begin
    r_byte_count  <=  0;
    r_ab_count    <=  0;
    o_bram_addr   <=  0;
    o_axis_ready  <=  0;
    state         <=  IDLE;
  end
  else begin
    case (state)
      IDLE: begin
        r_byte_count    <=  0;
        o_bram_addr     <=  0;
        if (i_en) begin
          o_axis_ready  <=  1;
          state         <=  READ_AXI_DATA;
        end
      end
      READ_AXI_DATA: begin
        if (i_axis_valid) begin
          o_axis_ready  <=  0;
          o_bram_data   <=  w_ab_data[r_ab_count];
          r_ab_count    <=  r_ab_count + 1;
          o_bram_addr   <=  o_bram_addr + 1;
          r_byte_count  <=  r_byte_count + w_bram_inc;
          o_bram_wea    <=  1;
          state         <=  BRAM_WRITE;
        end
      end
      BRAM_WRITE: begin
        o_bram_data   <=  w_ab_data[r_ab_count];
        r_ab_count    <=  r_ab_count + 1;
        o_bram_addr   <=  o_bram_addr + 1;
        r_byte_count  <=  r_byte_count + w_bram_inc;
        o_bram_wea    <=  1;
        if ((r_byte_count + w_bram_inc) >= i_byte_read_size) begin
          state       <=  READ_FIN;
        end
        else if ((r_ab_count + 1) >= AB_RATIO) begin
          state       <=  READ_AXI_DATA;
        end
      end
      READ_FIN: begin
        o_ack         <=  1;
        if (!o_ack) begin
          state       <=  IDLE;
        end
      end
    endcase
  end
end
end
/*****************************************************************************/
else begin //BRAM_DATA_WIDTH > AXI_DATA_WIDTH

reg   [BA_RATIO - 1: 0]         r_ba_count;
wire  [AXI_DATA_WIDTH - 1: 0]  r_ba_data[0:BA_RATIO];

genvar gc;
for (gc = 0; gc < BA_RATIO; gc = gc + 1) begin
  assign  w_bram_data[((gc + 1) * BRAM_DATA_WIDTH) - 1: (gc * BRAM_DATA_WIDTH)] = r_ba_data[gc];
end

always @ (posedge clk) begin
  o_ack           <=  0;
  o_bram_wea      <=  0;
  if (rst) begin
    r_ba_count    <=  0;
    r_byte_count  <=  0;
    state         <=  IDLE;
  end
  else begin
    case (state)
      IDLE: begin
        r_byte_count    <=  0;
        o_bram_addr     <=  0;
        if (i_en) begin
          state         <=  READ_AXI_DATA;
          o_axis_ready  <=  1;
        end
      end
      READ_AXI_DATA: begin
        o_axis_ready    <=  1;
        if (i_axis_valid) begin
          r_ba_data[r_ba_count] <=  i_axis_data;
          r_ba_count            <=  r_ba_count + 1;
          r_byte_count          <=  r_byte_count + w_axis_inc;
          if ((r_ba_count + 1) >= BA_RATIO) begin
            o_bram_wea          <=  1;
            o_bram_addr         <=  o_bram_addr + 1;
            r_ba_count          <=  0; 
          end
          if ((r_byte_count + w_axis_inc) >= r_byte_count) begin
            state               <=  READ_FIN;
          end
        end
      end
      READ_FIN: begin
        o_ack         <=  1;
        if (!o_ack) begin
          state       <=  IDLE;
        end
      end
    endcase
  end
end
end

endmodule
