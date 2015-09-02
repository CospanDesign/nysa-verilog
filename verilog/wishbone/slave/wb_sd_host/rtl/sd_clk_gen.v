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



//sd_clkgen.v
`timescale 1 ns/1 ps


module sd_clkgen (

input          clk,
input          rst,

output         locked,
output         out_clk,
output         out_clk_x2,
output         phy_out_clk
);

`ifdef COCOTB_SIMULATION
wire clkout0;
reg  clkout1 = 0;
wire  clkout2;
wire  clkout3;
wire  clkout4;
wire  clkout5;
wire  phy_bufout;

assign  clkout0 = clk;
assign  locked  =  1;

always @ (posedge clk) begin
  if (rst) begin
    clkout1 <=  0;
  end
  else begin
    clkout1 <= ~clkout1;
  end
end

`else
wire  clkfbout_buf;
wire  clkfb;
wire  clkout0;
wire  clkout1;
wire  clkout2;
wire  clkout3;
wire  clkout4;
wire  clkout5;
wire  phy_bufout;

PLL_ADV # (
  .BANDWIDTH            ("OPTIMIZED"          ),
  .CLK_FEEDBACK         ("CLKFBOUT"           ),
  .CLKIN1_PERIOD        (10.000               ),
  .CLKIN2_PERIOD        (10.000               ),
  .CLKOUT0_DIVIDE       (10                   ),
  .CLKOUT1_DIVIDE       (20                   ),
  .CLKOUT2_DIVIDE       (20                   ),
  .CLKOUT3_DIVIDE       (20                   ),
  .CLKOUT4_DIVIDE       (20                   ),
  .CLKOUT5_DIVIDE       (20                   ),
  .CLKOUT0_PHASE        (0.00                 ),
  .CLKOUT1_PHASE        (0.00                 ),
  .CLKOUT2_PHASE        (0.00                 ),
  .CLKOUT3_PHASE        (0.00                 ),
  .CLKOUT4_PHASE        (0.00                 ),
  .CLKOUT5_PHASE        (0.00                 ),
  .CLKOUT0_DUTY_CYCLE   (0.500                ),
  .CLKOUT1_DUTY_CYCLE   (0.500                ),
  .CLKOUT2_DUTY_CYCLE   (0.500                ),
  .CLKOUT3_DUTY_CYCLE   (0.500                ),
  .CLKOUT4_DUTY_CYCLE   (0.500                ),
  .CLKOUT5_DUTY_CYCLE   (0.500                ),

  .COMPENSATION         ("SOURCE_SYNCHRONOUS" ),
  .DIVCLK_DIVIDE        (1                    ),
  .CLKFBOUT_MULT        (10                   ),
  .CLKFBOUT_PHASE       (0.0                  ),
  .REF_JITTER           (0.005000             )

) pll (
  .RST                  (rst                  ),
  .CLKFBOUT             (clkfb                ),
  .CLKFBIN              (clkfb                ),
  .CLKIN1               (clk                  ),
  .CLKIN2               (1'b0                 ),
  .CLKINSEL             (1'b1                 ),
  .DADDR                (5'b00                ),
  .DCLK                 (1'b0                 ),
  .DEN                  (1'b0                 ),
  .DI                   (1'b0                 ),
  .DWE                  (1'b0                 ),
  .DO                   (                     ),
  .DRDY                 (                     ),
  .REL                  (1'b0                 ),

  .CLKFBDCM             (                     ),
  .CLKOUTDCM0           (                     ),
  .CLKOUTDCM1           (                     ),
  .CLKOUTDCM2           (                     ),
  .CLKOUTDCM3           (                     ),
  .CLKOUTDCM4           (                     ),
  .CLKOUTDCM5           (                     ),
                        
  .CLKOUT0              (clkout0              ),
  .CLKOUT1              (clkout1              ),
  .CLKOUT2              (clkout2              ),
  .CLKOUT3              (clkout3              ),
  .CLKOUT4              (clkout4              ),
  .CLKOUT5              (clkout5              ),
                       
  .LOCKED               (locked               )
);


`endif

/*
PLL_BASE #(
  .BANDWIDTH            ("OPTIMIZED"          ),
  .CLK_FEEDBACK         ("CLKFBOUT"           ),
  .COMPENSATION         ("SOURCE_SYNCHRONOUS" ),
  //.COMPENSATION         ("INTERNAL"           ),
  .DIVCLK_DIVIDE        (1                    ),
  .CLKFBOUT_MULT        (10                   ),
  .CLKFBOUT_PHASE       (0.000                ),
  .CLKOUT0_DIVIDE       (10                   ),
  .CLKOUT0_PHASE        (0.00                 ),
  .CLKOUT0_DUTY_CYCLE   (0.500                ),
  .CLKOUT1_DIVIDE       (11                   ),
  .CLKOUT1_DUTY_CYCLE   (0.500                ),
  .CLKIN_PERIOD         (10.000               ),
  .REF_JITTER           (0.010                )

) pll (

  //Input Clock and Input Clock Control
  //.CLKFBIN              (clkfbout_buf         ),

  //Feedback
  .CLKFBOUT             (clkfbout             ),
  .CLKFBIN              (clkfbout             ),
  .CLKIN                (clk                  ),

  //Status/Control
  .LOCKED               (locked               ),
  .RST                  (rst                  ),


  .CLKOUT0              (clkout0              ),
  .CLKOUT1              (clkout1              ),
  .CLKOUT2              (clkout2              ),
  .CLKOUT3              (clkout3              ),
  .CLKOUT4              (clkout4              ),
  .CLKOUT5              (clkout5              )
);
*/





BUFG bufg_clk_x2 (
        .I(clkout0),
        .O(out_clk_x2)
);
BUFG bufg_clk (
        .I(clkout1),
        .O(out_clk)
);




/*
BUFG  pll_fb (
  .I (clkfbout),
  .O (clkfbout_buf)
);

BUFG phy_clock_out (
  .I(clkout1),
  .O(phy_bufout)
);
*/

ODDR2 #(
  .DDR_ALIGNMENT  ("NONE"      ),      //Sets output alignment to NON
  .INIT           (1'b0        ),      //Sets the inital state to 0
  .SRTYPE         ("SYNC"      )       //Specified "SYNC" or "ASYNC" reset
) pad_buf (

  .Q              (phy_out_clk ),
//  .C0             (phy_bufout  ),
//  .C1             (~phy_bufout ),
  .C0             (out_clk     ),
  .C1             (~out_clk    ),
  .CE             (1'b1        ),
  .D0             (1'b1        ),
  .D1             (1'b0        ),
  .R              (1'b0        ),
  .S              (1'b0        )
);

endmodule

