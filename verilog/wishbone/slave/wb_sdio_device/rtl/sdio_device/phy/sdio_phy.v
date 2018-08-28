`include "sdio_defines.v"

module sdio_device_phy (
  input               rst,

  //Configuration
  input               i_ddr_en,
  input               i_spi_phy,
  input               i_sd1_phy,
  input               i_sd4_phy,

  //Data Link Interface
  output              o_cmd_phy_idle,
  output  reg         o_cmd_phy,
  output  reg         o_cmd_stb,
  output  reg         o_cmd_crc_good_stb,
  output  reg [5:0]   o_cmd,
  output  reg [31:0]  o_cmd_arg,

  input               i_rsps_stb,
  input       [39:0]  i_rsps,
  input       [7:0]   i_rsps_len,
  input               i_rsps_fail,
  output  reg         o_rsps_idle,

  //XXX: Need to hook this up
  input               i_interrupt,

  input               i_data_activate,
  output              o_data_finished,
  input               i_write_flag,
  input       [12:0]  i_data_count,

  output              o_data_wr_stb,
  output      [7:0]   o_data_wr_data,
  input               i_data_rd_stb,
  input       [7:0]   i_data_rd_data,
  output              o_data_hst_rdy,
  input               i_data_com_rdy,
  //FPGA Interface
  input               i_sdio_clk,

  output  reg         o_sdio_cmd_dir,
  input               i_sdio_cmd_in,
  output  reg         o_sdio_cmd_out,

  //FPGA Debug Interface
  output  [3:0]       o_state,
  output  reg [7:0]   o_gen_crc,
  output  reg [7:0]   o_rmt_crc,


  output              o_sdio_data_dir,
  input   [7:0]       i_sdio_data_in,
  output  [7:0]       o_sdio_data_out
);

//Local Parameters
localparam            IDLE              = 4'h0;
localparam            READ_COMMAND      = 4'h1;
localparam            RESPONSE_DIR_BIT  = 4'h2;
localparam            WAIT_FOR_RESPONSE = 4'h3;
localparam            RESPONSE          = 4'h4;
localparam            RESPONSE_FIRST_CRC= 4'h5;
localparam            RESPONSE_CRC      = 4'h6;
localparam            RESPONSE_FINISHED = 4'h7;

//Local Registers/Wires
reg   [3:0]           state;
reg   [3:0]           phy_mode;
reg   [7:0]           bit_count;
reg                   txrx_dir;
reg   [6:0]           r_crc;
wire  [6:0]           crc;
wire  [6:0]           crc_good;
wire                  busy;
wire                  crc_bit;
reg                   crc_en;
reg                   crc_rst;
reg   [39:0]          lcl_rsps;

//Submodules
crc7 crc_gen (
  .clk                (i_sdio_clk      ),
  .rst                (crc_rst         ),
  .bit                (crc_bit         ),
  .crc                (crc             ),
  .en                 (crc_en          )
);

sdio_data_phy data_phy(
  .clk                (i_sdio_clk      ),
  .rst                (rst             ),
  .i_interrupt        (i_interrupt     ),
  .i_ddr_en           (i_ddr_en        ),
  .i_spi_phy          (i_spi_phy       ),
  .i_sd1_phy          (i_sd1_phy       ),
  .i_sd4_phy          (i_sd4_phy       ),

  .i_activate         (i_data_activate ),
  .o_finished         (o_data_finished ),
  .i_write_flag       (i_write_flag    ),
  .i_data_count       (i_data_count    ),

  .o_data_wr_stb      (o_data_wr_stb   ),
  .o_data_wr_data     (o_data_wr_data  ),
  .i_data_rd_stb      (i_data_rd_stb   ),
  .i_data_rd_data     (i_data_rd_data  ),
  .o_data_hst_rdy     (o_data_hst_rdy  ),
  .i_data_com_rdy     (i_data_com_rdy  ),

  .o_sdio_data_dir    (o_sdio_data_dir ),
  .i_sdio_data_in     (i_sdio_data_in  ),
  .o_sdio_data_out    (o_sdio_data_out )
);

//Asynchronous Logic
assign  busy          = ((state != IDLE) || !i_sdio_cmd_in);
assign  crc_bit       = o_sdio_cmd_dir ? o_sdio_cmd_out: i_sdio_cmd_in;
assign  o_cmd_phy_idle  = !busy;
//Synchronous Logic

//XXX: this clock should probably be i_sdio_clk
always @ (posedge i_sdio_clk) begin
  if (rst) begin
    //Start out in SPI mode
    bit_count         <=  0;
    txrx_dir          <=  0;
    state             <=  IDLE;
    o_rsps_idle       <=  0;

    o_cmd_stb         <=  0;
    o_cmd             <=  0;
    o_cmd_arg         <=  0;
    r_crc             <=  0;
    o_sdio_cmd_out    <=  1;
    o_sdio_cmd_dir    <=  0;

    crc_en            <=  0;
    crc_rst           <=  1;
    lcl_rsps          <=  0;
    o_gen_crc         <=  0;
    o_rmt_crc         <=  0;
  end
  else begin
    //strobes
    o_cmd_stb         <=  0;
    o_cmd_crc_good_stb<=  0;
    crc_rst           <=  0;
    //Incrementing bit count
    if (busy) begin
      bit_count         <=  bit_count + 1;
    end
    else begin
      bit_count         <=  0;
    end


    case (state)
      IDLE: begin
        o_rsps_idle     <=  1;
        o_sdio_cmd_out  <=  1;
        o_sdio_cmd_dir  <=  0;
        crc_en          <=  0;
        crc_rst         <=  0;
        //Detect beginning of transaction when the command line goes low
        if (!i_sdio_cmd_in) begin
          o_rsps_idle   <=  0;
          crc_en        <=  1;
          //New Command Detected
          state         <=  READ_COMMAND;
        end
        else begin
          crc_rst       <=  1;
        end
      end
      READ_COMMAND: begin
        if (bit_count == `SDIO_C_BIT_ARG_END) begin
          crc_en        <=  0;
        end
        if (bit_count == `SDIO_C_BIT_TXRX_DIR)
          txrx_dir      <= i_sdio_cmd_in;
        else if ((bit_count >= `SDIO_C_BIT_CMD_START) && (bit_count <= `SDIO_C_BIT_CMD_END))
          o_cmd         <=  {o_cmd[4:0], i_sdio_cmd_in};
        else if ((bit_count >= `SDIO_C_BIT_ARG_START) && (bit_count <= `SDIO_C_BIT_ARG_END))
          o_cmd_arg     <=  {o_cmd_arg[30:0], i_sdio_cmd_in};
        else if ((bit_count >= `SDIO_C_BIT_CRC_START) && (bit_count <= `SDIO_C_BIT_CRC_END))
          r_crc         <=  {r_crc[5:0], i_sdio_cmd_in};
        else begin    //Last Bit
          r_crc         <=  {r_crc[5:0], i_sdio_cmd_in};
          state         <=  RESPONSE_DIR_BIT;
        end
      end
      RESPONSE_DIR_BIT: begin
        //Test
        o_gen_crc               <=  {1'b0, crc};
        o_rmt_crc               <=  {1'b0, r_crc};
        if (r_crc == crc) begin
          o_cmd_crc_good_stb    <=  1;
          crc_rst               <=  1;
        end
        o_cmd_stb               <=  1;
        o_sdio_cmd_out          <=  1;
        o_sdio_cmd_dir          <=  1;
        //End Test
        state                   <=  WAIT_FOR_RESPONSE;
      end
      WAIT_FOR_RESPONSE: begin
        if (i_rsps_stb) begin
          lcl_rsps                <=  i_rsps;
          state                   <=  RESPONSE;
          bit_count               <=  0;
          o_sdio_cmd_out          <=  0;  //Direction From Device to Host
        end
      end
      RESPONSE: begin
        crc_en                  <=  1;
        o_sdio_cmd_out          <=  lcl_rsps[39];
        lcl_rsps                <=  {lcl_rsps[38:0], 1'b0};
        if (bit_count >= i_rsps_len) begin
          crc_en                <=  0;
          state                 <=  RESPONSE_FIRST_CRC;
          bit_count             <=  0;
        end
      end
      RESPONSE_FIRST_CRC: begin
        o_gen_crc               <=  {1'b0, crc};
        o_sdio_cmd_out          <=  crc[6];
        r_crc                   <=  {crc[5:0], 1'b0};
        state                   <=  RESPONSE_CRC;
      end
      RESPONSE_CRC: begin
        o_sdio_cmd_out          <=  r_crc[6];
        r_crc                   <=  {r_crc[5:0], 1'b0};
        if (bit_count >= 8'h6) begin
          state                 <=  RESPONSE_FINISHED;
        end
      end
      RESPONSE_FINISHED: begin
        o_sdio_cmd_out          <=  1'b1;
        state                   <=  IDLE;
      end
      default: begin
        o_sdio_cmd_dir          <=  0;
        state                   <=  IDLE;
      end
    endcase
    if (i_rsps_fail) begin
      //Do not respond when we detect a fail
      state                     <=  IDLE;
    end
  end
end
assign  o_state   = state;
endmodule
