/*
Distributed under the MIT licesnse.
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



`timescale 1 ns/1 ps

module tb_cocotb (

//Virtual Host Interface Signals
input             clk,
input             sata_clk,
input             rst,
output            master_ready,
input             in_ready,
input   [31:0]    in_command,
input   [31:0]    in_address,
input   [31:0]    in_data,
input   [27:0]    in_data_count,

input             out_ready,
output            out_en,
output  [31:0]    out_status,
output  [31:0]    out_address,
output  [31:0]    out_data,
output  [27:0]    out_data_count,
input   [31:0]    test_id,

input             ih_reset,
output            device_interrupt

);

//Local Parameters
localparam        HI_ADDR_WIDTH = 32;
localparam        HI_DATA_WIDTH = 32;
localparam        P_ADDR_WIDTH  = 32;
localparam        P_DATA_WIDTH  = 32;
localparam        M_ADDR_WIDTH  = 32;
localparam        M_DATA_WIDTH  = 32;

//Registers/Wires
reg               r_rst;
reg               r_in_ready;
reg   [31:0]      r_in_command;
reg   [31:0]      r_in_address;
reg   [31:0]      r_in_data;
reg   [27:0]      r_in_data_count;
reg               r_out_ready;
reg               r_ih_reset;



//There is a bug in COCOTB when stiumlating a signal, sometimes it can be corrupted if not registered
always @ (*) r_rst           = rst;
always @ (*) r_in_ready      = in_ready;
always @ (*) r_in_command    = in_command;
always @ (*) r_in_address    = in_address;
always @ (*) r_in_data       = in_data;
always @ (*) r_in_data_count = in_data_count;
always @ (*) r_out_ready     = out_ready;
always @ (*) r_ih_reset      = ih_reset;

//AXI 4 Specific Registers/Wires
wire                       w_p_aclk;
wire                       w_p_areset_n;
wire [3:0]                 w_p_awid;
wire [P_ADDR_WIDTH - 1:0]  w_p_awaddr;
wire [3:0]                 w_p_awlen;
wire [2:0]                 w_p_awsize;
wire [1:0]                 w_p_awburst;
wire [1:0]                 w_p_awlock;
wire [3:0]                 w_p_awcache;
wire [2:0]                 w_p_awprot;
wire                       w_p_awvalid;
wire                       w_p_awready;

  //Peripheral bus write data
wire [3:0]                 w_p_wid;
wire [P_DATA_WIDTH - 1: 0] w_p_wdata;
wire [P_DATA_WIDTH >> 3:0] w_p_wstrobe;
wire                       w_p_wlast;
wire                       w_p_wvalid;
wire                       w_p_wready;

  //Peripheral Write Response Channel
wire [3:0]                 w_p_bid;
wire [1:0]                 w_p_bresp;
wire                       w_p_bvalid;
wire                       w_p_bready;

  //Peripheral bus read addr path
wire  [3:0]                w_p_arid;
wire  [P_ADDR_WIDTH - 1:0] w_p_araddr;
wire  [3:0]                w_p_arlen;
wire  [2:0]                w_p_arsize;
wire  [1:0]                w_p_arburst;
wire  [1:0]                w_p_arlock;
wire  [3:0]                w_p_arcache;
wire  [2:0]                w_p_arprot;
wire                       w_p_arvalid;
wire                       w_p_arready;

  //Peripheral bus read data
wire [3:0]                 w_p_rid;
wire [P_DATA_WIDTH - 1: 0] w_p_rdata;
wire [P_DATA_WIDTH >> 3:0] w_p_rstrobe;
wire                       w_p_rlast;
wire                       w_p_rvalid;
wire                       w_p_rready;

  //Low Power Bus
wire                       w_p_csysreq;
wire                       w_p_csysack;
wire                       w_p_cactive;

//Axi4 Memory Bus
wire                       w_m_aclk;
wire                       w_m_areset_n;

  //memory bus write addr path
wire [3:0]                 w_m_awid;
wire [M_ADDR_WIDTH - 1:0]  w_m_awaddr;
wire [3:0]                 w_m_awlen;
wire [2:0]                 w_m_awsize;
wire [1:0]                 w_m_awburst;
wire [1:0]                 w_m_awlock;
wire [3:0]                 w_m_awcache;
wire [2:0]                 w_m_awprot;
wire                       w_m_awvalid;
wire                       w_m_awready;



  //Memory bus write data
wire [3:0]                 w_m_wid;
wire [M_DATA_WIDTH - 1: 0] w_m_wdata;

wire [M_DATA_WIDTH >> 3:0] w_m_wstrobe;
wire                       w_m_wlast;
wire                       w_m_wvalid;
wire                       w_m_wready;

  //Memory Write Response Channel
wire [3:0]                 w_m_bid;
wire [1:0]                 w_m_bresp;

wire                       w_m_bvalid;
wire                       w_m_bready;

  //Memory bus read addr path
wire [3:0]                 w_m_arid;
wire [M_ADDR_WIDTH - 1:0]  w_m_araddr;
wire [3:0]                 w_m_arlen;
wire [2:0]                 w_m_arsize;
wire [1:0]                 w_m_arburst;
wire [1:0]                 w_m_arlock;
wire [3:0]                 w_m_arcache;
wire [2:0]                 w_m_arprot;
wire                       w_m_arvalid;
wire                        w_m_arready;


  //Memory bus read data
wire [3:0]                 w_m_rid;
wire [M_DATA_WIDTH - 1: 0] w_m_rdata;

wire [M_DATA_WIDTH >> 3:0] w_m_rstrobe;
wire                       w_m_rlast;
wire                       w_m_rvalid;
wire                       w_m_rready;

  //Low Power Bus
wire                       w_m_csysreq;
wire                       w_m_csysack;
wire                       w_m_cactive;


wire  [3:0]                w_as_awid;
wire  [P_ADDR_WIDTH - 1:0] w_as_awaddr;
wire  [3:0]                w_as_awlen;
wire  [2:0]                w_as_awsize;
wire  [1:0]                w_as_awburst;
wire  [1:0]                w_as_awlock;
wire  [3:0]                w_as_awcache;
wire  [2:0]                w_as_awprot;
wire                       w_as_awvalid;
wire                       w_as_awready;
wire  [3:0]                w_as_wid;
wire  [P_DATA_WIDTH - 1: 0]w_as_wdata;
wire  [P_DATA_WIDTH >> 3:0]w_as_wstrobe;
wire                       w_as_wlast;
wire                       w_as_wvalid;
wire                       w_as_wready;
wire  [3:0]                w_as_bid;
wire  [1:0]                w_as_bresp;
wire                       w_as_bvalid;
wire                       w_as_bready;
wire  [3:0]                w_as_arid;
wire  [P_ADDR_WIDTH - 1:0] w_as_araddr;
wire  [3:0]                w_as_arlen;
wire  [2:0]                w_as_arsize;
wire  [1:0]                w_as_arburst;
wire  [1:0]                w_as_arlock;
wire  [3:0]                w_as_arcache;
wire  [2:0]                w_as_arprot;
wire                       w_as_arvalid;
wire                       w_as_arready;
wire  [3:0]                w_as_rid;
wire  [P_DATA_WIDTH - 1: 0]w_as_rdata;
wire  [P_DATA_WIDTH >> 3:0]w_as_rstrobe;
wire                       w_as_rlast;
wire                       w_as_rvalid;
wire                       w_as_rready;
wire                       w_as_csysreq;
wire                       w_as_csysack;
wire                       w_as_cactive;





//Submodules
axi4_master#(
   .HI_ADDR_WIDTH       (HI_ADDR_WIDTH    ),
   .HI_DATA_WIDTH       (HI_DATA_WIDTH    ),
   .P_ADDR_WIDTH        (P_ADDR_WIDTH     ),
   .P_DATA_WIDTH        (P_DATA_WIDTH     ),
   .M_ADDR_WIDTH        (M_ADDR_WIDTH     ),
   .M_DATA_WIDTH        (M_DATA_WIDTH     )
)am (
  //System Signals
  .clk                  (clk              ),
  .rst                  (rst              ),

  //Interface Signals
  .o_master_ready       (w_master_ready   ),

  .i_ih_reset           (r_ih_reset       ),

  .i_ih_ready           (r_in_ready       ),
  .i_ih_command         (r_in_command     ),
  .i_ih_address         (r_in_address     ),
  .i_ih_data            (r_in_data        ),
  .i_ih_data_count      (r_in_data_count  ),

  .i_oh_ready           (r_out_ready      ),
  .o_oh_en              (w_out_en         ),
  .o_oh_status          (w_out_status     ),
  .o_oh_address         (w_out_address    ),
  .o_oh_data            (w_out_data       ),
  .o_oh_data_count      (w_out_data_count ),


  //Peripheral Signals
  .o_p_aclk             (w_p_aclk         ),
  .o_p_areset_n         (w_p_areset_n     ),

  //Peripheral Write Address
  .o_p_awid             (w_p_awid         ),
  .o_p_awaddr           (w_p_awaddr       ),
  .o_p_awlen            (w_p_awlen        ),
  .o_p_awsize           (w_p_awsize       ),
  .o_p_awburst          (w_p_awburst      ),
  .o_p_awlock           (w_p_awlock       ),
  .o_p_awcache          (w_p_awcache      ),
  .o_p_awprot           (w_p_awprot       ),
  .o_p_awvalid          (w_p_awvalid      ),
  .i_p_awready          (w_p_awready      ),
  .o_p_wid              (w_p_wid          ),
  .o_p_wdata            (w_p_wdata        ),
  .o_p_wstrobe          (w_p_wstrobe      ),
  .o_p_wlast            (w_p_wlast        ),
  .o_p_wvalid           (w_p_wvalid       ),
  .i_p_wready           (w_p_wready       ),

  //Peripheral Write Data
  .i_p_bid              (w_p_bid          ),
  .i_p_bresp            (w_p_bresp        ),
  .i_p_bvalid           (w_p_bvalid       ),
  .o_p_bready           (w_p_bready       ),
  .o_p_arid             (w_p_arid         ),
  .o_p_araddr           (w_p_araddr       ),
  .o_p_arlen            (w_p_arlen        ),
  .o_p_arsize           (w_p_arsize       ),
  .o_p_arburst          (w_p_arburst      ),
  .o_p_arlock           (w_p_arlock       ),
  .o_p_arcache          (w_p_arcache      ),
  .o_p_arprot           (w_p_arprot       ),
  .o_p_arvalid          (w_p_arvalid      ),
  .i_p_arready          (w_p_arready      ),
  .i_p_rid              (w_p_rid          ),
  .i_p_rdata            (w_p_rdata        ),
  .i_p_rstrobe          (w_p_rstrobe      ),
  .i_p_rlast            (w_p_rlast        ),
  .i_p_rvalid           (w_p_rvalid       ),
  .o_p_rready           (w_p_rready       ),

  //Peripheral Power Bus
  .o_p_csysreq          (w_p_csysreq      ),
  .i_p_csysack          (w_p_csysack      ),
  .i_p_cactive          (w_p_cactive      ),

  //Memory Signals
  .o_m_aclk             (w_m_aclk         ),
  .o_m_areset_n         (w_m_areset_n     ),

  //Memory Write Address
  .o_m_awid             (w_m_awid         ),
  .o_m_awaddr           (w_m_awaddr       ),
  .o_m_awlen            (w_m_awlen        ),
  .o_m_awsize           (w_m_awsize       ),
  .o_m_awburst          (w_m_awburst      ),
  .o_m_awlock           (w_m_awlock       ),
  .o_m_awcache          (w_m_awcache      ),
  .o_m_awprot           (w_m_awprot       ),
  .o_m_awvalid          (w_m_awvalid      ),
  .o_m_awready          (w_m_awready      ),

  //Memory Write Data
  .o_m_wid              (w_m_wid          ),
  .o_m_wdata            (w_m_wdata        ),
  .o_m_wstrobe          (w_m_wstrobe      ),
  .o_m_wlast            (w_m_wlast        ),
  .o_m_wvalid           (w_m_wvalid       ),
  .i_m_wready           (w_m_wready       ),

  //Memory Write Response
  .i_m_bid              (w_m_bid          ),
  .i_m_bresp            (w_m_bresp        ),
  .i_m_bvalid           (w_m_bvalid       ),
  .o_m_bready           (w_m_bready       ),

  //Memory Read Address
  .o_m_arid             (w_m_arid         ),
  .o_m_araddr           (w_m_araddr       ),
  .o_m_arlen            (w_m_arlen        ),
  .o_m_arsize           (w_m_arsize       ),
  .o_m_arburst          (w_m_arburst      ),
  .o_m_arlock           (w_m_arlock       ),
  .o_m_arcache          (w_m_arcache      ),
  .o_m_arprot           (w_m_arprot       ),
  .o_m_arvalid          (w_m_arvalid      ),
  .i_m_arready          (w_m_arready      ),

  //Memory Read Data
  .i_m_rid              (w_m_rid          ),
  .i_m_rdata            (w_m_rdata        ),
  .i_m_rstrobe          (w_m_rstrobe      ),
  .i_m_rlast            (w_m_rlast        ),
  .i_m_rvalid           (w_m_rvalid       ),
  .o_m_rready           (w_m_rready       ),

  //Memory Power Device
  .o_m_csysreq          (w_m_csysreq      ),
  .i_m_csysack          (w_m_csysack      ),
  .i_m_cactive          (w_m_cactive      )
);

axi4_interconnect pi(
  //Master Interface Signals
  .am_aclk              (w_p_aclk         ),
  .am_areset_n          (w_p_areset_n     ),

  //Master Peripheral Write Address
  .i_am_awid            (w_p_awid         ),
  .i_am_awaddr          (w_p_awaddr       ),
  .i_am_awlen           (w_p_awlen        ),
  .i_am_awsize          (w_p_awsize       ),
  .i_am_awburst         (w_p_awburst      ),
  .i_am_awlock          (w_p_awlock       ),
  .i_am_awcache         (w_p_awcache      ),
  .i_am_awprot          (w_p_awprot       ),
  .i_am_awvalid         (w_p_awvalid      ),
  .o_am_awready         (w_p_awready      ),

  //Master Peripheral Write Data
  .i_am_wid             (w_p_wid          ),
  .i_am_wdata           (w_p_wdata        ),
  .i_am_wstrobe         (w_p_wstrobe      ),
  .i_am_wlast           (w_p_wlast        ),
  .i_am_wvalid          (w_p_wvalid       ),
  .o_am_wready          (w_p_wready       ),

  //Master Peripheral Write Response
  .o_am_bid             (w_p_bid          ),
  .o_am_bresp           (w_p_bresp        ),
  .o_am_bvalid          (w_p_bvalid       ),
  .i_am_bready          (w_p_bready       ),

  //Master Peripheral Read Address
  .i_am_arid            (w_p_arid         ),
  .i_am_araddr          (w_p_araddr       ),
  .i_am_arlen           (w_p_arlen        ),
  .i_am_arsize          (w_p_arsize       ),
  .i_am_arburst         (w_p_arburst      ),
  .i_am_arlock          (w_p_arlock       ),
  .i_am_arcache         (w_p_arcache      ),
  .i_am_arprot          (w_p_arprot       ),
  .i_am_arvalid         (w_p_arvalid      ),
  .o_am_arready         (w_p_arready      ),

  //Master Peripheral Read Data
  .o_am_rid             (w_p_rid          ),
  .o_am_rdata           (w_p_rdata        ),
  .o_am_rstrobe         (w_p_rstrobe      ),
  .o_am_rlast           (w_p_rlast        ),
  .o_am_rvalid          (w_p_rvalid       ),
  .i_am_rready          (w_p_rready       ),

  //Master Peripheral Power
  .i_am_csysreq         (w_p_csysreq      ),
  .o_am_csysack         (w_p_csysack      ),
  .o_am_cactive         (w_p_cactive      ),


//Axi4 Slave
  //Axi4 Peripheral Bus

    //peripheral bus

  //Slave Write Address Data
  .o_as_awid            (w_as_awid        ),
  .o_as_awaddr          (w_as_awaddr      ),
  .o_as_awlen           (w_as_awlen       ),
  .o_as_awsize          (w_as_awsize      ),
  .o_as_awburst         (w_as_awburst     ),
  .o_as_awlock          (w_as_awlock      ),
  .o_as_awcache         (w_as_awcache     ),
  .o_as_awprot          (w_as_awprot      ),
  .o_as_awvalid         (w_as_awvalid     ),
  .i_as_awready         (w_as_awready     ),

  //Slave Write Data
  .o_as_wid             (w_as_wid         ),
  .o_as_wdata           (w_as_wdata       ),
  .o_as_wstrobe         (w_as_wstrobe     ),
  .o_as_wlast           (w_as_wlast       ),
  .o_as_wvalid          (w_as_wvalid      ),
  .i_as_wready          (w_as_wready      ),

  //Slave Write Ack
  .i_as_bid             (w_as_bid         ),
  .i_as_bresp           (w_as_bresp       ),
  .i_as_bvalid          (w_as_bvalid      ),
  .o_as_bready          (w_as_bready      ),

  //Slave Peripheral Read Address
  .o_as_arid            (w_as_arid        ),
  .o_as_araddr          (w_as_araddr      ),
  .o_as_arlen           (w_as_arlen       ),
  .o_as_arsize          (w_as_arsize      ),
  .o_as_arburst         (w_as_arburst     ),
  .o_as_arlock          (w_as_arlock      ),
  .o_as_arcache         (w_as_arcache     ),
  .o_as_arprot          (w_as_arprot      ),
  .o_as_arvalid         (w_as_arvalid     ),
  .i_as_arready         (w_as_arready     ),

  //Slave Periphal Read Data
  .i_as_rid             (w_as_rid         ),
  .i_as_rdata           (w_as_rdata       ),
  .i_as_rstrobe         (w_as_rstrobe     ),
  .i_as_rlast           (w_as_rlast       ),
  .i_as_rvalid          (w_as_rvalid      ),
  .o_as_rready          (w_as_rready      ),

  //Slave Power Bus
  .o_as_csysreq         (w_as_csysreq     ),
  .i_as_csysack         (w_as_csysack     ),
  .i_as_cactive         (w_as_cactive     )
);

axi4_slave as(
  //System Signals
  .clk                  (w_p_aclk         ),
  .rst_n                (w_p_areset_n     ),

  //Write Address Bus
  .i_awid               (w_as_awid        ),
  .i_awaddr             (w_as_awaddr      ),
  .i_awlen              (w_as_awlen       ),
  .i_awsize             (w_as_awsize      ),
  .i_awburst            (w_as_awburst     ),
  .i_awlock             (w_as_awlock      ),
  .i_awcache            (w_as_awcache     ),
  .i_awprot             (w_as_awprot      ),
  .i_awvalid            (w_as_awvalid     ),
  .o_awready            (w_as_awready     ),

  //Write Data Bus
  .i_wid                (w_as_wid         ),
  .i_wdata              (w_as_wdata       ),
  .i_wstrobe            (w_as_wstrobe     ),
  .i_wlast              (w_as_wlast       ),
  .i_wvalid             (w_as_wvalid      ),
  .o_wready             (w_as_wready      ),
  .o_bid                (w_as_bid         ),
  .o_bresp              (w_as_bresp       ),
  .o_bvalid             (w_as_bvalid      ),
  .i_bready             (w_as_bready      ),

  //Read Data Bus
  .i_arid               (w_as_arid        ),
  .i_araddr             (w_as_araddr      ),
  .i_arlen              (w_as_arlen       ),
  .i_arsize             (w_as_arsize      ),
  .i_arburst            (w_as_arburst     ),
  .i_arlock             (w_as_arlock      ),
  .i_arcache            (w_as_arcache     ),
  .i_arprot             (w_as_arprot      ),
  .i_arvalid            (w_as_arvalid     ),

  //Read Data Bus
  .o_arready            (w_as_arready     ),
  .o_rid                (w_as_rid         ),
  .o_rdata              (w_as_rdata       ),
  .o_rstrobe            (w_as_rstrobe     ),
  .o_rlast              (w_as_rlast       ),
  .o_rvalid             (w_as_rvalid      ),
  .i_rready             (w_as_rready      ),

  //Power Bus
  .i_csysreq            (w_as_csysreq     ),
  .o_csysack            (w_as_csysack     ),
  .o_cactive            (w_as_cactive     )
);

//Asynchronous Logic
//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
