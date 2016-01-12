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
 * Author:
 * Description:
 *
 * Changes:
 */

module adapter_ppfifo_2_axi_stream (
  input                     rst,

  //Ping Poing FIFO Read Interface
  input                     i_ppfifo_clk,
  input                     i_ppfifo_rdy,
  output  reg               o_ppfifo_act,
  input       [23:0]        i_ppfifo_size,
  input       [31:0]        i_ppfifo_data,
  output  reg               o_ppfifo_stb,

  //AXI Stream Output
  output                    o_axi_clk,
  input                     i_axi_ready,
  output  reg [31:0]        o_axi_data,
  output      [3:0]         o_axi_keep,
  output  reg               o_axi_last,
  output  reg               o_axi_valid
);

//local parameters
localparam      IDLE        = 0;
localparam      READY       = 1;
localparam      RELEASE     = 2;

//registes/wires
wire                      clk;
reg     [23:0]            r_count;
reg     [3:0]             state;
//submodules
//asynchronous logic
assign  o_axi_clk       = i_ppfifo_clk;
assign  clk             = i_ppfifo_clk;
assign  o_axi_keep      = 4'b1111;
//synchronous logic

always @ (posedge clk) begin
  o_ppfifo_stb          <=  0;
  o_axi_valid           <=  0;
  o_axi_last            <=  0;

  if (rst) begin
    state               <=  IDLE;
    o_axi_data          <=  0;
    o_ppfifo_act        <=  0;
    r_count             <=  0;
  end
  else begin
    case (state)
      IDLE: begin
        o_ppfifo_act    <=  0;
        if (i_ppfifo_rdy && !o_ppfifo_act) begin
          r_count       <=  0;
          o_ppfifo_act  <=  1;
          state         <=  READY;
        end
      end
      READY: begin
        //Wait for the AXI Stream output to be ready
        if (i_axi_ready) begin
          //Axi Bus is ready, PPFIFO is ready, send data
          o_axi_valid     <=  1;
          o_axi_data      <=  i_ppfifo_data;

          if (r_count >= (i_ppfifo_size - 1)) begin
            //No more data within the PPFIFO
            o_axi_last    <=  1;
            state         <=  RELEASE;
          end
          else begin
            //get the next piece of data
            o_ppfifo_stb  <=  1;
          end
        end
      end
      RELEASE: begin
        o_ppfifo_act      <=  0;
        state             <=  IDLE;
      end
      default: begin
      end
    endcase
  end
end

endmodule
