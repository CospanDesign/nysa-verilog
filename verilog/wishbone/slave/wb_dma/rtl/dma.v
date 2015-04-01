
`include "dma_defines.v"

module dma #(
  parameter WISHBONE_BUS_COUNT  = 1,
  parameter ROM_SIZE            = 6
) (

  input               clk,
  input               rst,
  input               enable,

  input       [31:0]  src0_control,
  input       [31:0]  src1_control,
  input       [31:0]  src2_control,
  input       [31:0]  src3_control,

  output      [31:0]  src0_status,
  output      [31:0]  src1_status,
  output      [31:0]  src2_status,
  output      [31:0]  src3_status,


  input       [31:0]  snk0_control,
  input       [31:0]  snk1_control,
  input       [31:0]  snk2_control,
  input       [31:0]  snk3_control,

  output      [31:0]  snk0_status,
  output      [31:0]  snk1_status,
  output      [31:0]  snk2_status,
  output      [31:0]  snk3_status,




  //Source 0
  input       [31:0]  i_src0_address,
  input               i_src0_start,
  output              o_src0_finished,
  output              o_src0_busy,

  output              o_src0_strobe,
  output      [31:0]  i_src0_data,
  input               i_src0_ready,
  output              o_src0_activate,
  input       [23:0]  i_src0_size,
  input               i_src0_starved,

  //Source 1
  input       [31:0]  i_src1_address,
  input               i_src1_start,
  output              o_src1_finished,
  output              o_src1_busy,

  output              o_src1_strobe,
  output      [31:0]  i_src1_data,
  input               i_src1_ready,
  output              o_src1_activate,
  input       [23:0]  i_src1_size,
  input               i_src1_starved,

  //Source 2
  input       [31:0]  i_src2_address,
  input               i_src2_start,
  output              o_src2_finished,
  output              o_src2_busy,

  output              o_src2_strobe,
  output      [31:0]  i_src2_data,
  input               i_src2_ready,
  output              o_src2_activate,
  input       [23:0]  i_src2_size,
  input               i_src2_starved,

  //Source 3
  input       [31:0]  i_src3_address,
  input               i_src3_start,
  output              o_src3_finished,
  output              o_src3_busy,

  output              o_src3_strobe,
  output      [31:0]  i_src3_data,
  input               i_src3_ready,
  output              o_src3_activate,
  input       [23:0]  i_src3_size,
  input               i_src3_starved,

  //Sink 0
  output              o_snk0_address,
  output              o_snk0_valid,

  output              o_snk0_strobe,
  input       [1:0]   i_snk0_ready,
  output      [1:0]   o_snk0_activate,
  input       [23:0]  i_snk0_size,
  output      [31:0]  o_snk0_data,

  //Sink 1
  output              o_snk1_address,
  output              o_snk1_valid,

  output              o_snk1_strobe,
  input       [1:0]   i_snk1_ready,
  output      [1:0]   o_snk1_activate,
  input       [23:0]  i_snk1_size,
  output      [31:0]  o_snk1_data,

  //Sink 2
  output              o_snk2_address,
  output              o_snk2_valid,

  output              o_snk2_strobe,
  input       [1:0]   i_snk2_ready,
  output      [1:0]   o_snk2_activate,
  input       [23:0]  i_snk2_size,
  output      [31:0]  o_snk2_data,

  //Sink 3
  output              o_snk3_address,
  output              o_snk3_valid,

  output              o_snk3_strobe,
  input       [1:0]   i_snk3_ready,
  output      [1:0]   o_snk3_activate,
  input       [23:0]  i_snk3_size,
  output      [31:0]  o_snk3_data,

  input       [63:0]  cmd_src_address0,
  input       [63:0]  cmd_dest_address0,
  input       [31:0]  cmd_count0,
  input       [15:0]  cmd_flags0,
  input       [15:0]  cmd_cross_src_port0,
  input       [15:0]  cmd_cross_dest_port0,
  input       [2:0]   cmd_next0,

  input       [63:0]  cmd_src_address1,
  input       [63:0]  cmd_dest_address1,
  input       [31:0]  cmd_count1,
  input       [15:0]  cmd_flags1,
  input       [15:0]  cmd_cross_src_port1,
  input       [15:0]  cmd_cross_dest_port1,
  input       [2:0]   cmd_next1,

  input       [63:0]  cmd_src_address2,
  input       [63:0]  cmd_dest_address2,
  input       [31:0]  cmd_count2,
  input       [15:0]  cmd_flags2,
  input       [15:0]  cmd_cross_src_port2,
  input       [15:0]  cmd_cross_dest_port2,
  input       [2:0]   cmd_next2,

  input       [63:0]  cmd_src_address3,
  input       [63:0]  cmd_dest_address3,
  input       [31:0]  cmd_count3,
  input       [15:0]  cmd_flags3,
  input       [15:0]  cmd_cross_src_port3,
  input       [15:0]  cmd_cross_dest_port3,
  input       [2:0]   cmd_next3,

  input       [63:0]  cmd_src_address4,
  input       [63:0]  cmd_dest_address4,
  input       [31:0]  cmd_count4,
  input       [15:0]  cmd_flags4,
  input       [15:0]  cmd_cross_src_port4,
  input       [15:0]  cmd_cross_dest_port4,
  input       [2:0]   cmd_next4,

  input       [63:0]  cmd_src_address5,
  input       [63:0]  cmd_dest_address5,
  input       [31:0]  cmd_count5,
  input       [15:0]  cmd_flags5,
  input       [15:0]  cmd_cross_src_port5,
  input       [15:0]  cmd_cross_dest_port5,
  input       [2:0]   cmd_next5,

  input       [63:0]  cmd_src_address6,
  input       [63:0]  cmd_dest_address6,
  input       [31:0]  cmd_count6,
  input       [15:0]  cmd_flags6,
  input       [15:0]  cmd_cross_src_port6,
  input       [15:0]  cmd_cross_dest_port6,
  input       [2:0]   cmd_next6,

  input       [63:0]  cmd_src_address7,
  input       [63:0]  cmd_dest_address7,
  input       [31:0]  cmd_count7,
  input       [15:0]  cmd_flags7,
  input       [15:0]  cmd_cross_src_port7,
  input       [15:0]  cmd_cross_dest_port7,
  input       [2:0]   cmd_next7,

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
localparam          IDLE                  = 4'h0;
localparam          SETUP                 = 4'h1;
localparam          ACTIVE                = 4'h2;
localparam          FLUSH                 = 4'h3;
localparam          FINISHED              = 4'h4;

//Registers/Wires
wire        [31:0]  src_control         [3:0];
wire        [31:0]  src_status          [3:0];

reg                 inst_ready          [`INST_COUNT - 1:0];
reg                 inst_busy           [`INST_COUNT - 1:0];
reg                 inst_finished       [`INST_COUNT - 1:0];
reg                 inst_idle           [`INST_COUNT - 1:0];

wire        [31:0]  snk_control         [3:0];
wire        [31:0]  snk_status          [3:0];

reg         [3:0]   state               [3:0];

wire        [31:0]  src_address         [3:0];
reg         [23:0]  src_count           [3:0];
wire                src_start           [3:0];
reg                 src_dma_finished    [3:0];
wire                src_busy            [3:0];

reg                 src_strobe          [3:0];
wire        [31:0]  src_data            [3:0];
wire                src_ready           [3:0];
reg                 src_activate        [3:0];
wire        [23:0]  src_size            [3:0];
wire                src_starved         [3:0];

//Sink Control Values
reg         [31:0]  snk_address         [3:0];
reg                 snk_valid           [3:0];

//Sink FIFO Command
reg                 snk_strobe          [3:0];
wire        [1:0]   snk_ready           [3:0];
reg         [1:0]   snk_activate        [3:0];
wire        [23:0]  snk_size            [3:0];
reg         [31:0]  snk_data            [3:0];
reg         [23:0]  snk_count           [3:0];

//Channel Specific Controls
wire                dma_enable          [3:0];
wire                src_dma_busy        [3:0];
wire        [3:0]   src_snk_addr        [3:0];
wire                snk_dma_busy        [3:0];


//Transfer Command ROM
wire        [63:0]  cmd_src_address     [7:0];
wire        [63:0]  cmd_dest_address    [7:0];
wire        [31:0]  cmd_count           [7:0];
wire        [15:0]  cmd_flags           [7:0];
wire        [1:0]   cmd_cross_src_port  [7:0];
wire        [1:0]   cmd_cross_dest_port [7:0];
wire        [2:0]   cmd_next            [7:0];

//Instruction Pointer into the ROM
reg         [2:0]   ip [3:0];

//Dynamic Command Values
reg         [63:0]  curr_src_address    [3:0];
reg         [63:0]  curr_dest_address   [3:0];
reg         [31:0]  curr_count          [3:0];
reg         [31:0]  channel_count       [3:0];
reg         [1:0]   snka                [3:0];
reg                 snk_in_use          [1:0];
wire        [1:0]   channel_sink        [3:0];

reg         [31:0]  data_out;
reg         [ROM_SIZE - 1:0]   addr_out;

//Submodules
//Asynchronous Logic

//Matrixize the inputs and outptus
assign src_control[0]                      = i_src0_control;
assign src_control[1]                      = i_src1_control;
assign src_control[2]                      = i_src2_control;
assign src_control[3]                      = i_src3_control;

assign o_src0_status                       = src_status[0];
assign o_src1_status                       = src_status[1];
assign o_src2_status                       = src_status[2];
assign o_src3_status                       = src_status[3];

assign snk_control[0]                      = i_snk0_control;
assign snk_control[1]                      = i_snk1_control;
assign snk_control[2]                      = i_snk2_control;
assign snk_control[3]                      = i_snk3_control;

assign o_snk0_status                       = snk_status[0];
assign o_snk1_status                       = snk_status[1];
assign o_snk2_status                       = snk_status[2];
assign o_snk3_status                       = snk_status[3];

assign o_src0_finished                     = src_dma_finished[0];
assign o_src1_finished                     = src_dma_finished[1];
assign o_src2_finished                     = src_dma_finished[2];
assign o_src3_finished                     = src_dma_finished[3];

assign o_src0_busy                         = src_busy[0];
assign o_src1_busy                         = src_busy[1];
assign o_src2_busy                         = src_busy[2];
assign o_src3_busy                         = src_busy[3];

assign o_src0_strobe                       = src_strobe[0];
assign o_src1_strobe                       = src_strobe[1];
assign o_src2_strobe                       = src_strobe[2];
assign o_src3_strobe                       = src_strobe[3];

assign src_data[0]                         = i_src0_data;
assign src_data[1]                         = i_src1_data;
assign src_data[2]                         = i_src2_data;
assign src_data[3]                         = i_src3_data;

assign src_ready[0]                        = i_src0_ready;
assign src_ready[1]                        = i_src1_ready;
assign src_ready[2]                        = i_src2_ready;
assign src_ready[3]                        = i_src3_ready;

assign o_src0_activate                     = src_activate[0];
assign o_src1_activate                     = src_activate[1];
assign o_src2_activate                     = src_activate[2];
assign o_src3_activate                     = src_activate[3];

assign src_size[0]                         =  i_src0_size;
assign src_size[1]                         =  i_src1_size;
assign src_size[2]                         =  i_src2_size;
assign src_size[3]                         =  i_src3_size;

assign src_starved[0]                      = i_src0_starved  ;
assign src_starved[1]                      = i_src1_starved  ;
assign src_starved[2]                      = i_src2_starved  ;
assign src_starved[3]                      = i_src3_starved  ;

assign o_snk0_valid                        = snk_valid[0];
assign o_snk1_valid                        = snk_valid[1];
assign o_snk2_valid                        = snk_valid[2];
assign o_snk3_valid                        = snk_valid[3];

assign o_snk0_strobe                       = snk_strobe[0];
assign o_snk1_strobe                       = snk_strobe[1];
assign o_snk2_strobe                       = snk_strobe[2];
assign o_snk3_strobe                       = snk_strobe[3];

assign snk_ready[0]                        = i_snk0_ready;
assign snk_ready[1]                        = i_snk1_ready;
assign snk_ready[2]                        = i_snk2_ready;
assign snk_ready[3]                        = i_snk3_ready;

assign o_snk0_activate                     = snk_activate[0];
assign o_snk1_activate                     = snk_activate[1];
assign o_snk2_activate                     = snk_activate[2];
assign o_snk3_activate                     = snk_activate[3];

assign snk_size[0]                         = i_snk0_size;
assign snk_size[1]                         = i_snk1_size;
assign snk_size[2]                         = i_snk2_size;
assign snk_size[3]                         = i_snk3_size;

assign o_snk0_data                         = snk_data[0];
assign o_snk1_data                         = snk_data[1];
assign o_snk2_data                         = snk_data[2];
assign o_snk3_data                         = snk_data[3];

assign dma_enable[0]                       = src0_control[`CTRL_DMA_ENABLE];
assign dma_enable[1]                       = src1_control[`CTRL_DMA_ENABLE];
assign dma_enable[2]                       = src2_control[`CTRL_DMA_ENABLE];
assign dma_enable[3]                       = src3_control[`CTRL_DMA_ENABLE];

//Status Output
assign src0_status[`STS_BUSY]              = src_dma_busy[0];
assign src1_status[`STS_BUSY]              = src_dma_busy[1];
assign src2_status[`STS_BUSY]              = src_dma_busy[2];
assign src3_status[`STS_BUSY]              = src_dma_busy[3];

assign src0_status[`STS_FIN]               = src_dma_finished[0];
assign src1_status[`STS_FIN]               = src_dma_finished[1];
assign src2_status[`STS_FIN]               = src_dma_finished[2];
assign src3_status[`STS_FIN]               = src_dma_finished[3];

assign src0_status[`STS_ERR_CONFLICT_SINK] = src_err_conflict_sink[0];
assign src1_status[`STS_ERR_CONFLICT_SINK] = src_err_conflict_sink[1];
assign src2_status[`STS_ERR_CONFLICT_SINK] = src_err_conflict_sink[2];
assign src3_status[`STS_ERR_CONFLICT_SINK] = src_err_conflict_sink[3];

assign src0_status[`CTRL_DMA_ENABLE]       = dma_enable[0];
assign src1_status[`CTRL_DMA_ENABLE]       = dma_enable[1];
assign src2_status[`CTRL_DMA_ENABLE]       = dma_enable[2];
assign src3_status[`CTRL_DMA_ENABLE]       = dma_enable[3];




//Put all the commands into the program memory block
assign cmd_src_address[0]     = cmd_src_address0;
assign cmd_dest_address[0]    = cmd_dest_address0;
assign cmd_count[0]           = cmd_count0;
assign cmd_flags[0]           = cmd_flags0;
assign cmd_cross_src_port[0]  = cmd_cross_src_port0;
assign cmd_cross_dest_port[0] = cmd_cross_dest_port0;
assign cmd_next[0]            = cmd_next0;

assign cmd_src_address[1]     = cmd_src_address1;
assign cmd_dest_address[1]    = cmd_dest_address1;
assign cmd_count[1]           = cmd_count1;
assign cmd_flags[1]           = cmd_flags1;
assign cmd_cross_src_port[1]  = cmd_cross_src_port1;
assign cmd_cross_dest_port[1] = cmd_cross_dest_port1;
assign cmd_next[1]            = cmd_next1;

assign cmd_src_address[2]     = cmd_src_address2;
assign cmd_dest_address[2]    = cmd_dest_address2;
assign cmd_count[2]           = cmd_count2;
assign cmd_flags[2]           = cmd_flags2;
assign cmd_cross_src_port[2]  = cmd_cross_src_port2;
assign cmd_cross_dest_port[2] = cmd_cross_dest_port2;
assign cmd_next[2]            = cmd_next2;

assign cmd_src_address[3]     = cmd_src_address3;
assign cmd_dest_address[3]    = cmd_dest_address3;
assign cmd_count[3]           = cmd_count3;
assign cmd_flags[3]           = cmd_flags3;
assign cmd_cross_src_port[3]  = cmd_cross_src_port3;
assign cmd_cross_dest_port[3] = cmd_cross_dest_port3;
assign cmd_next[3]            = cmd_next3;

assign cmd_src_address[4]     = cmd_src_address4;
assign cmd_dest_address[4]    = cmd_dest_address4;
assign cmd_count[4]           = cmd_count4;
assign cmd_flags[4]           = cmd_flags4;
assign cmd_cross_src_port[4]  = cmd_cross_src_port4;
assign cmd_cross_dest_port[4] = cmd_cross_dest_port4;
assign cmd_next[4]            = cmd_next4;

assign cmd_src_address[5]     = cmd_src_address5;
assign cmd_dest_address[5]    = cmd_dest_address5;
assign cmd_count[5]           = cmd_count5;
assign cmd_flags[5]           = cmd_flags5;
assign cmd_cross_src_port[5]  = cmd_cross_src_port5;
assign cmd_cross_dest_port[5] = cmd_cross_dest_port5;
assign cmd_next[5]            = cmd_next5;

assign cmd_src_address[6]     = cmd_src_address6;
assign cmd_dest_address[6]    = cmd_dest_address6;
assign cmd_count[6]           = cmd_count6;
assign cmd_flags[6]           = cmd_flags6;
assign cmd_cross_src_port[6]  = cmd_cross_src_port6;
assign cmd_cross_dest_port[6] = cmd_cross_dest_port6;
assign cmd_next[6]            = cmd_next6;

assign cmd_src_address[7]     = cmd_src_address7;
assign cmd_dest_address[7]    = cmd_dest_address7;
assign cmd_count[7]           = cmd_count7;
assign cmd_flags[7]           = cmd_flags7;
assign cmd_cross_src_port[7]  = cmd_cross_src_port7;
assign cmd_cross_dest_port[7] = cmd_cross_dest_port7;
assign cmd_next[7]            = cmd_next7;




genvar g;
generate
for (g = 0; g < `SOURCE_COUNT; g = g + 1) begin
  assign src_busy[g]            = (state[g] != IDLE);
