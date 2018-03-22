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
 * Author: Dave McCoy (dave.mccoy@cospandesign.com)
 * Description: Reads from axi stream fifo and generates axi_stream
 *
 * Changes:     Who?  What?
 *  03/01/2018: DFM   Initial check in.
 */

`timescale 1ps / 1ps

module frame_fifo_to_axi_stream #(
  parameter                                     AXIS_DATA_WIDTH     = 32,
  parameter                                     AXIS_STROBE_WIDTH   = AXIS_DATA_WIDTH / 8,
  parameter                                     USER_DEPTH          = 1
)(
  input                                         clk,
  input                                         rst,

  //Ping Poing FIFO Read Interface
  input                                         i_frame_fifo_ready,
  output                                        o_frame_fifo_next_stb,
  input                                         i_frame_fifo_sof,
  input                                         i_frame_fifo_last,
  input       [AXIS_DATA_WIDTH - 1: 0]          i_frame_fifo_data,

  //AXI Stream Output
  output      [USER_DEPTH - 1:0]                o_axis_user,
  input                                         i_axis_ready,
  output      [AXIS_DATA_WIDTH - 1:0]           o_axis_data,
  output                                        o_axis_last,
  output                                        o_axis_valid
);

//Functions
//local parameters
//submodules
//asynchronous logic

assign  o_axis_user               = i_frame_fifo_sof;
assign  o_axis_last               = i_frame_fifo_last;
assign  o_axis_valid              = i_frame_fifo_ready;
assign  o_frame_fifo_next_stb     = (o_axis_valid && i_axis_ready);
assign  o_axis_data               = i_frame_fifo_data;

//synchronous logic
endmodule
