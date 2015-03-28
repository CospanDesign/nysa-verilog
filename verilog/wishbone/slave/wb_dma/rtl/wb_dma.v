//wb_dma.v
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
  Set the Vendor ID (Hexidecimal 64-bit Number)
  SDB_VENDOR_ID:0x800000000000C594

  Set the Device ID (Hexcidecimal 32-bit Number)
  SDB_DEVICE_ID:0x800000000000C594

  Set the version of the Core XX.XXX.XXX Example: 01.000.000
  SDB_CORE_VERSION:00.000.001

  Set the Device Name: 19 UNICODE characters
  SDB_NAME:wb_dma

  Set the class of the device (16 bits) Set as 0
  SDB_ABI_CLASS:0

  Set the ABI Major Version: (8-bits)
  SDB_ABI_VERSION_MAJOR:13

  Set the ABI Minor Version (8-bits)
  SDB_ABI_VERSION_MINOR:0

  Set the Module URL (63 Unicode Characters)
  SDB_MODULE_URL:http://www.example.com

  Set the date of module YYYY/MM/DD
  SDB_DATE:2015/03/27

  Device is executable (True/False)
  SDB_EXECUTABLE:True

  Device is readable (True/False)
  SDB_READABLE:True

  Device is writeable (True/False)
  SDB_WRITEABLE:True

  Device Size: Number of Registers
  SDB_SIZE:3
*/


module wb_dma #(
  parameter START_ENABLED       = 1,
  parameter WISHBONE_BUS_COUNT  = 1
)(
  input               clk,
  input               rst,

  //Add signals to control your device here

  //Wishbone Bus Signals
  input               i_wbs_we,
  input               i_wbs_cyc,
  input       [3:0]   i_wbs_sel,
  input       [31:0]  i_wbs_dat,
  input               i_wbs_stb,
  output  reg         o_wbs_ack,
  output  reg [31:0]  o_wbs_dat,
  input       [31:0]  i_wbs_adr,

  //Source 0
  input       [31:0]  i_src0_address,
  input       [31:0]  i_src0_size,
  input               i_src0_start,
  output              o_src0_finished,
  output              o_src0_busy,

  output              o_src0_if_strobe,
  output      [31:0]  i_src0_if_data,
  input       [1:0]   i_src0_if_ready,
  output      [1:0]   o_src0_if_activate,
  input       [23:0]  i_src0_if_size,
  input               i_src0_if_starved,

  //Source 1
  input       [31:0]  i_src1_address,
  input       [31:0]  i_src1_size,
  input               i_src1_start,
  output              o_src1_finished,
  output              o_src1_busy,

  output              o_src1_if_strobe,
  output      [31:0]  i_src1_if_data,
  input       [1:0]   i_src1_if_ready,
  output      [1:0]   o_src1_if_activate,
  input       [23:0]  i_src1_if_size,
  input               i_src1_if_starved,

  //Source 2
  input       [31:0]  i_src2_address,
  input       [31:0]  i_src2_size,
  input               i_src2_start,
  output              o_src2_finished,
  output              o_src2_busy,

  output              o_src2_if_strobe,
  output      [31:0]  i_src2_if_data,
  input       [1:0]   i_src2_if_ready,
  output      [1:0]   o_src2_if_activate,
  input       [23:0]  i_src2_if_size,
  input               i_src2_if_starved,

  //Source 3
  input       [31:0]  i_src3_address,
  input       [31:0]  i_src3_size,
  input               i_src3_start,
  output              o_src3_finished,
  output              o_src3_busy,

  output              o_src3_if_strobe,
  output      [31:0]  i_src3_if_data,
  input       [1:0]   i_src3_if_ready,
  output      [1:0]   o_src3_if_activate,
  input       [23:0]  i_src3_if_size,
  input               i_src3_if_starved,

  //Sink 0
  output              o_snk0_address,
  output              o_snk0_valid,

  output              o_snk0_strobe,
  input               i_snk0_ready,
  output              o_snk0_activate,
  input       [23:0]  i_snk0_size,
  input       [31:0]  o_snk0_data,

  //Sink 1
  output              o_snk1_address,
  output              o_snk1_valid,

  output              o_snk1_strobe,
  input               i_snk1_ready,
  output              o_snk1_activate,
  input       [23:0]  i_snk1_size,
  input       [31:0]  o_snk1_data,

  //Sink 2
  output              o_snk2_address,
  output              o_snk2_valid,

  output              o_snk2_strobe,
  input               i_snk2_ready,
  output              o_snk2_activate,
  input       [23:0]  i_snk2_size,
  input       [31:0]  o_snk2_data,

  //Sink 3
  output              o_snk3_address,
  output              o_snk3_valid,

  output              o_snk3_strobe,
  input               i_snk3_ready,
  output              o_snk3_activate,
  input       [23:0]  i_snk3_size,
  input       [31:0]  o_snk3_data,

  //Wishbone Bus Master
  output              wbm_o_we,
  output              wbm_o_stb,
  output              wbm_o_cyc,
  output      [3:0]   wbm_o_sel,
  output      [31:0]  wbm_o_adr,
  output      [31:0]  wbm_o_dat,
  input       [31:0]  wbm_i_dat,
  input               wbm_i_ack,
  input               wbm_i_int,

  //This interrupt can be controlled from this module or a submodule
  output  reg         o_wbs_int
  //output              o_wbs_int
);

