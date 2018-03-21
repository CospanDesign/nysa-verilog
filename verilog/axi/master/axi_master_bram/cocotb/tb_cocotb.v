`timescale 1ns/1ps

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

module tb_cocotb #(
  parameter AXI_DATA_WIDTH          = 32, //This is the output bus
  parameter AXI_ADDR_WIDTH          = 32,
  parameter AXI_MAX_BURST_LENGTH    = 1024,
  parameter MAX_PACKET_WIDTH        = `CLOG2(AXI_MAX_BURST_LENGTH),
  parameter BRAM_ADDR_WIDTH         = 10,
  parameter BRAM_DATA_WIDTH         = 32,
  parameter INTERRUPT_WIDTH         = 32
)(

//Virtual Host Interface Signals
input                               clk,
input                               rst,


input       [31:0]                  test_id,

input                                 CMD_EN,
output                                CMD_ERROR,
output                                CMD_ACK,

input       [AXI_ADDR_WIDTH - 1:0]    CMD_ADR,
input                                 CMD_ADR_FIXED,
input                                 CMD_ADR_WRAP,

input                                 CMD_WR_RD,        //1 = wRITE, 0 = rEAD
input       [MAX_PACKET_WIDTH - 1: 0] CMD_COUNT,

output      [31:0]                    CMD_STATUS,
output                                CMD_INTERRUPTS,

//BRAM Data
input                                 BRAM_INGRESS_CLK,
input                                 BRAM_INGRESS_WEA,
input       [BRAM_ADDR_WIDTH - 1: 0]  BRAM_INGRESS_ADDR,
input       [BRAM_DATA_WIDTH - 1: 0]  BRAM_INGRESS_DATA,

input                                 BRAM_EGRESS_CLK,
output      [BRAM_ADDR_WIDTH - 1: 0]  BRAM_EGRESS_ADDR,
output      [BRAM_DATA_WIDTH - 1: 0]  BRAM_EGRESS_DATA,

//***************** AXI Bus ************************************************

//bus write addr path
output      [3:0]                     AXI_AWID,         //Write ID
output      [AXI_ADDR_WIDTH - 1:0]    AXI_AWADDR,       //Write Addr Path Address
output      [7:0]                     AXI_AWLEN,        //Write Addr Path Burst Length
output      [2:0]                     AXI_AWSIZE,       //Write Addr Path Burst Size (Byte with (00 = 8 bits wide, 01 = 16 bits wide)
output      [1:0]                     AXI_AWBURST,      //Write Addr Path Burst Type
                                                          //  0 = Fixed
                                                          //  1 = Incrementing
                                                          //  2 = wrap
output      [1:0]                     AXI_AWLOCK,       //Write Addr Path Lock (atomic) information
                                                          //  0 = Normal
                                                          //  1 = Exclusive
                                                          //  2 = Locked
output      [3:0]                     AXI_AWCACHE,      //Write Addr Path Cache Type
output      [2:0]                     AXI_AWPROT,       //Write Addr Path Protection Type
output                                AXI_AWVALID,      //Write Addr Path Address Valid
input                                 AXI_AWREADY,      //Write Addr Path Slave Ready
                                                          //  1 = Slave Ready
                                                          //  0 = Slave Not Ready

//bus write data
output      [3:0]                     AXI_WID,          //Write ID
output      [AXI_DATA_WIDTH - 1: 0]       AXI_WDATA,        //Write Data (this size is set with the AXI_DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
output      [(AXI_DATA_WIDTH >> 3) - 1:0] AXI_WSTRB,      //Write Strobe (a 1 in the write is associated with the byte to write)
output                                AXI_WLAST,        //Write Last transfer in a write burst
output                                AXI_WVALID,       //Data through this bus is valid
input                                 AXI_WREADY,       //Slave is ready for data

//Write Response Channel
input       [3:0]                     AXI_BID,          //Response ID (this must match awid)
input       [1:0]                     AXI_BRESP,        //Write Response
                                                          //  0 = OKAY
                                                          //  1 = EXOKAY
                                                          //  2 = SLVERR
                                                          //  3 = DECERR
input                                 AXI_BVALID,       //Write Response is:
                                                          //  1 = Available
                                                          //  0 = Not Available
output                                AXI_BREADY,       //WBM Ready

//bus read addr path
output       [3:0]                    AXI_ARID,         //Read ID
output       [AXI_ADDR_WIDTH - 1:0]       AXI_ARADDR,       //Read Addr Path Address
output       [7:0]                    AXI_ARLEN,        //Read Addr Path Burst Length
output       [2:0]                    AXI_ARSIZE,       //Read Addr Path Burst Size (Byte with (00 = 8 bits wide, 01 = 16 bits wide)
output       [1:0]                    AXI_ARBURST,      //Read Addr Path Burst Type
output       [1:0]                    AXI_ARLOCK,       //Read Addr Path Lock (atomic) information
output       [3:0]                    AXI_ARCACHE,      //Read Addr Path Cache Type
output       [2:0]                    AXI_ARPROT,       //Read Addr Path Protection Type
output                                AXI_ARVALID,      //Read Addr Path Address Valid
input                                 AXI_ARREADY,      //Read Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready
//bus read data
input       [3:0]                     AXI_RID,          //Write ID
input       [AXI_DATA_WIDTH - 1: 0]       AXI_RDATA,        //Write Data (this size is set with the AXI_DATA_WIDTH Parameter
                                                          //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
input       [1:0]                     AXI_RRESP,
input       [(AXI_DATA_WIDTH >> 3) - 1:0] AXI_RSTRB,      //Write Strobe (a 1 in the write is associated with the byte to write)
input                                 AXI_RLAST,        //Write Last transfer in a write burst
input                                 AXI_RVALID,       //Data through this bus is valid
output                                AXI_RREADY,       //WBM is ready for data
                                                        //  1 = WBM Ready
                                                        //  0 = Slave Ready

input     [INTERRUPT_WIDTH - 1:0]   i_interrupts


);

