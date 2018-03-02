`timescale 1ns/1ps


module tb_cocotb #(
  parameter AXI_ADDR_WIDTH      = 10,
  parameter AXI_DATA_WIDTH      = 32,
  parameter STROBE_WIDTH        = (AXI_DATA_WIDTH / 8),
  parameter AXIS_DATA_WIDTH     = 128,
  parameter AXIS_STROBE_WIDTH   = (AXIS_DATA_WIDTH / 8)
)(

input                               clk,
input                               vdma_clk,
input                               i_cam_0_clk,
input                               i_cam_1_clk,
input                               i_cam_2_clk,
input                               rst,

//Write Address Channel
input                               AXIML_AWVALID,
input       [AXI_ADDR_WIDTH - 1: 0] AXIML_AWADDR,
output                              AXIML_AWREADY,

//Write Data Channel
input                               AXIML_WVALID,
output                              AXIML_WREADY,
input       [STROBE_WIDTH - 1:0]    AXIML_WSTRB,
input       [AXI_DATA_WIDTH - 1: 0] AXIML_WDATA,

//Write Response Channel
output                              AXIML_BVALID,
input                               AXIML_BREADY,
output      [1:0]                   AXIML_BRESP,

//Read Address Channel
input                               AXIML_ARVALID,
output                              AXIML_ARREADY,
input       [AXI_ADDR_WIDTH - 1: 0] AXIML_ARADDR,

//Read Data Channel
output                              AXIML_RVALID,
input                               AXIML_RREADY,
output      [1:0]                   AXIML_RRESP,
output      [AXI_DATA_WIDTH - 1: 0] AXIML_RDATA,

output      [0:0]                      VDMA0_AXISS_TUSER,
output      [AXIS_DATA_WIDTH - 1: 0]   VDMA0_AXISS_TDATA,
output      [AXIS_STROBE_WIDTH - 1: 0] VDMA0_AXISS_TSTROBE,
output                                 VDMA0_AXISS_TLAST,
output                                 VDMA0_AXISS_TVALID,
output                                 VDMA0_AXISS_TREADY,

output      [0:0]                      VDMA1_AXISS_TUSER,
output      [AXIS_DATA_WIDTH - 1: 0]   VDMA1_AXISS_TDATA,
output      [AXIS_STROBE_WIDTH - 1: 0] VDMA1_AXISS_TSTROBE,
output                                 VDMA1_AXISS_TLAST,
output                                 VDMA1_AXISS_TVALID,
output                                 VDMA1_AXISS_TREADY,

output      [0:0]                      VDMA2_AXISS_TUSER,
output      [AXIS_DATA_WIDTH - 1: 0]   VDMA2_AXISS_TDATA,
output      [AXIS_STROBE_WIDTH - 1: 0] VDMA2_AXISS_TSTROBE,
output                                 VDMA2_AXISS_TLAST,
output                                 VDMA2_AXISS_TVALID,
output                                 VDMA2_AXISS_TREADY
);


//Parameters
localparam                            BUS_SIZE = (`BUS_WIDTH);
//Registers
reg               r_rst;
always @ (*)      r_rst           = rst;
reg   [3:0]       test_id         = 0;


//Raw unsynchronized data
wire       [(8 * LANE_WIDTH) - 1: 0]     i_cam_0_raw_data;
wire       [(8 * LANE_WIDTH) - 1: 0]     i_cam_1_raw_data;
wire       [(8 * LANE_WIDTH) - 1: 0]     i_cam_2_raw_data;

wire      [7:0]                         w_cam_raw_data[0: 2][0:LANE_WIDTH - 1];

//TAP Delay for incomming data
wire      [(5 * LANE_WIDTH) - 1: 0]     o_cam_0_tap_data;
wire      [(5 * LANE_WIDTH) - 1: 0]     o_cam_1_tap_data;
wire      [(5 * LANE_WIDTH) - 1: 0]     o_cam_2_tap_data;


//Interface Directly to Camera
wire                                    o_cam_0_trigger;
wire                                    o_cam_1_trigger;
wire                                    o_cam_2_trigger;
wire                                    o_cam_0_xclear_n;
wire                                    o_cam_1_xclear_n;
wire                                    o_cam_2_xclear_n;
wire                                    o_cam_0_power_en;
wire                                    o_cam_1_power_en;
wire                                    o_cam_2_power_en;
wire                                    o_cam_0_tap_delay_rst;
wire                                    o_cam_1_tap_delay_rst;
wire                                    o_cam_2_tap_delay_rst;

