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
 *  This module generates a CRC7 value from an incomming bitstream
 *  the value is generated from bit that is currently shifting out
 *  The final crc is valid after the last bit is sent, it might be
 *  necessary to send this value one clock cycle before
 *
 *  this value should be placed in the top bits of the last byte
 *      CCCCCCC1
 *          C = CRC bit
 *
 *  Hold in reset when not using
 *
 * Changes:
 *  2015.08.08: Initial Add
 */

module crc7 #(
  parameter             POLYNOMIAL  =   8'h09,
  parameter             SEED        =   8'h00
)(
  input                 clk,
  input                 rst,
  input                 bit,
  output reg    [6:0]   crc,
  input                 en
);
//local parameters
//registes/wires
wire          inv;

//submodules
//asynchronous logic
assign  inv = bit ^ crc[6];                   // XOR required?
//synchronous logic
//XXX: Does this need to be asynchronous?

always @ (posedge clk) begin
  if (rst) begin
    crc  <=  SEED;
  end
  else begin
    //Shift the output value
    if (en) begin
      crc[6] <=  crc[5];
      crc[5] <=  crc[4];
      crc[4] <=  crc[3];
      crc[3] <=  crc[2] ^ inv;
      crc[2] <=  crc[1];
      crc[1] <=  crc[0];
      crc[0] <=  inv;
    end
  end
end

endmodule
