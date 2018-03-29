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
 *  2/22/2018: Initial Commit
 *  2/27/2018: Incorporating newer cam_in_to_bram module
 *    In order to send the correct number of bytes we need the image width
 *    (This will allow us to utilize the strobe signals to enable the correct
 *    bytes)
 *    We probably won't need the r_image_height but I've added it just in case
 */

`timescale 1ps / 1ps

`define MAJOR_VERSION             1
`define MINOR_VERSION             0
`define REVISION                  0

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16

module axi_sony_imx_control #(
  parameter DEFAULT_TRIGGER_LEN = 100,
  parameter DEFAULT_TRIGGER_PERIOD = 370000, //200 hertz at 74MHz

  parameter LANE_WIDTH          = 8,

  //parameter AXIS_DATA_WIDTH     = 128,
  parameter AXIS_DATA_WIDTH     = 64,
  parameter AXIS_STROBE_WIDTH   = (AXIS_DATA_WIDTH / 8),

  parameter BRAM_DATA_DEPTH     = 9,
  parameter BRAM_DATA_WIDTH     = 16,

  parameter AXI_ADDR_WIDTH      = 9,
  parameter AXI_DATA_WIDTH      = 32,

  parameter AXI_STROBE_WIDTH    = (AXI_DATA_WIDTH / 8),
  parameter INVERT_AXI_RESET    = 1,
  parameter INVERT_VDMA_RESET   = 1,
  parameter CAM0_LVDS_INVERT_MAP= 8'b00000000,
  parameter CAM1_LVDS_INVERT_MAP= 8'b00001000,
  parameter CAM2_LVDS_INVERT_MAP= 8'b00100000
)(
  input                                       i_axi_clk,
  input                                       i_axi_rst,

  //AXI Lite Interface

  //Write Address Channel
  input                                       i_awvalid,
  input       [AXI_ADDR_WIDTH - 1: 0]         i_awaddr,
  output                                      o_awready,

  //Write Data Channel
  input                                       i_wvalid,
  output                                      o_wready,
  input       [AXI_DATA_WIDTH - 1: 0]         i_wdata,

  //Write Response Channel
  output                                      o_bvalid,
  input                                       i_bready,
  output      [1:0]                           o_bresp,

  //Read Address Channel
  input                                       i_arvalid,
  output                                      o_arready,
  input       [AXI_ADDR_WIDTH - 1: 0]         i_araddr,

  //Read Data Channel
  output                                      o_rvalid,
  input                                       i_rready,
  output      [1:0]                           o_rresp,
  output      [AXI_DATA_WIDTH - 1: 0]         o_rdata,


  //VDMA AXIS Data Channel
  input                                       i_vdma_clk,
  input                                       i_vdma_rst,


  output      [0:0]                           o_vdma_0_axis_user,
  output      [AXIS_DATA_WIDTH - 1: 0]        o_vdma_0_axis_data,
  output                                      o_vdma_0_axis_last,
  output                                      o_vdma_0_axis_valid,
  input                                       i_vdma_0_axis_ready,

  output      [0:0]                           o_vdma_1_axis_user,
  output      [AXIS_DATA_WIDTH - 1: 0]        o_vdma_1_axis_data,
  output                                      o_vdma_1_axis_last,
  output                                      o_vdma_1_axis_valid,
  input                                       i_vdma_1_axis_ready,

  output      [0:0]                           o_vdma_2_axis_user,
  output      [AXIS_DATA_WIDTH - 1: 0]        o_vdma_2_axis_data,
  output                                      o_vdma_2_axis_last,
  output                                      o_vdma_2_axis_valid,
  input                                       i_vdma_2_axis_ready,

  //CAMERA Signals
  input                                       i_cam_0_clk,
  input                                       i_cam_1_clk,
  input                                       i_cam_2_clk,

  //Raw unsynchronized data
  input       [(8 * LANE_WIDTH) - 1: 0]       i_cam_0_raw_data,
  input       [(8 * LANE_WIDTH) - 1: 0]       i_cam_1_raw_data,
  input       [(8 * LANE_WIDTH) - 1: 0]       i_cam_2_raw_data,

  //TAP Delay for incomming data
  output      [(5 * LANE_WIDTH) - 1: 0]       o_cam_0_tap_data,
  output      [(5 * LANE_WIDTH) - 1: 0]       o_cam_1_tap_data,
  output      [(5 * LANE_WIDTH) - 1: 0]       o_cam_2_tap_data,


  //Interface Directly to Camera
  output                                      o_cam_0_trigger,
  output                                      o_cam_1_trigger,
  output                                      o_cam_2_trigger,
  output                                      o_cam_0_xclear_n,
  output                                      o_cam_1_xclear_n,
  output                                      o_cam_2_xclear_n,
  output  reg                                 o_cam_0_power_en,
  output  reg                                 o_cam_1_power_en,
  output  reg                                 o_cam_2_power_en,
  output                                      o_serdes_0_sync_rst,
  output                                      o_serdes_1_sync_rst,
  output                                      o_serdes_2_sync_rst,
  output                                      o_serdes_0_async_rst,
  output                                      o_serdes_1_async_rst,
  output                                      o_serdes_2_async_rst,

  //Vsync and HSync only inputs for now
  input                                       i_cam_0_imx_vs,
  input                                       i_cam_0_imx_hs,

  input                                       i_cam_1_imx_vs,
  input                                       i_cam_1_imx_hs,

  input                                       i_cam_2_imx_vs,
  input                                       i_cam_2_imx_hs

);

