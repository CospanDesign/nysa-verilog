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

module sd_spi_phy #(
  parameter                 DDR_EN        = 0
)(
  input                     clk,
  input                     rst,

  //Coniguration
  input                     i_crc_en_flag,

  //Command/Response Interface
  input                     i_cmd_stb,
  input                     i_cmd,
  input         [7:0]       i_cmd_len,

  input                     i_rsp_long_flag,
  output                    o_rsp_stb,
  output                    o_rsp,

  //Data From Host to SD Interface
  input                     i_h2s_fifo_ready,
  output                    o_h2s_fifo_activate,
  input         [23:0]      i_h2s_fifo_size,
  output                    o_h2s_fifo_stb,
  input         [31:0]      i_h2s_fifo_data,

  //Data From SD to Host Interface
  input         [1:0]       i_s2h_fifo_ready,
  output        [1:0]       o_s2h_fifo_activate,
  input         [23:0]      i_s2h_fifo_size,
  input                     i_s2h_fifo_stb,
  output        [31:0]      o_s2h_fifo_data

);

//local parameters
localparam  IDLE          = 4'h0;
localparam  SPI_START_CMD = 4'h1;
localparam  SD_START_CMD  = 4'h2;


//registes/wires
reg             [3:0]       state;
reg             [6:0]       cmd_count;
//submodules
sd_crc_7 crc7 (
 .clk         (clk    ),
 .rst         (rst    ),
 .bitval      (bitval ),
 .en          (en     ),
 .crc         (crc    )
);



//asynchronous logic
//synchronous logic
always @ (posedge clk) begin
  if (rst) begin
    state             <=  IDLE;
    cmd_count         <=  0;
  end
  else begin
    case (state)
      IDLE: begin
        if (i_cmd_stb) begin
        end
      end
      SPI_START_CMD: begin
      end
      SD_START_CMD: begin
      end
      default: begin
      end
    endcase
  end
end



endmodule