//Local Parameters
localparam      CONTROL_ADDR        = 32'h00000000;
localparam      STATUS_ADDR         = 32'h00000001;
localparam      SOURCE_COUNT_ADDR   = 32'h00000002;
localparam      SINK_COUNT_ADDR     = 32'h00000003;
localparam      WB_BUS_COUNT_ADDR   = 32'h00000004;
localparam      SNK0_CONTROL_ADDR   = 32'h00000005;
localparam      SNK1_CONTROL_ADDR   = 32'h00000006;
localparam      SNK2_CONTROL_ADDR   = 32'h00000007;
localparam      SNK3_CONTROL_ADDR   = 32'h00000008;
localparam      SRC0_CONTROL_ADDR   = 32'h00000009;
localparam      SRC1_CONTROL_ADDR   = 32'h0000000A;
localparam      SRC2_CONTROL_ADDR   = 32'h0000000B;
localparam      SRC3_CONTROL_ADDR   = 32'h0000000C;
localparam      WB_CONTROL_ADDR     = 32'h0000000D;



localparam      CNTL_DMA_ENABLE     = 0;

//Local Registers/Wires
reg   [31:0]          control;
wire                  dma_enable;
reg   [31:0]          snk0_control;
reg   [31:0]          snk1_control;
reg   [31:0]          snk2_control;
reg   [31:0]          snk3_control;

wire  [31:0]          snk0_status;
wire  [31:0]          snk1_status;
wire  [31:0]          snk2_status;
wire  [31:0]          snk3_status;

reg   [31:0]          src0_control;
reg   [31:0]          src1_control;
reg   [31:0]          src2_control;
reg   [31:0]          src3_control;

wire  [31:0]          src0_status;
wire  [31:0]          src1_status;
wire  [31:0]          src2_status;
wire  [31:0]          src3_status;

reg   [31:0]          wb_control;
wire  [31:0]          wb_status;