//Functions
function integer clogb2 (input integer bit_depth);
begin
  for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
    bit_depth = bit_depth >> 1;
end
endfunction

//local parameters
localparam                  MAX_CAMERA_COUNT          = 3;
localparam                  MAX_LANE_WIDTH            = 16;

//Address Map
localparam                  REG_CONTROL               = 0;
localparam                  REG_STATUS                = 1;
localparam                  REG_TRIGGER_PULSE_WIDTH   = 2;
localparam                  REG_TRIGGER_PERIOD        = 3;
localparam                  REG_CAMERA_COUNT          = 4;
localparam                  REG_LANE_WIDTH            = 5;
localparam                  REG_ALIGNED_FLAG_LOW      = 6;
localparam                  REG_ALIGNED_FLAG_HIGH     = 7;
localparam                  REG_FRAME_WIDTH           = 8;
localparam                  REG_FRAME_HEIGHT          = 9;
localparam                  REG_PRE_VERTICAL_BLANK    = 10;
localparam                  REG_PRE_HORIZONTAL_BLANK  = 11;
localparam                  REG_POST_VERTICAL_BLANK   = 12;
localparam                  REG_POST_HORIZONTAL_BLANK = 13;

localparam                  REG_TAP_DELAY_START       = 16;
localparam                  SIZE_TAP_DELAY            = MAX_LANE_WIDTH * MAX_CAMERA_COUNT;
localparam                  REG_VERSION               = REG_TAP_DELAY_START + SIZE_TAP_DELAY;  //Always Should be last




//BIT MAP
localparam                  CTRL_BIT_CLEAR_EN           = 0;
localparam                  CTRL_BIT_TRIGGER_EN         = 1;
localparam                  CTRL_BIT_CAM_ASYNC_RST_EN   = 2;
localparam                  CTRL_BIT_CAM_SYNC_RST_EN    = 3;

localparam                  CTRL_BIT_POWER_EN0          = 12;
localparam                  CTRL_BIT_POWER_EN1          = 13;
localparam                  CTRL_BIT_POWER_EN2          = 14;

//Register/Wire
wire                                w_cam_clk[0:2];
wire                                w_cam_sync_rst[0:2];

reg                                 r_serdes_sync_rst_en;
reg                                 r_cam_xclear;
reg                                 r_serdes_async_rst_en;
wire  [11:0]                        w_image_0_byte_count;
wire  [11:0]                        w_image_1_byte_count;
wire  [11:0]                        w_image_2_byte_count;





assign  o_serdes_0_async_rst    = r_serdes_async_rst_en;
assign  o_serdes_1_async_rst    = r_serdes_async_rst_en;
assign  o_serdes_2_async_rst    = r_serdes_async_rst_en;

wire                                w_frame_fifo_ready[0: MAX_CAMERA_COUNT - 1];
wire                                w_frame_fifo_next_stb[0: MAX_CAMERA_COUNT - 1];
wire                                w_frame_fifo_sof[0: MAX_CAMERA_COUNT - 1];
wire                                w_frame_fifo_last[0: MAX_CAMERA_COUNT - 1];
wire      [AXIS_DATA_WIDTH - 1: 0]  w_frame_fifo_data[0: MAX_CAMERA_COUNT - 1];

