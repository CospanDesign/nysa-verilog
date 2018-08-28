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
 * Description: Card Controller for device side of SDIO
 *  This layer is above the PHY, it expects that data will arrive as data
 *  values instead of a stream of bits
 *  This behaves as a register map and controls data transfers
 *
 *  SPI MODE IS NOT SUPORTED YET, SO IF CS_N IS LOW DO NOT REPSOND!
 *
 * Changes:
 *  2015.08.09: Inital Commit
 *  2015.08.13: Changed name to card controller
 */


/* TODO:
 *  - How to implement busy??
 */

//`include "sdio_cia_defines.v"

module sdio_card_control (

  input                     sdio_clk,
  input                     rst,
  input                     i_soft_reset,
  input         [7:0]       i_func_interrupt,
  input         [7:0]       i_func_interrupt_en,
  output                    o_interrupt,

  //SD Flash Interface
  output                    o_mem_en,
  //Function Interface
  output  reg               o_func_activate,
  input                     i_func_finished,

  output  reg   [3:0]       o_func_num,
  output  reg               o_func_inc_addr,
  output  reg               o_func_block_mode,

  output  reg               o_func_write_flag,      /* Read = 0, Write = 1 */
  output  reg               o_func_rd_after_wr,
  output  reg   [17:0]      o_func_addr,
  output  reg   [12:0]      o_func_data_count,

  //Command Data Bus
  output  reg               o_cmd_bus_sel,
  output  reg   [7:0]       o_func_write_data,
  input         [7:0]       i_func_read_data,

  // tunning block
  output  reg               o_tunning_block,

  //Debug
  output        [3:0]       o_state,

  //PHY Interface
  input                     i_cmd_stb,
  input                     i_cmd_crc_good_stb,
  input         [5:0]       i_cmd,
  input         [31:0]      i_cmd_arg,
  input                     i_cmd_phy_idle,

  input                     i_chip_select_n,

  output  reg               o_rsps_stb,
  output        [39:0]      o_rsps,
  output        [7:0]       o_rsps_len,
  output  reg               o_rsps_fail,
  input                     i_rsps_idle

);

//local parameters
localparam      NORMAL_RESPONSE     = 1'b0;
localparam      EXTENDED_RESPONSE   = 1'b1;

localparam      RESET               = 4'h0;
localparam      INITIALIZE          = 4'h1;
localparam      STANDBY             = 4'h2;
localparam      COMMAND             = 4'h3;
localparam      TRANSFER            = 4'h4;
localparam      INACTIVE            = 4'h5;

localparam      R1                  = 4'h1;
localparam      R2                  = 4'h2;
localparam      R3                  = 4'h3;
localparam      R4                  = 4'h4;
localparam      R5                  = 4'h5;
localparam      R6                  = 4'h6;
localparam      R7                  = 4'h7;

//registes/wires
reg             [3:0]       state;

reg             [47:0]      response_value;
//reg             [136:0]     response_value_extended;
reg                         response_type;
reg             [15:0]      register_card_address;  /* Host can set this so later it can be used to identify this card */
reg             [23:0]      voltage_select;
reg                         v1p8_sel;

reg                         bad_crc;
reg                         cmd_arg_out_of_range;
reg                         illegal_command;
reg                         card_error;

reg             [3:0]       response_index;

wire            [1:0]       r5_cmd;
wire            [15:0]      max_f0_block_size;
wire                        enable_async_interrupt;
wire                        data_txrx_in_progress_flag;

reg             [3:0]       component_select;
reg                         rsps_stb;
reg                         rsps_fail;


reg                         direct_read_write;  //Read/Write using command channel
reg             [17:0]      data_count;
reg             [7:0]       cmd_data;



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

//asynchronous logic
assign  o_rsps      = response_value[47:8];
assign  o_rsps_len  = 40;

assign  r5_cmd      = (state == RESET) || (state == INITIALIZE) || (state == STANDBY) || (state == INACTIVE) ? 2'b00 :
                      (state == COMMAND)                                                                     ? 2'b01 :
                      (state == TRANSFER)                                                                    ? 2'b10 :
                                                                                                               2'b11;

//assign  o_func_host_rdy = i_cmd_phy_idle; /* Can only send data when i_cmd phy is not sending data */
//assign  cia_activate  = (o_func_num == 0);
assign  o_mem_en      = 1'b0;
assign  o_interrupt   = ((i_func_interrupt & i_func_interrupt_en) > 0);

//synchronous logic
initial begin
  state               <=  RESET;
end
always @ (posedge sdio_clk) begin
  o_rsps_stb                <=  0;
  if (rst) begin
    response_type           <=  NORMAL_RESPONSE;
    response_value          <=  48'h00000000;