//Vsync and HSync only regs for now
wire       [2:0]                        w_serdes_io_rst;
wire                                    w_serdes_0_io_rst;
wire                                    w_serdes_1_io_rst;
wire                                    w_serdes_2_io_rst;

wire                                    i_cam_0_imx_vs;
wire                                    i_cam_0_imx_hs;
wire                                    cam_0_clk_rst;

wire                                    i_cam_1_imx_vs;
wire                                    i_cam_1_imx_hs;
wire                                    cam_1_clk_rst;

wire                                    i_cam_2_imx_vs;
wire                                    i_cam_2_imx_hs;
wire                                    cam_2_clk_rst;




assign  i_cam_0_imx_vs = vs[0];
assign  i_cam_1_imx_vs = vs[1];
assign  i_cam_2_imx_vs = vs[2];

assign  i_cam_0_imx_hs = hs[0];
assign  i_cam_1_imx_hs = hs[1];
assign  i_cam_2_imx_hs = hs[2];

assign  w_serdes_0_io_rst = w_serdes_io_rst[0];
assign  w_serdes_1_io_rst = w_serdes_io_rst[1];
assign  w_serdes_2_io_rst = w_serdes_io_rst[2];


//submodules
parameter LANE_WIDTH    = 8;
parameter CAMERA_COUNT  = 3;

