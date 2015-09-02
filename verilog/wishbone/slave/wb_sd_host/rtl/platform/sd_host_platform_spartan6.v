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

`define NUM_EXT_PINS  4

module sd_host_platform_spartan6.v (
  input                     rst
  input                     100mhz_clk,
  output                    sd_clk,

  input                     sd_data_dir,
  input           [7:0]     sd_data_out,
  output          [7:0]     sd_data_in,
  input                     sd_cmd_out,
  output                    sd_cmd_in,


  output                    phy_clk,
  inout                     phy_cmd,
  inout           [3:0]     phy_data

);
//local parameters
localparam     PARAM1  = 32'h00000000;
//registes/wires

//submodules

//Generate the SERDES
genvar pcnt;
genvar scnt;
generate
for (pcnt = 0; pcnt < `NUM_EXT_PINS; pcnt = pcnt + 1) begin: sgen


IOBUF #(
) iobuffer (
  .IO                       (phy_data[pcnt] ),
  .O                        (data_out[pcnt] ),
  .I                        (data_in[pcnt]  ),
  .T                        (data_tristate  )
);                          
                            
ISERDES2 #(                 
  .BITSLIP_ENABLE           ("FALSE"        ),
  .DATA_RATE                ("DDR"          ),
  .DATA_WIDTH               (2              ),
  .SERDES_MODE              ("NONE"         ),
  .OUTPUT_MODE              ("SINGLE_ENDED" )

) serdes (
  .RST                      (rst            ),
  .TCE                      (1'b1           ),
  .OCE                      (1'b1           ),
  
);


end
endgenerate

//asynchronous logic




endmodule
