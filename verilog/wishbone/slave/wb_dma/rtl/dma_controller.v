
`include "dma_defines.v"

module dma_controller #(
  parameter WISHBONE_BUS_COUNT  = 1
) (

  input               clk,
  input               rst,
  input               enable,

  input       [31:0]  snk0_control,
  input       [31:0]  snk1_control,
  input       [31:0]  snk2_control,
  input       [31:0]  snk3_control,

  output      [31:0]  snk0_status,
  output      [31:0]  snk1_status,
  output      [31:0]  snk2_status,
  output      [31:0]  snk3_status,

  input       [31:0]  src0_control,
  input       [31:0]  src1_control,
  input       [31:0]  src2_control,
  input       [31:0]  src3_control,

  output      [31:0]  src0_status,
  output      [31:0]  src1_status,
  output      [31:0]  src2_status,
  output      [31:0]  src3_status,


  input       [31:0]  wb_control,
  output      [31:0]  wb_status,

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
  output      [31:0]  o_snk0_data,

  //Sink 1
  output              o_snk1_address,
  output              o_snk1_valid,

  output              o_snk1_strobe,
  input               i_snk1_ready,
  output              o_snk1_activate,
  input       [23:0]  i_snk1_size,
  output      [31:0]  o_snk1_data,

  //Sink 2
  output              o_snk2_address,
  output              o_snk2_valid,

  output              o_snk2_strobe,
  input               i_snk2_ready,
  output              o_snk2_activate,
  input       [23:0]  i_snk2_size,
  output      [31:0]  o_snk2_data,

  //Sink 3
  output              o_snk3_address,
  output              o_snk3_valid,

  output              o_snk3_strobe,
  input               i_snk3_ready,
  output              o_snk3_activate,
  input       [23:0]  i_snk3_size,
  output      [31:0]  o_snk3_data,




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

  output              interrupt
);

//Local Parameters
localparam          IDLE          = 4'h0;
localparam          ACTIVE        = 4'h1;
localparam          FINISHED      = 4'h2;

//Registers/Wires
wire        [31:0]  src_control     [3:0];
wire        [31:0]  src_status      [3:0];

wire        [31:0]  snk_control     [3:0];
wire        [31:0]  snk_status      [3:0];

reg         [3:0]   snk_state       [3:0];
reg         [3:0]   src_state       [3:0];

wire        [31:0]  src_address     [3:0];
wire                src_start       [3:0];
reg                 src_finished    [3:0];
reg                 src_busy        [3:0];

wire                src_if_strobe   [3:0];
wire        [31:0]  src_if_data     [3:0];
wire        [1:0]   src_if_ready    [3:0];
wire        [1:0]   src_if_activate [3:0];
wire        [23:0]  src_if_size     [3:0];
wire                src_if_starved  [3:0];

reg         [31:0]  snk_address     [3:0];
reg                 snk_valid       [3:0];

wire                snk_strobe      [3:0];
wire                snk_ready       [3:0];
reg                 snk_activate    [3:0];
wire        [23:0]  snk_size        [3:0];
wire        [31:0]  snk_data        [3:0];

wire                src_enable        [3:0];
wire                src_ppfifo_wb_sel [3:0];
wire                src_dma_busy      [3:0];
wire        [3:0]   src_snk_addr      [3:0];

wire                snk_enable        [3:0];
wire                snk_ppfifo_wb_sel [3:0];
wire                snk_dma_busy      [3:0];


//Submodules
//Asynchronous Logic
assign src_control[0]     = i_src0_control;
assign src_control[1]     = i_src1_control;
assign src_control[2]     = i_src2_control;
assign src_control[3]     = i_src3_control;

assign o_src0_status      = src_status[0];
assign o_src1_status      = src_status[1];
assign o_src2_status      = src_status[2];
assign o_src3_status      = src_status[3];

assign snk_control[0]     = i_snk0_control;
assign snk_control[1]     = i_snk1_control;
assign snk_control[2]     = i_snk2_control;
assign snk_control[3]     = i_snk3_control;

assign o_snk0_status      = snk_status[0];
assign o_snk1_status      = snk_status[1];
assign o_snk2_status      = snk_status[2];
assign o_snk3_status      = snk_status[3];

assign src_address[0]     = i_src0_address;
assign src_address[1]     = i_src1_address;
assign src_address[2]     = i_src2_address;
assign src_address[3]     = i_src3_address;

assign src_start[0]       = i_src0_address;
assign src_start[1]       = i_src1_address;
assign src_start[2]       = i_src2_address;
assign src_start[3]       = i_src3_address;

assign o_src0_finished    = src_finished[0];
assign o_src1_finished    = src_finished[1];
assign o_src2_finished    = src_finished[2];
assign o_src3_finished    = src_finished[3];

assign o_src0_busy        = src_busy[0];
assign o_src1_busy        = src_busy[1];
assign o_src2_busy        = src_busy[2];
assign o_src3_busy        = src_busy[3];

assign o_src0_if_strobe   = src_if_strobe[0];
assign o_src1_if_strobe   = src_if_strobe[1];
assign o_src2_if_strobe   = src_if_strobe[2];
assign o_src3_if_strobe   = src_if_strobe[3];

assign src_if_data[0]     = i_src0_if_data;
assign src_if_data[1]     = i_src1_if_data;
assign src_if_data[2]     = i_src2_if_data;
assign src_if_data[3]     = i_src3_if_data;

assign src_if_ready[0]    = i_src0_if_ready;
assign src_if_ready[1]    = i_src1_if_ready;
assign src_if_ready[2]    = i_src2_if_ready;
assign src_if_ready[3]    = i_src3_if_ready;

assign o_src0_if_activate = src_if_activate[0];
assign o_src1_if_activate = src_if_activate[1];
assign o_src2_if_activate = src_if_activate[2];
assign o_src3_if_activate = src_if_activate[3];

assign src_if_size[0]     =  i_src0_if_size;
assign src_if_size[1]     =  i_src1_if_size;
assign src_if_size[2]     =  i_src2_if_size;
assign src_if_size[3]     =  i_src3_if_size;

assign src_if_starved[0]  = i_src0_if_starved  ;
assign src_if_starved[1]  = i_src1_if_starved  ;
assign src_if_starved[2]  = i_src2_if_starved  ;
assign src_if_starved[3]  = i_src3_if_starved  ;

assign o_snk0_address     = snk_address[0];
assign o_snk1_address     = snk_address[1];
assign o_snk2_address     = snk_address[2];
assign o_snk3_address     = snk_address[3];

assign o_snk0_valid       = snk_valid[0];
assign o_snk1_valid       = snk_valid[1];
assign o_snk2_valid       = snk_valid[2];
assign o_snk3_valid       = snk_valid[3];

assign o_snk0_strobe      = snk_strobe[0];
assign o_snk1_strobe      = snk_strobe[1];
assign o_snk2_strobe      = snk_strobe[2];
assign o_snk3_strobe      = snk_strobe[3];

assign snk_ready[0]       = i_snk0_ready;
assign snk_ready[1]       = i_snk1_ready;
assign snk_ready[2]       = i_snk2_ready;
assign snk_ready[3]       = i_snk3_ready;

assign o_snk0_activate    = snk_activate[0];
assign o_snk1_activate    = snk_activate[1];
assign o_snk2_activate    = snk_activate[2];
assign o_snk3_activate    = snk_activate[3];

assign snk_size[0]        = i_snk0_size;
assign snk_size[1]        = i_snk1_size;
assign snk_size[2]        = i_snk2_size;
assign snk_size[3]        = i_snk3_size;

assign o_snk0_data        = snk_data[0];
assign o_snk1_data        = snk_data[1];
assign o_snk2_data        = snk_data[2];
assign o_snk3_data        = snk_data[3];



assign src_enable[0]          = src0_control[`DMA_ENABLE];
assign src_enable[1]          = src1_control[`DMA_ENABLE];
assign src_enable[2]          = src2_control[`DMA_ENABLE];
assign src_enable[3]          = src3_control[`DMA_ENABLE];
                              
assign src_ppfifo_wb_sel[0]   = src0_control[`PPFIFO_WB_SEL];
assign src_ppfifo_wb_sel[1]   = src1_control[`PPFIFO_WB_SEL];
assign src_ppfifo_wb_sel[2]   = src2_control[`PPFIFO_WB_SEL];
assign src_ppfifo_wb_sel[3]   = src3_control[`PPFIFO_WB_SEL];

assign src0_status[`DMA_BUSY] = src_dma_busy[0];
assign src1_status[`DMA_BUSY] = src_dma_busy[1];
assign src2_status[`DMA_BUSY] = src_dma_busy[2];
assign src3_status[`DMA_BUSY] = src_dma_busy[3];

assign src_snk_addr[0]        = src0_control[`SINK_ADDR_TOP:`SINK_ADDR_BOT];
assign src_snk_addr[1]        = src1_control[`SINK_ADDR_TOP:`SINK_ADDR_BOT];
assign src_snk_addr[2]        = src2_control[`SINK_ADDR_TOP:`SINK_ADDR_BOT];
assign src_snk_addr[3]        = src3_control[`SINK_ADDR_TOP:`SINK_ADDR_BOT];




//Synchronous Logic

//Generate All the sinks and sources
genvar i;
generate
for (i = 0; i < 4; i = i + 1) begin: gen_paths

//Sink Controllers
/*
always @ (posedge clk) begin
  if (rst) begin
      snk_address[i]  <=  0;
      snk_valid[i]    <=  0;
      snk_activate[i] <=  0;
      snk_state[i]    <=  IDLE;
  end
  else begin
    case (snk_state[i])
      IDLE: begin
      end
      ACTIVE: begin
      end
      FINISHED: begin
      end
    endcase
  end
end
*/

//Source Controllers
always @ (posedge clk) begin
  if (rst) begin
      src_finished[i] <=  0;
      src_busy[i]     <=  0;
      src_state[i]    <=  IDLE;
  end
  else begin
    case (src_state[i])
      IDLE: begin
      end
      ACTIVE: begin
      end
      FINISHED: begin
      end
    endcase

  end
end


end //End For Loop
endgenerate

endmodule
