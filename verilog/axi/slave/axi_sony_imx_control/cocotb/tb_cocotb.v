`timescale 1ns/1ps


module tb_cocotb #(
  parameter ADDR_WIDTH          = 32,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8)
)(

input                               clk,
input                               rst,

//Write Address Channel
input                               AXIML_AWVALID,
input       [ADDR_WIDTH - 1: 0]     AXIML_AWADDR,
output                              AXIML_AWREADY,

//Write Data Channel
input                               AXIML_WVALID,
output                              AXIML_WREADY,
input       [STROBE_WIDTH - 1:0]    AXIML_WSTRB,
input       [DATA_WIDTH - 1: 0]     AXIML_WDATA,

//Write Response Channel
output                              AXIML_BVALID,
input                               AXIML_BREADY,
output      [1:0]                   AXIML_BRESP,

//Read Address Channel
input                               AXIML_ARVALID,
output                              AXIML_ARREADY,
input       [ADDR_WIDTH - 1: 0]     AXIML_ARADDR,

//Read Data Channel
output                              AXIML_RVALID,
input                               AXIML_RREADY,
output      [1:0]                   AXIML_RRESP,
output      [DATA_WIDTH - 1: 0]     AXIML_RDATA

);


//Parameters
//Registers

reg               r_rst;
always @ (*)      r_rst           = rst;
reg   [3:0]       test_id         = 0;


//Raw unsynchronized data
wire       [(8 * LANE_WIDTH) - 1: 0]     i_cam_0_raw_data;
wire       [(8 * LANE_WIDTH) - 1: 0]     i_cam_1_raw_data;
wire       [(8 * LANE_WIDTH) - 1: 0]     i_cam_2_raw_data;

reg       [7:0]                         r_cam_raw_data[0: 2][0:LANE_WIDTH - 1];

//Synchronized data
wire      [(8 * LANE_WIDTH) - 1: 0]     o_cam_0_sync_data;
wire      [(8 * LANE_WIDTH) - 1: 0]     o_cam_1_sync_data;
wire      [(8 * LANE_WIDTH) - 1: 0]     o_cam_2_sync_data;

//TAP Delay for incomming data
wire      [(5 * LANE_WIDTH) - 1: 0]     o_cam_0_tap_data;
wire      [(5 * LANE_WIDTH) - 1: 0]     o_cam_1_tap_data;
wire      [(5 * LANE_WIDTH) - 1: 0]     o_cam_2_tap_data;


//Interface Directly to Camera
wire                                    o_imx_trigger;
wire                                    o_cam_xclear_n;
wire                                    o_cam0_master_mode;
wire                                    o_cam1_master_mode;
wire                                    o_cam2_master_mode;
wire                                    o_tap_delay_rst;



//Vsync and HSync only regs for now
wire                                     i_cam_0_imx_vs;
wire                                     i_cam_0_imx_hs;

wire                                     i_cam_1_imx_vs;
wire                                     i_cam_1_imx_hs;

wire                                     i_cam_2_imx_vs;
wire                                     i_cam_2_imx_hs;

wire vs;
wire hs;

reg prev_hs;

assign  hs = ((hsync_high_count < HSYNC_HIGH_COUNT) && (hsync_low_count == HSYNC_LOW_COUNT));
assign  vs = ((vsync_high_count < VSYNC_HIGH_COUNT) && (vsync_low_count == VSYNC_LOW_COUNT));


assign  i_cam_0_imx_vs = vs;
assign  i_cam_1_imx_vs = vs;
assign  i_cam_2_imx_vs = vs;

assign  i_cam_0_imx_hs = hs;
assign  i_cam_1_imx_hs = hs;
assign  i_cam_2_imx_hs = hs;


//submodules
parameter LANE_WIDTH    = 8;
parameter CAMERA_COUNT  = 1;

axi_sony_imx_control #(
  .DEFAULT_CLEAR_LEN     (10            ),
  .DEFAULT_TRIGGER_LEN   (10            ),
  .DEFAULT_TRIGGER_PERIOD (100           ),
  .CAMERA_COUNT          (CAMERA_COUNT  ),
  .LANE_WIDTH            (LANE_WIDTH    ),

  .ADDR_WIDTH            (ADDR_WIDTH    ),
  .DATA_WIDTH            (DATA_WIDTH    ),
  .INVERT_AXI_RESET      (0             )

) dut (
  .clk              (clk            ),
  .rst              (r_rst          ),


  .i_awvalid        (AXIML_AWVALID  ),
  .i_awaddr         (AXIML_AWADDR   ),
  .o_awready        (AXIML_AWREADY  ),


  .i_wvalid         (AXIML_WVALID   ),
  .o_wready         (AXIML_WREADY   ),
  .i_wdata          (AXIML_WDATA    ),


  .o_bvalid         (AXIML_BVALID   ),
  .i_bready         (AXIML_BREADY   ),
  .o_bresp          (AXIML_BRESP    ),


  .i_arvalid        (AXIML_ARVALID  ),
  .o_arready        (AXIML_ARREADY  ),
  .i_araddr         (AXIML_ARADDR   ),


  .o_rvalid         (AXIML_RVALID   ),
  .i_rready         (AXIML_RREADY   ),
  .o_rresp          (AXIML_RRESP    ),
  .o_rdata          (AXIML_RDATA    ),


  //Raw unsynchronized data
  .i_cam_0_raw_data  (i_cam_0_raw_data),
  .i_cam_1_raw_data  (i_cam_1_raw_data),
  .i_cam_2_raw_data  (i_cam_2_raw_data),

  //Synchronized data
  .o_cam_0_sync_data (o_cam_0_sync_data),
  .o_cam_1_sync_data (o_cam_1_sync_data),
  .o_cam_2_sync_data (o_cam_2_sync_data),

  //TAP Delay for incomming data
  .o_cam_0_tap_data  (o_cam_0_tap_data),
  .o_cam_1_tap_data  (o_cam_1_tap_data),
  .o_cam_2_tap_data  (o_cam_2_tap_data),


  //Interface Directly to Camera
  .o_imx_trigger      (o_imx_trigger),
  .o_cam_xclear_n     (o_cam_xclear_n),
  .o_cam0_master_mode (o_cam0_master_mode),
  .o_cam1_master_mode (o_cam1_master_mode),
  .o_cam2_master_mode (o_cam2_master_mode),
  .o_tap_delay_rst    (o_tap_delay_rst),

  //Vsync and HSync only inputs for now
  .i_cam_0_imx_vs    (i_cam_0_imx_vs),
  .i_cam_0_imx_hs    (i_cam_0_imx_hs),

  .i_cam_1_imx_vs    (i_cam_1_imx_vs),
  .i_cam_1_imx_hs    (i_cam_1_imx_hs),

  .i_cam_2_imx_vs    (i_cam_2_imx_vs),
  .i_cam_2_imx_hs    (i_cam_2_imx_hs)


);


//asynchronus logic
//synchronous logic

initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

genvar gv;
generate
  for (gv = 0; gv < LANE_WIDTH; gv = gv + 1) begin : LW
    assign i_cam_0_raw_data[(gv * 8) + 7:(gv * 8)] = r_cam_raw_data[0][gv];
    assign i_cam_1_raw_data[(gv * 8) + 7:(gv * 8)] = r_cam_raw_data[1][gv];
    assign i_cam_2_raw_data[(gv * 8) + 7:(gv * 8)] = r_cam_raw_data[2][gv];
  end
endgenerate

integer i;
integer j;

localparam  VSYNC_LOW_COUNT = 10;
localparam  HSYNC_LOW_COUNT = 10;

localparam  VSYNC_HIGH_COUNT = 10;  //Number of HYSNCs
localparam  HSYNC_HIGH_COUNT = 100;


localparam  ROW_START_DELAY = 10;

reg   [31:0] vsync_low_count;
reg   [31:0] vsync_high_count;
reg   [31:0] hsync_low_count;
reg   [31:0] hsync_high_count;

reg   [31:0] row_start_delay;
wire         row_start;
reg   [31:0]  data_index;
assign row_start = (!prev_hs & hs);
assign row_end = (prev_hs & !hs);


always @ (posedge clk) begin
  if (rst) begin
    vsync_low_count       <=  0;
    vsync_high_count      <=  VSYNC_HIGH_COUNT;
    data_index            <=  0;

    hsync_low_count       <=  HSYNC_LOW_COUNT;
    hsync_high_count      <=  HSYNC_HIGH_COUNT;
    row_start_delay       <=  ROW_START_DELAY;
    

    for (i = 0; i < 3; i = i + 1) begin
      for (j = 0; j < LANE_WIDTH; j = j + 1) begin
        //Raw unsynchronized data
        r_cam_raw_data[i][j]  <=  0;
        r_cam_raw_data[i][j]  <=  0;
        r_cam_raw_data[i][j]  <=  0;
      end
    end
  end
  else begin

    //VSYNC
    if (vsync_low_count < VSYNC_LOW_COUNT) begin
      vsync_low_count   <=  vsync_low_count + 1;
      hsync_low_count   <=  0;
      vsync_high_count  <=  0;
    end
    else begin
      if (vsync_high_count < VSYNC_HIGH_COUNT) begin
        if (row_end) begin
          vsync_high_count <=  vsync_high_count + 1;
        end
      end
      else begin
        vsync_low_count   <=  0;
      end
    end

    //HSYNC
    if (vs) begin
      if (hsync_low_count < HSYNC_LOW_COUNT) begin
        hsync_low_count   <= hsync_low_count + 1;
        hsync_high_count  <= 0;
      end
      else begin
        if (hsync_high_count < HSYNC_HIGH_COUNT) begin
          hsync_high_count <=  hsync_high_count + 1;
        end
        else begin
          hsync_low_count <= 0;
        end
      end
    end

    if (hs) begin
      if (row_start_delay < ROW_START_DELAY) begin
        row_start_delay <=  row_start_delay + 1;
      end
      else begin
        case (data_index)
          0: begin
            r_cam_raw_data[0][0]  <=  8'h7F;
          end
          1: begin
            r_cam_raw_data[0][0]  <=  8'h80;
          end
          2: begin
            r_cam_raw_data[0][0]  <=  8'h00;
          end
          3: begin
            r_cam_raw_data[0][0]  <=  8'h40;
          end
          4: begin
            r_cam_raw_data[0][0]  <=  8'h00;
          end
          default: begin
            r_cam_raw_data[0][0]  <=  8'h00;
          end
        endcase
        data_index  <=  data_index + 1;
      end
    end
    else begin
      row_start_delay <=  0;
      data_index      <=  0;
    end


    prev_hs <=  hs;
  end
end

endmodule
