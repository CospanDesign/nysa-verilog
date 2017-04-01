`timescale 1ns/1ps


module tb_cocotb #(
  parameter ADDR_WIDTH          = 32,
  parameter DATA_WIDTH          = 32,
  parameter RGB_WIDTH           = 24,
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
output      [DATA_WIDTH - 1: 0]     AXIML_RDATA,


//RGB Video interface
input       [RGB_WIDTH - 1:0]       VIDEO_RGB,
input                               VIDEO_HSYNC,
input                               VIDEO_VSYNC,
input                               VIDEO_DATA_EN,
input                               VIDEO_HBLANK,
input                               VIDEO_VBLANK

);


//Parameters
//Registers

reg               r_rst;
always @ (*)      r_rst           = rst;
reg   [3:0]       test_id         = 0;

reg   [31:0]      r_tear_count;
reg   [7:0]       r_tear_status;

wire              w_backlight_enable;
wire              w_register_data_sel;
reg               r_tearing_effect;
wire              w_write_n;
wire              w_read_n;
wire  [7:0]       w_data;
wire              w_cs_n;
wire              w_reset_n;
wire              w_display_on;


reg   [7:0]       r_read_data;

reg   [15:0]      r_write_parameter;




//submodules

axi_pmod_tft #(
  .ADDR_WIDTH         (ADDR_WIDTH       ),
  .DATA_WIDTH         (DATA_WIDTH       ),
  .RGB_WIDTH          (RGB_WIDTH        ),
  .INVERT_AXI_RESET   (0                ),
  .INVERT_VIDEO_RESET (0                ),
  .BUFFER_SIZE        (9                )
) dut (
  .clk                (clk              ),
  .rst                (r_rst            ),


  //AXI Lite Interface
  .i_awvalid          (AXIML_AWVALID    ),
  .i_awaddr           (AXIML_AWADDR     ),
  .o_awready          (AXIML_AWREADY    ),


  .i_wvalid           (AXIML_WVALID     ),
  .o_wready           (AXIML_WREADY     ),
  .i_wstrb            (AXIML_WSTRB      ),
  .i_wdata            (AXIML_WDATA      ),


  .o_bvalid           (AXIML_BVALID     ),
  .i_bready           (AXIML_BREADY     ),
  .o_bresp            (AXIML_BRESP      ),


  .i_arvalid          (AXIML_ARVALID    ),
  .o_arready          (AXIML_ARREADY    ),
  .i_araddr           (AXIML_ARADDR     ),


  .o_rvalid           (AXIML_RVALID     ),
  .i_rready           (AXIML_RREADY     ),
  .o_rresp            (AXIML_RRESP      ),
  .o_rdata            (AXIML_RDATA      ),

  //AXI Stream
  .i_video_clk        (clk              ),
  .i_video_rst        (r_rst            ),
  .i_video_rgb        (VIDEO_RGB        ),
  .i_video_h_sync     (VIDEO_HSYNC      ),
  .i_video_v_sync     (VIDEO_VSYNC      ),
  .i_video_data_en    (VIDEO_DATA_EN    ),

  //Physical Signals

  .o_backlight_enable  (w_backlight_enable  ),
  .i_tearing_effect    (r_tearing_effect    ),
  .o_register_data_sel (w_register_data_sel ),
  .o_write_n           (w_write_n           ),
  .o_read_n            (w_read_n            ),
  .io_data             (w_data              ),
  .o_cs_n              (w_cs_n              ),
  .o_reset_n           (w_reset_n           ),
  .o_display_on        (w_display_on        )

);

//asynchronus logic
assign  w_data  = (!w_read_n) ? r_read_data: 8'hZZ;
//synchronous logic

initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

always @ (posedge clk) begin
  if (rst) begin
    r_tear_count            <=  0;
    r_tear_status           <=  8'h00;
    r_tearing_effect        <=  0;
  end
  else begin
    if (r_tear_count < 100) begin
      r_tear_count          <=  r_tear_count + 1;
    end
    else begin
      if (r_tear_status == 8'h00) begin
        r_tear_status       <=  8'h80;
        r_tearing_effect    <=  1;
      end
      else begin
        r_tear_status       <=  8'h00;
        r_tearing_effect    <=  0;
      end
      r_tear_count          <= 0;
    end
  end
end

always @ (posedge clk) begin
  if (rst) begin
    r_read_data             <=  0;
    r_write_parameter       <=  0;
  end
  else begin
    if (!w_write_n && w_register_data_sel) begin
      r_write_parameter     <=  {r_write_parameter[7:0], w_data};
    end
    if (!w_register_data_sel & !w_cs_n) begin
      case (w_data)
        0: begin
          r_read_data       <=  8'h01;
        end
        14: begin
          r_read_data       <=  r_tear_status;
        end
        44: begin
          r_read_data       <=  8'hFF;
        end
        184: begin
          r_read_data       <=  8'hAA;
        end
      endcase
    end
  end
end


endmodule
