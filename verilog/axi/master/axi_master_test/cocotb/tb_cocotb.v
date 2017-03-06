`timescale 1ns/1ps
//`include "project_defines.v"

module tb_cocotb (

//Virtual Host Interface Signals
input               clk,
input               rst,

input       [31:0]  test_id,
output              device_interrupt,

output      [1:0]   ingress_rdy,
input       [1:0]   ingress_act,
input               ingress_stb,
input       [31:0]  ingress_data,
output      [23:0]  ingress_size,

output              egress_rdy,
input               egress_act,
input               egress_stb,
output      [31:0]  egress_data,
output      [23:0]  egress_size

);

//Local Parameters
localparam         INGRESS_FIFO_DEPTH    = 9; //512
localparam         EGRESS_FIFO_DEPTH     = 9; //512
localparam         HI_DATA_WIDTH         = 32;
localparam         HI_ADDR_WIDTH         = 32;
localparam         ADDR_WIDTH            = 32;
localparam         DATA_WIDTH            = 32;
localparam         INTERRUPT_WIDTH       = 32;
localparam         ENABLE_WRITE_RESP     = 0; //Don't send a response when writing (Faster)
localparam         ENABLE_NACK           = 0; //Enable timeout
localparam         DEFAULT_TIMEOUT       = 32'd100000000;  //1 Second at 100MHz
localparam         SDB_ADDRESS           = 64'h0000000000000000;


reg                 r_rst;
reg         [1:0]   r_ingress_act;
reg                 r_ingress_stb;
reg         [31:0]  r_ingress_data;
reg                 r_egress_clk;
reg                 r_egress_act;
reg                 r_egress_stb;

//Parameters
//Registers/Wires

//wishbone signals
wire              w_wbp_we;
wire              w_wbp_cyc;
wire              w_wbp_stb;
wire [3:0]        w_wbp_sel;
wire [31:0]       w_wbp_adr;
wire [31:0]       w_wbp_dat_o;
wire [31:0]       w_wbp_dat_i;
wire              w_wbp_ack;
wire              w_wbp_int;

//Wishbone Slave 0 (SDB) signals
wire              w_wbs0_we;
wire              w_wbs0_cyc;
wire  [31:0]      w_wbs0_dat_o;
wire              w_wbs0_stb;
wire  [3:0]       w_wbs0_sel;
wire              w_wbs0_ack;
wire  [31:0]      w_wbs0_dat_i;
wire  [31:0]      w_wbs0_adr;
wire              w_wbs0_int;

//mem slave 0
wire              w_sm0_i_wbs_we;
wire              w_sm0_i_wbs_cyc;
wire  [31:0]      w_sm0_i_wbs_dat;
wire  [31:0]      w_sm0_o_wbs_dat;
wire  [31:0]      w_sm0_i_wbs_adr;
wire              w_sm0_i_wbs_stb;
wire  [3:0]       w_sm0_i_wbs_sel;
wire              w_sm0_o_wbs_ack;
wire              w_sm0_o_wbs_int;

//wishbone slave 1 (Unit Under Test) signals
wire              w_wbs1_we;
wire              w_wbs1_cyc;
wire              w_wbs1_stb;
wire  [3:0]       w_wbs1_sel;
wire              w_wbs1_ack;
wire  [31:0]      w_wbs1_dat_i;
wire  [31:0]      w_wbs1_dat_o;
wire  [31:0]      w_wbs1_adr;
wire              w_wbs1_int;

//Memory Interface
wire              w_mem_we_o;
wire              w_mem_cyc_o;
wire              w_mem_stb_o;
wire  [3:0]       w_mem_sel_o;
wire  [31:0]      w_mem_adr_o;
wire  [31:0]      w_mem_dat_i;
wire  [31:0]      w_mem_dat_o;
wire              w_mem_ack_i;
wire              w_mem_int_i;

wire              w_arb0_i_wbs_stb;
wire              w_arb0_i_wbs_cyc;
wire              w_arb0_i_wbs_we;
wire  [3:0]       w_arb0_i_wbs_sel;
wire  [31:0]      w_arb0_i_wbs_dat;
wire  [31:0]      w_arb0_o_wbs_dat;
wire  [31:0]      w_arb0_i_wbs_adr;
wire              w_arb0_o_wbs_ack;
wire              w_arb0_o_wbs_int;