//AXI Signals
reg         [15:0]                  r_frame_width;
reg         [15:0]                  r_frame_height;
reg         [7:0]                   r_pre_vblank;
reg         [7:0]                   r_pre_hblank;
reg         [7:0]                   r_post_vblank;
reg         [7:0]                   r_post_hblank;

//Simple User Interface
wire  [AXI_ADDR_WIDTH - 1: 0]         w_reg_address;
wire  [((AXI_ADDR_WIDTH - 1) - 2): 0] w_reg_32bit_address;
reg                                   r_reg_invalid_addr;

wire                                w_reg_in_rdy;
reg                                 r_reg_in_ack_stb;
wire  [AXI_DATA_WIDTH - 1: 0]       w_reg_in_data;

wire                                w_reg_out_req;
reg                                 r_reg_out_rdy_stb;
reg   [AXI_DATA_WIDTH - 1: 0]       r_reg_out_data;

wire                                w_axi_rst;
wire                                w_vdma_rst;

reg                                 r_trigger_en;
wire  [LANE_WIDTH - 1: 0]           w_report_align       [0: MAX_CAMERA_COUNT - 1];
wire  [(MAX_CAMERA_COUNT * MAX_LANE_WIDTH) - 1: 0]             w_report_align_array;
wire  [LANE_WIDTH - 1: 0]           w_lane_data_valid        [0: MAX_CAMERA_COUNT - 1];
wire  [MAX_CAMERA_COUNT - 1: 0]     w_cam_data_valid;

wire  [BRAM_DATA_DEPTH - 1: 0]      w_vdma_0_addr;
wire  [BRAM_DATA_DEPTH - 1: 0]      w_vdma_1_addr;
wire  [BRAM_DATA_DEPTH - 1: 0]      w_vdma_2_addr;

//VDMA Signals
wire                                w_vdma_axis_user    [0: MAX_CAMERA_COUNT - 1];
wire  [AXIS_DATA_WIDTH - 1: 0]      w_vdma_axis_data    [0: MAX_CAMERA_COUNT - 1];
//wire  [AXIS_STROBE_WIDTH - 1: 0]    w_vdma_axis_strobe  [0: MAX_CAMERA_COUNT - 1];
wire                                w_vdma_axis_last    [0: MAX_CAMERA_COUNT - 1];
wire                                w_vdma_axis_valid   [0: MAX_CAMERA_COUNT - 1];
wire                                w_vdma_axis_ready   [0: MAX_CAMERA_COUNT - 1];


wire  [MAX_CAMERA_COUNT - 1: 0]     w_vdma_active;
wire  [BRAM_DATA_DEPTH - 1: 0]      w_bram_count        [0: MAX_CAMERA_COUNT - 1][0: LANE_WIDTH -1];
wire  [BRAM_DATA_DEPTH - 1: 0]      w_bram_addr         [0: MAX_CAMERA_COUNT - 1];
wire  [BRAM_DATA_WIDTH - 1: 0]      w_bram_data         [0: MAX_CAMERA_COUNT - 1][0: LANE_WIDTH - 1];
wire  [AXIS_DATA_WIDTH - 1: 0]      w_bram_cam_data     [0: MAX_CAMERA_COUNT - 1];
wire                                w_bram_frame_start  [0: MAX_CAMERA_COUNT - 1][0: LANE_WIDTH - 1];



//XXX: TODO Use Alignment Information to determine if the Lane data is useful
wire  [LANE_WIDTH - 1: 0]           w_cam_0_aligned;
wire  [LANE_WIDTH - 1: 0]           w_cam_1_aligned;
wire  [LANE_WIDTH - 1: 0]           w_cam_2_aligned;

wire  [2: 0]                        w_hsync;
wire  [2: 0]                        w_vsync;
//Put the aligned and unaligned data in a format that can be used by the generate block
wire  [63:0]                        w_cam_unaligned     [0: MAX_CAMERA_COUNT - 1];


wire  [7:0]                         w_unaligned_data    [0: MAX_CAMERA_COUNT - 1][0:LANE_WIDTH - 1];
wire  [7:0]                         w_aligned_data      [0: MAX_CAMERA_COUNT - 1][0:LANE_WIDTH - 1];

wire  [(5 * LANE_WIDTH) - 1:0]      w_tap_lane_value    [0: MAX_CAMERA_COUNT - 1];
reg   [4:0]                         r_tap_value         [0: MAX_CAMERA_COUNT - 1][0:MAX_LANE_WIDTH - 1];

reg   [31:0]                        r_trigger_pulse_width;
reg   [31:0]                        r_trigger_pulse_count[0:2];

