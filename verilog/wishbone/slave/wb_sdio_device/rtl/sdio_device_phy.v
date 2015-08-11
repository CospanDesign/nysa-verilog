`include "sdio_defines.v"

module sdio_device_phy (
  //input               clk,
  input               rst,

  //Configuration
  input               spi_phy,
  input               sd1_phy,
  input               sd4_phy,

  //Data Link Interface
  output              cmd_phy_idle,
  output  reg         cmd_phy,
  output  reg         cmd_stb,
  output  reg         cmd_crc_good_stb,
  output  reg [5:0]   cmd,
  output  reg [31:0]  cmd_arg,

  input       [127:0] rsps,
  input       [7:0]   rsps_len,
  input               rsps_fail,

  //XXX: Need to hook this up
  input               interrupt,
  //XXX: Need to hook this up
  input               read_wait,

  //FPGA Interface
  output              ddr_en,
  input               sdio_clk,
  input               sdio_cmd_in,
  output  reg         sdio_cmd_out,
  output  reg         sdio_cmd_dir,
  //XXX: Need to hook this up
  input   [3:0]       sdio_data_in,
  output  [3:0]       sdio_data_out,
  output              sdio_data_dir
);

//Local Parameters
localparam            IDLE              = 4'h0;
localparam            READ_COMMAND      = 4'h1;
localparam            RESPONSE_DIR_BIT  = 4'h2;
localparam            RESPONSE          = 4'h3;
localparam            RESPONSE_CRC      = 4'h4;
localparam            RESPONSE_FINISHED = 4'h5;

//Local Registers/Wires
reg   [3:0]           state;
reg   [3:0]           phy_mode;
reg   [7:0]           bit_count;
reg                   txrx_dir;
reg   [7:0]           cmd_crc;
wire  [6:0]           crc;
wire                  busy;
wire                  crc_bit;
reg                   crc_hold;
reg                   crc_rst;
reg   [127:0]         lcl_rsps;

//Submodules
crc7 crc_gen (
  .clk               (sdio_clk ),
  .rst               (crc_rst  ),
  .bit               (crc_bit  ),
  .crc               (crc      ),
  .hold              (crc_hold )
);
//Asynchronous Logic
assign  busy          = ((state != IDLE) || !sdio_cmd_in);
assign  crc_bit       = sdio_cmd_dir ? sdio_cmd_out: sdio_cmd_in;
assign  cmd_phy_idle  = !busy;
//Synchronous Logic

//XXX: this clock should probably be sdio_clk
always @ (posedge sdio_clk) begin
  if (rst) begin
    //Start out in SPI mode
    bit_count       <=  0;
    txrx_dir        <=  0;
    state           <=  IDLE;

    cmd_stb         <=  0;
    cmd             <=  0;
    cmd_arg         <=  0;
    cmd_crc         <=  0;
    sdio_cmd_out    <=  1;
    sdio_cmd_dir    <=  0;

    crc_hold        <=  0;
    crc_rst         <=  1;
    lcl_rsps        <=  0;
  end
  else begin
    //strobes
    cmd_stb         <=  0;
    cmd_crc_good_stb<=  0;
    crc_rst         <=  0;


    //Incrementing bit count
    if (busy) begin
      bit_count     <=  bit_count + 1;
    end
    else begin
      bit_count     <=  0;
    end
    case (state)
      IDLE: begin
        sdio_cmd_out  <=  1;
        sdio_cmd_dir  <=  0;
        crc_hold      <=  0;
        crc_rst       <=  1;
        //Detect beginning of transaction when the command line goes low
        if (!sdio_cmd_in) begin
          //New Command Detected
          state       <=  READ_COMMAND;
        end
      end
      READ_COMMAND: begin
        if (bit_count == `SDIO_C_BIT_TXRX_DIR)
          txrx_dir    <= sdio_cmd_in;
        else if ((bit_count >= `SDIO_C_BIT_CMD_START) && (bit_count <= `SDIO_C_BIT_CMD_END))
          cmd         <=  {cmd[4:0], sdio_cmd_in};
        else if ((bit_count >= `SDIO_C_BIT_ARG_START) && (bit_count <= `SDIO_C_BIT_ARG_END))
          cmd_arg     <=  {cmd_arg[30:0], sdio_cmd_in};
        else if ((bit_count >= `SDIO_C_BIT_CRC_START) && (bit_count <= `SDIO_C_BIT_CRC_END))
          cmd_crc     <=  {cmd_crc[5:0], sdio_cmd_in};
        else begin    //Last Bit
          if (cmd_crc == crc)
            cmd_crc_good_stb    <=  1;
          crc_rst       <=  1;
          cmd_stb       <=  1;
          bit_count     <=  0;
          sdio_cmd_dir  <=  1;
          sdio_cmd_out  <=  0;
          state         <=  RESPONSE_DIR_BIT;
        end
      end
      RESPONSE_DIR_BIT: begin
        sdio_cmd_out    <=  0;  //Direction From Device to Host
        bit_count       <=  0;
        state           <=  RESPONSE;
        lcl_rsps        <=  rsps;
      end
      RESPONSE: begin
        sdio_cmd_out    <=  lcl_rsps[127];
        lcl_rsps        <=  {lcl_rsps[126:0], 1'b0};
        if (bit_count >= rsps_len) begin
          state         <=  RESPONSE_CRC;
          bit_count     <=  0;
          crc_hold      <=  1;
        end
      end
      RESPONSE_CRC: begin
        sdio_cmd_out    <=  crc[6];
        cmd_crc          <=  {crc[5:0], 1'b0};
        if (bit_count >= 8'h7) begin
          state         <=  RESPONSE_FINISHED;
        end
      end
      RESPONSE_FINISHED: begin
        sdio_cmd_out    <=  1'b1;
        state           <=  IDLE;
      end
      default: begin
        sdio_cmd_dir    <=  0;
        state           <=  IDLE;
      end
    endcase
    
    if (rsps_fail) begin
      //Do not respond when we detect a fail
      state             <=  IDLE;
    end
  end
end
endmodule