wire              mem_o_we;
wire              mem_o_stb;
wire              mem_o_cyc;
wire  [3:0]       mem_o_sel;
wire  [31:0]      mem_o_adr;
wire  [31:0]      mem_o_dat;
wire  [31:0]      mem_i_dat;
wire              mem_i_ack;
wire              mem_i_int;





//AXI Bus
wire                              w_aclk;
wire                              w_areset_n;

//bus write addr path
wire        [3:0]                 w_awid;         //Write ID
wire        [ADDR_WIDTH - 1:0]    w_awaddr;       //Write Addr Path Address
wire        [3:0]                 w_awlen;        //Write Addr Path Burst Length
wire        [2:0]                 w_awsize;       //Write Addr Path Burst Size
wire        [1:0]                 w_awburst;      //Write Addr Path Burst Type
                                                      //  0 = Fixed
                                                      //  1 = Incrementing
                                                      //  2 = wrap
wire        [1:0]                 w_awlock;       //Write Addr Path Lock (atomic) information
                                                      //  0 = Normal
                                                      //  1 = Exclusive
                                                      //  2 = Locked
wire        [3:0]                 w_awcache;      //Write Addr Path Cache Type
wire        [2:0]                 w_awprot;       //Write Addr Path Protection Type
wire                              w_awvalid;      //Write Addr Path Address Valid
input                             w_awready;      //Write Addr Path Slave Ready
                                                      //  1 = Slave Ready
                                                      //  0 = Slave Not Ready

  //bus write data
wire        [3:0]                 w_wid;          //Write ID
wire        [DATA_WIDTH - 1: 0]   w_wdata;        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                    //Valid values are: 8; 16; 32; 64; 128; 256; 512; 1024
wire        [DATA_WIDTH >> 3:0]   w_wstrobe;      //Write Strobe (a 1 in the write is associated with the byte to write)
wire                              w_wlast;        //Write Last transfer in a write burst
wire                              w_wvalid;       //Data through this bus is valid
input                             w_wready;       //Slave is ready for data

  //Write Response Channel
input       [3:0]                 w_bid;          //Response ID (this must match awid)
input       [1:0]                 w_bresp;        //Write Response
                                                      //  0 = OKAY
                                                      //  1 = EXOKAY
                                                      //  2 = SLVERR
                                                      //  3 = DECERR
input                             w_bvalid;       //Write Response is:
                                                      //  1 = Available
                                                      //  0 = Not Available
wire                              w_bready;       //WBM Ready

  //bus read addr path
wire         [3:0]                w_arid;         //Read ID
wire         [ADDR_WIDTH - 1:0]   w_araddr;       //Read Addr Path Address
wire         [3:0]                w_arlen;        //Read Addr Path Burst Length
wire         [2:0]                w_arsize;       //Read Addr Path Burst Size
wire         [1:0]                w_arburst;      //Read Addr Path Burst Type
wire         [1:0]                w_arlock;       //Read Addr Path Lock (atomic) information
wire         [3:0]                w_arcache;      //Read Addr Path Cache Type
wire         [2:0]                w_arprot;       //Read Addr Path Protection Type
wire                              w_arvalid;      //Read Addr Path Address Valid
input                             w_arready;      //Read Addr Path Slave Ready
                                                      //  1 = Slave Ready
                                                      //  0 = Slave Not Ready
  //bus read data
input       [3:0]                 w_rid;          //Write ID
input       [DATA_WIDTH - 1: 0]   w_rdata;        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                  //Valid values are: 8; 16; 32; 64; 128; 256; 512; 1024
input       [DATA_WIDTH >> 3:0]   w_rstrobe;      //Write Strobe (a 1 in the write is associated with the byte to write)
input                             w_rlast;        //Write Last transfer in a write burst
input                             w_rvalid;       //Data through this bus is valid
wire                              w_rready;       //WBM is ready for data
                                                      //  1 = WBM Ready
                                                      //  0 = Slave Ready

input     [INTERRUPT_WIDTH - 1:0] w_interrupts;




