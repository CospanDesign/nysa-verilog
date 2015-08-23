/*
Distributed under the MIT license.
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
 * Author: David McCoy (dave.mccoy@cospandesign.com)
 * Description: SDIO Host Stack
 *
 * Changes:
 */

module sd_host_stack (
  input                     clk,
  input                     rst,
  //output  reg   [7:0]       o_reg_example
  //input         [7:0]       i_reg_example
  input                     i_card_detect,
  input                     i_card_command,


  output                    o_interrupt

);
//local parameters
//registes/wires
wire    [15:0]              settings;
wire    [39:0]              cmd_out_master;
wire    [39:0]              cmd_in_host;

//submodules
sd_cmd_master cmd_master_1(
  .clk              (clk                     ),
  .rst              (rst                     ),

  //Initiate a command
  .new_cmd          (new_cmd                 ),
  .ack_in           (ack_in_host             ),

  .data_write       (d_write                 ),
  .data_read        (d_read                  ),

  .ARG_REG          (argument_reg            ),
  .CMD_SET_REG      (cmd_setting_reg[13:0]   ),
  .STATUS_REG       (status_reg_w            ),
  .TIMEOUT_REG      (time_out_reg            ),
  .RESP_1_REG       (cmd_resp_1_w            ),
  .ERR_INT_REG      (error_int_status_reg_w  ),
  .NORMAL_INT_REG   (normal_int_status_reg_w ),
  .ERR_INT_RST      (error_isr_reset         ),
  .NORMAL_INT_RST   (normal_isr_reset        ),
  .settings         (settings                ),
  .go_idle_o        (go_idle                 ),
  .cmd_out          (i_card_detect           ),
  .req_out          (req_out_master          ),
  .ack_out          (ack_out_master          ),
  .req_in           (req_in_host             ),
  .cmd_in           (cmd_in_host             ),
  .serial_status    (serial_status           ),
  .card_detect      (card_detect             )

);


//asynchronous logic
//synchronous logic

endmodule
