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

module sd_host_platform_spartan6 #(
  parameter                 OUTPUT_DELAY  = 0,
  parameter                 INPUT_DELAY   = 0
)(
  input                     rst,
  input                     clk,
  output                    o_locked,
  input                     i_read_wait,

  output                    o_sd_clk,
  output                    o_sd_clk_x2,

  input                     i_sd_data_dir,
  input           [7:0]     i_sd_data_out,
  output          [7:0]     o_sd_data_in,

  input                     i_sd_cmd_dir,
  input                     i_sd_cmd_out,
  output                    o_sd_cmd_in,

  output                    o_phy_clk,
  inout                     io_phy_cmd,
  inout           [3:0]     io_phy_data

);
//local parameters
//registes/wires
wire                [7:0]   sd_data_out;
wire                        pll_locked;
wire                        pll_serdes_clk;
wire                        pll_sd_clk;

wire                        ddr_clk_predelay;
wire                        ddr_clk_delay;

wire                        ddr_clk;

wire                        sd_cmd_tristate_dly;
wire                        sd_cmd_out_delay;
wire                        sd_cmd_in_delay;

wire                [3:0]   pin_data_out;
wire                [3:0]   pin_data_in;
wire                [3:0]   pin_data_tristate;

wire                [3:0]   pin_data_out_delay;
wire                [3:0]   pin_data_in_predelay;
wire                [3:0]   pin_data_tristate_predelay;
wire                        serdes_strobe;

wire                        din_serdes_strobe_buf;



pullup (io_phy_data[0]);
pullup (io_phy_data[1]);
pullup (io_phy_data[2]);
pullup (io_phy_data[3]);
//submodules

//Generate the SERDES

PLL_BASE #(
  .BANDWIDTH            ("OPTIMIZED"          ),
  .CLK_FEEDBACK         ("CLKFBOUT"           ),
  .COMPENSATION         ("SYSTEM_SYNCHRONOUS" ),
  .DIVCLK_DIVIDE        (1                    ),
  .CLKFBOUT_MULT        (9                    ),
  .CLKFBOUT_PHASE       (0.000                ),
  .CLKOUT0_DIVIDE       (9                    ),
  .CLKOUT0_PHASE        (0.00                 ),
  .CLKOUT0_DUTY_CYCLE   (0.500                ),
  .CLKOUT1_DIVIDE       (18                   ),
  .CLKOUT1_DUTY_CYCLE   (0.500                ),
  .CLKIN_PERIOD         (10.000               ),
  .REF_JITTER           (0.010                )
) pll (
  //Input Clock and Input Clock Control
  .RST                  (rst                  ),
  .CLKFBIN              (clkfbout             ),
  .CLKFBOUT             (clkfbout             ),

  .CLKIN                (clk                  ),

  //Status/Control
  .LOCKED               (pll_locked           ),
  .CLKOUT0              (pll_serdes_clk       ),
  .CLKOUT1              (pll_sd_clk           )
);

//Clock will be used to drive both the output and the internal state machine
BUFG sd_clk_bufg(
  .I                    (pll_sd_clk           ),
  .O                    (o_sd_clk             )
);
BUFG sd_clk_x2_bufg(
  .I                    (pll_serdes_clk       ),
  .O                    (o_sd_clk_x2          )
);

//Delay For Clock
/*
IODELAY2 #(
  .DATA_RATE            ("SDR"                ),
  .ODELAY_VALUE         (OUTPUT_DELAY         ),
  .COUNTER_WRAPAROUND   ("STAY_AT_LIMIT"      ),
  .DELAY_SRC            ("ODATAIN"            ),
  .SERDES_MODE          ("NONE"               ),
  .SIM_TAPDELAY_VALUE   (75                   )

)clk_delay (
  .T                    (1'b0                 ),
  .DOUT                 (ddr_clk_delay        ),
  .ODATAIN              (ddr_clk_predelay     ),

  .IDATAIN              (1'b0                 ),
  .TOUT                 (                     ),
  .DATAOUT              (                     ),
  .DATAOUT2             (                     ),

  .IOCLK0               (1'b0                 ),
  .IOCLK1               (1'b0                 ),
  .CLK                  (1'b0                 ),
  .CAL                  (1'b0                 ),
  .INC                  (1'b0                 ),
  .CE                   (1'b0                 ),
  .BUSY                 (                     ),
  .RST                  (1'b0                 )
);
*/