reg   [31:0]                        r_trigger_period;
reg   [31:0]                        r_trigger_period_count[0:2];
wire                                w_frame_start;

assign  w_vsync[0]                  = i_cam_0_imx_vs;
assign  w_vsync[1]                  = i_cam_1_imx_vs;
assign  w_vsync[2]                  = i_cam_2_imx_vs;

assign  w_hsync[0]                  = i_cam_0_imx_hs;
assign  w_hsync[1]                  = i_cam_1_imx_hs;
assign  w_hsync[2]                  = i_cam_2_imx_hs;

assign  o_cam_0_xclear_n            = !r_cam_xclear;
assign  o_cam_1_xclear_n            = !r_cam_xclear;
assign  o_cam_2_xclear_n            = !r_cam_xclear;

assign  w_vdma_0_addr               = w_bram_addr[0];
assign  w_vdma_1_addr               = w_bram_addr[1];
assign  w_vdma_2_addr               = w_bram_addr[2];

integer lc;

//Submodules
genvar cam_i;
genvar lane_i;
generate

for (cam_i = 0; cam_i < MAX_CAMERA_COUNT; cam_i = cam_i + 1) begin : CAMERA

  if (LANE_WIDTH < MAX_LANE_WIDTH) begin
    assign w_report_align_array[((cam_i * MAX_LANE_WIDTH) + (MAX_LANE_WIDTH - 1)):(cam_i * MAX_LANE_WIDTH) + LANE_WIDTH] = 0;
  end


  //Take into consideration that we may not have all cameras declared
  //Map the statically named 'cam_0, cam_1, cam_2' to the mult dimensional arrays
  case (cam_i)
    0: begin
      assign w_cam_clk[0]           = i_cam_0_clk;
      assign w_cam_unaligned[0]     = i_cam_0_raw_data;
      assign o_cam_0_tap_data       = w_tap_lane_value[0];
      assign o_serdes_0_sync_rst    = w_cam_sync_rst[0];
      assign o_cam_0_trigger        = ((r_trigger_en) & (r_trigger_pulse_count[0] < r_trigger_pulse_width));

      assign  o_vdma_0_axis_user[0] = w_vdma_axis_user[0];
      assign  o_vdma_0_axis_data    = w_vdma_axis_data[0];
      assign  o_vdma_0_axis_last    = w_vdma_axis_last[0];
      assign  o_vdma_0_axis_valid   = w_vdma_axis_valid[0];
      assign  w_vdma_axis_ready[0]  = i_vdma_0_axis_ready;
    end
    1: begin
      assign w_cam_clk[1]           = i_cam_1_clk;
      assign w_cam_unaligned[1]     = i_cam_1_raw_data;
      assign o_cam_1_tap_data       = w_tap_lane_value[1];
      assign o_serdes_1_sync_rst    = w_cam_sync_rst[1];
      assign o_cam_1_trigger        = ((r_trigger_en) & (r_trigger_pulse_count[1] < r_trigger_pulse_width));

      assign  o_vdma_1_axis_user[0] = w_vdma_axis_user[1];
      assign  o_vdma_1_axis_data    = w_vdma_axis_data[1];
      assign  o_vdma_1_axis_last    = w_vdma_axis_last[1];
      assign  o_vdma_1_axis_valid   = w_vdma_axis_valid[1];
      assign  w_vdma_axis_ready[1]  = i_vdma_1_axis_ready;
    end
    2: begin
      assign w_cam_clk[2]           = i_cam_2_clk;
      assign w_cam_unaligned[2]     = i_cam_2_raw_data;
      assign o_cam_2_tap_data       = w_tap_lane_value[2];
      assign o_serdes_2_sync_rst    = w_cam_sync_rst[2];
      assign o_cam_2_trigger        = ((r_trigger_en) & (r_trigger_pulse_count[2] < r_trigger_pulse_width));

      assign  o_vdma_2_axis_user[0] = w_vdma_axis_user[2];
      assign  o_vdma_2_axis_data    = w_vdma_axis_data[2];
      assign  o_vdma_2_axis_last    = w_vdma_axis_last[2];
      assign  o_vdma_2_axis_valid   = w_vdma_axis_valid[2];
      assign  w_vdma_axis_ready[2]  = i_vdma_2_axis_ready;
    end
  endcase

	assign w_cam_sync_rst[cam_i] = r_serdes_sync_rst_en;

  //Trigger Signals for the Cameras in Slave Trigger Mode
  always @ (posedge w_cam_clk[cam_i] or posedge w_axi_rst) begin
    if (w_cam_sync_rst[cam_i] || w_axi_rst)begin
      r_trigger_pulse_count[cam_i]        <=  DEFAULT_TRIGGER_LEN;
      r_trigger_period_count[cam_i] <=  DEFAULT_TRIGGER_PERIOD;
    end
    else begin
      if (r_trigger_en) begin
        if (r_trigger_pulse_count[cam_i] < r_trigger_pulse_width) begin
          r_trigger_pulse_count[cam_i]      <=  r_trigger_pulse_count[cam_i]  + 1;
        end
        if (r_trigger_period_count[cam_i]   <   r_trigger_period) begin
          r_trigger_pulse_count[cam_i]      <=  r_trigger_period;
        end
        else begin
          r_trigger_pulse_count[cam_i]      <=  0;
          r_trigger_period_count[cam_i]     <=  0;
        end
      end
      else begin
        r_trigger_pulse_count[cam_i]        <=  r_trigger_pulse_width;
        r_trigger_period_count[cam_i]       <=  r_trigger_period;
      end
    end
  end

  //XXX: IF ALL THE ROW DATA IS NOT SENT THEN CHECK TO SEE IF w_lane_data_valid[cam_i] are all high
  //  assign w_vdma_axis_valid[cam_i]   = (w_lane_data_valid[cam_i] == ((1 << LANE_WIDTH) - 1) && (w_bram_addr[cam_i] < w_bram_count[cam_i][0]));
  assign w_cam_data_valid[cam_i]    = (w_lane_data_valid[cam_i] == ((1 << LANE_WIDTH) - 1));
  assign w_vdma_active[cam_i]       = (w_vdma_axis_valid[cam_i] && w_vdma_axis_ready[cam_i]);
  if (cam_i == 0) begin
    serdes_descramble #(
      .INVERT_MAP (CAM0_LVDS_INVERT_MAP       )
    )serdes_descramble_cam (
      .i_lvds     (w_cam_unaligned [cam_i]    ),
      .o_lvds0    (w_unaligned_data[cam_i][0] ),
      .o_lvds1    (w_unaligned_data[cam_i][2] ),
      .o_lvds2    (w_unaligned_data[cam_i][4] ),
      .o_lvds3    (w_unaligned_data[cam_i][6] ),
      .o_lvds4    (w_unaligned_data[cam_i][7] ),
      .o_lvds5    (w_unaligned_data[cam_i][5] ),
      .o_lvds6    (w_unaligned_data[cam_i][3] ),
      .o_lvds7    (w_unaligned_data[cam_i][1] )
    );
  end
  if (cam_i == 1) begin
    serdes_descramble #(
      .INVERT_MAP (CAM1_LVDS_INVERT_MAP       )
    )serdes_descramble_cam (
      .i_lvds     (w_cam_unaligned [cam_i]    ),
      .o_lvds0    (w_unaligned_data[cam_i][0] ),
      .o_lvds1    (w_unaligned_data[cam_i][2] ),
      .o_lvds2    (w_unaligned_data[cam_i][4] ),
      .o_lvds3    (w_unaligned_data[cam_i][6] ),
      .o_lvds4    (w_unaligned_data[cam_i][7] ),
      .o_lvds5    (w_unaligned_data[cam_i][5] ),
      .o_lvds6    (w_unaligned_data[cam_i][3] ),
      .o_lvds7    (w_unaligned_data[cam_i][1] )
    );
  end
  if (cam_i == 2) begin
    serdes_descramble #(
      .INVERT_MAP (CAM2_LVDS_INVERT_MAP       )
    )serdes_descramble_cam (
      .i_lvds     (w_cam_unaligned [cam_i]    ),
      .o_lvds0    (w_unaligned_data[cam_i][0] ),
      .o_lvds1    (w_unaligned_data[cam_i][2] ),
      .o_lvds2    (w_unaligned_data[cam_i][4] ),
      .o_lvds3    (w_unaligned_data[cam_i][6] ),
      .o_lvds4    (w_unaligned_data[cam_i][7] ),
      .o_lvds5    (w_unaligned_data[cam_i][5] ),
      .o_lvds6    (w_unaligned_data[cam_i][3] ),
      .o_lvds7    (w_unaligned_data[cam_i][1] )
    );
  end




  //LANES: Go through the lanes
  for (lane_i = 0; lane_i < LANE_WIDTH; lane_i = lane_i + 1) begin : LANES

    //Map parts of the large camera blocks to multi dimensional arrays
    assign w_tap_lane_value[cam_i][(lane_i * 5) + 4:(lane_i * 5)] = r_tap_value[cam_i][lane_i];

    //Map the data valid signals to an array
    assign w_report_align_array[(cam_i * MAX_LANE_WIDTH) + lane_i]  = w_report_align[cam_i][lane_i];

    assign w_frame_start = w_bram_frame_start[0][0];
    //Map the aligned data to the VDMA data bus
    if (AXIS_DATA_WIDTH == 128) begin
      assign w_bram_cam_data[cam_i][(AXIS_DATA_WIDTH - 1) - (BRAM_DATA_WIDTH * lane_i): (AXIS_DATA_WIDTH - 1) - ((BRAM_DATA_WIDTH * (lane_i + 1)) - 1)] = w_bram_data[cam_i][lane_i];
    end
    else if (AXIS_DATA_WIDTH == 64) begin
      assign w_bram_cam_data[cam_i][(AXIS_DATA_WIDTH - 1) - (8 * lane_i): (AXIS_DATA_WIDTH - 1) - ((8 * (lane_i + 1)) - 1)] = w_bram_data[cam_i][lane_i][15:8];
    end

    cam_in_to_bram #(
      .ADDR_WIDTH       (BRAM_DATA_DEPTH                  ),
      .DATA_WIDTH       (BRAM_DATA_WIDTH                  )

      ) rtrbuf (

      .camera_clk       (w_cam_clk[cam_i]                 ),
      .rst              (w_cam_sync_rst[cam_i]            ),
      .vdma_clk         (i_vdma_clk                       ),

      .i_xvs            (w_vsync[cam_i]                   ),
      .i_xhs            (w_hsync[cam_i]                   ),
      .i_lvds           (w_unaligned_data[cam_i][lane_i]  ),
//      .o_mode           (), //XXX
      .o_report_align   (w_report_align[cam_i][lane_i]    ),
      .o_data_valid     (w_lane_data_valid[cam_i][lane_i] ),
      .o_data_count     (w_bram_count[cam_i][lane_i]      ),
      .i_rbuf_addrb     (w_bram_addr[cam_i]               ),  //XXX
      .o_rbuf_doutb     (w_bram_data[cam_i][lane_i]       ),
      .o_frame_start    (w_bram_frame_start[cam_i][lane_i])
    );
  end

  bram_to_frame_fifo #(
    .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH                    ),
    .BRAM_DATA_DEPTH  (BRAM_DATA_DEPTH                    )

  ) bram2ff (
    .clk                    (i_vdma_clk                   ),
    .rst                    (w_vdma_rst                   ),

    .i_frame_width          (r_frame_width                ),
    .i_frame_height         (r_frame_height               ),
    .i_pre_vblank           (r_pre_vblank                 ),
    .i_pre_hblank           (r_pre_hblank                 ),
    .i_post_vblank          (r_post_vblank                ),
    .i_post_hblank          (r_post_hblank                ),

    .i_vsync                (w_vsync[cam_i]               ),

    .i_bram_frame_start     (w_frame_start                ),
    .i_bram_data_valid      (w_cam_data_valid[cam_i]      ),
    .i_bram_size            (w_bram_count[cam_i][0]       ),
    .o_bram_addr            (w_bram_addr[cam_i]           ),
    .i_bram_data            (w_bram_cam_data[cam_i]       ),

    .o_frame_fifo_ready     (w_frame_fifo_ready[cam_i]    ),
    .i_frame_fifo_next_stb  (w_frame_fifo_next_stb[cam_i] ),
    .o_frame_fifo_sof       (w_frame_fifo_sof[cam_i]      ),
    .o_frame_fifo_last      (w_frame_fifo_last[cam_i]     ),
    .o_frame_fifo_data      (w_frame_fifo_data[cam_i]     )

  );

  //AXI Frame FIFO to Stream Interface
  frame_fifo_to_axi_stream #(
    .AXIS_DATA_WIDTH        (AXIS_DATA_WIDTH              )
  ) ff2axis (
    .clk                    (i_vdma_clk                   ),
    .rst                    (w_vdma_rst                   ),

    .i_frame_fifo_ready     (w_frame_fifo_ready[cam_i]    ),
    .o_frame_fifo_next_stb  (w_frame_fifo_next_stb[cam_i] ),
    .i_frame_fifo_sof       (w_frame_fifo_sof[cam_i]      ),
    .i_frame_fifo_last      (w_frame_fifo_last[cam_i]     ),
    .i_frame_fifo_data      (w_frame_fifo_data[cam_i]     ),

    .o_axis_user            (w_vdma_axis_user[cam_i]      ),
    .i_axis_ready           (w_vdma_axis_ready[cam_i]     ),
    .o_axis_data            (w_vdma_axis_data[cam_i]      ),
    .o_axis_last            (w_vdma_axis_last[cam_i]      ),
    .o_axis_valid           (w_vdma_axis_valid[cam_i]     )

  );