//Submodules
/*
wishbone_master #(
//  .INGRESS_FIFO_DEPTH    (9                ),
//  .EGRESS_FIFO_DEPTH     (9                ),
//  .ENABLE_WRITE_RESP     (0                ),
//  .ENABLE_NACK           (0                ),
//  .DEFAULT_TIMEOUT       (`CLOCK_RATE      )
) wm (

  .clk                   (clk              ),
  .rst                   (r_rst            ),


  //indicate to the input that we are ready
  .i_ingress_clk         (clk              ),
  .o_ingress_rdy         (ingress_rdy      ),
  .i_ingress_act         (r_ingress_act    ),
  .i_ingress_stb         (r_ingress_stb    ),
  .i_ingress_data        (r_ingress_data   ),
  .o_ingress_size        (ingress_size     ),

  .i_egress_clk          (clk              ),
  .o_egress_rdy          (egress_rdy       ),
  .i_egress_act          (r_egress_act     ),
  .i_egress_stb          (r_egress_stb     ),
  .o_egress_data         (egress_data      ),
  .o_egress_size         (egress_size      ),

  //General Control
  .o_sync_rst            (w_sync_rst       ),

  .o_per_we              (w_wbp_we         ),
  .o_per_adr             (w_wbp_adr        ),
  .o_per_dat             (w_wbp_dat_i      ),
  .i_per_dat             (w_wbp_dat_o      ),
  .o_per_stb             (w_wbp_stb        ),
  .o_per_cyc             (w_wbp_cyc        ),
  .o_per_msk             (w_wbp_msk        ),
  .o_per_sel             (w_wbp_sel        ),
  .i_per_ack             (w_wbp_ack        ),
  .i_per_int             (w_wbp_int        ),

  //memory interconnect signals
  .o_mem_we              (w_mem_we_o       ),
  .o_mem_adr             (w_mem_adr_o      ),
  .o_mem_dat             (w_mem_dat_o      ),
  .i_mem_dat             (w_mem_dat_i      ),
  .o_mem_stb             (w_mem_stb_o      ),
  .o_mem_cyc             (w_mem_cyc_o      ),
  .o_mem_sel             (w_mem_sel_o      ),
  .i_mem_ack             (w_mem_ack_i      ),
  .i_mem_int             (w_mem_int_i      )
);
*/

axi_master #(
  .INGRESS_FIFO_DEPTH   (INGRESS_FIFO_DEPTH ),
  .EGRESS_FIFO_DEPTH    (EGRESS_FIFO_DEPTH  ),
  .HI_DATA_WIDTH        (HI_DATA_WIDTH      ),
  .HI_ADDR_WIDTH        (HI_ADDR_WIDTH      ),
  .ADDR_WIDTH           (ADDR_WIDTH         ),
  .DATA_WIDTH           (DATA_WIDTH         ),
  .INTERRUPT_WIDTH      (INTERRUPT_WIDTH    ),
  .ENABLE_WRITE_RESP    (ENABLE_WRITE_RESP  ),
  .ENABLE_NACK          (ENABLE_NACK        ),
  .DEFAULT_TIMEOUT      (DEFAULT_TIMEOUT    ),
  .SDB_ADDRESS          (SDB_ADDRESS        )
) am (

  .clk                   (clk               ),
  .rst                   (r_rst             ),

  //indicate to the input that we are ready
  .i_ingress_clk         (clk               ),
  .o_ingress_rdy         (ingress_rdy       ),
  .i_ingress_act         (r_ingress_act     ),
  .i_ingress_stb         (r_ingress_stb     ),
  .i_ingress_data        (r_ingress_data    ),
  .o_ingress_size        (ingress_size      ),

  .i_egress_clk          (clk               ),
  .o_egress_rdy          (egress_rdy        ),
  .i_egress_act          (r_egress_act      ),
  .i_egress_stb          (r_egress_stb      ),
  .o_egress_data         (egress_data       ),
  .o_egress_size         (egress_size       ),


  //AXI Bus
  .o_aclk                (w_aclk            ),
  .o_areset_n            (w_areset_n        ),

  //bus write addr path
  .o_awid                (w_awid            ),
  .o_awaddr              (w_awaddr          ),
  .o_awlen               (w_awlen           ),
  .o_awsize              (w_awsize          ),
  .o_awburst             (w_awburst         ),
  .o_awlock              (w_awlock          ),
  .o_awcache             (w_awcache         ),
  .o_awprot              (w_awprot          ),
  .o_awvalid             (w_awvalid         ),
  .i_awready             (w_awready         ),

  //bus write data
  .o_wid                 (w_wid             ),
  .o_wdata               (w_wdata           ),
  .o_wstrobe             (w_wstrobe         ),
  .o_wlast               (w_wlast           ),
  .o_wvalid              (w_wvalid          ),
  .i_wready              (w_wready          ),

  //Write Response Channel
  .i_bid                 (w_bid             ),
  .i_bresp               (w_bresp           ),
  .i_bvalid              (w_bvalid          ),
  .o_bready              (w_bready          ),

  //bus read addr path
  .o_arid                (w_arid            ),
  .o_araddr              (w_araddr          ),
  .o_arlen               (w_arlen           ),
  .o_arsize              (w_arsize          ),
  .o_arburst             (w_arburst         ),
  .o_arlock              (w_arlock          ),
  .o_arcache             (w_arcache         ),
  .o_arprot              (w_arprot          ),
  .o_arvalid             (w_arvalid         ),
  .i_arready             (w_arready         ),

  //bus read data
  .i_rid                 (w_rid             ),
  .i_rdata               (w_rdata           ),
  .i_rstrobe             (w_rstrobe         ),
  .i_rlast               (w_rlast           ),
  .i_rvalid              (w_rvalid          ),
  .o_rready              (w_rready          ),

  //nterrupts
  .i_interrupts          (w_interrupts      )
);


