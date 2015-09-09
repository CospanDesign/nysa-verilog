/*
Distributed under the MIT license.
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



//sd_host_platform_cocotb.v
`timescale 1 ns/1 ps


module sd_host_platform_cocotb (

input               clk,
input               rst,

//SD Stack Interface
output  reg         o_locked,
output  reg         o_out_clk,
output              o_out_clk_x2,

input               i_sd_cmd_dir,
output              o_sd_cmd_in,
input               i_sd_cmd_out,


input               i_sd_data_dir,
output        [7:0] o_sd_data_in,
input         [7:0] i_sd_data_out,

output  reg         o_phy_out_clk,
inout               io_phy_sd_cmd,
inout         [3:0] io_phy_sd_data

);

reg           [7:0] lock_count;
wire                pos_edge_clk;
reg                 prev_phy_clk;
wire          [3:0] data_out;


assign  o_out_clk_x2 = clk;
assign  pos_edge_clk  = (clk & !prev_phy_clk);

assign  io_phy_sd_cmd = i_sd_cmd_dir  ? i_sd_cmd_out : 1'hZ;
assign  o_sd_cmd_in   = io_phy_sd_cmd;

assign  io_phy_sd_data= i_sd_data_dir ? data_out: 8'hZ;
assign  o_sd_data_in  = io_phy_sd_data;


assign  data_out      = pos_edge_clk ?  { i_sd_data_out[0],
                                          i_sd_data_out[2],
                                          i_sd_data_out[4],
                                          i_sd_data_out[6]} :
                                        { i_sd_data_out[1],
                                          i_sd_data_out[3],
                                          i_sd_data_out[5],
                                          i_sd_data_out[7]};
assign  o_sd_data_in  = pos_edge_clk ?  { io_phy_sd_data[0],
                                          io_phy_sd_data[2],
                                          io_phy_sd_data[4],
                                          io_phy_sd_data[6]} :
                                        { io_phy_sd_data[1],
                                          io_phy_sd_data[3],
                                          io_phy_sd_data[5],
                                          io_phy_sd_data[7]};



always @ (posedge clk) begin
  if (rst) begin
    o_out_clk     <=  0;
    o_phy_out_clk <=  0;
    lock_count    <=  0;
    o_locked      <=  0;
    prev_phy_clk  <=  0;
  end
  else begin
    prev_phy_clk  <=  o_phy_out_clk;
    o_out_clk     <= ~o_out_clk;
    o_phy_out_clk <= ~o_phy_out_clk;
    if (lock_count < 4'hF) begin
      lock_count  <=  lock_count + 1;
    end
    else begin
      o_locked    <=  1;
    end

  end
end
endmodule