//Take the output of the delay buffer and send it through ODDR2
ODDR2 #(
  .DDR_ALIGNMENT        ("C0"                 ),
  .INIT                 (1'b0                 ),
  .SRTYPE               ("ASYNC"              )
) oddr2_clk (
  .D0                   (1'b1                 ),
  .D1                   (1'b0                 ),
  .C0                   (o_sd_clk             ),
  .C1                   (~o_sd_clk            ),
  .CE                   (1'b1                 ),
  .Q                    (ddr_clk_predelay     )
);

//Output of ODDR2 and send it through pin output buffer
OBUF #(
  .IOSTANDARD           ("LVCMOS18"           )
)
sd_output_clk (
//  .I                    (ddr_clk_delay        ),
  .I                    (ddr_clk_predelay     ),
  .O                    (o_phy_clk            )
);




//Internal Clock Interface
BUFPLL #(
  .DIVIDE               (2                    )
)
sd_buff_pll (
  .LOCKED               (pll_locked           ),
  .PLLIN                (pll_serdes_clk       ),
  .LOCK                 (o_locked             ),
  .GCLK                 (o_sd_clk             ),

  .IOCLK                (serdes_clk           ),
  .SERDESSTROBE         (serdes_strobe        )
);

//Control Line
IOBUF #(
  .IOSTANDARD           ("LVCMOS18"           )
)cmd_iobuf(
  .T                    (sd_cmd_tristate_dly  ),

  .O                    (sd_cmd_in_delay      ),
  .I                    (sd_cmd_out_delay     ),

  .IO                   (io_phy_cmd           )
);

pullup (io_phy_cmd);

