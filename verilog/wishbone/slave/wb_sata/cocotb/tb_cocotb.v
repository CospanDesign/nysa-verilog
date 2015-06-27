`timescale 1ns/1ps

`include "wb_sata_defines.v"

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

input             u2h_write_enable,
output            u2h_write_finished,
input   [23:0]    u2h_write_count,
output            u2h_read_error,

input             h2u_read_enable,
output  [23:0]    h2u_read_total_count,
output            h2u_read_error,
output            h2u_read_busy,


input             hold,
output            hd_ready

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


reg               r_hold;
reg               r_u2h_write_enable;
reg   [23:0]      r_u2h_write_count;
reg               r_h2u_read_enable;

wire              hd_read_from_host;
wire  [31:0]      hd_data_from_host;
wire              hd_write_to_host;
wire  [31:0]      hd_data_to_host;

//There is a bug in COCOTB when stiumlating a signal, sometimes it can be corrupted if not registered
always @ (*) r_rst           = rst;
always @ (*) r_in_ready      = in_ready;
always @ (*) r_in_command    = in_command;
always @ (*) r_in_address    = in_address;
always @ (*) r_in_data       = in_data;
always @ (*) r_in_data_count = in_data_count;
always @ (*) r_out_ready     = out_ready;
always @ (*) r_ih_reset      = ih_reset;

always @ (*) r_hold               = hold;

always @ (*) r_u2h_write_enable   = u2h_write_enable;
always @ (*) r_u2h_write_count    = u2h_write_count;
always @ (*) r_h2u_read_enable    = h2u_read_enable;


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

reg               execute_command;
reg               command_finished;
reg               request_more_data;
reg               request_more_data_ack;
reg     [27:0]    data_write_count;
reg     [27:0]    data_read_count;

wire              write_enable    [3:0];
wire    [63:0]    write_addr      [3:0];
wire              write_addr_inc  [3:0];
wire              write_addr_dec  [3:0];
wire              write_finished  [3:0];
wire    [23:0]    write_data_count[3:0];
wire              write_flush     [3:0];

wire    [1:0]     write_ready     [3:0];
wire    [1:0]     write_activate  [3:0];
wire    [23:0]    write_size      [3:0];
wire              write_strobe    [3:0];
wire    [31:0]    write_data      [3:0];


wire              read_enable     [3:0];
wire    [63:0]    read_addr       [3:0];
wire              read_addr_inc   [3:0];
wire              read_addr_dec   [3:0];
wire              read_busy       [3:0];
wire              read_error      [3:0];
wire    [23:0]    read_data_count [3:0];
wire              read_flush      [3:0];

wire              read_ready      [3:0];
wire              read_activate   [3:0];
wire    [23:0]    read_size       [3:0];
wire    [31:0]    read_data       [3:0];
wire              read_strobe     [3:0];

//SATA Signals
wire              sata_clk;
wire              tx_comm_wake;
wire              tx_comm_reset;
wire              tx_elec_idle;
wire    [31:0]    tx_dout;
wire              tx_is_k;

wire              comm_init_detect;
wire              comm_wake_detect;
wire              rx_byte_is_aligned;
wire              rx_elec_idle;
wire    [31:0]    rx_din;
wire    [3:0]     rx_is_k;

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
wb_sata s1 (

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
  .o_wbs_int            (w_wbs1_int           ),

  .sata_75mhz_clk       (sata_clk             ),
  .i_platform_ready     (1'b1                 ),
  .i_phy_error          (1'b0                 ),

  .o_tx_comm_wake       (tx_comm_wake         ),
  .o_tx_comm_reset      (tx_comm_reset        ),
  .i_tx_oob_complete    (1'b1                 ),
  .o_tx_elec_idle       (tx_elec_idle         ),
  .o_tx_dout            (tx_dout              ),
  .o_tx_is_k            (tx_is_k              ),

  .i_comm_init_detect   (comm_init_detect     ),
  .i_comm_wake_detect   (comm_wake_detect     ),
  .i_rx_byte_is_aligned (rx_byte_is_aligned   ),
  .i_rx_elec_idle       (rx_elec_idle         ),
  .i_rx_din             (rx_din               ),
  .i_rx_is_k            (rx_is_k              )

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

//hd data reader core
hd_data_reader user_2_hd_reader(
  .clk                   (sata_clk             ),
  .rst                   (r_rst || !hd_ready   ),
  .error                 (u2h_read_error       ),
  .enable                (r_u2h_write_enable   ),

  .hd_read_from_host     (hd_read_from_host    ),
  .hd_data_from_host     (hd_data_from_host    )
);

//hd data writer core
hd_data_writer hd_2_user_generator(
  .clk                   (sata_clk             ),
  .rst                   (r_rst || !hd_ready   ),
  .enable                (r_h2u_read_enable    ),
  .data                  (hd_data_to_host      ),
  .strobe                (hd_write_to_host     )
);



faux_sata_hd  fshd   (
  .rst                   (r_rst                ),
  .clk                   (sata_clk             ),
  .tx_set_elec_idle      (rx_elec_idle         ),
  .tx_dout               (rx_din               ),
  .tx_is_k               (rx_is_k              ),

  .rx_din                (tx_dout              ),
  .rx_is_k               ({3'b000, tx_is_k}    ),
  .rx_is_elec_idle       (tx_elec_idle         ),
  .rx_byte_is_aligned    (rx_byte_is_aligned   ),

  .comm_reset_detect     (tx_comm_reset        ),
  .comm_wake_detect      (tx_comm_wake         ),

  .tx_comm_reset         (comm_init_detect     ),
  .tx_comm_wake          (comm_wake_detect     ),

  .hd_ready              (hd_ready             ),

  .dbg_data_scrambler_en (1'b1                  ),

  .dbg_hold              (r_hold               ),

  .dbg_ll_write_start    (1'b0                 ),
  .dbg_ll_write_data     (32'h0                ),
  .dbg_ll_write_size     (0                    ),
  .dbg_ll_write_hold     (1'b0                 ),
  .dbg_ll_write_abort    (1'b0                 ),

  .dbg_ll_read_ready     (1'b0                 ),
  .dbg_t_en              (1'b0                 ),

  .dbg_send_reg_stb      (1'b0                 ),
  .dbg_send_dma_act_stb  (1'b0                 ),
  .dbg_send_data_stb     (1'b0                 ),
  .dbg_send_pio_stb      (1'b0                 ),
  .dbg_send_dev_bits_stb (1'b0                 ),

  .dbg_pio_transfer_count(16'h0000             ),
  .dbg_pio_direction     (1'b0                 ),
  .dbg_pio_e_status      (8'h00                ),

  .dbg_d2h_interrupt     (1'b0                 ),
  .dbg_d2h_notification  (1'b0                 ),
  .dbg_d2h_status        (8'b0                 ),
  .dbg_d2h_error         (8'b0                 ),
  .dbg_d2h_port_mult     (4'b0000              ),
  .dbg_d2h_device        (8'h00                ),
  .dbg_d2h_lba           (48'h000000000000     ),
  .dbg_d2h_sector_count  (16'h0000             ),

  .dbg_cl_if_data        (32'b0                ),
  .dbg_cl_if_ready       (1'b0                 ),
  .dbg_cl_if_size        (24'h0                ),

  .dbg_cl_of_ready       (2'b0                 ),
  .dbg_cl_of_size        (24'h0                ),

  .hd_read_from_host     (hd_read_from_host    ),
  .hd_data_from_host     (hd_data_from_host    ),


  .hd_write_to_host      (hd_write_to_host     ),
  .hd_data_to_host       (hd_data_to_host      )


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
