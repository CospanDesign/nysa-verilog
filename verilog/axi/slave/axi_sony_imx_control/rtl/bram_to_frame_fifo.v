/*
Distributed under the MIT license.
Copyright (c) 2017 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Author: David McCoy
 * Description: Reads in data from the cam_in_to_bram
 *  Translates data from a BRAM to an AXI Stream FIFO
 *    The FIFO is needed because the stream requires data
 *    to be available instantly, BRAM doesn't allow this.
 *  Removes vertical start padding
 *  Removes vertical end padding
 *  Removes horizontal start padding
 *  Removes horizontal end padding
 *
 *  XXX: THIS HAS BEEN DESIGNED TO WORK WITH 8 LANES ONLY!!!
 *
 * TODO:
 *  Configure Start of Frame
 *    Use the i_vsync positive edge transition to determine when a frame is started
 *  Figure out how to remove initial vertical padding
 *  Figure out how to remove end vertial padding
 *  Figure out how to remove initial horizontal padding
 *  Figure out how to remove end horizontal padding
 *  Figure out 128 VS 64 Stream Depth
 *  Figure out how to handle offset of 4 on the padding
 *
 * Changes:     Who?    What?
 *  03/12/2018  DFM     Initial Commit
 *
 */

`timescale 1ps / 1ps

module bram_to_frame_fifo #(
  parameter                 AXIS_DATA_WIDTH = 64,
  parameter                 BRAM_DATA_DEPTH = 1024
)(
  input                                 clk,
  input                                 rst,

  input                                 i_vsync,

  input                                 i_bram_data_valid,
  input       [AXIS_DATA_WIDTH - 1: 0]  i_bram_data,
  input       [BRAM_DATA_DEPTH - 1: 0]  i_bram_size,
  output  reg [BRAM_DATA_DEPTH - 1: 0]  o_bram_addr,

  output                                o_frame_fifo_ready,
  input                                 i_frame_fifo_next_stb,
  output  reg                           o_frame_fifo_sof,
  output                                o_frame_fifo_last,
  output      [AXIS_DATA_WIDTH - 1: 0]  o_frame_fifo_data,

  input       [15:0]                    i_frame_width,
  input       [15:0]                    i_frame_height,
  input       [7:0]                     i_pre_vblank,
  input       [7:0]                     i_pre_hblank,
  input       [7:0]                     i_post_vblank,
  input       [7:0]                     i_post_hblank
);
//local parameters
localparam     PARAM1  = 32'h00000000;

localparam  IDLE        = 0;

localparam  BRAM_START  = 1;
localparam  BRAM_DELAY  = 2;
localparam  BRAM_READ   = 3;
localparam  BRAM_FIN    = 4;


localparam  DECOUPLE_DEPTH = 4;
localparam  DECOUPLE_COUNT_SIZE = 2;

//registes/wires
reg   [3:0]             state;
reg   [3:0]             r_sr_vsync;
wire                    w_posedge_vsync;
reg                     r_frame_fifo_enable;

reg   [15:0]            r_hcount;
reg   [15:0]            r_vcount;

wire                    w_pre_vpad;
wire                    w_post_vpad;
wire                    w_frame_finished;

wire                    w_pre_hpad;
wire                    w_post_hpad;

wire                    w_half_pad;


reg   [DECOUPLE_COUNT_SIZE - 1:0]   dstart;
reg   [DECOUPLE_COUNT_SIZE - 1:0]   dend;
reg   [AXIS_DATA_WIDTH - 1:0]       dframe_fifo[0:DECOUPLE_DEPTH - 1];  //Decoupling FIFO
reg   [AXIS_DATA_WIDTH - 1:0]       r_prev_data;  //Used for 1/2 pre/post blanks

wire                                dempty;
wire                                dfull;
wire                                dalmost_full;
wire                                dlast;
wire  [AXIS_DATA_WIDTH - 1:0]       dcurrent_data;



//submodules
//asynchronous logic

assign  w_pre_vpad            = (r_vcount < i_pre_vblank);
assign  w_pre_hpad            = (r_hcount < ((1 << i_pre_hblank) - 1));
assign  w_post_hpad           = (w_half_pad) ? (r_hcount > (i_frame_width + 8)) : (r_hcount > (i_frame_width + i_pre_hblank - i_post_hblank + 8));
assign  w_half_pad            = (i_pre_hblank == 4);
assign  w_frame_finished      = (r_vcount >= (i_frame_height + i_pre_vblank));

assign  dempty                = (dstart == dend);
assign  dfull                 = (dend == (1 << DECOUPLE_COUNT_SIZE) - 1) ?  (dstart == 0) : ((dend + 1) == dstart);
assign  dalmost_full          = (dend == (1 << DECOUPLE_COUNT_SIZE) - 2) ?  (dstart == 0) : (dend == (1 << DECOUPLE_COUNT_SIZE) - 1) ?  (dstart == 1) : ((dend + 2) == dstart);
assign  dlast                 = (dstart == (1 << DECOUPLE_COUNT_SIZE) - 1) ? (dend   == 0) : ((dstart + 1) == dend);
assign  o_frame_fifo_data     = dframe_fifo[dstart];
assign  o_frame_fifo_ready    = !dempty && r_frame_fifo_enable; //r_frame_fifo_enable to stop FIFO fill oscillation
assign  o_frame_fifo_last     = (dlast && (state == BRAM_FIN));
assign  dcurrent_data         = dframe_fifo[dstart];

//Edges??
assign  w_posedge_vsync   = (r_sr_vsync   == 4'b0011);

//synchronous logic
integer i;
always @ (posedge clk) begin
  if (rst) begin
    state                 <=  IDLE;
    r_hcount              <=  0;
    r_vcount              <=  0;

    o_bram_addr           <=  0;
    dstart                <=  0;
    dend                  <=  0;
    r_prev_data           <=  0;
    o_frame_fifo_sof      <=  0;
    r_frame_fifo_enable   <=  0;
    for (i = 0; i < DECOUPLE_DEPTH; i = i + 1) begin
      dframe_fifo[i]            <=  0;
    end

    r_sr_vsync            <=  0;
  end
  else begin

    case (state)
      IDLE: begin
        o_bram_addr         <=  0;
        dstart              <=  0;
        dend                <=  0;
        r_hcount            <=  0;
        r_frame_fifo_enable <=  0;
        if (i_bram_data_valid) begin
          if (w_pre_vpad || (r_vcount >= (i_frame_height + i_pre_vblank + i_post_vblank) || w_frame_finished)) begin
            state     <=  BRAM_FIN;
          end
          else begin
            state     <=  BRAM_START;
          end
        end
      end
      BRAM_START: begin
        //If the FIFO is not full request data from BRAM
        if (dfull) begin
          r_frame_fifo_enable <=  1;
        end
        if (w_pre_hpad) begin
          //Definetly not full
          r_prev_data   <=  i_bram_data;
          o_bram_addr   <=  o_bram_addr + 1;
          r_hcount      <=  r_hcount + 8;
          state         <=  BRAM_DELAY;
        end
        else if (w_post_hpad) begin
          state         <=  BRAM_FIN;
        end
        else if (!dfull) begin
          r_prev_data   <=  i_bram_data;
          if (w_half_pad) begin
            dframe_fifo[dend] <=  {i_bram_data[31:0], r_prev_data[63:32]};
          end
          else begin
            dframe_fifo[dend] <=  i_bram_data;
          end
          dend          <=  dend + 1;
          o_bram_addr   <=  o_bram_addr + 1;
          r_hcount      <=  r_hcount + 8;
          if ((o_bram_addr + 1) >= i_bram_size) begin
            state  <=  BRAM_FIN;
          end
          else begin
            state  <=  BRAM_DELAY;
          end
        end
      end
      BRAM_DELAY: begin
        if (o_bram_addr >= i_bram_size) begin
            state  <=  BRAM_FIN;
        end
        else if (w_post_hpad) begin
            state  <=  BRAM_FIN;
        end
        else if (dfull) begin
          state    <=  BRAM_START;
        end
        else begin
          state         <=  BRAM_READ;
          r_prev_data   <=  i_bram_data;
          o_bram_addr   <=  o_bram_addr + 1;
          r_hcount      <=  r_hcount + 8;
        end
      end
      BRAM_READ: begin
        if (w_half_pad) begin
          dframe_fifo[dend] <=  {i_bram_data[(AXIS_DATA_WIDTH / 2) - 1:0], r_prev_data[AXIS_DATA_WIDTH - 1:(AXIS_DATA_WIDTH / 2)]};
        end
        else begin
          dframe_fifo[dend] <=  i_bram_data;
        end
        dend            <=  dend + 1;

        if (o_bram_addr > i_bram_size) begin
          state  <=  BRAM_FIN;
        end
        else if (w_post_hpad) begin
          state  <=  BRAM_FIN;
        end
        else if (dfull || dalmost_full) begin
          state  <=  BRAM_START;
        end
        else begin
          r_prev_data   <=  i_bram_data;
          o_bram_addr   <=  o_bram_addr + 1;
          r_hcount      <=  r_hcount + 8;
        end
      end
      BRAM_FIN: begin
        if (!i_bram_data_valid) begin
          state         <=  IDLE;
          r_frame_fifo_enable <=  0;
          r_vcount      <= r_vcount + 1;
        end
      end
    endcase

    if (i_frame_fifo_next_stb) begin
      o_frame_fifo_sof    <=  0;
      dstart              <=  dstart + 1;
    end

    if (w_posedge_vsync) begin
      r_vcount            <=  0;
      o_frame_fifo_sof    <=  1;
    end

    r_sr_vsync            <=  {r_sr_vsync[2:0], i_vsync};
  end
end



endmodule
