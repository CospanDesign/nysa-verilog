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
 * Description: AXI Master
 *
 * Changes:
 *  10/2/2016: Initial Commit
 */

`timescale 1 ns/1 ps

`include "command_defines.v"
`include "axi_defines.v"

`define COMMAND_POS             0
`define DATA_COUNT_POS          1
`define ADDRESS_POS             2

`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   (x <= 32)    ? 5 :  \
   (x <= 64)    ? 6 :  \
   (x <= 128)   ? 7 :  \
   (x <= 256)   ? 8 :  \
   (x <= 512)   ? 9 :  \
   (x <= 1024)  ? 10 : \
   (x <= 2048)  ? 11 : \
   (x <= 4096)  ? 12 : \
   -1

module axi_master #(
  //Parameters
  parameter           DATA_FIFO_DEPTH       = 9,              //512
  parameter           ADDR_WIDTH            = 32,
  parameter           DATA_BYTE_SIZE        = 4,
  parameter           INTERRUPT_WIDTH       = 32,
  parameter           ENABLE_NACK           = 0,              //Enable timeout
  parameter           DEFAULT_TIMEOUT       = 32'd100000000,  //1 Second at 100MHz

  parameter           DATA_WIDTH            = DATA_BYTE_SIZE * 8,
  parameter           INVERT_AXI_RESET      = 0

)(
  input                               clk,
  input                               rst,

  //indicate to the input that we are ready
  //************* User Facing Side *******************************************
  input                               i_cmd_en,
  output  reg                         o_cmd_error,
  output  reg                         o_cmd_ack,

  output  reg [7:0]                   o_cmd_status,
  output                              o_cmd_interrupt,

  input       [ADDR_WIDTH - 1:0]      i_cmd_addr,
  //input                               i_cmd_adr_fixed_en, //XXX: Not Supported Yet
  //input                               i_cmd_adr_wrap_en,  //XXX: Not Supported Yet

  input                               i_cmd_wr_rd,
  input                               i_cmd_master_cfg,
  input       [DATA_FIFO_DEPTH - 1:0] i_cmd_data_count,


  input                               i_ingress_clk,
  output                              o_ingress_rdy,
  input                               i_ingress_act,
  input                               i_ingress_stb,
  input       [DATA_WIDTH - 1:0]      i_ingress_data,
  output      [23:0]                  o_ingress_size,

  input                               i_egress_clk,
  output                              o_egress_rdy,
  input                               i_egress_act,
  input                               i_egress_stb,
  output      [DATA_WIDTH - 1:0]      o_egress_data,
  output      [23:0]                  o_egress_size,


  //AXI Bus
  output                              o_aclk,
  //XXX: MAKE SURE THIS ONLY RESETS THE BUS AND NOT THE HOST INTERFACE
  output                              o_areset_n,

  //bus write addr path
  output  reg [3:0]                   o_awid,         //Write ID
  output      [ADDR_WIDTH - 1:0]      o_awaddr,       //Write Addr Path Address
  output  reg [7:0]                   o_awlen,        //Write Addr Path Burst Length
  output  reg [2:0]                   o_awsize,       //Write Addr Path Burst Size
  output      [1:0]                   o_awburst,      //Write Addr Path Burst Type
                                                          //  0 = Fixed
                                                          //  1 = Incrementing
                                                          //  2 = wrap
  output      [1:0]                   o_awlock,       //Write Addr Path Lock (atomic) information
                                                          //  0 = Normal
                                                          //  1 = Exclusive
                                                          //  2 = Locked
  output      [3:0]                   o_awcache,      //Write Addr Path Cache Type
  output      [2:0]                   o_awprot,       //Write Addr Path Protection Type
  output  reg                         o_awvalid,      //Write Addr Path Address Valid
  input                               i_awready,      //Write Addr Path Slave Ready
                                                          //  1 = Slave Ready
                                                          //  0 = Slave Not Ready

    //bus write data
  output  reg [3:0]                   o_wid,          //Write ID
  output  reg [DATA_WIDTH - 1: 0]     o_wdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                        //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  output  reg [(DATA_WIDTH >> 3) - 1:0] o_wstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  output  reg                         o_wlast,        //Write Last transfer in a write burst
  output                              o_wvalid,       //Data through this bus is valid
  input                               i_wready,       //Slave is ready for data

    //Write Response Channel
  input       [3:0]                   i_bid,          //Response ID (this must match awid)
  input       [1:0]                   i_bresp,        //Write Response
                                                          //  0 = OKAY
                                                          //  1 = EXOKAY
                                                          //  2 = SLVERR
                                                          //  3 = DECERR
  input                               i_bvalid,       //Write Response is:
                                                          //  1 = Available
                                                          //  0 = Not Available
  output  reg                         o_bready,       //WBM Ready

    //bus read addr path
  output  reg  [3:0]                  o_arid,         //Read ID
  output       [ADDR_WIDTH - 1:0]     o_araddr,       //Read Addr Path Address
  output  reg  [7:0]                  o_arlen,        //Read Addr Path Burst Length
  output  reg  [2:0]                  o_arsize,       //Read Addr Path Burst Size
  output       [1:0]                  o_arburst,      //Read Addr Path Burst Type
  output       [1:0]                  o_arlock,       //Read Addr Path Lock (atomic) information
  output       [3:0]                  o_arcache,      //Read Addr Path Cache Type
  output       [2:0]                  o_arprot,       //Read Addr Path Protection Type
  output  reg                         o_arvalid,      //Read Addr Path Address Valid
  input                               i_arready,      //Read Addr Path Slave Ready
                                                          //  1 = Slave Ready
                                                          //  0 = Slave Not Ready
    //bus read data
  input       [3:0]                   i_rid,          //Write ID
  input       [DATA_WIDTH - 1: 0]     i_rdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
  input       [1:0]                   i_rresp,        //Read Response Value
                                                          //  0 = Response Okay
                                                          //  1 = Response ExOkay
                                                          //  2 = Response Slave Error
                                                          //  3 = Response Decode Error
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  input       [(DATA_WIDTH >> 3) - 1:0] i_rstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  input                               i_rlast,        //Write Last transfer in a write burst
  input                               i_rvalid,       //Data through this bus is valid
  output  reg                         o_rready,       //WBM is ready for data
                                                          //  1 = WBM Ready
                                                          //  0 = Slave Ready

  input     [INTERRUPT_WIDTH - 1:0]   i_interrupts
);

//local parameters
localparam        DATA_STROBE_ALL_EN      = (DATA_BYTE_SIZE - 1);

//States
localparam        IDLE                  = 4'h0;
localparam        WRITE_CMD             = 4'h4; //Write Command and Address to Slave
localparam        WRITE_DATA            = 4'h5; //Write Data to Slave
localparam        WRITE_RESP            = 4'h6; //Receive Response from device
localparam        READ_CMD              = 4'h7; //Send Read Command and Address to Slave
localparam        READ_DATA             = 4'h8; //Receive Read Response from Slave (including data)
localparam        MASTER_CFG_WRITE      = 4'h9;
localparam        MASTER_CFG_READ       = 4'hA;
localparam        SEND_RESPONSE         = 4'hB;
localparam        SEND_INTERRUPT        = 5'hC;
//localparam        FLUSH                 = 4'hD;

//registes/wires
reg     [3:0]       state = IDLE;

// PPFIFO wires
wire                        w_ingress_rdy;
reg                         r_ingress_act;
wire  [23:0]                w_ingress_size;
wire  [DATA_WIDTH - 1:0]    w_ingress_data;
wire                        w_ingress_stb;
reg                         r_ingress_stb;

wire                        w_egress_rdy;
reg                         r_egress_act;
reg                         r_egress_stb;
wire  [23:0]                w_egress_size;
reg   [DATA_WIDTH - 1:0]    r_egress_data;


reg   [1:0]                 r_command;
reg   [7:0]                 r_flags;
reg   [31:0]                r_data_size;
reg   [ADDR_WIDTH - 1:0]    r_address;

wire                        w_reset_command;
wire                        w_ping_command;
wire  [31:0]                w_status;
wire                        w_master_config_space;
reg                         r_nack_timeout;
wire                        w_en_nack;

reg   [23:0]                r_ingress_count;
reg   [23:0]                r_egress_count;

reg   [31:0]                r_data_count; //Techinically this should go all the way up to DATA_COUNT - 1: 0
reg   [31:0]                r_interrupts;

wire                        w_writing_data;
reg   [1:0]                 r_bus_status;

wire                        w_rst;
reg                         r_sync_rst;

//Some Features are not supported at this time

assign  o_awlock            = 0;
assign  o_awprot            = 0;
assign  o_arprot            = 0;
assign  o_arlock            = 0;
assign  o_awcache           = 0;
assign  o_arcache           = 0;

assign  w_rst               = INVERT_AXI_RESET ? ~rst : rst;


//Submodules
block_fifo #(
  .DATA_WIDTH       (DATA_WIDTH           ),
  .ADDRESS_WIDTH    (DATA_FIFO_DEPTH      )
) ingress (
  .reset            (rst                  ),

  //write side
  .write_clock     (i_ingress_clk         ),
  .write_data      (i_ingress_data        ),
  .write_ready     (o_ingress_rdy         ),
  .write_activate  (i_ingress_act         ),
  .write_fifo_size (o_ingress_size        ),
  .write_strobe    (i_ingress_stb         ),
//  .starved         (                      ),

  //read side
  .read_clock      (clk                   ),
  .read_strobe     (w_ingress_stb         ),
  .read_ready      (w_ingress_rdy         ),
  .read_activate   (r_ingress_act         ),
  .read_count      (w_ingress_size        ),
  .read_data       (w_ingress_data        )
//  .inactive        (                      )
);

block_fifo #(
  .DATA_WIDTH       (DATA_WIDTH           ),
  .ADDRESS_WIDTH    (DATA_FIFO_DEPTH      )
) egress (
  .reset           (rst                   ),

  //write side
  .write_clock     (clk                   ),
  .write_data      (r_egress_data         ),
  .write_ready     (w_egress_rdy          ),
  .write_activate  (r_egress_act          ),
  .write_fifo_size (w_egress_size         ),
  .write_strobe    (r_egress_stb          ),
//  .starved         (  ),

  //read side
  .read_clock      (i_egress_clk          ),
  .read_strobe     (i_egress_stb          ),
  .read_ready      (o_egress_rdy          ),
  .read_activate   (i_egress_act          ),
  .read_count      (o_egress_size         ),
  .read_data       (o_egress_data         )
//  .inactive        (                      )
);


//asynchronous logic

assign  o_aclk                                  = clk;
assign  o_areset_n                              = ~w_rst || ~r_sync_rst;


assign  w_reset_command                         = (r_command == `COMMAND_MASTER_CFG_WRITE) && (r_address[3:0] == `MADDR_RESET);
assign  w_ping_command                          = (r_command == `COMMAND_MASTER_CFG_READ) &&  (r_address[3:0] == `MADDR_PING);



assign  w_status[`STATUS_BIT_CMPLT]             = 1'h1;
assign  w_status[`STATUS_BIT_PING]              = w_ping_command;
assign  w_status[`STATUS_BIT_WRITE]             = r_command == `COMMAND_WRITE;
assign  w_status[`STATUS_BIT_READ]              = r_command == `COMMAND_READ;
assign  w_status[`STATUS_BIT_RESET]             = w_reset_command;
assign  w_status[`STATUS_BIT_MSTR_CFG_WR]       = r_command == `COMMAND_MASTER_CFG_WRITE;
assign  w_status[`STATUS_BIT_MSTR_CFG_RD]       = r_command == `COMMAND_MASTER_CFG_READ;
assign  w_status[`STATUS_RANGE_BUS_STATUS]      = r_bus_status;

assign  w_status[`STATUS_BIT_UNREC_CMD]         = 0;
assign  w_status[`STATUS_BIT_UNUSED]            = 0;

assign  o_awburst                               = r_flags[`MASTER_FLAG_BURST_MODE];
assign  o_arburst                               = r_flags[`MASTER_FLAG_BURST_MODE];
assign  w_en_nack                               = r_flags[`MASTER_FLAG_EN_NACK];

assign  o_awaddr                                = r_address;
assign  o_araddr                                = r_address;

assign  w_writing_data                          = (state == WRITE_DATA);
assign  o_wvalid                                = w_writing_data && r_ingress_act;
assign  w_ingress_stb                           = w_writing_data ? i_wready : r_ingress_stb;

//synchronous logic
always @ (posedge clk) begin
  //De-assert Strobes
  r_ingress_stb       <= 0;
  r_egress_stb        <= 0;
  r_sync_rst          <= 0;

  //AXI Strobes
  o_awvalid           <= 0;

  o_wlast             <= 0;
  o_wstrobe           <= 0;

  o_bready            <= 0;

  o_arvalid           <= 0;

  o_rready            <= 0;

  if (w_rst) begin
    r_address         <= 0;
    r_ingress_count   <= 24'h0;
    r_data_count      <= 32'h0;

    r_ingress_act     <= 1'b0;
    r_egress_act      <= 0;
    r_egress_data     <= 32'h0;

    r_nack_timeout    <= DEFAULT_TIMEOUT;
    r_flags[`MASTER_FLAG_EN_NACK]     <=  ENABLE_NACK;

    //AXI

    //Write Address Path
    o_awid            <=  0;
    o_awlen           <=  0;
    o_awsize          <=  0;

    //Write Data Path
    o_wid             <=  0;
    o_wdata           <=  0;

    //Read Address Path
    o_arid            <=  0;
    o_arlen           <=  0;
    o_arsize          <=  0;

    r_bus_status      <=  0;

    r_command         <= 0;
    r_data_size       <= 0;

  end
  else begin
    //Always get a free FIFO
    if (w_ingress_rdy && !r_ingress_act) begin
      r_ingress_count         <=  24'h0;
      r_ingress_act           <=  1'h1;
    end

    if (w_egress_rdy && !r_egress_act) begin
      r_egress_count          <=  24'h0;
      r_egress_act            <=  1'h1;
    end

    case (state)
      IDLE: begin
        r_ingress_count       <=  24'h0;
        r_egress_count        <=  24'h0;

        if (i_cmd_en) begin
          if (i_cmd_master_cfg) begin
            if (i_cmd_wr_rd)begin
              r_command           <=  `COMMAND_MASTER_CFG_WRITE;
              state               <=  MASTER_CFG_WRITE;
            end
            else begin
              r_command           <=  `COMMAND_MASTER_CFG_READ;
              state               <=  MASTER_CFG_READ;
            end
          end
          else begin
            if (i_cmd_wr_rd) begin
              r_command           <=  `COMMAND_WRITE;
              state               <=  WRITE_CMD;
            end
            else begin
              r_command           <=  `COMMAND_READ;
              state               <=  READ_CMD;
            end
          end
          r_address             <=  i_cmd_addr;
          r_data_size           <=  i_cmd_data_count;
          r_data_count          <=  32'h0;
        end
        else if (((~r_prev_int) & i_interrupts) > 0) begin
          //Something new from interrupts
          state               <=  SEND_INTERRUPT;
          r_interrupts        <=  i_interrupts;
        end
      end
      WRITE_CMD: begin
        //Wait for the slave to acknowledge my request to write data
        o_awid                    <=  0;
        o_awvalid                 <=  1;
        if (i_awready && o_awvalid) begin
          o_awvalid               <=  0;
          state                   <=  WRITE_DATA;
        end
      end
      WRITE_DATA: begin
        //By Default assert all the byte enable signals
        o_wstrobe                 <= DATA_STROBE_ALL_EN;
        if (r_data_count < r_data_size) begin
          if (w_ingress_stb) begin
            r_data_count          <=  r_data_count + 1;
            r_ingress_count       <=  r_ingress_count + 1;
            if ((r_ingress_count + 1) >= w_ingress_size) begin
              r_ingress_act       <=  0;
            end
          end
        end
        else begin
          state                   <=  WRITE_RESP;
          r_ingress_act           <=  0;
        end
      end
      WRITE_RESP: begin
        if ((o_awid == i_bid) && i_bvalid)begin
          //Incomming ID matches the one we sent out
          r_bus_status            <=  i_bresp;
          o_bready                <=  1;
          state                   <=  IDLE;
        end
      end
      READ_CMD: begin
        o_arid                    <=  0;
        o_arvalid                 <=  1;
        if (i_arready && o_arvalid) begin
          o_arvalid               <=  0;
          state                   <=  READ_DATA;
        end
      end
      READ_DATA: begin
        if (i_rid == o_arid) begin
          //Need to pull data in
          //  Ready should be tied to activate
          //  Valid should be tied to strobe  (strobe = (valid & activate))
          //  Increment Address when I get a strobe
        end
      end
      MASTER_CFG_WRITE: begin
        if (w_reset_command) begin
          r_sync_rst                <=  1;
        end
        if (r_data_size == 0) begin
          state                 <=  IDLE;
        end
        else if (r_ingress_act) begin
          if (r_ingress_count < w_ingress_size) begin
            if (r_data_count < r_data_size) begin
              case (r_address)
                `MADDR_CTR_FLAGS: begin
                  r_flags       <=  w_ingress_data[7:0];
                end
                `MADDR_NACK_TIMEOUT: begin
                  r_nack_timeout<=  w_ingress_data;
                end
                default: begin
                end
              endcase
              r_data_count        <=  r_data_count + 1;
              r_ingress_count     <=  r_ingress_count + 1;
              r_ingress_stb       <=  1;
            end
          end
          else begin
            r_ingress_act       <=  0;
          end
        end
      end
      MASTER_CFG_READ: begin
        if (w_reset_command) begin
          r_sync_rst                <=  1;
        end
        if (r_data_size == 0) begin
          state                     <=  IDLE;
        end
        else if (r_egress_act) begin
          if (r_data_count < r_data_size) begin
            case (r_address)
              `MADDR_STATUS: begin
                r_egress_data       <=  w_status;
              end
              `MADDR_CTR_FLAGS: begin
                r_egress_data       <=  {24'h00, r_flags};
              end
              `MADDR_NACK_TIMEOUT: begin
                r_egress_data       <=  r_nack_timeout;
              end
              `MADDR_PING: begin
                r_egress_data       <=  32'h00000000;
              end
              `MADDR_RESET: begin
                r_egress_data       <=  32'h00000000;
              end
              default: begin
                r_egress_data       <=  32'hFFFFFFFF;
              end
            endcase
            r_egress_stb            <=  1;
            r_address               <=  r_address + 1;
            r_data_count            <=  r_data_count + 1;
            r_egress_count          <=  r_egress_count + 1;
            if (r_egress_count >= w_egress_size - 1)
              r_egress_act          <=  0;
          end
          else begin
            r_egress_act            <=  0;
            state                   <=  IDLE;
          end
        end
      end
      SEND_RESPONSE: begin
        //XXX: Need to implement this
      end
      SEND_INTERRUPT: begin
        //XXX: Need to acknowledge Interrupts
      end
      default: begin
      end
    endcase

  end
end



endmodule
