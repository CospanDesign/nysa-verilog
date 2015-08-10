`timescale 1ns/1ps

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

input             ih_reset

);


//Parameters
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

//wishbone signals
wire              w_wbm_we;
wire              w_wbm_cyc;
wire              w_wbm_stb;
wire [3:0]        w_wbm_sel;
wire [31:0]       w_wbm_adr;
wire [31:0]       w_wbm_dat_o;
wire [31:0]       w_wbm_dat_i;
wire              w_wbm_ack;
wire              w_wbm_int;

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


//Submodules
wishbone_master wm (
  .clk            (clk            ),
  .rst            (r_rst          ),

  .i_ih_rst       (r_ih_reset     ),
  .i_ready        (r_in_ready     ),
  .i_command      (r_in_command   ),
  .i_address      (r_in_address   ),
  .i_data         (r_in_data      ),
  .i_data_count   (r_in_data_count),
  .i_out_ready    (r_out_ready    ),
  .o_en           (out_en         ),
  .o_status       (out_status     ),
  .o_address      (out_address    ),
  .o_data         (out_data       ),
  .o_data_count   (out_data_count ),
  .o_master_ready (master_ready   ),

  .o_per_we        (w_wbm_we        ),
  .o_per_adr       (w_wbm_adr       ),
  .o_per_dat       (w_wbm_dat_i     ),
  .i_per_dat       (w_wbm_dat_o     ),
  .o_per_stb       (w_wbm_stb       ),
  .o_per_cyc       (w_wbm_cyc       ),
  .o_per_msk       (w_wbm_msk       ),
  .o_per_sel       (w_wbm_sel       ),
  .i_per_ack       (w_wbm_ack       ),
  .i_per_int       (w_wbm_int       )
);

//slave 1
wb_sdio_device s1 (

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

  .i_m_we     (w_wbm_we             ),
  .i_m_cyc    (w_wbm_cyc            ),
  .i_m_stb    (w_wbm_stb            ),
  .o_m_ack    (w_wbm_ack            ),
  .i_m_dat    (w_wbm_dat_i          ),
  .o_m_dat    (w_wbm_dat_o          ),
  .i_m_adr    (w_wbm_adr            ),
  .o_m_int    (w_wbm_int            ),

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


assign  w_wbs0_ack              = 0;
assign  w_wbs0_dat_o            = 0;
assign  start                   = 1;

//Submodules
//Asynchronous Logic
//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