//slave 1
axi_master_test s1 (

  .clk                  (clk                  ),
  .rst                  (r_rst                ),

  .i_wbs_we             (w_wbs1_we            ),
  .i_wbs_sel            (4'b1111              ),
  .i_wbs_cyc            (w_wbs1_cyc           ),
  .i_wbs_dat            (w_wbs1_dat_i         ),
  .i_wbs_stb            (w_wbs1_stb           ),
  .o_wbs_ack            (w_wbs1_ack           ),
  .o_wbs_dat            (w_wbs1_dat_o         ),
  .i_wbs_adr            (w_wbs1_adr           ),
  .o_wbs_int            (w_wbs1_int           )
);

wishbone_interconnect wi (
  .clk        (clk                  ),
  .rst        (r_rst                ),

  .i_m_we     (w_wbp_we             ),
  .i_m_cyc    (w_wbp_cyc            ),
  .i_m_stb    (w_wbp_stb            ),
  .o_m_ack    (w_wbp_ack            ),
  .i_m_dat    (w_wbp_dat_i          ),
  .o_m_dat    (w_wbp_dat_o          ),
  .i_m_adr    (w_wbp_adr            ),
  .o_m_int    (w_wbp_int            ),

  .o_s0_we    (w_wbs0_we            ),
  .o_s0_cyc   (w_wbs0_cyc           ),
  .o_s0_stb   (w_wbs0_stb           ),
  .i_s0_ack   (w_wbs0_ack           ),
  .o_s0_dat   (w_wbs0_dat_i         ),
  .i_s0_dat   (w_wbs0_dat_o         ),
  .o_s0_adr   (w_wbs0_adr           ),
  .i_s0_int   (w_wbs0_int           ),

  .o_s1_we    (w_wbs1_we            ),
  .o_s1_cyc   (w_wbs1_cyc           ),
  .o_s1_stb   (w_wbs1_stb           ),
  .i_s1_ack   (w_wbs1_ack           ),
  .o_s1_dat   (w_wbs1_dat_i         ),
  .i_s1_dat   (w_wbs1_dat_o         ),
  .o_s1_adr   (w_wbs1_adr           ),
  .i_s1_int   (w_wbs1_int           )
);

wishbone_mem_interconnect wmi (
  .clk        (clk                  ),
  .rst        (r_rst                ),

  //master
  .i_m_we     (w_mem_we_o           ),
  .i_m_cyc    (w_mem_cyc_o          ),
  .i_m_stb    (w_mem_stb_o          ),
  .i_m_sel    (w_mem_sel_o          ),
  .o_m_ack    (w_mem_ack_i          ),
  .i_m_dat    (w_mem_dat_o          ),
  .o_m_dat    (w_mem_dat_i          ),
  .i_m_adr    (w_mem_adr_o          ),
  .o_m_int    (w_mem_int_i          ),

  //slave 0
  .o_s0_we    (w_sm0_i_wbs_we       ),
  .o_s0_cyc   (w_sm0_i_wbs_cyc      ),
  .o_s0_stb   (w_sm0_i_wbs_stb      ),
  .o_s0_sel   (w_sm0_i_wbs_sel      ),
  .i_s0_ack   (w_sm0_o_wbs_ack      ),
  .o_s0_dat   (w_sm0_i_wbs_dat      ),
  .i_s0_dat   (w_sm0_o_wbs_dat      ),
  .o_s0_adr   (w_sm0_i_wbs_adr      ),
  .i_s0_int   (w_sm0_o_wbs_int      )
);

arbiter_2_masters arb0 (
  .clk        (clk                  ),
  .rst        (r_rst                ),

  //masters
  .i_m1_we    (mem_o_we             ),
  .i_m1_stb   (mem_o_stb            ),
  .i_m1_cyc   (mem_o_cyc            ),
  .i_m1_sel   (mem_o_sel            ),
  .i_m1_dat   (mem_o_dat            ),
  .i_m1_adr   (mem_o_adr            ),
  .o_m1_dat   (mem_i_dat            ),
  .o_m1_ack   (mem_i_ack            ),
  .o_m1_int   (mem_i_int            ),


  .i_m0_we    (w_sm0_i_wbs_we       ),
  .i_m0_stb   (w_sm0_i_wbs_stb      ),
  .i_m0_cyc   (w_sm0_i_wbs_cyc      ),
  .i_m0_sel   (w_sm0_i_wbs_sel      ),
  .i_m0_dat   (w_sm0_i_wbs_dat      ),
  .i_m0_adr   (w_sm0_i_wbs_adr      ),
  .o_m0_dat   (w_sm0_o_wbs_dat      ),
  .o_m0_ack   (w_sm0_o_wbs_ack      ),
  .o_m0_int   (w_sm0_o_wbs_int      ),

  //slave
  .o_s_we     (w_arb0_i_wbs_we      ),
  .o_s_stb    (w_arb0_i_wbs_stb     ),
  .o_s_cyc    (w_arb0_i_wbs_cyc     ),
  .o_s_sel    (w_arb0_i_wbs_sel     ),
  .o_s_dat    (w_arb0_i_wbs_dat     ),
  .o_s_adr    (w_arb0_i_wbs_adr     ),
  .i_s_dat    (w_arb0_o_wbs_dat     ),
  .i_s_ack    (w_arb0_o_wbs_ack     ),
  .i_s_int    (w_arb0_o_wbs_int     )
);

wb_bram #(
  .DATA_WIDTH (32                   ),
  .ADDR_WIDTH (10                   )
)bram(
  .clk        (clk                  ),
  .rst        (r_rst                ),

  .i_wbs_we   (w_arb0_i_wbs_we      ),
  .i_wbs_sel  (w_arb0_i_wbs_sel     ),
  .i_wbs_cyc  (w_arb0_i_wbs_cyc     ),
  .i_wbs_dat  (w_arb0_i_wbs_dat     ),
  .i_wbs_stb  (w_arb0_i_wbs_stb     ),
  .i_wbs_adr  (w_arb0_i_wbs_adr     ),
  .o_wbs_dat  (w_arb0_o_wbs_dat     ),
  .o_wbs_ack  (w_arb0_o_wbs_ack     ),
  .o_wbs_int  (w_arb0_o_wbs_int     )
);

