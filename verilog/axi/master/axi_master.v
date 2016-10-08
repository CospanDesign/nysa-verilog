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

`include "cbuilder_defines.v"
`include "axi_defines.v"



`define COMMAND_POS             0
`define DATA_COUNT_POS          1
`define ADDRESS_POS             2

`define HEADER_SIZE             3

`define MASTER_CFG_COUNT        2



module axi_master #(
  //Parameters
  parameter           INGRESS_FIFO_DEPTH    = 9, //512
  parameter           EGRESS_FIFO_DEPTH     = 9, //512
  parameter           HI_DATA_WIDTH         = 32,
  parameter           HI_ADDR_WIDTH         = 32,
  parameter           ADDR_WIDTH            = 32,
  parameter           DATA_WIDTH            = 32,
  parameter           INTERRUPT_WIDTH       = 32,
  parameter           ENABLE_WRITE_RESP     = 0, //Don't send a response when writing (Faster)
  parameter           ENABLE_NACK           = 0, //Enable timeout
  parameter           DEFAULT_TIMEOUT       = 32'd100000000  //1 Second at 100MHz

)(
  input                             clk,
  input                             rst,

  //indicate to the input that we are ready

  input                             i_ingress_clk,
  output      [1:0]                 o_ingress_rdy,
  input       [1:0]                 i_ingress_act,
  input                             i_ingress_stb,
  input       [HI_DATA_WIDTH - 1:0] i_ingress_data,
  output      [HI_ADDR_WIDTH - 1:0] o_ingress_size,

  input                             i_egress_clk,
  output                            o_egress_rdy,
  input                             i_egress_act,
  input                             i_egress_stb,
  output      [HI_DATA_WIDTH - 1:0] o_egress_data,
  output      [HI_ADDR_WIDTH - 1:0] o_egress_size,

  //AXI Bus
  output                            o_aclk,
  output reg                        o_areset_n,

  //peripheral bus write addr path
  output  reg [3:0]                 o_awid,         //Write ID
  output  reg [ADDR_WIDTH - 1:0]    o_awaddr,       //Write Addr Path Address
  output  reg [3:0]                 o_awlen,        //Write Addr Path Burst Length
  output  reg [2:0]                 o_awsize,       //Write Addr Path Burst Size
  output  reg [1:0]                 o_awburst,      //Write Addr Path Burst Type
                                                        //  0 = Fixed
                                                        //  1 = Incrementing
                                                        //  2 = wrap
  output  reg [1:0]                 o_awlock,       //Write Addr Path Lock (atomic) information
                                                        //  0 = Normal
                                                        //  1 = Exclusive
                                                        //  2 = Locked
  output  reg [3:0]                 o_awcache,      //Write Addr Path Cache Type
  output  reg [2:0]                 o_awprot,       //Write Addr Path Protection Type
  output  reg                       o_awvalid,      //Write Addr Path Address Valid
  input                             i_awready,      //Write Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready

    //bus write data
  output  reg [3:0]                 o_wid,          //Write ID
  output  reg [DATA_WIDTH - 1: 0]   o_wdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  output  reg [DATA_WIDTH >> 3:0]   o_wstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  output  reg                       o_wlast,        //Write Last transfer in a write burst
  output  reg                       o_wvalid,       //Data through this bus is valid
  input                             i_wready,       //Slave is ready for data

    //Write Response Channel
  input       [3:0]                 i_bid,          //Response ID (this must match awid)
  input       [1:0]                 i_bresp,        //Write Response
                                                        //  0 = OKAY
                                                        //  1 = EXOKAY
                                                        //  2 = SLVERR
                                                        //  3 = DECERR
  input                             i_bvalid,       //Write Response is:
                                                        //  1 = Available
                                                        //  0 = Not Available
  output  reg                       o_bready,       //WBM Ready

    //bus read addr path
  output  reg  [3:0]                o_arid,         //Read ID
  output  reg  [ADDR_WIDTH - 1:0]   o_araddr,       //Read Addr Path Address
  output  reg  [3:0]                o_arlen,        //Read Addr Path Burst Length
  output  reg  [2:0]                o_arsize,       //Read Addr Path Burst Size
  output  reg  [1:0]                o_arburst,      //Read Addr Path Burst Type
  output  reg  [1:0]                o_arlock,       //Read Addr Path Lock (atomic) information
  output  reg  [3:0]                o_arcache,      //Read Addr Path Cache Type
  output  reg  [2:0]                o_arprot,       //Read Addr Path Protection Type
  output  reg                       o_arvalid,      //Read Addr Path Address Valid
  input                             i_arready,      //Read Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready
    //bus read data
  input       [3:0]                 i_rid,          //Write ID
  input       [DATA_WIDTH - 1: 0]   i_rdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                    //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  input       [DATA_WIDTH >> 3:0]   i_rstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  input                             i_rlast,        //Write Last transfer in a write burst
  input                             i_rvalid,       //Data through this bus is valid
  output  reg                       o_rready,       //WBM is ready for data
                                                        //  1 = WBM Ready
                                                        //  0 = Slave Ready

  input     [INTERRUPT_WIDTH - 1:0] i_interrupts
);

//local parameters
localparam        IDLE                  = 4'h0;
localparam        READ_INGRESS_FIFO     = 4'h1;
localparam        PARSE_COMMAND         = 4'h2;
localparam        PING                  = 4'h3;
localparam        WRITE_CMD             = 4'h4; //Write Command and Address to Slave
localparam        WRITE_DATA            = 4'h5; //Write Data to Slave
localparam        WRITE_RESP            = 4'h6; //Receive Response from device
localparam        READ_CMD              = 4'h7; //Send Read Command and Address to Slave
localparam        READ_DATA             = 4'h8; //Receive Read Response from Slave (including data)
localparam        MASTER_CFG_WRITE      = 4'h9;
localparam        MASTER_CFG_READ       = 4'hA;
localparam        SEND_RESPONSE         = 4'hB;
localparam        SEND_INTERRUPT        = 5'hC;
localparam        FLUSH                 = 4'hD;

//registes/wires
reg     [3:0]       state = IDLE;

// PPFIFO wires
wire                        w_ingress_rdy;
reg                         r_ingress_act;
wire  [HI_ADDR_WIDTH - 1:0] w_ingress_size;
wire  [HI_DATA_WIDTH - 1:0] w_ingress_data;
reg                         r_ingress_stb;

wire  [1:0]                 w_egress_rdy;
reg   [1:0]                 r_egress_act;
reg                         r_egress_stb;
wire  [HI_ADDR_WIDTH - 1:0] w_egress_size;
reg   [HI_DATA_WIDTH - 1:0] r_egress_data;


wire  [15:0]                w_command;
wire  [15:0]                w_flags;
wire  [31:0]                w_data_size;
wire  [ADDR_WIDTH:0]        w_address;
reg   [ADDR_WIDTH:0]        r_address;

wire  [31:0]                w_status;
wire                        w_auto_inc_addr;
wire                        w_master_config_space;
wire  [31:0]                w_master_flags;
reg                         r_en_nack;
reg                         r_en_wr_resp = 0;

reg   [23:0]                r_ingress_count;
reg   [3:0]                 r_hdr_count;
reg   [23:0]                r_egress_count;

reg   [31:0]                r_data_count; //Techinically this should go all the way up to DATA_COUNT - 1: 0
reg   [31:0]                r_interrupts;

reg   [31:0]                r_header  [0:(`HEADER_SIZE - 1)];





