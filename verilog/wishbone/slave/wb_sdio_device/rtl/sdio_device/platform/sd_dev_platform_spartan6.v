///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.0
//  \   \        Filename: serdes_1_to_n_clk_ddr_s8_diff.v
//  /   /        Date Last Modified:  November 5 2009
// /___/   /\    Date Created: September 1 2009
// \   \  /  \
//  \___\/\___\
//
//Device:   Spartan 6
//Purpose:    1-bit generic 1:n DDR clock receiver module for serdes factors
//    from 2 to 8 with differential inputs
//    Instantiates necessary BUFIO2 clock buffers
//Reference:
//
//Revision History:
//    Rev 1.0 - First created (nicks)
///////////////////////////////////////////////////////////////////////////////
//
//  Disclaimer:
//
//    This disclaimer is not a license and does not grant any rights to the materials
//              distributed herewith. Except as otherwise provided in a valid license issued to you
//              by Xilinx, and to the maximum extent permitted by applicable law:
//              (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS,
//              AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY,
//              INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR
//              FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether in contract
//              or tort, including negligence, or under any other theory of liability) for any loss or damage
//              of any kind or nature related to, arising under or in connection with these materials,
//              including for any direct, or any indirect, special, incidental, or consequential loss
//              or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered
//              as a result of any action brought by a third party) even if such damage or loss was
//              reasonably foreseeable or Xilinx had been advised of the possibility of the same.
//
//  Critical Applications:
//
//    Xilinx products are not designed or intended to be fail-safe, or for use in any application
//    requiring fail-safe performance, such as life-support or safety devices or systems,
//    Class III medical devices, nuclear facilities, applications related to the deployment of airbags,
//    or any other applications that could lead to death, personal injury, or severe property or
//    environmental damage (individually and collectively, "Critical Applications"). Customer assumes
//    the sole risk and liability of any use of Xilinx products in Critical Applications, subject only
//    to applicable laws and regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
//
//////////////////////////////////////////////////////////////////////////////



/*
 * Author:
 * Description:
 *
 * Changes:
 */