axi_sony_imx_control #(
  .DEFAULT_TRIGGER_LEN    (10                   ),
  .DEFAULT_TRIGGER_PERIOD (100                  ),
  //.CAMERA_COUNT           (CAMERA_COUNT         ),
  .LANE_WIDTH             (LANE_WIDTH           ),
                                                
  .AXI_ADDR_WIDTH         (AXI_ADDR_WIDTH       ),
  .AXI_DATA_WIDTH         (AXI_DATA_WIDTH       ),
  .INVERT_AXI_RESET       (0                    ),

  .AXIS_DATA_WIDTH        (AXIS_DATA_WIDTH      ),
  .AXIS_STROBE_WIDTH      (AXIS_STROBE_WIDTH    ),


  .INVERT_VDMA_RESET      (0                    )

) dut (
  .i_axi_clk              (clk                 ),
  .i_axi_rst              (r_rst               ),

  .i_cam_0_clk            (i_cam_0_clk         ),
  .i_cam_1_clk            (i_cam_1_clk         ),
  .i_cam_2_clk            (i_cam_2_clk         ),

  .i_vdma_clk             (vdma_clk            ),
  .i_vdma_rst             (r_rst               ),

  // ---- AXI LITE SLAVE INTERFACE -----
  .i_awvalid              (AXIML_AWVALID       ),
  .i_awaddr               (AXIML_AWADDR        ),
  .o_awready              (AXIML_AWREADY       ),


  .i_wvalid               (AXIML_WVALID        ),
  .o_wready               (AXIML_WREADY        ),
  .i_wdata                (AXIML_WDATA         ),


  .o_bvalid               (AXIML_BVALID        ),
  .i_bready               (AXIML_BREADY        ),
  .o_bresp                (AXIML_BRESP         ),


  .i_arvalid              (AXIML_ARVALID       ),
  .o_arready              (AXIML_ARREADY       ),
  .i_araddr               (AXIML_ARADDR        ),


  .o_rvalid               (AXIML_RVALID        ),
  .i_rready               (AXIML_RREADY        ),
  .o_rresp                (AXIML_RRESP         ),
  .o_rdata                (AXIML_RDATA         ),


  // ---- CAMERA INTERFACE -----
  .o_serdes_0_io_rst      (w_serdes_io_rst[0]  ),
  .o_serdes_1_io_rst      (w_serdes_io_rst[1]  ),
  .o_serdes_2_io_rst      (w_serdes_io_rst[2]  ),

  //Raw unsynchronized data
  .i_cam_0_raw_data       (i_cam_0_raw_data    ),
  .i_cam_1_raw_data       (i_cam_1_raw_data    ),
  .i_cam_2_raw_data       (i_cam_2_raw_data    ),

  //TAP Delay for incomming data
  .o_cam_0_tap_data       (o_cam_0_tap_data    ),
  .o_cam_1_tap_data       (o_cam_1_tap_data    ),
  .o_cam_2_tap_data       (o_cam_2_tap_data    ),


  //Interface Directly to Camera
  .o_cam_0_trigger        (o_cam_0_trigger     ),
  .o_cam_1_trigger        (o_cam_1_trigger     ),
  .o_cam_2_trigger        (o_cam_2_trigger     ),

  .o_cam_0_xclear_n       (o_cam_0_xclear_n    ),
  .o_cam_1_xclear_n       (o_cam_1_xclear_n    ),
  .o_cam_2_xclear_n       (o_cam_2_xclear_n    ),

  .o_cam_0_power_en       (o_cam_0_power_en    ),
  .o_cam_1_power_en       (o_cam_1_power_en    ),
  .o_cam_2_power_en       (o_cam_2_power_en    ),

  .o_cam_0_tap_delay_rst  (o_cam_0_tap_delay_rst),
  .o_cam_1_tap_delay_rst  (o_cam_1_tap_delay_rst),
  .o_cam_2_tap_delay_rst  (o_cam_2_tap_delay_rst),

  //Vsync and HSync only inputs for now
  .i_cam_0_imx_vs         (i_cam_0_imx_vs       ),
  .i_cam_0_imx_hs         (i_cam_0_imx_hs       ),

  .i_cam_1_imx_vs         (i_cam_1_imx_vs       ),
  .i_cam_1_imx_hs         (i_cam_1_imx_hs       ),

  .i_cam_2_imx_vs         (i_cam_2_imx_vs       ),
  .i_cam_2_imx_hs         (i_cam_2_imx_hs       ),

  // ---- CAMERA INTERFACE -----

  .o_vdma_0_axis_user     (VDMA0_AXISS_TUSER     ),
  .o_vdma_0_axis_data     (VDMA0_AXISS_TDATA     ),
  .o_vdma_0_axis_strobe   (VDMA0_AXISS_TSTROBE   ),
  .o_vdma_0_axis_last     (VDMA0_AXISS_TLAST     ),
  .o_vdma_0_axis_valid    (VDMA0_AXISS_TVALID    ),
  .i_vdma_0_axis_ready    (VDMA0_AXISS_TREADY    ),

  .o_vdma_1_axis_user     (VDMA1_AXISS_TUSER     ),
  .o_vdma_1_axis_data     (VDMA1_AXISS_TDATA     ),
  .o_vdma_1_axis_strobe   (VDMA1_AXISS_TSTROBE   ),
  .o_vdma_1_axis_last     (VDMA1_AXISS_TLAST     ),
  .o_vdma_1_axis_valid    (VDMA1_AXISS_TVALID    ),
  .i_vdma_1_axis_ready    (VDMA1_AXISS_TREADY    ),

  .o_vdma_2_axis_user     (VDMA2_AXISS_TUSER     ),
  .o_vdma_2_axis_data     (VDMA2_AXISS_TDATA     ),
  .o_vdma_2_axis_strobe   (VDMA2_AXISS_TSTROBE   ),
  .o_vdma_2_axis_last     (VDMA2_AXISS_TLAST     ),
  .o_vdma_2_axis_valid    (VDMA2_AXISS_TVALID    ),
  .i_vdma_2_axis_ready    (VDMA2_AXISS_TREADY    ),

  .o_serdes_0_clk_rst_stb (cam_0_clk_rst         ),
  .o_serdes_1_clk_rst_stb (cam_1_clk_rst         ),
  .o_serdes_2_clk_rst_stb (cam_2_clk_rst         )
);


//asynchronus logic
//synchronous logic

initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

integer i;
integer j;

localparam  VSYNC_LOW_COUNT = 10;
localparam  HSYNC_LOW_COUNT = 10;

localparam  VSYNC_HIGH_COUNT = 10;  //Number of HYSNCs
localparam  HSYNC_HIGH_COUNT = 100;

localparam  HSYNC_HIGH_PAD = 10;



localparam  ROW_START_DELAY = 10;

wire vs[2:0];
wire hs[2:0];

reg prev_hs[2:0];