//Local Parameters
localparam        INVERT_AXI_RESET      = 0;
localparam        FIFO_DEPTH            = 8; //256
localparam        ENABLE_NACK           = 0; //Enable timeout
localparam        DEFAULT_TIMEOUT       = 32'd100000000;  //1 Second at 100MHz


//Registers/Wires
reg                               r_rst;

wire      [INTERRUPT_WIDTH - 1:0] w_interrupts;

//Submodules
axi_master_bram #(
  .INVERT_AXI_RESET     (INVERT_AXI_RESET        ),
  .INTERNAL_BRAM        (1                       ),
//  .AXI_MAX_BURST_LENGTH(
  .AXI_MAX_BURST_LENGTH (AXI_MAX_BURST_LENGTH    ),
  .AXI_ADDR_WIDTH       (AXI_ADDR_WIDTH          ),
  .AXI_DATA_WIDTH       (AXI_DATA_WIDTH          ),
  .INTERRUPT_WIDTH      (INTERRUPT_WIDTH         ),
  .ENABLE_NACK          (ENABLE_NACK             ),
  .DEFAULT_TIMEOUT      (DEFAULT_TIMEOUT         )
) am (

  .i_axi_clk             (clk                    ),
  .i_axi_rst             (r_rst                  ),
  //************* User Facing Side *******************************************
  .i_cmd_en              (CMD_EN                 ),
  .o_cmd_error           (CMD_ERROR              ),
  .o_cmd_ack             (CMD_ACK                ),

  .o_cmd_status          (CMD_STATUS             ),
  .o_cmd_interrupts      (CMD_INTERRUPTS         ),

  .i_cmd_addr            (CMD_ADR                ),

  .i_cmd_wr_rd           (CMD_WR_RD              ),
  .i_cmd_data_byte_count (CMD_COUNT              ),

  //Data BRAM
  .i_int_bram_ingress_clk    (BRAM_INGRESS_CLK  ),
  .i_int_bram_ingress_wea    (BRAM_INGRESS_WEA  ),
  .i_int_bram_ingress_addr   (BRAM_INGRESS_ADDR ),
  .i_int_bram_ingress_data   (BRAM_INGRESS_DATA ),

  .i_int_bram_egress_clk     (BRAM_EGRESS_CLK   ),
  .i_int_bram_egress_addr    (BRAM_EGRESS_ADDR  ),
  .o_int_bram_egress_data    (BRAM_EGRESS_DATA  ),


  .o_ext_bram_ingress_addr   (                  ),
  .i_ext_bram_ingress_data   (0                 ),

  .o_ext_bram_egress_wea     (                  ),
  .o_ext_bram_egress_addr    (                  ),
  .o_ext_bram_egress_data    (                  ),




  //***************** AXI Bus ************************************************
  //bus write addr path
  .o_awid                (AXI_AWID              ),
  .o_awaddr              (AXI_AWADDR            ),
  .o_awlen               (AXI_AWLEN             ),
  .o_awsize              (AXI_AWSIZE            ),
  .o_awburst             (AXI_AWBURST           ),
  .o_awlock              (AXI_AWLOCK            ),
  .o_awcache             (AXI_AWCACHE           ),
  .o_awprot              (AXI_AWPROT            ),
  .o_awvalid             (AXI_AWVALID           ),
  .i_awready             (AXI_AWREADY           ),

  //bus write data
  .o_wid                 (AXI_WID               ),
  .o_wdata               (AXI_WDATA             ),
  .o_wstrobe             (AXI_WSTRB             ),
  .o_wlast               (AXI_WLAST             ),
  .o_wvalid              (AXI_WVALID            ),
  .i_wready              (AXI_WREADY            ),

  //Write Response Channel
  .i_bid                 (AXI_BID               ),
  .i_bresp               (AXI_BRESP             ),
  .i_bvalid              (AXI_BVALID            ),
  .o_bready              (AXI_BREADY            ),

  //bus read addr path
  .o_arid                (AXI_ARID              ),
  .o_araddr              (AXI_ARADDR            ),
  .o_arlen               (AXI_ARLEN             ),
  .o_arsize              (AXI_ARSIZE            ),
  .o_arburst             (AXI_ARBURST           ),
  .o_arlock              (AXI_ARLOCK            ),
  .o_arcache             (AXI_ARCACHE           ),
  .o_arprot              (AXI_ARPROT            ),
  .o_arvalid             (AXI_ARVALID           ),
  .i_arready             (AXI_ARREADY           ),

  //bus read data
  .i_rid                 (AXI_RID               ),
  .i_rdata               (AXI_RDATA             ),
  .i_rresp               (AXI_RRESP             ),
  .i_rstrobe             (AXI_RSTRB             ),
  .i_rlast               (AXI_RLAST             ),
  .i_rvalid              (AXI_RVALID            ),
  .o_rready              (AXI_RREADY            ),

  //nterrupts
  .i_interrupts          (i_interrupts           )
);

//There is a timing thing in COCOTB when stiumlating a signal, sometimes it can be corrupted if not registered
always @ (*) r_rst          = rst;



//Submodules
//Asynchronous Logic
//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