end
endgenerate


//Convert AXI Slave signals to a simple register/address strobe
axi_lite_slave #(
  .ADDR_WIDTH         (AXI_ADDR_WIDTH       ),
  .DATA_WIDTH         (AXI_DATA_WIDTH       )

) axi_lite_reg_interface (
  .clk                (i_axi_clk            ),
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
assign        w_axi_rst               = (INVERT_AXI_RESET)   ? ~i_axi_rst         : i_axi_rst;
assign        w_vdma_rst              = (INVERT_VDMA_RESET)  ? ~i_vdma_rst        : i_vdma_rst;
assign        w_reg_32bit_address     = w_reg_address[(AXI_ADDR_WIDTH - 1): 2];

integer i;
integer j;
//blocks
always @ (posedge i_axi_clk) begin
  //De-assert Strobes
  r_reg_in_ack_stb                        <= 0;
  r_reg_out_rdy_stb                       <= 0;
  r_reg_invalid_addr                      <= 0;

  if (w_axi_rst) begin
    r_reg_out_data                        <= 0;
    r_serdes_async_rst_en                 <= 0;
    r_serdes_sync_rst_en                  <= 0;
    r_cam_xclear                          <= 0;

    r_trigger_pulse_width                 <= DEFAULT_TRIGGER_LEN;
    r_trigger_period                      <= DEFAULT_TRIGGER_PERIOD;

    o_cam_0_power_en                      <= 0;
    o_cam_1_power_en                      <= 0;
    o_cam_2_power_en                      <= 0;
    r_trigger_en                          <= 0;

    r_frame_width                         <= 0;
    r_frame_height                        <= 0;
    r_pre_vblank                          <= 0;
    r_pre_hblank                          <= 0;
    r_post_vblank                         <= 0;
    r_post_hblank                         <= 0;

    for (i = 0; i < MAX_CAMERA_COUNT; i = i + 1) begin
      for (j = 0; j < MAX_LANE_WIDTH; j = j + 1) begin
        r_tap_value[i][j] <= 0;
      end
    end
  end
  else begin
    if (w_reg_in_rdy && !r_reg_in_ack_stb) begin
      //From master
      case (w_reg_32bit_address)
        REG_CONTROL: begin
          o_cam_0_power_en                          <= w_reg_in_data[CTRL_BIT_POWER_EN0];
          o_cam_1_power_en                          <= w_reg_in_data[CTRL_BIT_POWER_EN1];
          o_cam_2_power_en                          <= w_reg_in_data[CTRL_BIT_POWER_EN2];
          r_trigger_en                              <= w_reg_in_data[CTRL_BIT_TRIGGER_EN];

          r_serdes_async_rst_en                     <= w_reg_in_data[CTRL_BIT_CAM_ASYNC_RST_EN];
          r_serdes_sync_rst_en                      <= w_reg_in_data[CTRL_BIT_CAM_SYNC_RST_EN];
          r_cam_xclear                              <= w_reg_in_data[CTRL_BIT_CLEAR_EN];
        end
        REG_TRIGGER_PULSE_WIDTH: begin
          r_trigger_pulse_width                     <= w_reg_in_data;
        end
        REG_TRIGGER_PERIOD: begin
          r_trigger_period                          <= w_reg_in_data;
        end
        REG_FRAME_WIDTH: begin
          r_frame_width                             <= w_reg_in_data[15:0];
        end
        REG_FRAME_HEIGHT: begin
          r_frame_height                            <= w_reg_in_data[15:0];
        end
        REG_PRE_VERTICAL_BLANK: begin
          r_pre_vblank                              <= w_reg_in_data[7:0];
        end
        REG_PRE_HORIZONTAL_BLANK: begin
          r_pre_hblank                              <= w_reg_in_data[7:0];
        end
        REG_POST_VERTICAL_BLANK: begin
          r_post_vblank                             <= w_reg_in_data[7:0];
        end
        REG_POST_HORIZONTAL_BLANK: begin
          r_post_hblank                             <= w_reg_in_data[7:0];
        end
        default: begin
          for (i = 0; i < MAX_CAMERA_COUNT; i = i + 1) begin
            for (j = 0; j < MAX_LANE_WIDTH; j = j + 1) begin
              if (w_reg_32bit_address == (REG_TAP_DELAY_START + (i  * MAX_LANE_WIDTH) + j))  begin
                $display("Register Address (Write): %h", w_reg_32bit_address);
                r_tap_value[i][j]         <= w_reg_in_data;
              end
            end
          end
        end
      endcase
      if (w_reg_32bit_address > REG_VERSION) begin
        $display("Invalid Register Address: %h", w_reg_32bit_address);

        r_reg_invalid_addr                          <= 1;
      end
      r_reg_in_ack_stb                              <= 1;
    end
    else if (w_reg_out_req && !r_reg_out_rdy_stb) begin
      case (w_reg_32bit_address)
        REG_CONTROL: begin
          r_reg_out_data[CTRL_BIT_CLEAR_EN]         <=  r_cam_xclear;
          r_reg_out_data[CTRL_BIT_POWER_EN0]        <=  o_cam_0_power_en;
          r_reg_out_data[CTRL_BIT_POWER_EN1]        <=  o_cam_1_power_en;
          r_reg_out_data[CTRL_BIT_POWER_EN2]        <=  o_cam_2_power_en;
          r_reg_out_data[CTRL_BIT_TRIGGER_EN]       <=  r_trigger_en;
        end
        REG_STATUS: begin
          r_reg_out_data                            <=  0;
        end
        REG_TRIGGER_PULSE_WIDTH: begin
          r_reg_out_data                            <=  r_trigger_pulse_width;
        end
        REG_TRIGGER_PERIOD: begin
          r_reg_out_data                            <=  r_trigger_period;
        end
        REG_CAMERA_COUNT: begin
          r_reg_out_data                            <=  MAX_CAMERA_COUNT;
        end
        REG_LANE_WIDTH: begin
          r_reg_out_data                            <=  LANE_WIDTH;
        end
        REG_ALIGNED_FLAG_LOW: begin
          r_reg_out_data                            <=  w_report_align_array[31:0];
        end
        REG_ALIGNED_FLAG_HIGH: begin
          r_reg_out_data                            <=  {16'h0000, w_report_align_array[47:32]};
        end
        REG_FRAME_WIDTH: begin
          r_reg_out_data                            <=  {16'h000, r_frame_width};
        end
        REG_FRAME_HEIGHT: begin
          r_reg_out_data                            <=  {16'h000, r_frame_height};
        end
        REG_PRE_VERTICAL_BLANK: begin
          r_reg_out_data                            <=  {24'h000000, r_pre_vblank};
        end
        REG_PRE_HORIZONTAL_BLANK: begin
          r_reg_out_data                            <=  {24'h000000, r_pre_hblank};
        end
        REG_POST_VERTICAL_BLANK: begin
          r_reg_out_data                            <=  {24'h000000, r_post_vblank};
        end
        REG_POST_HORIZONTAL_BLANK: begin
          r_reg_out_data                            <=  {24'h000000, r_post_hblank};
        end
        REG_VERSION: begin
          r_reg_out_data                            <= 32'h00;
          r_reg_out_data[`MAJOR_RANGE]              <= `MAJOR_VERSION;
          r_reg_out_data[`MINOR_RANGE]              <= `MINOR_VERSION;
          r_reg_out_data[`REVISION_RANGE]           <= `REVISION;
        end
        default: begin
          r_reg_out_data                            <= 32'h00;
          for (i = 0; i < MAX_CAMERA_COUNT; i = i + 1) begin
            for (j = 0; j < MAX_LANE_WIDTH; j = j + 1) begin
              if (w_reg_32bit_address == (REG_TAP_DELAY_START + (i  * MAX_LANE_WIDTH) + j))  begin
                $display("Register Address (Read): %h", w_reg_32bit_address);
                r_reg_out_data            <=  r_tap_value[i][j];
              end
            end
          end
        end
      endcase
      if (w_reg_32bit_address > REG_VERSION) begin
        $display("Invalid Register Address: %h", w_reg_32bit_address);
        r_reg_invalid_addr                <= 1;
      end
      r_reg_out_rdy_stb                   <= 1;
    end
  end
end


endmodule