//There is a bug in COCOTB when stiumlating a signal, sometimes it can be corrupted if not registered
always @ (*) r_rst          = rst;
always @ (*) r_ingress_act  = ingress_act;
always @ (*) r_ingress_stb  = ingress_stb;
always @ (*) r_ingress_data = ingress_data;
always @ (*) r_egress_act   = egress_act;
always @ (*) r_egress_stb   = egress_stb;


//Disable Slave 0
assign  w_wbs0_int              = 0;
assign  w_wbs0_ack              = 0;
assign  w_wbs0_dat_o            = 0;
assign  device_interrupt        = w_wbp_int;

/*
  READ ME IF YOUR MODULE WILL INTERFACE WITH MEMORY

  If you want to talk to memory over the wishbone bus directly, your module must control the following signals:

  (Your module will be a wishbone master)
    mem_o_we
    mem_o_stb
    mem_o_cyc
    mem_o_sel
    mem_o_adr
    mem_o_dat
    mem_i_dat
    mem_i_ack
    mem_i_int

  Currently this bus is disabled so if will not interface with memory these signals can be left

  For a reference check out wb_sd_host

*/
assign  mem_o_we                = 0;
assign  mem_o_stb               = 0;
assign  mem_o_cyc               = 0;
assign  mem_o_sel               = 0;
assign  mem_o_adr               = 0;
assign  mem_o_dat               = 0;

//Submodules
//Asynchronous Logic
//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
