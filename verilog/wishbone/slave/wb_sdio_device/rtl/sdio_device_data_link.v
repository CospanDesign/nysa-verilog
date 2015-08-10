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

  //


  //PHY Interface
  input               cmd_stb,
  input               cmd_crc_stb,
  input   [5:0]       cmd,
  input   [31:0]      cmd_arg,

  output  [127:0]     rsps,
  output  [7:0]       rsps_len

);
//local parameters
localparam     NORMAL_RESPONSE    = 1'b0;
localparam     EXTENDED_RESPONSE  = 1'b1;
//registes/wires
reg       [7:0]       response_value;
reg       [31:0]      response_value_extended;
reg                   response_type;
reg       [15:0]      register_card_address;  /* Host can set this so later it can be used to identify this card */
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
assign  rsps[128] = 0; //Start bit
assign  rsps[127] = 0; //Direction bit (to the host)
assign  rsps[126:0] = response_type ? response_value_extended[126:0] : {response_value[29:0], 96'h0};
assign  rsps_len    = response_type ? 136 : 40;
//synchronous logic


always @ (posedge sdio_clk) begin
  if (rst) begin
    response_type           <=  NORMAL_RESPONSE;
    register_value          <=  32'h00000000;
    register_value_extended <=  128'h00;
    register_card_address   <=  16'h0000;
  end
  else begin
    case (cmd)
      `SD_CMD_GO_IDLE_STATE:      begin
      end
      `SD_CMD_SEND_RELATIVE_ADDR: begin
        //Relative address response
        //response_value[??:??] <=  register_card_address;
      end
      `SD_CMD_IO_SEND_OP_CMD:     begin
        response_type     <=  NORMAL_RESPONSE;
        response_value[`CMD5_RSP_READY]                                   <=  1'b1;
        response_value[`CMD5_RSP_NUM_FUNCS_START:`CMD5_RSP_NUM_FUNCSEND]  <=  NUM_FUNCS;
        response_value[`CMD5_RSP_MEM_PRESENT]                             <=  MEM_PRESENT;
        response_value[`CMD5_UHSII_AVAILABLE]                             <=  UHSII_AVAILABLE;
      end
      `SD_CMD_SWITCH_FUNC:        begin
      end
      `SD_CMD_SEL_DESEL_CARD:     begin
      end
      `SD_CMD_SEND_IF_COND:       begin
      end
      `SD_CMD_VOLTAGE_SWICH:      begin
      end
      `SD_CMD_GO_INACTIVE_STATE:  begin
      end
      `SD_CMD_SEND_TUNNING_BLOCK: begin
      end
      `SD_CMD_IO_RW_DIRECT:       begin
        //single byte access to the SDIO Function
      end
      `SD_CMD_IO_RW_EXTENDED:     begin
        //Multiple Byte/Block access to the SDIO Function
      end
      default: begin
      end
    endcase
  end
end


endmodule