reg   [31:0] hsync_pad              = HSYNC_HIGH_PAD;
reg   [31:0] hsync_high             = HSYNC_HIGH_COUNT;

reg   [31:0] vsync_high_total_count = VSYNC_HIGH_COUNT;
wire  [31:0] hsync_high_total_count;

assign  hsync_high_total_count = hsync_pad + hsync_high;


reg   [31:0] vsync_low_count[0:2];
reg   [31:0] vsync_high_count[0:2];
reg   [31:0] hsync_low_count[0:2];
reg   [31:0] hsync_high_count[0:2];

reg   [31:0] row_start_delay[0:2];
wire         row_start[0:2];
wire         row_end[0:2];
reg   [31:0]  data_index[0:2];
wire  [2:0]   cam_clk;
assign cam_clk[0] = i_cam_0_clk;
assign cam_clk[1] = i_cam_1_clk;
assign cam_clk[2] = i_cam_2_clk;

genvar gv;
genvar fv;
generate

for (fv = 0; fv < LANE_WIDTH; fv = fv + 1) begin: FRAME_BLOCK 
  assign i_cam_0_raw_data[(fv * 8) + 7:(fv * 8)] = w_cam_raw_data[0][fv];
  assign i_cam_1_raw_data[(fv * 8) + 7:(fv * 8)] = w_cam_raw_data[1][fv];
  assign i_cam_2_raw_data[(fv * 8) + 7:(fv * 8)] = w_cam_raw_data[2][fv];
end

for (gv = 0; gv < CAMERA_COUNT; gv = gv + 1) begin: GEN_BLOCK
  case (BUS_SIZE)
    12: begin
      rxd_to_rbuf_12test rtr12t (
        .camera_clk     (cam_clk[gv]           ),
        .rst            (w_serdes_io_rst[gv]   ),
        .o_xvs          (vs[gv]                ),
        .o_xhs          (hs[gv]                ),
        .o_lvds8_0      (w_cam_raw_data[gv][0] ),
        .o_lvds8_1      (w_cam_raw_data[gv][1] ),
        .o_lvds8_2      (w_cam_raw_data[gv][2] ),
        .o_lvds8_3      (w_cam_raw_data[gv][3] ),
        .o_lvds8_4      (w_cam_raw_data[gv][4] ),
        .o_lvds8_5      (w_cam_raw_data[gv][5] ),
        .o_lvds8_6      (w_cam_raw_data[gv][6] ),
        .o_lvds8_7      (w_cam_raw_data[gv][7] )
      );
    end
    10: begin
      rxd_to_rbuf_10test rtr10t (
        .camera_clk     (cam_clk[gv]           ),
        .rst            (w_serdes_io_rst[gv]   ),
        .o_xvs          (vs[gv]                ),
        .o_xhs          (hs[gv]                ),
        .o_lvds8_0      (w_cam_raw_data[gv][0] ),
        .o_lvds8_1      (w_cam_raw_data[gv][1] ),
        .o_lvds8_2      (w_cam_raw_data[gv][2] ),
        .o_lvds8_3      (w_cam_raw_data[gv][3] ),
        .o_lvds8_4      (w_cam_raw_data[gv][4] ),
        .o_lvds8_5      (w_cam_raw_data[gv][5] ),
        .o_lvds8_6      (w_cam_raw_data[gv][6] ),
        .o_lvds8_7      (w_cam_raw_data[gv][7] )
      );
    end
    default : begin
      rxd_to_rbuf_8test rtr8t (
        .camera_clk     (cam_clk[gv]           ),
        .rst            (w_serdes_io_rst[gv]   ),
        .o_xvs          (vs[gv]                ),
        .o_xhs          (hs[gv]                ),
        .o_lvds8_0      (w_cam_raw_data[gv][0] ),
        .o_lvds8_1      (w_cam_raw_data[gv][1] ),
        .o_lvds8_2      (w_cam_raw_data[gv][2] ),
        .o_lvds8_3      (w_cam_raw_data[gv][3] ),
        .o_lvds8_4      (w_cam_raw_data[gv][4] ),
        .o_lvds8_5      (w_cam_raw_data[gv][5] ),
        .o_lvds8_6      (w_cam_raw_data[gv][6] ),
        .o_lvds8_7      (w_cam_raw_data[gv][7] )
      );
    end
  endcase
end
endgenerate
endmodule
