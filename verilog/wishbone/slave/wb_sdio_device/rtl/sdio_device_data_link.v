/*
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
 * Author: David McCoy
 * Description: Data Link Layer for device side of SDIO
 *  This layer is above the PHY, it expects that data will arrive as data
 *  values instead of a stream of bits
 *  This behaves as a register map and controls data transfers
 *
 *  SPI MODE IS NOT SUPORTED YET, SO IF DATA[1] IS LOW DO NOT REPSOND!
 *
 * Changes:
 *  2015.08.09: Inital Commit
 */

module sdio_device_data_link #(
  parameter           NUM_FUNCS       = 1,        /* Number of SDIO Functions available */
  parameter           MEM_PRESENT     = 0,        /* Not supported yet */
  parameter           UHSII_AVAILABLE = 0,        /* UHS Mode Not available yet */
  parameter           IO_OCR          = 24'hFFF0  /* Operating condition mode (voltage range) */
)(
  input               sdio_clk,
  input               rst,

  //Functio Interface
  output  reg               func_stb,
  input                     func_ack_stb,
  output  reg               func_num,
  output  reg               func_write_flag,      /* Read = 0, Write = 1 */
  output  reg               func_read_after_write,
  output  reg   [17:0]      func_reg_addr,
  output  reg   [7:0]       func_reg_write_data,
  input         [7:0]       func_reg_read_data,

  //PHY Interface
  input                     cmd_stb,
  input                     cmd_crc_good_stb,
  input         [5:0]       cmd,
  input         [31:0]      cmd_arg,

  input                     chip_select_n,

  output        [127:0]     rsps,
  output        [7:0]       rsps_len,
  output  reg               rsps_stb

);
//local parameters
localparam      NORMAL_RESPONSE     = 1'b0;
localparam      EXTENDED_RESPONSE   = 1'b1;

localparam      RESET               = 4'h0;
localparam      INITIALIZE          = 4'h1;
localparam      STANDBY             = 4'h2;  /* Standby */
localparam      COMMAND             = 4'h3;
localparam      TRANSFER            = 4'h4;
localparam      INACTIVE            = 4'h5;
//registes/wires
reg       [3:0]       state;

reg       [47:0]      response_value;
reg       [136:0]     response_value_extended;
reg                   response_type;
reg       [15:0]      register_card_address;  /* Host can set this so later it can be used to identify this card */
reg       [3:0]       voltage_select;
reg                   v1p8_sel;
reg       [23:0]      vio_ocr;
reg                   busy;

reg                   crc_bad;
reg                   cmd_arg_out_of_range;
reg                   illegal_command;
reg                   card_error;

/*
 * Needed
 *
 *  OCR (32 bit) CMD5 (SD_CMD_SEND_OP_CMD) ****
 *  X CID (128 bit) CMD10 (SD_CMD_SEND_CID) NOT SUPPORTED ON SDIO ONLY
 *  X CSD (128 bit) CMD9  (SD_CMD_SEND_CSD) NOT SUPPORTED ON SDIO ONLY
 *  RCA (16 bit) ???
 *  X DSR (16 bit optional) NOT SUPPORTED ON SDIO ONLY
 *  X SCR (64 bit) NOT SUPPORTED ON SDIO ONLY
 *  X SD_CARD_STATUS (512 bit) NOT SUPPORED ON SDIO ONLY
 *  CCCR
 */