//Submodules
ppfifo #(
  .DATA_WIDTH       (HI_DATA_WIDTH        ),
  .ADDRESS_WIDTH    (HI_ADDR_WIDTH        )
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
  .read_strobe     (r_ingress_stb         ),
  .read_ready      (w_ingress_rdy         ),
  .read_activate   (r_ingress_act         ),
  .read_count      (w_ingress_size        ),
  .read_data       (w_ingress_data        )
//  .inactive        (                      )
);

ppfifo #(
  .DATA_WIDTH       (HI_DATA_WIDTH        ),
  .ADDRESS_WIDTH    (HI_ADDR_WIDTH        )
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
assign  o_areset_n                              = ~rst || ~r_sync_rst;

assign  w_master_flags[`MASTER_FLAG_UNUSED]     = 0;
assign  w_master_flags[`MASTER_FLAG_EN_WR_RESP] = r_en_wr_resp;
assign  w_master_flags[`MASTER_FLAG_EN_NACK]    = r_en_nack;

assign  w_master_config[`MADDR_CTR_FLAGS]       = w_master_flags;
assign  w_master_config[`MADDR_NACK_TIMEOUT]    = r_nack_timeout;




assign  w_status[`STATUS_BIT_CMPLT]             = 1'h1;
assign  w_status[`STATUS_BIT_PING]              = (w_command == `COMMAND_PING);
assign  w_status[`STATUS_BIT_WRITE]             = (w_command == `COMMAND_WRITE & !w_master_config_space);
assign  w_status[`STATUS_BIT_READ]              = (w_command == `COMMAND_READ  & !w_master_config_space);
assign  w_status[`STATUS_BIT_RESET]             = (w_command == `COMMAND_RESET);
assign  w_status[`STATUS_BIT_MSTR_CFG_WR]       = (w_command == `COMMAND_WRITE &  w_master_config_space);
assign  w_status[`STATUS_BIT_MSTR_CFG_RD]       = (w_command == `COMMAND_READ  &  w_master_config_space);

