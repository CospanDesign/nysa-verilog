/*
Distributed under the MIT license.
Copyright (c) 2016 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Author:
 * Description:
 *
 * Changes:
 */

`timescale 1ps / 1ps

`define AXI_RESP_OKAY   2'b00 /* Everything is good */
`define AXI_RESP_EXOKAY 2'b01 /* Everything is good (Exclusive Access) */
`define AXI_RESP_SLVERR 2'b10 /* Slave Error */
`define AXI_RESP_DECERR 2'b11 /* Decode Error Slave doesn't exist at that address (for interconnects) */

module axi4_lite_demo #(
  parameter ADDR_WIDTH          = 32,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8)
)(
  input                               clk,
  input                               rst,

  //Write Address Channel
  input                               i_awvalid,
  input       [ADDR_WIDTH - 1: 0]     i_awaddr,
  output  reg                         o_awready,

  //Write Data Channel
  input                               i_wvalid,
  output  reg                         o_wready,
  input       [STROBE_WIDTH - 1:0]    i_wstrb,
  input       [DATA_WIDTH - 1: 0]     i_wdata,

  //Write Response Channel
  output  reg                         o_bvalid,
  input                               i_bready,
  output  reg [1:0]                   o_bresp,

  //Read Address Channel
  input                               i_arvalid,
  output  reg                         o_arready,
  input       [ADDR_WIDTH - 1: 0]     i_araddr,

  //Read Data Channel
  output  reg                         o_rvalid,
  input                               i_rready,
  output  reg [1:0]                   o_rresp,
  output  reg [DATA_WIDTH - 1: 0]     o_rdata


  //output  reg   [7:0]               o_reg_example
  //input         [7:0]               i_reg_example

);
//local parameters


localparam      IDLE                = 4'h0;
localparam      RECEIVE_WRITE_DATA  = 4'h1;
localparam      SEND_WRITE_RESP     = 4'h2;
localparam      SEND_READ_DATA      = 4'h3;


//Address Map
localparam  ADDR_CONTROL  = 0;
localparam  ADDR_STATUS   = 1;

//registes/wires
reg   [3:0]                     state;
reg   [ADDR_WIDTH - 1: 0]       address;

reg   [DATA_WIDTH - 1: 0]       control;
reg   [DATA_WIDTH - 1: 0]       status;

wire  [STROBE_WIDTH - 1: 0]     w_data_in_bytes [7: 0];


//submodules
//asynchronous logic

//synchronous logic

always @ (posedge clk) begin
  //Deassert Strobes
  o_bvalid              <=  0;
  o_rvalid              <=  0;

  if (rst) begin
    address             <=  0;
    o_arready           <=  0;
    o_awready           <=  0;
    o_wready            <=  0;

    o_rvalid            <=  0;
    o_bresp             <=  0;
    o_rresp             <=  0;
    o_bvalid            <=  0;


    //Demo values
    control             <=  0;
    status              <=  0;
    state               <= IDLE;
  end
  else begin
    case (state)
      IDLE: begin
        address         <=  0;
        o_awready       <=  1;
        o_arready       <=  1;
        o_rvalid        <=  0;
        o_bresp         <=  0;
        o_rresp         <=  0;
        o_bvalid        <=  0;

        //Only handle read or write at one time, not both
        if (i_awvalid && o_awready) begin
          address       <=  i_awaddr;
          //XXX: If need be a delay canbe added before asserting the o_wready (ready to read data) but this must be in another state
          o_wready      <=  1;
          o_arready     <=  0;
          state         <=  RECEIVE_WRITE_DATA;
        end
        else if (i_arvalid && o_arready) begin
          address       <=  i_araddr;
          o_awready     <=  0;
          state         <=  SEND_READ_DATA;
        end
      end
      RECEIVE_WRITE_DATA: begin
        o_awready       <=  0;

        if (i_wvalid) begin
          //Assume everything is okay unless the address is wrong,
          //We don't want to clutter our states with this statement over and over again
          o_bresp       <=  `AXI_RESP_OKAY;
          o_bvalid      <=  1;
          case (address)
            ADDR_CONTROL: begin
              control   <= i_wdata;
              //$display("Wrote to address: %h with a value of %h", address, i_wdata);
            end
            default: begin
              //Can't write to status, any other address is invalid
              $display("%h is not writable!", address);
              o_bresp   <=  `AXI_RESP_DECERR;
            end
          endcase
          state         <=  SEND_WRITE_RESP;
        end
      end
      SEND_WRITE_RESP: begin
        if (i_bready) begin
          o_bvalid      <=  0;
          state         <=  IDLE;
        end
      end

      //Read Path
      SEND_READ_DATA: begin
        o_arready       <=  0;
        o_rresp         <=  `AXI_RESP_OKAY;
        //If more time is needed for a response another state should be added here
        o_rvalid        <=  1;
        case (address)
          ADDR_CONTROL: begin
            //$display ("Reading from address %h, host should receive", address, control);
            o_rdata     <=  control;
          end
          ADDR_STATUS: begin
            o_rdata     <=  status;
          end
          default: begin
            //Nothing here
            o_rdata     <=  0;
            o_rresp     <=  `AXI_RESP_DECERR;
          end
        endcase
        if (i_rready && o_rvalid) begin
          o_rvalid      <=  0;
          state         <=  IDLE;
        end
      end
      default: begin
        $display("Shouldn't have gotten here!");
      end
    endcase
  end
end

endmodule
