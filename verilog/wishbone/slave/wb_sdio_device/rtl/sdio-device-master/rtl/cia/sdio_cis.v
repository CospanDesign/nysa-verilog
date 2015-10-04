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
 * Author: David McCoy (dave.mccoy@cospandesign.com)
 * Description: Card Information Structure (CIS)
 *  Information about card behavior
 *
 * Changes:
 */

module sdio_cis #(
  parameter                 FILE_LENGTH = 10,
  parameter                 FILENAME = "cis.rom"
)(
  input                     clk,
  input                     rst,

  input                     i_activate,
  input         [17:0]      i_address,
  input                     i_data_stb,
  output  reg   [7:0]       o_data_out
);
//local parameters
//registes/wires
reg   [7:0]                 rom [0:FILE_LENGTH];

//submodules
//asynchronous logic
//synchronous logic
initial begin
  $readmemb(FILENAME, rom, 0, FILE_LENGTH - 1);
end

always @ (posedge clk) begin
  //De-assert Strobes
  if (rst) begin
    o_data_out          <=  0;
  end
  else begin
    if (i_activate) begin
      if (i_data_stb) begin
        o_data_out      <=  rom[i_address];
      end
    end
  end
end

endmodule