IODELAY2 #(
  .DATA_RATE            ("SDR"                ),
  .IDELAY_VALUE         (INPUT_DELAY          ),
  .ODELAY_VALUE         (OUTPUT_DELAY         ),
  .IDELAY_TYPE          ("FIXED"              ),
  .COUNTER_WRAPAROUND   ("STAY_AT_LIMIT"      ),
  .DELAY_SRC            ("IO"                 ),
  .SERDES_MODE          ("NONE"               ),
  .SIM_TAPDELAY_VALUE   (75                   )
) cmd_delay (
  .T                    (!i_sd_cmd_dir        ),
  .ODATAIN              (i_sd_cmd_out         ),
  //.DATAOUT              (o_sd_cmd_in          ),
  .DATAOUT2             (o_sd_cmd_in          ),

  //FPGA Fabric

  //IOB
  .TOUT                 (sd_cmd_tristate_dly  ),
  .IDATAIN              (sd_cmd_in_delay      ),
  .DOUT                 (sd_cmd_out_delay     ),

  .IOCLK0               (1'b0                 ),  //XXX: This one is not SERDESized.. Do I need to add a clock??
  .IOCLK1               (1'b0                 ),
  .CLK                  (1'b0                 ),
  .CAL                  (1'b0                 ),
  .INC                  (1'b0                 ),
  .CE                   (1'b0                 ),
  .BUSY                 (                     ),
  .RST                  (1'b0                 )
);

//DATA Lines
genvar pcnt;
generate
for (pcnt = 0; pcnt < 4; pcnt = pcnt + 1) begin: sgen
IOBUF #(
  .IOSTANDARD           ("LVCMOS18"             )
) io_data_buffer (
  .T                    (pin_data_tristate[pcnt]),

  .I                    (pin_data_out[pcnt]     ),
  .O                    (pin_data_in[pcnt]      ),

  .IO                   (io_phy_data[pcnt]      )
);

IODELAY2 #(
  .DATA_RATE            ("SDR"                ),
  .IDELAY_VALUE         (INPUT_DELAY          ),
  .ODELAY_VALUE         (OUTPUT_DELAY         ),
  .IDELAY_TYPE          ("FIXED"              ),
  .COUNTER_WRAPAROUND   ("STAY_AT_LIMIT"      ),
  .DELAY_SRC            ("IO"                 ),
  .SERDES_MODE          ("NONE"               ),
  .SIM_TAPDELAY_VALUE   (75                   )
)sd_data_delay(
  //IOSerdes
  .T                    (pin_data_tristate_predelay[pcnt] ),
  .ODATAIN              (pin_data_in_predelay[pcnt]       ),
  .DATAOUT              (pin_data_out_delay[pcnt]         ),

  //To/From IO Buffer
  .TOUT                 (pin_data_tristate[pcnt]          ),
  .IDATAIN              (pin_data_in[pcnt]                ),
  .DOUT                 (pin_data_out[pcnt]               ),

  .DATAOUT2             (                     ),
  .IOCLK0               (1'b0                 ),  //This one is not SERDESized.. Do I need to add a clock??
  .IOCLK1               (1'b0                 ),
  .CLK                  (1'b0                 ),
  .CAL                  (1'b0                 ),
  .INC                  (1'b0                 ),
  .CE                   (1'b0                 ),
  .BUSY                 (                     ),
  .RST                  (1'b0                 )
);

ISERDES2 #(
  .BITSLIP_ENABLE       ("FALSE"              ),
  .DATA_RATE            ("SDR"                ),  //Because we are using a PLL to generate a high speed clock we use single data rate
  .DATA_WIDTH           (2                    ),
  .SERDES_MODE          ("NONE"               ),
  .INTERFACE_TYPE       ("NETWORKING"         )
) data_in_serdes (

  .RST                  (rst                  ),
  .SHIFTIN              (                     ),
  .SHIFTOUT             (                     ),
  .FABRICOUT            (                     ),
  .CFB0                 (                     ),
  .CFB1                 (                     ),
  .DFB                  (                     ),

  .INCDEC               (                     ),
  .VALID                (                     ),
  .BITSLIP              (1'b0                 ),

  .CE0                  (1'b1                 ),
  .CLK0                 (serdes_clk           ),
  .CLK1                 (1'b0                 ),
  .CLKDIV               (o_sd_clk             ),
  .IOCE                 (serdes_strobe        ),

  //Actual Data
  .D                    (pin_data_out_delay[pcnt]),
  .Q1                   (o_sd_data_in[pcnt]     ),
  .Q2                   (o_sd_data_in[pcnt + 4] )
);

OSERDES2 #(
  .DATA_RATE_OQ         ("SDR"                ),
  .DATA_RATE_OT         ("SDR"                ),
  .TRAIN_PATTERN        (0                    ),
  .DATA_WIDTH           (2                    ),
  .SERDES_MODE          ("NONE"               ),
  .OUTPUT_MODE          ("SINGLE_ENDED"       )
) data_out_serdes (
  .D1                   (sd_data_out[pcnt + 4]), 
  .D2                   (sd_data_out[pcnt]    ),
  .T1                   (!i_sd_data_dir && !i_read_wait  ),
  .T2                   (!i_sd_data_dir && !i_read_wait  ),
  .SHIFTIN1             (1'b1                 ),
  .SHIFTIN2             (1'b1                 ),
  .SHIFTIN3             (1'b1                 ),
  .SHIFTIN4             (1'b1                 ),
  .SHIFTOUT1            (                     ),
  .SHIFTOUT2            (                     ),
  .SHIFTOUT3            (                     ),
  .SHIFTOUT4            (                     ),
  .TRAIN                (1'b0                 ),
  .OCE                  (1'b1                 ),
  .CLK0                 (serdes_clk           ),
  .CLK1                 (1'b0                 ),
  .CLKDIV               (o_sd_clk             ),

  .OQ                   (pin_data_in_predelay[pcnt]   ),
  .TQ                   (pin_data_tristate_predelay[pcnt]),
  .IOCE                 (serdes_strobe        ),
  .TCE                  (1'b1                 ),
  .RST                  (rst                  )
);

end
endgenerate

//asynchronous logic
assign  sd_data_out = i_read_wait ? {1'b1, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1}:
                                    i_sd_data_out;
            
endmodule