//    response_value_extended <=  128'h00;
  end
  else if (rsps_stb) begin
    //Strobe
    //Process Command
    o_rsps_stb                                <=  1;
    case (response_index)
      R1: begin
        //R1
        response_type                         <=  NORMAL_RESPONSE;
        response_value                        <=  48'h0;
        response_value[`CMD_RSP_CMD]          <=  i_cmd;
        response_value[`R1_OUT_OF_RANGE]      <=  cmd_arg_out_of_range;
        response_value[`R1_COM_CRC_ERROR]     <=  bad_crc;
        response_value[`R1_ILLEGAL_COMMAND]   <=  illegal_command;
        response_value[`R1_ERROR]             <=  card_error;
        response_value[`R1_CURRENT_STATE]     <=  4'hF;
      end
      R4: begin
        //R4:
        response_type                         <=  NORMAL_RESPONSE;
        response_value                        <=  48'h0;
        response_value[`R4_RSRVD]             <=  6'h3F;
        response_value[`R4_READY]             <=  1'b1;
        response_value[`R4_NUM_FUNCS]         <=  `NUM_FUNCS;
        response_value[`R4_MEM_PRESENT]       <=  `MEM_PRESENT;
        response_value[`R4_UHSII_AVAILABLE]   <=  `UHSII_AVAILABLE;
        response_value[`R4_S18A]              <=  v1p8_sel;
        //response_value[`R4_IO_OCR]            <=  voltage_select;
        response_value[`R4_IO_OCR]            <=  `OCR_VALUE;
        //response_value[7:0]                   <=  8'h00;
      end
      R5: begin
        //R5:
        response_type                         <=  NORMAL_RESPONSE;
        response_value                        <=  48'h0;
        response_value[`CMD_RSP_CMD]          <=  i_cmd;
        response_value[`R5_FLAG_CRC_ERROR]    <=  bad_crc;
        response_value[`R5_INVALID_CMD]       <=  illegal_command;
        response_value[`R5_FLAG_CURR_STATE]   <=  r5_cmd;
        response_value[`R5_FLAG_ERROR]        <=  card_error;
        response_value[`R5_DATA]              <=  cmd_data;
      end
      R6: begin
        //R6: Relative address response
        response_type                         <=  NORMAL_RESPONSE;
        response_value                        <=  48'h0;
        response_value[`CMD_RSP_CMD]          <=  i_cmd;
        response_value[`R6_REL_ADDR]          <=  register_card_address;
        response_value[`R6_STS_CRC_COMM_ERR]  <=  bad_crc;
        response_value[`R6_STS_ILLEGAL_CMD]   <=  illegal_command;
        response_value[`R6_STS_ERROR]         <=  card_error;
      end
      R7: begin
        //R7
        response_type                         <=  NORMAL_RESPONSE;
        response_value                        <=  48'h0;
        response_value[`CMD_RSP_CMD]          <=  i_cmd;
        response_value[`R7_VHS]               <=  i_cmd_arg[`CMD8_ARG_VHS];
        response_value[`R7_PATTERN]           <=  i_cmd_arg[`CMD8_ARG_PATTERN];
      end
      default: begin
        response_value                        <=  48'h0;
      end
    endcase
  end
end

always @ (posedge sdio_clk) begin
  //Deassert Strobes
  rsps_stb                          <=  0;
  o_func_activate                   <=  0;

  if (rst || i_soft_reset) begin
    state                           <=  INITIALIZE;
    register_card_address           <=  16'h0001;       // Initializes the RCA to 0
    voltage_select                  <=  `OCR_VALUE;
    v1p8_sel                        <=  0;

    bad_crc                         <=  0;
    cmd_arg_out_of_range            <=  0;
    illegal_command                 <=  0;              //Illegal Command for the Given State
    card_error                      <=  0;              //Unknown Error

    o_func_inc_addr                 <=  0;
    o_func_block_mode               <=  0;
    o_func_num                      <=  4'h0;
    o_func_write_flag               <=  0;              /* Read Write Flag R = 0, W = 1 */
    o_func_rd_after_wr              <=  0;
    o_func_addr                     <=  18'h0;
    o_func_write_data               <=  8'h00;
    o_func_data_count               <=  12'h00;
    data_count                      <=  0;

    response_index                  <=  0;
    o_tunning_block                 <=  0;
    //o_func_host_rdy                 <=  0;
    cmd_data                        <=  0;
    o_cmd_bus_sel                   <=  1;
    o_rsps_fail                     <=  0;

  end
  else if (i_cmd_stb && !i_cmd_crc_good_stb) begin
    bad_crc                         <=  1;
    o_rsps_fail                     <=  1;
    //Do not send a response
  end
  else if (o_rsps_fail) begin
    if (i_cmd_phy_idle) begin
      o_rsps_fail                   <=  0;
    end
  end
  else    //Strobe
    if (rsps_stb) begin
      //Whenever a response is successful de-assert any of the errors, they will have been picked up by the response
      bad_crc                       <=  0;
      cmd_arg_out_of_range          <=  0;
      illegal_command               <=  0;
      card_error                    <=  0;  //Unknown Error
    end
    //Card Bootup Sequence
    case (state)
      RESET: begin
        //o_func_host_rdy             <= 0;
        o_cmd_bus_sel               <= 1;
        register_card_address       <=  16'h0001;       // Initializes the RCA to 0
        voltage_select              <=  `OCR_VALUE;
        v1p8_sel                    <=  0;
        bad_crc                     <=  0;
        cmd_arg_out_of_range        <=  0;
        illegal_command             <=  0;              //Illegal Command for the Given State
        card_error                  <=  0;              //Unknown Error
        o_func_inc_addr             <=  0;
        o_func_block_mode           <=  0;
        o_func_num                  <=  4'h0;
        o_func_write_flag           <=  0;              /* Read Write Flag R = 0, W = 1 */
        o_func_rd_after_wr          <=  0;
        o_func_addr                 <=  18'h0;
        o_func_write_data           <=  8'h00;
        o_func_data_count           <=  12'h00;
        data_count                  <=  0;
        response_index              <=  0;
        o_tunning_block             <=  0;
        //o_func_host_rdy             <=  0;
        cmd_data                    <=  0;
        o_rsps_fail                 <=  0;
        state                       <= INITIALIZE;
      end
      INITIALIZE: begin
        //o_func_host_rdy             <= 0;
        o_cmd_bus_sel               <= 1;
        if (i_cmd_stb) begin
          //$display ("Strobe!");
          case (i_cmd)
            `SD_CMD_IO_SEND_OP_CMD: begin
              v1p8_sel              <=  i_cmd_arg[`CMD5_ARG_S18R];
              //voltage_select        <=  i_cmd_arg[`CMD5_ARG_OCR] & `OCR_VALUE;
              voltage_select        <=  `OCR_VALUE;
              response_index        <=  R4;
              rsps_stb              <=  1;
            end
            `SD_CMD_SEND_RELATIVE_ADDR: begin
              state                 <=  STANDBY;
              response_index        <=  R6;
              //TODO: Possibly change the relative card address (RCA)
              rsps_stb              <=  1;
            end
            `SD_CMD_GO_INACTIVE_STATE: begin
              state                 <=  INACTIVE;
            end
            default: begin
              illegal_command       <=  1;
              o_rsps_fail           <=  1;
            end
          endcase
        end
      end
      STANDBY: begin
        //o_func_host_rdy             <= 0;
        o_cmd_bus_sel               <= 1;
        if (i_cmd_stb) begin
          case (i_cmd)
            `SD_CMD_SEND_RELATIVE_ADDR: begin
              $display("SD CMD Send Relative Address");
              state                 <=  STANDBY;
              response_index        <=  R6;
              rsps_stb              <=  1;
            end
            `SD_CMD_SEL_DESEL_CARD: begin
              response_index        <=  R1;
              if (register_card_address == i_cmd_arg[`CMD7_RCA]) begin
                $display("SD CMD Send Relative Address: Card Selected");
                state               <= COMMAND;
                rsps_stb            <=  1;
              end
              else begin
                $display("SD CMD Send Relative Address: Incorrect Address");
                o_rsps_fail         <=  1;
              end
            end
            `SD_CMD_GO_INACTIVE_STATE: begin
              $display("SD CMD Go to inactive state");
              state                 <=  INACTIVE;
            end
            default: begin
              illegal_command       <=  1;
              o_rsps_fail           <=  1;
            end
          endcase
        end
      end
      COMMAND: begin
        //o_func_host_rdy             <= 0;
        o_cmd_bus_sel               <= 1;
        data_count                  <= 0;
        if (i_cmd_stb) begin
          direct_read_write         <= 0;
          case (i_cmd)
            `SD_CMD_IO_RW_DIRECT: begin
              $display("SD CMD IO RW");
              o_func_write_flag     <= i_cmd_arg[`CMD52_ARG_RW_FLAG ];
              o_func_rd_after_wr    <= i_cmd_arg[`CMD52_ARG_RAW_FLAG];
              o_func_num            <= i_cmd_arg[`CMD52_ARG_FNUM    ];
              o_func_addr           <= i_cmd_arg[`CMD52_ARG_REG_ADDR];
              o_func_write_data     <= i_cmd_arg[`CMD52_ARG_WR_DATA ];
              o_func_inc_addr       <= 0;
              o_func_data_count     <= 1;
              state                 <= TRANSFER;
              direct_read_write     <= 1;
              response_index        <= R5;
              cmd_data              <= 0;
              o_func_activate       <= 1;
            end
            `SD_CMD_IO_RW_EXTENDED: begin
              $display("SD CMD IO RW Extended");
              o_func_write_flag     <= i_cmd_arg[`CMD53_ARG_RW_FLAG   ];
              o_func_rd_after_wr    <= 0;
              o_func_num            <= i_cmd_arg[`CMD53_ARG_FNUM      ];
              o_func_addr           <= i_cmd_arg[`CMD53_ARG_REG_ADDR  ];
              o_func_data_count     <= {4'h0, i_cmd_arg[`CMD53_ARG_DATA_COUNT]};
              o_func_block_mode     <= i_cmd_arg[`CMD53_ARG_BLOCK_MODE];
              o_func_inc_addr       <= i_cmd_arg[`CMD53_ARG_INC_ADDR  ];
              rsps_stb              <= 1;
              state                 <= TRANSFER;
              response_index        <=  R5;
              o_cmd_bus_sel         <=  0;
            end
            `SD_CMD_SEL_DESEL_CARD: begin
              if (register_card_address != i_cmd_arg[`CMD7_RCA]) begin
                $display("Card Deselected");
                state               <= STANDBY;
              end
              response_index        <= R1;
              rsps_stb              <= 1;
            end
            `SD_CMD_SEND_TUNNING_BLOCK: begin
              $display("SD CMD Send tunning block");
              response_index        <= R1;
              rsps_stb              <= 1;
              o_tunning_block       <= 1;
            end
            `SD_CMD_GO_INACTIVE_STATE: begin
              $display("SD CMD Go to inactive state");
              state                 <= INACTIVE;
            end
            default: begin
              illegal_command       <= 1;
              o_rsps_fail           <= 1;
            end
          endcase
        end
      end
      TRANSFER: begin
        if (o_cmd_bus_sel) begin
          o_func_activate             <= 1;
          //Single Byte Transfer
          if (i_func_finished) begin
            o_func_activate           <= 0;
            rsps_stb                  <= 1;
            if (o_func_rd_after_wr || !o_func_write_flag) begin
              cmd_data                <= i_func_read_data;
            end
            else begin
              cmd_data                <= 0;
            end
            state                     <= COMMAND;
          end
        end
        else if (i_rsps_idle) begin
          //Not command bus read/write
          o_func_activate           <=  1;
          if (i_func_finished) begin
            o_func_activate         <=  0;
            state                   <= COMMAND;
          end
        end
        if (i_cmd_stb) begin
          case (i_cmd)
            `SD_CMD_IO_RW_DIRECT: begin
              $display("Direct Read/Write");
              o_func_write_flag     <= i_cmd_arg[`CMD52_ARG_RW_FLAG ];
              o_func_rd_after_wr    <= i_cmd_arg[`CMD52_ARG_RAW_FLAG];
              o_func_num            <= i_cmd_arg[`CMD52_ARG_FNUM    ];
              o_func_addr           <= i_cmd_arg[`CMD52_ARG_REG_ADDR];
              o_func_write_data     <= i_cmd_arg[`CMD52_ARG_WR_DATA ];
              o_func_activate       <= 0;
              rsps_stb              <= 1;
              o_func_data_count     <= 1;
              cmd_data              <= 0;

