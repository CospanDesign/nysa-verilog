/*
Distributed under the MIT license.
Copyright (c) 2016 Dave McCoy (dave.mccoy@cospandesign.com)

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

`timescale 1ps / 1ps

`define MAJOR_VERSION             1
`define MINOR_VERSION             0
`define REVISION                  0

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16

module axi_sony_imx_control #(
  parameter DEFAULT_CLEAR_LEN   = 100,
  parameter DEFAULT_TRIGGER_LEN = 100,
  parameter DEFAULT_TRIGGER_PERIOD = 370000, //200 hertz at 74MHz
  parameter CAMERA_COUNT        = 1,
  parameter LANE_WIDTH          = 8,

  parameter ADDR_WIDTH          = 8,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8),
  parameter INVERT_AXI_RESET    = 1
)(
  input                               clk,
  input                               rst,

  //AXI Lite Interface

  //Write Address Channel
  input                               i_awvalid,
  input       [ADDR_WIDTH - 1: 0]     i_awaddr,
  output                              o_awready,

  //Write Data Channel
  input                               i_wvalid,
  output                              o_wready,
  input       [DATA_WIDTH - 1: 0]     i_wdata,

  //Write Response Channel
  output                              o_bvalid,
  input                               i_bready,
  output      [1:0]                   o_bresp,

  //Read Address Channel
  input                               i_arvalid,
  output                              o_arready,
  input       [ADDR_WIDTH - 1: 0]     i_araddr,

  //Read Data Channel
  output                              o_rvalid,
  input                               i_rready,
  output      [1:0]                   o_rresp,
  output      [DATA_WIDTH - 1: 0]     o_rdata,



  //CAMERA Signals

  //Raw unsynchronized data
  input       [(8 * LANE_WIDTH) - 1: 0]     i_cam_0_raw_data,
  input       [(8 * LANE_WIDTH) - 1: 0]     i_cam_1_raw_data,
  input       [(8 * LANE_WIDTH) - 1: 0]     i_cam_2_raw_data,

  //Synchronized data
  output      [(8 * LANE_WIDTH) - 1: 0]     o_cam_0_sync_data,
  output      [(8 * LANE_WIDTH) - 1: 0]     o_cam_1_sync_data,
  output      [(8 * LANE_WIDTH) - 1: 0]     o_cam_2_sync_data,

  //TAP Delay for incomming data
  output      [(5 * LANE_WIDTH) - 1: 0]     o_cam_0_tap_data,
  output      [(5 * LANE_WIDTH) - 1: 0]     o_cam_1_tap_data,
  output      [(5 * LANE_WIDTH) - 1: 0]     o_cam_2_tap_data,


  //Interface Directly to Camera
  output                              o_imx_trigger,
  output                              o_cam_xclear_n,
  output  reg                         o_cam0_master_mode,
  output  reg                         o_cam1_master_mode,
  output  reg                         o_cam2_master_mode,
  output  reg                         o_tap_delay_rst,



  //Vsync and HSync only inputs for now
  input                               i_cam_0_imx_vs,
  input                               i_cam_0_imx_hs,

  input                               i_cam_1_imx_vs,
  input                               i_cam_1_imx_hs,

  input                               i_cam_2_imx_vs,
  input                               i_cam_2_imx_hs

);
//local parameters

//Address Map
localparam                  REG_CONTROL             = 0;
localparam                  REG_STATUS              = 1;
localparam                  REG_CLEAR_PULSE_WIDTH   = 2;
localparam                  REG_TRIGGER_PULSE_WIDTH = 3;
localparam                  REG_TRIGGER_PERIOD      = 4;
localparam                  REG_CAMERA_COUNT        = 5;
localparam                  REG_LANE_WIDTH          = 6;
localparam                  REG_ALIGNED_FLAG_LOW    = 12;
localparam                  REG_ALIGNED_FLAG_HIGH   = 13;


localparam                  REG_TAP_DELAY_START     = 16;

localparam                  SIZE_TAP_DELAY          = LANE_WIDTH * CAMERA_COUNT;


localparam                  REG_VERSION             = REG_TAP_DELAY_START + SIZE_TAP_DELAY;  //Always Should be last




//BIT MAP
localparam                  CTRL_BIT_CLEAR          = 0;
localparam                  CTRL_BIT_RESET_TAP_DELAY= 1;
localparam                  CTRL_BIT_TRIGGER_EN     = 2;

localparam                  CTRL_BIT_MASTER_MODE0   = 8;
localparam                  CTRL_BIT_MASTER_MODE1   = 9;
localparam                  CTRL_BIT_MASTER_MODE2   = 10;



//Register/Wire

//AXI Signals
wire        [31:0]              status;

//Simple User Interface
wire  [ADDR_WIDTH - 1: 0]           w_reg_address;
wire   [((ADDR_WIDTH - 1) - 2): 0]  w_reg_32bit_address;
reg                                 r_reg_invalid_addr;

wire                                w_reg_in_rdy;
reg                                 r_reg_in_ack_stb;
wire  [DATA_WIDTH - 1: 0]           w_reg_in_data;

wire                                w_reg_out_req;
reg                                 r_reg_out_rdy_stb;
reg   [DATA_WIDTH - 1: 0]           r_reg_out_data;

wire                                w_axi_rst;

reg                                 r_trigger_en;
wire                                w_cam_xclear;
wire  [(3 * 16) - 1: 0]             w_align_flag;
wire                                w_align_flag_md[0: CAMERA_COUNT - 1][0: LANE_WIDTH - 1];

if (CAMERA_COUNT * LANE_WIDTH < 3 * 16) begin
  assign  w_align_flag[(3 * 16) - 1: (CAMERA_COUNT * LANE_WIDTH)] = 0;
end



//XXX: TODO Use Alignment Information to determine if the Lane data is useful
wire  [LANE_WIDTH - 1: 0]           w_cam_0_aligned;
wire  [LANE_WIDTH - 1: 0]           w_cam_1_aligned;
wire  [LANE_WIDTH - 1: 0]           w_cam_2_aligned;

wire  [2: 0]         w_hsync;
assign  w_hsync[0]     = i_cam_0_imx_hs;
assign  w_hsync[1]     = i_cam_1_imx_hs;
assign  w_hsync[2]     = i_cam_2_imx_hs;



//Put the aligned and unaligned data in a format that can be used by the generate block
wire  [63:0]                        w_cam_unaligned [0: CAMERA_COUNT - 1];
wire  [63:0]                        w_cam_aligned   [0: CAMERA_COUNT - 1];


wire  [7:0]                         w_unaligned_data[0 : CAMERA_COUNT - 1][0:LANE_WIDTH - 1];
wire  [7:0]                         w_aligned_data  [0 : CAMERA_COUNT - 1][0:LANE_WIDTH - 1];

wire  [(5 * LANE_WIDTH) - 1:0]      w_tap_lane_value[0 : CAMERA_COUNT - 1];
reg   [4:0]                         r_tap_value     [0 : CAMERA_COUNT - 1][0:LANE_WIDTH - 1];

reg   [31:0]                        r_clear_pulse_width;
reg   [31:0]                        r_clear_pulse_count;

reg   [31:0]                        r_trigger_pulse_width;
reg   [31:0]                        r_trigger_pulse_count;

reg   [31:0]                        r_trigger_period;
reg   [31:0]                        r_trigger_period_count;

//Submodules
genvar cam_i;
genvar lane_i;
generate

for (cam_i = 0; cam_i < CAMERA_COUNT; cam_i = cam_i + 1) begin : ALIGNER
  //Take into consideration that we may not have all cameras declared
  //Map the statically named 'cam_0, cam_1, cam_2' to the mult dimensional arrays
  case (cam_i)
    0: begin
      assign w_cam_unaligned[0] = i_cam_0_raw_data;
      assign o_cam_0_sync_data  = w_cam_aligned[0];
      assign o_cam_0_tap_data   = w_tap_lane_value[0];
    end
    1: begin
      assign w_cam_unaligned[1] = i_cam_1_raw_data;
      assign o_cam_1_sync_data  = w_cam_aligned[1];
      assign o_cam_1_tap_data   = w_tap_lane_value[1];
    end
    2: begin
      assign w_cam_unaligned[2] = i_cam_2_raw_data;
      assign o_cam_2_sync_data  = w_cam_aligned[2];
      assign o_cam_2_tap_data   = w_tap_lane_value[2];
    end
  endcase

  //Go through the lanes
  for (lane_i = 0; lane_i < LANE_WIDTH; lane_i = lane_i + 1) begin : LANES

    //Map parts of the large camera blocks to multi dimensional arrays
    assign w_unaligned_data[cam_i][lane_i] = w_cam_unaligned[cam_i][(lane_i * 8) + 7:(lane_i * 8)];
    assign w_cam_aligned   [cam_i][(lane_i * 8) + 7:(lane_i * 8)] = w_aligned_data[cam_i][lane_i];
    assign w_tap_lane_value[cam_i][(lane_i * 5) + 4:(lane_i * 5)] = r_tap_value[cam_i][lane_i];

    assign w_align_flag[(cam_i * LANE_WIDTH) + lane_i] = w_align_flag_md[cam_i][lane_i];

    rxd_aligner rxa(
      .clk            (clk                              ),
      .rst            (w_axi_rst                        ),
      .i_hflag        (w_hsync[cam_i]                   ),
      .o_aligned      (w_align_flag_md[cam_i][lane_i]   ),
      .i_lvds         (w_unaligned_data[cam_i][lane_i]  ),
      .o_lvds_aligned (w_aligned_data[cam_i][lane_i]    )
    );

  end
end
endgenerate


//Convert AXI Slave signals to a simple register/address strobe
axi_lite_slave #(
  .ADDR_WIDTH         (ADDR_WIDTH           ),
  .DATA_WIDTH         (DATA_WIDTH           )

) axi_lite_reg_interface (
  .clk                (clk                  ),
  .rst                (w_axi_rst            ),


  .i_awvalid          (i_awvalid            ),
  .i_awaddr           (i_awaddr             ),
  .o_awready          (o_awready            ),

  .i_wvalid           (i_wvalid             ),
  .o_wready           (o_wready             ),
  .i_wdata            (i_wdata              ),

  .o_bvalid           (o_bvalid             ),
  .i_bready           (i_bready             ),
  .o_bresp            (o_bresp              ),

  .i_arvalid          (i_arvalid            ),
  .o_arready          (o_arready            ),
  .i_araddr           (i_araddr             ),

  .o_rvalid           (o_rvalid             ),
  .i_rready           (i_rready             ),
  .o_rresp            (o_rresp              ),
  .o_rdata            (o_rdata              ),


  .o_reg_address      (w_reg_address        ),
  .i_reg_invalid_addr (r_reg_invalid_addr   ),

  .o_reg_in_rdy       (w_reg_in_rdy         ),
  .i_reg_in_ack_stb   (r_reg_in_ack_stb     ),
  .o_reg_in_data      (w_reg_in_data        ),

  .o_reg_out_req      (w_reg_out_req        ),
  .i_reg_out_rdy_stb  (r_reg_out_rdy_stb    ),
  .i_reg_out_data     (r_reg_out_data       )
);

//Asynchronous Logic
assign        w_axi_rst               = (INVERT_AXI_RESET)   ? ~rst         : rst;
assign        w_reg_32bit_address     = w_reg_address[(ADDR_WIDTH - 1): 2];
assign        o_imx_trigger           = (r_trigger_pulse_count < r_trigger_pulse_width);
assign        o_cam_xclear_n          = !w_cam_xclear;
assign        w_cam_xclear            = (r_clear_pulse_count < r_clear_pulse_width);


integer i;
integer j;
//blocks
always @ (posedge clk) begin
  //De-assert Strobes
  r_reg_in_ack_stb                        <=  0;
  r_reg_out_rdy_stb                       <=  0;
  r_reg_invalid_addr                      <=  0;

  o_tap_delay_rst                         <=  0;

  if (w_axi_rst) begin
    r_reg_out_data                        <=  0;
    r_clear_pulse_width                   <= DEFAULT_CLEAR_LEN;
    r_clear_pulse_count                   <= DEFAULT_CLEAR_LEN;

    r_trigger_pulse_width                 <= DEFAULT_TRIGGER_LEN;
    r_trigger_pulse_count                 <= DEFAULT_TRIGGER_LEN;

    r_trigger_period                      <= DEFAULT_TRIGGER_PERIOD;
    r_trigger_period_count                <= DEFAULT_TRIGGER_PERIOD;

    o_cam0_master_mode                    <= 0;
    o_cam1_master_mode                    <= 0;
    o_cam2_master_mode                    <= 0;
    r_trigger_en                          <= 0;

    for (i = 0; i < CAMERA_COUNT; i = i + 1) begin
      for (j = 0; j < LANE_WIDTH; j = j + 1) begin
        r_tap_value[i][j] <= 0;
      end
    end
  end
  else begin
    if (w_reg_in_rdy && !r_reg_in_ack_stb) begin
      //From master
      case (w_reg_32bit_address)
        REG_CONTROL: begin
          o_tap_delay_rst                 <= w_reg_in_data[CTRL_BIT_RESET_TAP_DELAY];
          o_cam0_master_mode              <= w_reg_in_data[CTRL_BIT_MASTER_MODE0];
          o_cam1_master_mode              <= w_reg_in_data[CTRL_BIT_MASTER_MODE1];
          o_cam2_master_mode              <= w_reg_in_data[CTRL_BIT_MASTER_MODE2];
          r_trigger_en                    <= w_reg_in_data[CTRL_BIT_TRIGGER_EN];

          if (w_reg_in_data[CTRL_BIT_CLEAR])begin
            r_clear_pulse_count     <=  0;
          end
        end
        REG_CLEAR_PULSE_WIDTH: begin
          r_clear_pulse_width             <= w_reg_in_data;
          r_clear_pulse_count             <= w_reg_in_data;
        end
        REG_TRIGGER_PULSE_WIDTH: begin
          r_trigger_pulse_width           <= w_reg_in_data;
          r_trigger_pulse_count           <= w_reg_in_data;
        end
        REG_TRIGGER_PERIOD: begin
          r_trigger_period                <= w_reg_in_data;
          r_trigger_period_count          <= w_reg_in_data;
        end
        default: begin
          for (i = 0; i < CAMERA_COUNT; i = i + 1) begin
            for (j = 0; j < LANE_WIDTH; j = j + 1) begin
              if (w_reg_32bit_address == (REG_TAP_DELAY_START + (i  * 8) + j))  begin
                r_tap_value[i][j]         <= w_reg_in_data;
              end
            end
          end
        end
      endcase
      if (w_reg_32bit_address > REG_VERSION) begin
        r_reg_invalid_addr                <= 1;
      end
      r_reg_in_ack_stb                    <= 1;
    end
    else if (w_reg_out_req && !r_reg_out_rdy_stb) begin
      //To master
      case (w_reg_32bit_address)
        REG_CONTROL: begin
          r_reg_out_data[CTRL_BIT_CLEAR]           <=      w_cam_xclear;
          r_reg_out_data[CTRL_BIT_RESET_TAP_DELAY] <=      o_tap_delay_rst;
          r_reg_out_data[CTRL_BIT_MASTER_MODE0]    <=      o_cam0_master_mode;
          r_reg_out_data[CTRL_BIT_MASTER_MODE1]    <=      o_cam1_master_mode;
          r_reg_out_data[CTRL_BIT_MASTER_MODE2]    <=      o_cam2_master_mode;
          r_reg_out_data[CTRL_BIT_TRIGGER_EN]      <=      r_trigger_en;
        end
        REG_STATUS: begin
          r_reg_out_data                  <=  status;
        end
        REG_CLEAR_PULSE_WIDTH: begin
          r_reg_out_data                  <=  r_clear_pulse_width;
        end
        REG_TRIGGER_PULSE_WIDTH: begin
          r_reg_out_data                  <=  r_trigger_pulse_width;
        end
        REG_TRIGGER_PERIOD: begin
          r_reg_out_data                  <=  r_trigger_period;
        end
        REG_CAMERA_COUNT: begin
          r_reg_out_data                  <=  CAMERA_COUNT;
        end
        REG_LANE_WIDTH: begin
          r_reg_out_data                  <=  LANE_WIDTH;
        end
        REG_ALIGNED_FLAG_LOW: begin
          r_reg_out_data                  <=  w_align_flag[31:0];
        end
        REG_ALIGNED_FLAG_HIGH: begin
          r_reg_out_data                  <=  {16'h0000, w_align_flag[47:32]};
        end
        REG_VERSION: begin
          r_reg_out_data                  <= 32'h00;
          r_reg_out_data[`MAJOR_RANGE]    <= `MAJOR_VERSION;
          r_reg_out_data[`MINOR_RANGE]    <= `MINOR_VERSION;
          r_reg_out_data[`REVISION_RANGE] <= `REVISION;
        end
        default: begin
          r_reg_out_data                  <= 32'h00;
          for (i = 0; i < CAMERA_COUNT; i = i + 1) begin
            for (j = 0; j < LANE_WIDTH; j = j + 1) begin
              if (w_reg_32bit_address == (REG_TAP_DELAY_START + (i  * 8) + j))  begin
                r_reg_out_data            <=  r_tap_value[i][j];
              end
            end
          end
        end
      endcase
      if (w_reg_32bit_address > REG_VERSION) begin
        r_reg_invalid_addr                <= 1;
      end
      r_reg_out_rdy_stb                   <= 1;
    end

    //Trigger Control
    if (r_trigger_en) begin
      if (r_trigger_pulse_count < r_trigger_pulse_width) begin
        r_trigger_pulse_count <= r_trigger_pulse_count + 1;
      end

      if (r_trigger_period_count < r_trigger_period) begin
        r_trigger_period_count <= r_trigger_period_count + 1;
      end
      else begin
        r_trigger_pulse_count             <=  0;
        r_trigger_period_count            <=  0;
      end
    end

    //If the user has requrested xclear to be pulsed, raise it back after appropriate timeout
    if (r_clear_pulse_count < r_clear_pulse_width) begin
      r_clear_pulse_count                 <=  r_clear_pulse_count + 1;
    end

  end
end


endmodule