assign  w_status[`STATUS_BIT_UNREC_CMD]         = r_unrec_cmd;
assign  w_status[`STATUS_BIT_UNUSED]            = 0;

assign  w_command                               = r_header[`COMMAND_POS][`COMMAND_RANGE];
assign  w_flags                                 = r_header[`COMMAND_POS][`FLAG_RANGE];
assign  w_data_size                             = r_header[`DATA_COUNT_POS];
assign  w_address                               = r_header[`ADDRESS_POS];

assign  w_mem_bus_select                        =  ((w_flags & `FLAG_MEM_BUS            ) >  0);
assign  w_auto_inc_addr                         = !((w_flags | `FLAG_DISABLE_AUTO_INC   ) == 0);
assign  w_master_config_space                   =  ((w_flags & `FLAG_MASTER_ADDR_SPACE  ) >  0);






//synchronous logic
always @ (posedge clk) begin
  //De-assert Strobes
  r_ingress_stb       <= 0;
  r_egress_stb        <= 0;
  r_sync_rst          <= 0;


  if (rst) begin
    r_address         <= 32'h0;
    r_ingress_count   <= 24'h0;
    r_hdr_count       <= 4'h0;
    r_data_count      <= 32'h0;

    r_ingress_act     <= 1'b0;
    r_egress_act      <= 2'b0;
    r_egress_data     <= 32'h0;

    r_en_wr_resp      <= ENABLE_WRITE_RESP;
    r_en_nack         <= ENABLE_NACK;
    r_nack_timeout    <= DEFAULT_TIMEOUT;

    r_unrec_cmd       <= 0;
    r_prev_int        <= 0;

    for (i = 0; i < `HEADER_SIZE; i = i + 1)
      r_header[i]     <=  0;

    r_address         <=  32'h0;

  end
  else begin
    //Always get a free FIFO
    if (w_ingress_rdy && !r_ingress_act) begin
      r_ingress_count         <=  24'h0;
      r_ingress_act           <=  1'h1;
    end

    if ((w_egress_rdy > 0) && r_egress_act == 0) begin
      r_egress_count          <=  24'h0;
      if (w_egress_rdy[0])
        r_egress_act[0]       <=  1'h1;
      else
        r_egress_act[1]       <=  1'h1;
    end


    case (state)
      IDLE: begin
      end
      READ_INGRESS_FIFO: begin
      end
      PARSE_COMMAND: begin
      end
      PING: begin
      end
      WRITE_CMD: begin
      end
      WRITE_DATA: begin
      end
      WRITE_RESP: begin
      end
      READ_CMD: begin
      end
      READ_DATA: begin
      end
      MASTER_CFG_WRITE: begin
      end
      MASTER_CFG_READ: begin
      end
      SEND_RESPONSE: begin
      end
      SEND_INTERRUPT: begin
      end
      FLUSH: begin
      end
      default: begin
      end
    endcase

  end
end



endmodule