//Submodules
dma_controller #(
  .WISHBONE_BUS_COUNT(WISHBONE_BUS_COUNT )
) dmacntrl(

  .clk                (clk                ),
  .rst                (rst                ),
  .enable             (dma_enable         ),

  .snk0_control       (snk0_control       ),
  .snk1_control       (snk1_control       ),
  .snk2_control       (snk2_control       ),
  .snk3_control       (snk3_control       ),

  .src0_control       (src0_control       ),
  .src1_control       (src1_control       ),
  .src2_control       (src2_control       ),
  .src3_control       (src3_control       ),

  .wb_control         (wb_control         ),


  .i_src0_address     (i_src0_address     ),
  .i_src0_start       (i_src0_start       ),
  .o_src0_finished    (o_src0_finished    ),
  .o_src0_busy        (o_src0_busy        ),

  .o_src0_if_strobe   (o_src0_if_strobe   ),
  .i_src0_if_data     (i_src0_if_data     ),
  .i_src0_if_ready    (i_src0_if_ready    ),
  .o_src0_if_activate (o_src0_if_activate ),
  .i_src0_if_size     (i_src0_if_size     ),
  .i_src0_if_starved  (i_src0_if_starved  ),


  .i_src1_address     (i_src1_address     ),
  .i_src1_start       (i_src1_start       ),
  .o_src1_finished    (o_src1_finished    ),
  .o_src1_busy        (o_src1_busy        ),

  .o_src1_if_strobe   (o_src1_if_strobe   ),
  .i_src1_if_data     (i_src1_if_data     ),
  .i_src1_if_ready    (i_src1_if_ready    ),
  .o_src1_if_activate (o_src1_if_activate ),
  .i_src1_if_size     (i_src1_if_size     ),
  .i_src1_if_starved  (i_src1_if_starved  ),


  .i_src2_address     (i_src2_address     ),
  .i_src2_start       (i_src2_start       ),
  .o_src2_finished    (o_src2_finished    ),
  .o_src2_busy        (o_src2_busy        ),

  .o_src2_if_strobe   (o_src2_if_strobe   ),
  .i_src2_if_data     (i_src2_if_data     ),
  .i_src2_if_ready    (i_src2_if_ready    ),
  .o_src2_if_activate (o_src2_if_activate ),
  .i_src2_if_size     (i_src2_if_size     ),
  .i_src2_if_starved  (i_src2_if_starved  ),


  .i_src3_address     (i_src3_address     ),
  .i_src3_start       (i_src3_start       ),
  .o_src3_finished    (o_src3_finished    ),
  .o_src3_busy        (o_src3_busy        ),

  .o_src3_if_strobe   (o_src3_if_strobe   ),
  .i_src3_if_data     (i_src3_if_data     ),
  .i_src3_if_ready    (i_src3_if_ready    ),
  .o_src3_if_activate (o_src3_if_activate ),
  .i_src3_if_size     (i_src3_if_size     ),
  .i_src3_if_starved  (i_src3_if_starved  ),


  .o_snk0_address     (o_snk0_address     ),
  .o_snk0_valid       (o_snk0_valid       ),

  .o_snk0_strobe      (o_snk0_strobe      ),
  .i_snk0_ready       (i_snk0_ready       ),
  .o_snk0_activate    (o_snk0_activate    ),
  .i_snk0_size        (i_snk0_size        ),
  .o_snk0_data        (o_snk0_data        ),


  .o_snk1_address     (o_snk1_address     ),
  .o_snk1_valid       (o_snk1_valid       ),

  .o_snk1_strobe      (o_snk1_strobe      ),
  .i_snk1_ready       (i_snk1_ready       ),
  .o_snk1_activate    (o_snk1_activate    ),
  .i_snk1_size        (i_snk1_size        ),
  .o_snk1_data        (o_snk1_data        ),


  .o_snk2_address     (o_snk2_address     ),
  .o_snk2_valid       (o_snk2_valid       ),

  .o_snk2_strobe      (o_snk2_strobe      ),
  .i_snk2_ready       (i_snk2_ready       ),
  .o_snk2_activate    (o_snk2_activate    ),
  .i_snk2_size        (i_snk2_size        ),
  .o_snk2_data        (o_snk2_data        ),


  .o_snk3_address     (o_snk3_address     ),
  .o_snk3_valid       (o_snk3_valid       ),

  .o_snk3_strobe      (o_snk3_strobe      ),
  .i_snk3_ready       (i_snk3_ready       ),
  .o_snk3_activate    (o_snk3_activate    ),
  .i_snk3_size        (i_snk3_size        ),
  .o_snk3_data        (o_snk3_data        ),

  .wbm_o_we           (wbm_o_we           ),
  .wbm_o_stb          (wbm_o_stb          ),
  .wbm_o_cyc          (wbm_o_cyc          ),
  .wbm_o_sel          (wbm_o_sel          ),
  .wbm_o_adr          (wbm_o_adr          ),
  .wbm_o_dat          (wbm_o_dat          ),
  .wbm_i_dat          (wbm_i_dat          ),
  .wbm_i_ack          (wbm_i_ack          ),
  .wbm_i_int          (wbm_i_int          ),

  .interrupt          (interrupt          )
);