end
endgenerate


//Synchronous Logic
integer i;

//Source Controllers
always @ (posedge clk) begin
  if (rst) begin
    for (i = 0; i < `INST_COUNT; i = i + 1) begin
      inst_ready[i]           <=  0;
      inst_busy[i]            <=  0;
      inst_idle[i]            <=  0;
      inst_finished[i]        <=  0;
    end
    for (i = 0; i < `SOURCE_COUNT; i = i + 1) begin
      src_dma_finished[i]     <=  0;
      state[i]                <=  IDLE;
      src_count[i]            <=  0;
      src_strobe[i]           <=  0;
      src_activate[i]         <=  0;
      ip[i]                   <=  0;
      snka[i]                 <=  0;

    end
    for (i = 0; i < `SINK_COUNT; i = i + 1) begin
      snk_address[i]          <=  0;
      snk_count[i]            <=  0;
      snk_valid[i]            <=  0;
      snk_activate[i]         <=  0;
      snk_in_use[i]           <=  0;
    end
  end
  else begin
    for (i = 0; i < `SOURCE_COUNT; i = i + 1) begin

      src_strobe[i]       <=  0;
      snk_strobe[i]       <=  0;
      snk_in_use[snka[i]] <=  dma_enable[i];

      case (state[i])
        IDLE: begin
          if (dma_enable[i]) begin
            state[i]                    <= SETUP;
            ip[i]                       <= src_control[i][`CTRL_IP_ADDR_TOP:`CTRL_IP_ADDR_BOT];
            snka[i]                     <= src_control[i][`CTRL_SINK_ADDR_TOP:`CTRL_SINK_ADDR_BOT];
          end
          //Flush Anything within the sink FIFO
          if (!snk_in_use[i]) begin
            if (snk_activate[i] && (snk_count[i] < snk_size[i])) begin
              snk_strobe[i]             <=  1;
              snk_data[i]               <=  0;
              snk_count[i]              <=  snk_count[i] + 1;
            end
            else begin
              snk_activate[i]           <=  0;
            end
          end
        end
        SETUP: begin
          //The command from the memory should be set from the 'instruction pointer' now we can make a decision
          curr_src_address[i]           <=  cmd_src_address[ip[i]];   //  Mutable, Copy to channel specific value
          curr_dest_address[i]          <=  cmd_dest_address[ip[i]];  //  Mutable, Copy to channel specific value
          curr_count[i]                 <=  cmd_count[ip[i]];         //  Mutable, Copy to channel specific value
          channel_count[i]              <=  0;
          state[i]                      <=  ACTIVE;
        end

        INGRESS_WAIT: begin
        end

        ACTIVE: begin
          if (dma_enable[i]) begin
            //Activate the source FIFO
            if (!src_activate[i] && src_ready[i]) begin
              src_count[i]              <=  0;
              src_activate[i]           <=  1;
            end
            //Activate the sink FIFO
            if ((snk_activate[snka[i]] == 0) && (snk_ready[snka[i]] > 0)) begin
              snk_count[snka[i]]              <=  0;
              if (snk_ready[snka[i]][0]) begin
                snk_activate[snka[i]][0]      <=  1;
              end
              else begin
                snk_activate[snka[i]][1]      <=  1;
              end
            end

            //Both the Source and Sink FIFOs are ready
            if ((src_activate[i] && snk_activate[snka[i]]) && (snk_count[snka[i]] > 0) && (src_count[i]))begin
              snk_data[snka[i]]               <=  src_data[i];
              snk_strobe[snka[i]]             <=  1;
              src_strobe[i]                   <=  1;
              snk_count[snka[i]]              <=  snk_count[snka[i]] + 1;
              src_count[i]                    <=  src_count[i] + 1;
            end
            else begin
              if (src_activate[i] && (src_count[i] >= src_size[i])) begin
                src_activate[i]               <=  0;
              end
              if (snk_activate[snka[i]] && (snk_count[snka[i]] >= snk_size[snka[i]])) begin
                snk_activate[snka[i]]         <=  0;
              end
            end
          end
          else begin
            state[i]                          <=  FLUSH;
          end
        end
        FLUSH: begin
          if (src_activate[i] && (src_count[i] < src_size[i]))begin
            src_strobe[i]                     <=  1;
            src_count[i]                      <=  src_count[i] + 1;
          end
          else begin
          end
          if (snk_activate[snka[i]] && (snk_count[snka[i]] < snk_size[snka[i]])) begin
            snk_strobe[snka[i]]               <=  1;
            snk_data[snka[i]]                 <=  0;
            snk_count[snka[i]]                <=  snk_count[snka[i]] + 1;
          end
          else begin
            snk_activate[snka[i]]             <=  0;
          end
        end
        FINISHED: begin
          //This is a type of finish that we need to wait for the user to de-assert enable
          if (!dma_enable[i]) begin
            state[i]                          <=  IDLE;
          end
        end
      endcase
    end
  end
end

endmodule
