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
 *  This module generates a CRC16 value from an incomming bitstream
 *  the value is generated from bit that is currently shifting out
 *  The final crc is valid after the last bit is sent, it might be
 *  necessary to send this value one clock cycle before
 *
 *  Last two bytes of the data
 *  CCCCCCCCCCCCCCCC
 *          C = CRC bit
 *
 *  Hold in reset when not using
 *
 *  Online documentation is way to fucking complicated
 *  x^16 + x^12 + x^5 + 1
 *   To find the polynomial remove the top x^16 then add 2^12 + 2^5 + 1 = 0x1021 
 *
 *
 * Changes:
 *  2015.08.08: Initial Add
 *
 */

module crc16 #(
  parameter             POLYNOMIAL  =   16'h1021,
  parameter             SEED        =   16'h0000
)(
  input                 clk,
  input                 rst,
  input                 bit,
  output  reg   [15:0]  crc
);
//local parameters
//registes/wires

//submodules
//asynchronous logic
//synchronous logic
//XXX: Does this need to be asynchronous?

always @ (posedge clk) begin
  if (rst) begin
    crc  <=  SEED;
  end
  else begin
    //Shift the output value
    crc <=  bit ? ({crc[14:0], 1'b0} ^ POLYNOMIAL) : {crc[14:0], 1'b0};
  end
end

endmodule