//TODO: Check if this is an abort!
            end
            default: begin
              illegal_command       <= 1;
              o_rsps_fail           <= 1;
            end
          endcase
        end
      end
      INACTIVE: begin
        //Nothing Going on here
        //o_func_host_rdy             <= 0;
        o_rsps_fail                 <= 1;
      end
      default: begin
      end
    endcase


    //Always Respond to these commands regardless of state
    if (i_cmd_stb) begin
      case (i_cmd)
        `SD_CMD_GO_IDLE_STATE: begin
          $display ("Initialize SD or SPI Mode, SPI MODE NOT SUPPORTED NOW!!");
          o_rsps_fail               <=  0;
          illegal_command           <=  0;
          response_index            <=  R1;
          if (!i_chip_select_n) begin
            //XXX: SPI MODE IS NOT SUPPORTED YET!!!
            o_rsps_fail             <=  1;
          end
          else begin
            //We are in SD Mode
            rsps_stb                <=  1;
          end
        end
        `SD_CMD_SEND_IF_COND: begin
          $display ("Send Interface Condition");
          o_rsps_fail               <=  0;
          illegal_command           <=  0;
          response_index            <=  R7;
          if (i_cmd_arg[`CMD8_ARG_VHS] == `VHS_DEFAULT_VALUE) begin
            rsps_stb                <=  1;
          end
        end
        `SD_CMD_VOLTAGE_SWITCH: begin
          $display ("Voltage Mode Switch");
          o_rsps_fail               <=  0;
          illegal_command           <=  0;
          response_index            <=  R1;
          rsps_stb                  <=  1;
        end
        default: begin
        end
      endcase
  end
end

assign  o_state                     =  state;

endmodule
