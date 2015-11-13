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
 * Author: David McCoy
 * Description: High Speed Data Demo
 *  Demonstrate a source and sink interface for the DMA
 *
 * Changes:
 */

module hs_demo #(
  .BUFFER_WIDTH             = 10
)(
  input                     clk,
  input                     rst

  output                    o_idle;

  input                     i_read_enable;
  input                     i_write_enable;

  //Ping Pong FIFO Interface
  input                     i_rd_rdy,
  output  reg               o_rd_act,
  input       [23:0]        i_rd_size,
  output  reg               o_rd_stb,
  input       [31:0]        i_rd_data,

  //Ping Pong FIFO Write Interface
  input       [1:0]         i_wr_rdy,
  output  reg [1:0]         o_wr_act,
  input       [23:0]        i_wr_size,
  output  reg               o_wr_stb,
  output  reg [31:0]        o_wr_data
);
//local parameters
localparam      IDLE          = 0;
localparam      WRITE_ENABLE  = 1;
localparam      READ_ENABLE   = 2;
//registes/wires
reg   [23:0]          r_count;
reg   [3:0]           state;
//submodules

//Read/Write Data to a local buffer
dpb #(
  .DATA_WIDTH     (32                   ),
  .ADDR_WIDTH     (BUFFER_WIDTH         )

) local_buffer (

  .clka           (clk                  ),
  .wea            (a_wea                ),
  .addra          (a_addr               ),
  .dina           (a_din                ),
  .douta          (a_dout               )

  .clkb           (clk                  ),  //These clocks do not need to be the same
  .web            (b_web                ),
  .addrb          (b_addrb              ),
  .dinb           (b_dinb               ),
  .doutb          (b_dout               )
);

//asynchronous logic
//synchronous logic
always @ (posedge clk) begin
  //De-assert Strobes
  o_rd_stb                <=  0;
  o_wr_stb                <=  0;

  if (rst) begin
    o_rd_act              <=  0;
    o_wr_act              <=  0;
    o_wr_data             <=  0;
    r_count               <=  0;
    state                 <=  IDLE;

  end
  else begin
    case (state)
      IDLE: begin
      end
      WRITE_ENABLE: begin
      end
      READ_ENABLE: begin
        if (i_rd_rdy && !o_rd_act) begin
        end
      end
      default: begin
      end
    endcase

  end
end

endmodule