`define SWAP_CLK  0
module sd_dev_platform_spartan6 #(
  parameter                 OUTPUT_DELAY  = 63,
  parameter                 INPUT_DELAY   = 63
)(
  input                     rst,
  input                     clk,

  //SD Stack Interfface
  output                    o_locked,

  output                    o_sd_clk,
//  output                    o_sd_clk_x2,

  input                     i_sd_cmd_dir,
  input                     i_sd_cmd_out,
  output                    o_sd_cmd_in,

  input                     i_sd_data_dir,
  input           [7:0]     i_sd_data_out,
  output          [7:0]     o_sd_data_in,

  //Configuration
  input                     i_cfg_inc,
  input                     i_cfg_en,

  input                     i_phy_clk,
  inout                     io_phy_sd_cmd,
  inout           [3:0]     io_phy_sd_data
);

//local parameters
//registes/wires
wire                [7:0]   sd_data_out;
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

wire                        phy_clk_s;
wire                        pll_phy_clk;
wire                        clkfb;
wire                        serdes_clk_fb;


//assign    o_locked        = 1;
//submodules

//Read in the clock
wire  buf_clk;
wire  buf_phy_clk;
wire  buf_phy_clk_n;
wire  predelay_clk_p;
wire  predelay_clk_n;

wire  clock_delay_p;
wire  clock_delay_n;
reg   user_reset;
initial begin
  user_reset  <=  1;
  count       <=  0;
end

IBUFG input_clock_buffer_p(
  .I                    (i_phy_clk            ),
  .O                    (o_sd_clk             )
);

//Control Line
IOBUF
#(
  .IOSTANDARD           ("LVCMOS33"           )
)cmd_iobuf(
  .T                    (sd_cmd_tristate_dly  ),
  .O                    (sd_cmd_in_delay      ),
  .I                    (sd_cmd_out_delay     ),
  .IO                   (io_phy_sd_cmd        )
);

IODELAY2 #(
  .DATA_RATE            ("SDR"                ),
  .IDELAY_VALUE         (INPUT_DELAY          ),
  .ODELAY_VALUE         (OUTPUT_DELAY         ),
  .IDELAY_TYPE          ("FIXED"              ),
  //.IDELAY_TYPE          ("VARIABLE_FROM_ZERO" ),
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
  .CAL                  (1'b0                 ),
  .BUSY                 (                     ),

  .IOCLK0               (clk                  ),  //XXX: This one is not SERDESized.. Do I need to add a clock??
  .IOCLK1               (1'b0                 ),

  .CLK                  (clk                  ),
  .INC                  (i_cfg_inc            ),
  .CE                   (i_cfg_en             ),
  .RST                  (rst                  )
);

//DATA Lines
genvar pcnt;
generate
for (pcnt = 0; pcnt < 4; pcnt = pcnt + 1) begin: sgen
IOBUF #(
  .IOSTANDARD           ("LVCMOS33"             )
) io_data_buffer (
  .T                    (pin_data_tristate[pcnt]),

  .I                    (pin_data_out[pcnt]     ),
  .O                    (pin_data_in[pcnt]      ),

  .IO                   (io_phy_sd_data[pcnt]   )
);

IODELAY2 #(
  .DATA_RATE            ("SDR"                            ),
  .IDELAY_VALUE         (INPUT_DELAY                      ),
  .ODELAY_VALUE         (OUTPUT_DELAY                     ),
  .IDELAY_TYPE          ("FIXED"                          ),
  .COUNTER_WRAPAROUND   ("STAY_AT_LIMIT"                  ),
  .DELAY_SRC            ("IO"                             ),
  .SERDES_MODE          ("NONE"                           ),
  .SIM_TAPDELAY_VALUE   (75                               )
)sd_data_delay(
  //IOSerdes
  //.T                    (pin_data_tristate_predelay[pcnt] ),
  .T                    (!i_sd_data_dir                   ),
  .ODATAIN              (pin_data_in_predelay[pcnt]       ),
  .DATAOUT              (pin_data_out_delay[pcnt]         ),

  //To/From IO Buffer
  .TOUT                 (pin_data_tristate[pcnt]          ),
  .IDATAIN              (pin_data_in[pcnt]                ),
  .DOUT                 (pin_data_out[pcnt]               ),

  .DATAOUT2             (                                 ),
  .IOCLK0               (1'b0                             ),  //This one is not SERDESized.. Do I need to add a clock??
  .IOCLK1               (1'b0                             ),
  .CLK                  (1'b0                             ),
  .CAL                  (1'b0                             ),
  .INC                  (1'b0                             ),
  .CE                   (1'b0                             ),
  .BUSY                 (                                 ),
  .RST                  (1'b0                             )
  //.RST                  (rst                              )
);

IDDR2 #(
  .DDR_ALIGNMENT        ("NONE"                           ),
  .INIT_Q0              (0                                ),
  .INIT_Q1              (0                                ),
  .SRTYPE               ("SYNC"                           )
) data_in_ddr (
  .C0                   (o_sd_clk                         ),
  //.C1                   (neg_sd_clk                     ),
  .C1                   (!o_sd_clk                        ),
  .CE                   (1'b1                             ),
  .S                    (1'b0                             ),
  .R                    (1'b0                             ),

  .D                    (pin_data_out_delay[pcnt]         ),
  .Q0                   (o_sd_data_in[pcnt]               ),
  .Q1                   (o_sd_data_in[pcnt + 4]           )
);

ODDR2 #(
  .DDR_ALIGNMENT        ("C0"                             ),
  .INIT                 (0                                ),
  .SRTYPE               ("ASYNC"                           )
) data_out_ddr (
  .C0                   (o_sd_clk                         ),
  .C1                   (!o_sd_clk                        ),
  //.C1                   (neg_sd_clk                       ),
  .CE                   (1'b1                             ),
  .S                    (1'b0                             ),
  .R                    (1'b0                             ),

  .D0                   (sd_data_out[pcnt + 4]            ),
  .D1                   (sd_data_out[pcnt]                ),
  .Q                    (pin_data_in_predelay[pcnt]       )

);
end
endgenerate

//asynchronous logic
assign  sd_data_out = i_sd_data_out;
assign  o_locked    = !user_reset;


//Synchronous Logic
reg [7:0] count;
always @ (posedge clk) begin
  if (rst) begin
    count                 <=  0;
    user_reset            <=  1;
  end
  else begin
    if (count < 4) begin
      count               <=  count + 1;
    end
    else begin
      count               <=  0;
      user_reset          <=  0;
    end
  end
end



//Synchronous Logic
endmodule
