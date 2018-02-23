`timescale 1ns/1ps


module tb_cocotb #(
  parameter ADDR_WIDTH          = 10,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8)
)(

input                               clk,
input                               i_cam_0_clk,
input                               i_cam_1_clk,
input                               i_cam_2_clk,
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
wire       [2:0]                          w_serdes_io_rst;
wire                                      w_serdes_0_io_rst;
wire                                      w_serdes_1_io_rst;
wire                                      w_serdes_2_io_rst;

wire                                      i_cam_0_imx_vs;
wire                                      i_cam_0_imx_hs;
                                          
wire                                      i_cam_1_imx_vs;
wire                                      i_cam_1_imx_hs;
                                          
wire                                      i_cam_2_imx_vs;
wire                                      i_cam_2_imx_hs;


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
  .DEFAULT_TRIGGER_LEN    (10                  ),
  .DEFAULT_TRIGGER_PERIOD (100                 ),
  //.CAMERA_COUNT           (CAMERA_COUNT        ),
  .LANE_WIDTH             (LANE_WIDTH          ),
                                               
  .ADDR_WIDTH             (ADDR_WIDTH          ),
  .DATA_WIDTH             (DATA_WIDTH          ),
  .INVERT_AXI_RESET       (0                   )

) dut (
  .i_axi_clk              (clk                 ),
  .i_axi_rst              (r_rst               ),
                                               
  .i_cam_0_clk            (i_cam_0_clk         ),
  .i_cam_1_clk            (i_cam_1_clk         ),
  .i_cam_2_clk            (i_cam_2_clk         ),
                                               
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


  .o_serdes_0_io_rst      (w_serdes_io_rst[0]  ),
  .o_serdes_1_io_rst      (w_serdes_io_rst[1]  ),
  .o_serdes_2_io_rst      (w_serdes_io_rst[2]  ),
                                             
  //Raw unsynchronized data                  
  .i_cam_0_raw_data       (i_cam_0_raw_data    ),
  .i_cam_1_raw_data       (i_cam_1_raw_data    ),
  .i_cam_2_raw_data       (i_cam_2_raw_data    ),
                          
  //Synchronized data     
  .o_cam_0_sync_data      (o_cam_0_sync_data   ),
  .o_cam_1_sync_data      (o_cam_1_sync_data   ),
  .o_cam_2_sync_data      (o_cam_2_sync_data   ),
                                             
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

  .o_cam_0_tap_delay_rst  (o_cam_0_tap_delay_rst  ),
  .o_cam_1_tap_delay_rst  (o_cam_1_tap_delay_rst  ),
  .o_cam_2_tap_delay_rst  (o_cam_2_tap_delay_rst  ),

  //Vsync and HSync only inputs for now
  .i_cam_0_imx_vs         (i_cam_0_imx_vs      ),
  .i_cam_0_imx_hs         (i_cam_0_imx_hs      ),
                                               
  .i_cam_1_imx_vs         (i_cam_1_imx_vs      ),
  .i_cam_1_imx_hs         (i_cam_1_imx_hs      ),
                                               
  .i_cam_2_imx_vs         (i_cam_2_imx_vs      ),
  .i_cam_2_imx_hs         (i_cam_2_imx_hs      )
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


localparam  ROW_START_DELAY = 10;

wire vs[2:0];
wire hs[2:0];

reg prev_hs[2:0];


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

genvar fv;

generate
for (fv = 0; fv < LANE_WIDTH; fv = fv + 1) begin: FRAME_BLOCK
assign i_cam_0_raw_data[(fv * 8) + 7:(fv * 8)] = r_cam_raw_data[0][fv];
assign i_cam_1_raw_data[(fv * 8) + 7:(fv * 8)] = r_cam_raw_data[1][fv];
assign i_cam_2_raw_data[(fv * 8) + 7:(fv * 8)] = r_cam_raw_data[2][fv];
end
endgenerate

genvar gv;

generate
//always @ (posedge clk) begin
for (gv = 0; gv < 3; gv = gv + 1) begin : CAMERA_BLOCK

assign row_start[gv] = (!prev_hs[gv] & hs[gv]);
assign row_end[gv] = (prev_hs[gv] & !hs[gv]);

assign  hs[gv] = ((hsync_high_count[gv] < HSYNC_HIGH_COUNT) && (hsync_low_count[gv] == HSYNC_LOW_COUNT));
assign  vs[gv] = ((vsync_high_count[gv] < VSYNC_HIGH_COUNT) && (vsync_low_count[gv] == VSYNC_LOW_COUNT));



always @ (posedge cam_clk[gv]) begin
  if (w_serdes_io_rst[gv]) begin
    vsync_low_count[gv]       <=  0;
    vsync_high_count[gv]      <=  VSYNC_HIGH_COUNT;
    data_index[gv]            <=  0;

    hsync_low_count[gv]       <=  HSYNC_LOW_COUNT;
    hsync_high_count[gv]      <=  HSYNC_HIGH_COUNT;
    row_start_delay[gv]       <=  ROW_START_DELAY;
    

    for (j = 0; j < LANE_WIDTH; j = j + 1) begin
      //Raw unsynchronized data
      r_cam_raw_data[gv][j]  <=  0;
      r_cam_raw_data[gv][j]  <=  0;
      r_cam_raw_data[gv][j]  <=  0;
    end
  end
  else begin

    //VSYNC
    if (vsync_low_count[gv] < VSYNC_LOW_COUNT) begin
      vsync_low_count[gv]   <=  vsync_low_count[gv] + 1;
      hsync_low_count[gv]   <=  0;
      vsync_high_count[gv]  <=  0;
    end
    else begin
      if (vsync_high_count[gv] < VSYNC_HIGH_COUNT) begin
        if (row_end[gv]) begin
          vsync_high_count[gv] <=  vsync_high_count[gv] + 1;
        end
      end
      else begin
        vsync_low_count[gv]   <=  0;
      end
    end

    //HSYNC
    if (vs[gv]) begin
      if (hsync_low_count[gv] < HSYNC_LOW_COUNT) begin
        hsync_low_count[gv]   <= hsync_low_count[gv] + 1;
        hsync_high_count[gv]  <= 0;
      end
      else begin
        if (hsync_high_count[gv] < HSYNC_HIGH_COUNT) begin
          hsync_high_count[gv] <=  hsync_high_count[gv] + 1;
        end
        else begin
          hsync_low_count[gv] <= 0;
        end
      end
    end

    if (hs[gv]) begin
      if (row_start_delay[gv] < ROW_START_DELAY) begin
        row_start_delay[gv] <=  row_start_delay[gv] + 1;
      end
      else begin
        case (data_index[gv])
          0: begin
            r_cam_raw_data[gv][0]  <=  8'h7F;
          end
          1: begin
            r_cam_raw_data[gv][0]  <=  8'h80;
          end
          2: begin
            r_cam_raw_data[gv][0]  <=  8'h00;
          end
          3: begin
            r_cam_raw_data[gv][0]  <=  8'h40;
          end
          4: begin
            r_cam_raw_data[gv][0]  <=  8'h00;
          end
          default: begin
            r_cam_raw_data[gv][0]  <=  8'h00;
          end
        endcase
        data_index[gv]  <=  data_index[gv] + 1;
      end
    end
    else begin
      row_start_delay[gv] <=  0;
      data_index[gv]      <=  0;
    end


    prev_hs[gv] <=  hs[gv];
  end
end
end
endgenerate

endmodule
