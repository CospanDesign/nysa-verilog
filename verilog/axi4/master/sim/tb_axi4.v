//Axi4 Testbench
/*
Distributed under the MIT licesnse.
Copyright (c) 2013 Dave McCoy (dave.mccoy@cospandesign.com)

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

`define TIMEOUT_COUNT 40
`define INPUT_FILE "master_input_test_data.txt"
`define OUTPUT_FILE "master_output_test_data.txt"


`define CLK_HALF_PERIOD 1
`define CLK_PERIOD (2 * `CLK_HALF_PERIOD)

`define SLEEP_HALF_CLK #(`CLK_HALF_PERIOD)
`define SLEEP_FULL_CLK #(`CLK_PERIOD)

//Sleep a number of clock cycles
`define SLEEP_CLK(x)  #(x * `CLK_PERIOD)

module tb_axi4(
);

//Local Parameters
localparam        HI_ADDR_WIDTH = 32;
localparam        HI_DATA_WIDTH = 32;
localparam        P_ADDR_WIDTH  = 32;
localparam        P_DATA_WIDTH  = 32;
localparam        M_ADDR_WIDTH  = 32;
localparam        M_DATA_WIDTH  = 32;



localparam        IDLE            = 4'h0;
localparam        EXECUTE         = 4'h1;
localparam        RESET           = 4'h2;
localparam        PING_RESPONSE   = 4'h3;
localparam        WRITE_DATA      = 4'h4;
localparam        WRITE_RESPONSE  = 4'h5;
localparam        GET_WRITE_DATA  = 4'h6;
localparam        READ_RESPONSE   = 4'h7;
localparam        READ_MORE_DATA  = 4'h8;


//Registers/Wires
//Virtual Host Interface Signals
reg               clk           = 0;
reg               rst           = 0;
wire              w_master_ready;
reg               r_in_ready      = 0;
reg   [31:0]      r_in_command    = 32'h00000000;
reg   [31:0]      r_in_address    = 32'h00000000;
reg   [31:0]      r_in_data       = 32'h00000000;
reg   [23:0]      r_in_data_count = 0;
reg               r_out_ready     = 0;
wire              w_out_en;
wire  [31:0]      w_out_status;
wire  [31:0]      w_out_address;
wire  [31:0]      w_out_data;
wire  [23:0]      w_out_data_count;
reg               r_ih_reset      = 0;

//Registers/Wires/Simulation Integers
integer           fd_in;
integer           fd_out;
integer           read_count;
integer           timeout_count;
integer           ch;

integer           data_count;

reg [3:0]         state           =   IDLE;
reg               prev_int        = 0;

reg               execute_command;
reg               command_finished;
reg               request_more_data;
reg               request_more_data_ack;
reg     [27:0]    data_write_count;

//Axi Master
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
  .clk                  (clk              ),
  .rst                  (rst              ),

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


  .o_p_aclk             (w_p_aclk         ),
  .o_p_areset_n         (w_p_areset_n     ),

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

  .o_p_csysreq          (w_p_csysreq      ),
  .i_p_csysack          (w_p_csysack      ),
  .i_p_cactive          (w_p_cactive      ),

  .o_m_aclk             (w_m_aclk         ),
  .o_m_areset_n         (w_m_areset_n     ),

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

  .o_m_wid              (w_m_wid          ),
  .o_m_wdata            (w_m_wdata        ),

  .o_m_wstrobe          (w_m_wstrobe      ),
  .o_m_wlast            (w_m_wlast        ),
  .o_m_wvalid           (w_m_wvalid       ),
  .i_m_wready           (w_m_wready       ),


  .i_m_bid              (w_m_bid          ),
  .i_m_bresp            (w_m_bresp        ),

  .i_m_bvalid           (w_m_bvalid       ),
  .o_m_bready           (w_m_bready       ),

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

  .i_m_rid              (w_m_rid          ),
  .i_m_rdata            (w_m_rdata        ),

  .i_m_rstrobe          (w_m_rstrobe      ),
  .i_m_rlast            (w_m_rlast        ),
  .i_m_rvalid           (w_m_rvalid       ),
  .o_m_rready           (w_m_rready       ),

  .o_m_csysreq          (w_m_csysreq      ),
  .i_m_csysack          (w_m_csysack      ),
  .i_m_cactive          (w_m_cactive      )

);

axi4_interconnect pi(
  .am_aclk              (w_p_aclk         ),
  .am_areset_n          (w_p_areset_n     ),

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

  .i_am_wid             (w_p_wid          ),
  .i_am_wdata           (w_p_wdata        ),
  .i_am_wstrobe         (w_p_wstrobe      ),
  .i_am_wlast           (w_p_wlast        ),
  .i_am_wvalid          (w_p_wvalid       ),
  .o_am_wready          (w_p_wready       ),
  .o_am_bid             (w_p_bid          ),
  .o_am_bresp           (w_p_bresp        ),
  .o_am_bvalid          (w_p_bvalid       ),
  .i_am_bready          (w_p_bready       ),
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
  .o_am_rid             (w_p_rid          ),
  .o_am_rdata           (w_p_rdata        ),
  .o_am_rstrobe         (w_p_rstrobe      ),
  .o_am_rlast           (w_p_rlast        ),
  .o_am_rvalid          (w_p_rvalid       ),
  .i_am_rready          (w_p_rready       ),
  .i_am_csysreq         (w_p_csysreq      ),
  .o_am_csysack         (w_p_csysack      ),
  .o_am_cactive         (w_p_cactive      ),

//Axi4 Slave
  //Axi4 Peripheral Bus

    //peripheral bus
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
  .o_as_wid             (w_as_wid         ),
  .o_as_wdata           (w_as_wdata       ),
  .o_as_wstrobe         (w_as_wstrobe     ),
  .o_as_wlast           (w_as_wlast       ),
  .o_as_wvalid          (w_as_wvalid      ),
  .i_as_wready          (w_as_wready      ),
  .i_as_bid             (w_as_bid         ),
  .i_as_bresp           (w_as_bresp       ),
  .i_as_bvalid          (w_as_bvalid      ),
  .o_as_bready          (w_as_bready      ),
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
  .i_as_rid             (w_as_rid         ),
  .i_as_rdata           (w_as_rdata       ),
  .i_as_rstrobe         (w_as_rstrobe     ),
  .i_as_rlast           (w_as_rlast       ),
  .i_as_rvalid          (w_as_rvalid      ),
  .o_as_rready          (w_as_rready      ),
  .o_as_csysreq         (w_as_csysreq     ),
  .i_as_csysack         (w_as_csysack     ),
  .i_as_cactive         (w_as_cactive     )


);

axi4_slave as(
  .clk                  (w_p_aclk         ),
  .rst_n                (w_p_areset_n     ),
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
  .i_arid               (w_as_arid        ),
  .i_araddr             (w_as_araddr      ),
  .i_arlen              (w_as_arlen       ),
  .i_arsize             (w_as_arsize      ),
  .i_arburst            (w_as_arburst     ),
  .i_arlock             (w_as_arlock      ),
  .i_arcache            (w_as_arcache     ),
  .i_arprot             (w_as_arprot      ),
  .i_arvalid            (w_as_arvalid     ),
  .o_arready            (w_as_arready     ),
  .o_rid                (w_as_rid         ),
  .o_rdata              (w_as_rdata       ),
  .o_rstrobe            (w_as_rstrobe     ),
  .o_rlast              (w_as_rlast       ),
  .o_rvalid             (w_as_rvalid      ),
  .i_rready             (w_as_rready      ),
  .i_csysreq            (w_as_csysreq     ),
  .o_csysack            (w_as_csysack     ),
  .o_cactive            (w_as_cactive     )
);

//Asynchronous Logic

always #`CLK_HALF_PERIOD      clk = ~clk;

//Synchronous Logic
initial begin
  //$monitor("%t, state: %h", $time, state);
end

initial begin
  fd_out                      = 0;
  read_count                  = 0;
  data_count                  = 0;
  timeout_count               = 0;
  request_more_data_ack       <=  0;
  execute_command             <=  0;

  $dumpfile ("design.vcd");
  $dumpvars (0, tb_axi4);
  fd_in                       = $fopen(`INPUT_FILE, "r");
  fd_out                      = $fopen(`OUTPUT_FILE, "w");
  `SLEEP_HALF_CLK;

  rst                         <= 0;
  `SLEEP_CLK(2);
  rst                         <= 1;

  //clear the handler signals
  r_in_ready                    <= 0;
  r_in_command                  <= 0;
  r_in_address                  <= 32'h0;
  r_in_data                     <= 32'h0;
  r_in_data_count               <= 0;
  r_out_ready                   <= 0;
  //clear wishbone signals
  `SLEEP_CLK(10);
  rst                           <= 0;
  r_out_ready                   <= 1;

  if (fd_in == 0) begin
    $display ("TB: input stimulus file was not found");
  end
  else begin
    //while there is still data to be read from the file
    while (!$feof(fd_in)) begin
      //read in a command
      read_count = $fscanf (fd_in, "%h:%h:%h:%h\n",
                                  r_in_data_count,
                                  r_in_command,
                                  r_in_address,
                                  r_in_data);

      //Handle Frindge commands/comments
      if (read_count != 4) begin
        if (read_count == 0) begin
          ch = $fgetc(fd_in);
          if (ch == "\#") begin
            //$display ("Eat a comment");
            //Eat the line
            while (ch != "\n") begin
              ch = $fgetc(fd_in);
            end
            $display ("");
          end
          else begin
            $display ("Error unrecognized line: %h" % ch);
            //Eat the line
            while (ch != "\n") begin
              ch = $fgetc(fd_in);
            end
          end
        end
        else if (read_count == 1) begin
          $display ("Sleep for %h Clock cycles", r_in_data_count);
          `SLEEP_CLK(r_in_data_count);
          $display ("");
        end
        else begin
          $display ("Error: read_count = %h != 4", read_count);
          $display ("Character: %h", ch);
        end
      end
      else begin
        case (r_in_command)
          0: $display ("TB: Executing PING commad");
          1: $display ("TB: Executing WRITE command");
          2: $display ("TB: Executing READ command");
          3: $display ("TB: Executing RESET command");
        endcase
        execute_command                 <= 1;
        `SLEEP_CLK(1);
        while (~command_finished) begin
          request_more_data_ack         <= 0;

          if ((r_in_command & 32'h0000FFFF) == 1) begin
            if (request_more_data && ~request_more_data_ack) begin
              read_count      = $fscanf(fd_in, "%h\n", r_in_data);
              $display ("TB: reading a new double word: %h", r_in_data);
              request_more_data_ack     <= 1;
            end
          end

          //so time porgresses wait a tick
          `SLEEP_CLK(1);
          //this doesn't need to be here, but there is a weird behavior in iverilog
          //that wont allow me to put a delay in right before an 'end' statement
          execute_command <= 1;
        end //while command is not finished
        while (command_finished) begin
          `SLEEP_CLK(1);
          execute_command <= 0;
        end
        `SLEEP_CLK(50);
        $display ("TB: finished command");
      end //end read_count == 4
    end //end while ! eof
  end //end not reset
  `SLEEP_CLK(50);
  $fclose (fd_in);
  $fclose (fd_out);
  $finish();
end

always @ (posedge clk) begin
  if (rst) begin
    state                     <= IDLE;
    request_more_data         <= 0;
    timeout_count             <= 0;
    prev_int                  <= 0;
    r_ih_reset                <= 0;
    data_write_count          <= 0;
  end
  else begin
    r_ih_reset                <= 0;
    r_in_ready                <= 0;
    r_out_ready               <= 1;
    command_finished          <= 0;

    //Countdown the NACK timeout
    if (execute_command && timeout_count > 0) begin
      timeout_count           <= timeout_count - 1;
    end

    if (execute_command && timeout_count == 0) begin
      case (r_in_command)
        0: $display ("TB: Master timed out while executing PING commad");
        1: $display ("TB: Master timed out while executing WRITE command");
        2: $display ("TB: Master timed out while executing READ command");
        3: $display ("TB: Master timed out while executing RESET command");
      endcase

      state                   <= IDLE;
      command_finished        <= 1;
      timeout_count           <= `TIMEOUT_COUNT;
      data_write_count        <= 1;
    end //end reached the end of a timeout

    case (state)
      IDLE: begin
        if (execute_command & ~command_finished) begin
          $display ("TB: #:C:A:D = %h:%h:%h:%h", r_in_data_count, r_in_command, r_in_address, r_in_data);
          timeout_count       <= `TIMEOUT_COUNT;
          state               <= EXECUTE;
        end
      end
      EXECUTE: begin
        if (w_master_ready) begin
          //send the command over
          r_in_ready            <= 1;
          case (r_in_command & 32'h0000FFFF)
            0: begin
              //ping
              state           <=  PING_RESPONSE;
            end
            1: begin
              //write
              if (r_in_data_count > 1) begin
                $display ("TB: \tWrote double word %d: %h", data_write_count, r_in_data);
                state                   <=  WRITE_DATA;
                timeout_count           <= `TIMEOUT_COUNT;
                data_write_count        <=  data_write_count + 1;
              end
              else begin
                if (data_write_count > 1) begin
                  $display ("TB: \tWrote double word %d: %h", data_write_count, r_in_data);
                end
                state                   <=  WRITE_RESPONSE;
              end
            end
            2: begin
              //read
              state           <=  READ_RESPONSE;
            end
            3: begin
              //reset
              state           <=  RESET;
            end
          endcase
        end
      end
      RESET: begin
        //reset the system
        r_ih_reset                    <=  1;
        command_finished            <=  1;
        state                       <=  IDLE;
      end
      PING_RESPONSE: begin
        if (w_out_en) begin
          if (w_out_status == (~(32'h00000000))) begin
            $display ("TB: Read a successful ping reponse");
          end
          else begin
            $display ("TB: Ping response is incorrect!");
          end
          $display ("TB: \tS:A:D = %h:%h:%h\n", w_out_status, w_out_address, w_out_data);
          command_finished  <= 1;
          state                     <=  IDLE;
        end
      end
      WRITE_DATA: begin
        if (!r_in_ready && w_master_ready) begin
          state                     <=  GET_WRITE_DATA;
          request_more_data         <=  1;
        end
      end
      WRITE_RESPONSE: begin
        if (w_out_en) begin
         if (w_out_status == (~(32'h00000001))) begin
            $display ("TB: Read a successful write reponse");
          end
          else begin
            $display ("TB: Write response is incorrect!");
          end
          $display ("TB: \tS:A:D = %h:%h:%h\n", w_out_status, w_out_address, w_out_data);
          state                   <=  IDLE;
          command_finished  <= 1;
        end
      end
      GET_WRITE_DATA: begin
        if (request_more_data_ack) begin
//XXX: should request more data be a strobe?
          request_more_data   <=  0;
          r_in_ready            <=  1;
          r_in_data_count       <=  r_in_data_count -1;
          state               <=  EXECUTE;
        end
      end
      READ_RESPONSE: begin
        if (w_out_en) begin
          if (w_out_status == (~(32'h00000002))) begin
            $display ("TB: Read a successful read response");
            if (w_out_data_count > 0) begin
              state             <=  READ_MORE_DATA;
              //reset the NACK timeout
              timeout_count     <=  `TIMEOUT_COUNT;
            end
            else begin
              state             <=  IDLE;
              command_finished  <= 1;
            end
          end
          else begin
            $display ("TB: Read response is incorrect");
            command_finished  <= 1;
          end
          $display ("TB: \tS:A:D = %h:%h:%h\n", w_out_status, w_out_address, w_out_data);
        end
      end
      READ_MORE_DATA: begin
        if (w_out_en) begin
          r_out_ready             <=  0;
          if (w_out_status == (~(32'h00000002))) begin
            $display ("TB: Read a 32bit data packet");
            $display ("Tb: \tRead Data: %h", w_out_data);
          end
          else begin
            $display ("TB: Read reponse is incorrect");
          end

          //read the output data count to determine if there is more data
          if (w_out_data_count == 0) begin
            state             <=  IDLE;
            command_finished  <=  1;
          end
        end
      end
      default: begin
        $display ("TB: state is wrong");
        state <= IDLE;
      end //somethine wrong here
    endcase //state machine
    if (w_out_en && w_out_status == `PERIPH_INTERRUPT) begin
      $display("TB: Output Handler Recieved interrupt");
      $display("TB:\tcommand: %h", w_out_status);
      $display("TB:\taddress: %h", w_out_address);
      $display("TB:\tdata: %h", w_out_data);
    end
  end//not reset
end



endmodule