//submodules
//asynchronous logic
assign  rsps[135]   = 1'b0; //Start bit
assign  rsps[134]   = 1'b0; //Direction bit (to the host)
assign  rsps[133:0] = response_type ? response_value_extended[133:0] : {response_value[45:0], 87'h0};
assign  rsps_len    = response_type ? 128 : 40;
//synchronous logic


always @ (posedge sdio_clk) begin
  if (rst) begin
    response_type           <=  NORMAL_RESPONSE;
    response_value          <=  32'h00000000;
    response_value_extended <=  128'h00;
  end
  else if (rsps_stb || func_ack_stb) begin
    //Strobe
    //Process Command
    case (cmd)
      `SD_CMD_GO_IDLE_STATE:      begin
        //R1
        response_type                                                     <=  NORMAL_RESPONSE;
        response_value[`CMD_RSP_CMD]                                      <=  cmd;
        response_value[`CMD_RSP_CRD_STS_START:`CMD_RSP_CRD_STS_END]       <=  32'h0;
        response_value[`CARD_STS_OUT_OF_RANGE]                            <=  cmd_arg_out_of_range;
        response_value[`CARD_STS_CRC_ERROR]                               <=  crc_bad;
        response_value[`CARD_STS_ILLEGAL_COMMAND]                         <=  illegal_command;
        response_value[`CARD_STS_ERROR]                                   <=  card_error;
        response_value[`CARD_CURRENT_STATE_START:`CARD_CURRENT_STATE_END] <=  4'hF;
      end
      `SD_CMD_SEND_RELATIVE_ADDR: begin
        //Relative address response
        response_type                                                     <=  NORMAL_RESPONSE;
        register_card_address                                             <=  `RELATIVE_CARD_ADDRESS;
        response_value[`CMD3_RSP_REL_ADDR_START:`CMD3_RSP_REL_ADDR_END]   <=  `RELATIVE_CARD_ADDRESS;
      end
      `SD_CMD_IO_SEND_OP_CMD:     begin
        response_type                                                     <=  NORMAL_RESPONSE;
        response_value[`CMD5_RSP_READY]                                   <=  1'b1;
        response_value[`CMD5_RSP_NUM_FUNCS]                               <=  NUM_FUNCS;
        response_value[`CMD5_RSP_MEM_PRESENT]                             <=  MEM_PRESENT;
        response_value[`CMD5_RSP_UHSII_AVAILABLE]                         <=  UHSII_AVAILABLE;
        response_value[`CMD5_RSP_IO_OCR]                                  <=  cmd_arg[`CMD5_OCR_START:`CMD5_OCR_END];
      end
      `SD_CMD_SWITCH_FUNC:        begin
      end
      `SD_CMD_SEL_DESEL_CARD:     begin
      end
      `SD_CMD_SEND_IF_COND:       begin
        response_type                                                     <=  NORMAL_RESPONSE;
        response_value[`CMD_RSP_CMD]                                      <=  cmd;
        response_value[39:20]                                             <=  20'h00;
        response_value[`CMD8_RSP_PATTERN]                                 <=  cmd_arg[`CMD8_ARG_PATTERN];
        response_value[`CMD8_RSP_VHS]                                     <=  cmd_arg[`CMD_ARG_VHS] & VHS_DEFAULT_VALUE;
      end
      `SD_CMD_VOLTAGE_SWITCH:     begin
      end
      `SD_CMD_GO_INACTIVE_STATE:  begin
      end
      `SD_CMD_SEND_TUNNING_BLOCK: begin
      end
      `SD_CMD_IO_RW_DIRECT:       begin
        //single byte access to the SDIO Function
        response_type                                                     <=  NORMAL_RESPONSE;
        response_value[`CMD_RSP_CMD]                                      <=  cmd;
        response_value
      end
      `SD_CMD_IO_RW_EXTENDED:     begin
        //Multiple Byte/Block access to the SDIO Function
      end
      default: begin
      end
    endcase
  end
end


always @ (posedge sdio_clk) begin
  //Deassert Strobes
  rsps_stb                  <=  0;
  func_stb                  <=  0;

  if (rst) begin
    state                   <=  INITIALIZE;
    register_card_address   <=  16'h0001;       // Initializes the RCA to 0
    voltage_select          <=  `VHS_DEFAULT_VALUE;
    v1p8_sel                <=  0;
    vio_ocr                 <=  24'd21;

    crc_bad                 <=  0;
    cmd_arg_out_of_range    <=  0;
    illegal_command         <=  0;  //Illegal Command for the Given State
    card_error              <=  0;  //Unknown Error


    func_stb                <=  0;
    func_write_flag         <=  0;  /* Read Write Flag R = 0, W = 1 */
    func_num                <=  4'h0;
    func_read_after_write   <=  0;
    func_reg_addr           <=  18'h0;
    func_reg_byte           <=  8'h0;
    busy                    <=  0;

  end
  else if (cmd_stb && !cmd_crc_good_stb) begin
    crc_bad                 <=  1;
    //Do not send a response
  end
  else if (cmd_stb) begin
    //Strobe
    //Card Bootup Sequence
    case (state)
      RESET: begin
      end
      INITIALIZE: begin
        case (cmd)
          `SD_CMD_IO_SEND_OP_CMD: begin
            rsps_stb            <=  1;
          end
          `SD_CMD_SEND_RELATIVE_ADDR: begin
            state               <=  STANDBY;
            rsps_stb            <=  1;
          end
          `SD_CMD_GO_INACTIVE_STATE: begin
            state               <=  INACTIVE;
            rsps_stb            <=  1;
          end
          default: begin
            illegal_command     <=  1;
          end
        endcase
      end
      STANDBY: begin
        case (cmd)
          `SD_CMD_SEND_RELATIVE_ADDR: begin
            state               <=  STANDBY;
            rsps_stb            <=  1;
          end
          `SD_CMD_SEL_DESEL_CARD: begin
            if (register_card_address == cmd_arg[15:0]) begin
              state             <= COMMAND;
            end
            rsps_stb            <=  1;
          end
          `SD_CMD_GO_INACTIVE_STATE: begin
            state               <=  INACTIVE;
            rsps_stb            <=  1;
          end
          default: begin
            illegal_command     <=  1;
          end
        endcase
      end
      COMMAND: begin
        case (cmd)
          `SD_CMD_IO_RW_DIRECT: begin
            func_write_flag         <= cmd_arg[`CMD52_ARG_RW_FLAG];
            func_num                <= cmd_arg[`CMD52_ARG_FNUM];
            func_read_after_write   <= cmd_arg[`CMD52_ARG_RAW_FLAG];
            func_reg_addr           <= cmd_arg[`CMD52_ARG_REG_ADDR];
            func_reg_write_data     <= cmd_arg[`CMD52_ARG_WR_DATA];
            func_stb                <= 1;
            busy                    <= 1;
            if( cmd_arg[`CMD52_ARG_FNUM]                                 &&
                cmd_arg[`CMD52_ARG_REG_ADDR] == cmd_arg[`CMD52_RST_ADDR] &&
               !cmd_arg[`CMD52_ARG_RW_FLAG]                              &&
                cmd_arg[`CMD52_ARG_WR_DATA][CMD52_RST_BIT]) begin
              state                 <= INITIALIZE;
            end
            else begin
              state                 <= TRANSFER;
            end
            rsps_stb                <=  1;
          end
          `SD_CMD_SEL_DESEL_CARD: begin
            if (register_card_address == cmd_arg[15:0]) begin
              state             <= COMMAND;
            end
            else begin
              state             <= STANDBY;
            end
            rsps_stb            <=  1;
          end
          `SD_CMD_GO_INACTIVE_STATE: begin
            state               <=  INACTIVE;
            rsps_stb            <=  1;
          end
          default: begin
            illegal_command     <=  1;
          end
        endcase
      end
      TRANSFER: begin
        case (cmd)
          `SD_CMD_IO_RW_DIRECT: begin
            func_write_flag         <= cmd_arg[`CMD52_ARG_RW_FLAG];
            func_num                <= cmd_arg[`CMD52_ARG_FNUM];
            func_read_after_write   <= cmd_arg[`CMD52_ARG_RAW_FLAG];
            func_reg_addr           <= cmd_arg[`CMD52_ARG_REG_ADDR];
            func_reg_write_data     <= cmd_arg[`CMD52_ARG_WR_DATA];
            func_stb                <= 1;
            busy                    <= 1;
            if( cmd_arg[`CMD52_ARG_FNUM]                                 &&
                cmd_arg[`CMD52_ARG_REG_ADDR] == cmd_arg[`CMD52_RST_ADDR] &&
               !cmd_arg[`CMD52_ARG_RW_FLAG]                              &&
                cmd_arg[`CMD52_ARG_WR_DATA][CMD52_RST_BIT]) begin
              state                 <= INITIALIZE;
            end
            rsps_stb            <=  1;
          end
          default: begin
            illegal_command     <=  1;
          end
        endcase
      end
      INACTIVE: begin
        //Nothing Going on here
      end
      default: begin
      end
    endcase

    //Always Respond to these commands regardless of state
    if (cmd_stb) begin
      case (cmd)
        `SD_CMD_GO_IDLE_STATE: begin
          if (!chip_select_n) begin
            //We are in SD Mode
            //state           <=  INITIALIZE;
            rsps_stb        <=  1;
          end
          else begin
            //XXX: SPI MODE IS NOT SUPPORTED YET!!!
          end
        end
        `SD_CMD_SEND_IF_COND:       begin
          if (cmd_arg[`CMD_ARG_VHS] & VHS_DEFAULT_VALUE) begin
            v1p8_sel          <=  cmd_arg[`CMD5_ARG_S18R];
            vio_ocr           <=  cmd_arg[`CMD5_IO_OCR];
            if (cmd_arg[`CMD_ARG_VHS] & VHS_DEFAULT_VALUE)
              voltage_select  <=  cmd_arg[`CMD_ARG_VHS] & VHS_DEFAULT_VALUE;
            rsps_stb          <=  1;
        end
        `SD_CMD_IO_RW_DIRECT: begin
          //XXX: Check if the reset bit is set
        end
        default: begin
        end
      endcase
    end

  end
  else if (rsps_stb) begin
    //Whenever a response is successful de-assert any of the errors, they will have been picked up by the response
    crc_bad                 <=  0;
    cmd_arg_out_of_range    <=  0;
    illegal_command         <=  0;
    card_error              <=  0;  //Unknown Error
  end
  else if (func_ack_stb) begin
    busy                    <=  0;
  end
end


endmodule