//Asynchronous Logic
assign  dma_enable    = control[0];
//Synchronous Logic

always @ (posedge clk) begin
  if (rst) begin
    o_wbs_dat                     <= 32'h0;
    o_wbs_ack                     <= 0;
    o_wbs_int                     <= 0;

    control                       <= 0;
    control[CNTL_DMA_ENABLE]      <= START_ENABLED;

    snk0_control                  <= 0;
    snk1_control                  <= 0;
    snk2_control                  <= 0;
    snk3_control                  <= 0;

    src0_control                  <= 0;
    src1_control                  <= 0;
    src2_control                  <= 0;
    src3_control                  <= 0;

    wb_control                    <= 0;

  end

  else begin
    //when the master acks our ack, then put our ack down
    if (o_wbs_ack && ~i_wbs_stb)begin
      o_wbs_ack <= 0;
    end

    if (i_wbs_stb && i_wbs_cyc) begin
      //master is requesting somethign
      if (!o_wbs_ack) begin
        if (i_wbs_we) begin
          //write request
          case (i_wbs_adr)
            CONTROL_ADDR: begin
              control   <=  i_wbs_dat;
            end
            SNK0_CONTROL_ADDR: begin
              snk0_control   <=  i_wbs_dat;
            end
            SNK1_CONTROL_ADDR: begin
              snk1_control   <=  i_wbs_dat;
            end
            SNK2_CONTROL_ADDR: begin
              snk2_control   <=  i_wbs_dat;
            end
            SNK3_CONTROL_ADDR: begin
              snk3_control   <=  i_wbs_dat;
            end
            SRC0_CONTROL_ADDR: begin
              src0_control   <=  i_wbs_dat;
            end
            SRC1_CONTROL_ADDR: begin
              src1_control   <=  i_wbs_dat;
            end
            SRC2_CONTROL_ADDR: begin
              src2_control   <=  i_wbs_dat;
            end
            SRC3_CONTROL_ADDR: begin
              src3_control   <=  i_wbs_dat;
            end
            WB_CONTROL_ADDR: begin
              wb_control     <=  i_wbs_dat;
            end
            default: begin
            end
          endcase
        end
        else begin
          //read request
          case (i_wbs_adr)
            CONTROL_ADDR: begin
              o_wbs_dat <= control;
            end
            STATUS_ADDR: begin
              o_wbs_dat <= 32'h00000000;
            end
            SOURCE_COUNT_ADDR: begin
              o_wbs_dat <= SOURCE_COUNT;
            end
            SOURCE_COUNT_ADDR: begin
              o_wbs_dat <= SOURCE_COUNT;
            end
            SOURCE_COUNT_ADDR: begin
              o_wbs_dat <= SOURCE_COUNT;
            end
             SNK0_CONTROL_ADDR: begin
              o_wbs_dat <= snk0_status;
            end
             SNK1_CONTROL_ADDR: begin
              o_wbs_dat <= snk1_status;
            end
             SNK2_CONTROL_ADDR: begin
              o_wbs_dat <= snk2_status;
            end
             SNK0_CONTROL_ADDR: begin
              o_wbs_dat <= snk3_status;
            end
             SRC0_CONTROL_ADDR: begin
              o_wbs_dat <= src0_status;
            end
             SRC1_CONTROL_ADDR: begin
              o_wbs_dat <= src1_status;
            end
             SRC2_CONTROL_ADDR: begin
              o_wbs_dat <= src2_status;
            end
             SRC3_CONTROL_ADDR: begin
              o_wbs_dat <= src3_status;
            end
             WB_CONTROL_ADDR: begin
              o_wbs_dat <= wb_status;
            end
            default: begin
            end
          endcase
        end
      o_wbs_ack <= 1;
    end
    end
  end
end

endmodule
