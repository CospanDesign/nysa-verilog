`timescale 1ns/1ps


module tb_cocotb (

//Virtual Host Interface Signals
input             cocotb_clk,
input             in_clk,
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

input             request_read_wait,
input             request_interrupt
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
reg               clk;
reg               r_request_read_wait;
reg               r_request_interrupt;

//There is a bug in COCOTB when stiumlating a signal, sometimes it can be corrupted if not registered
always @ (*) r_rst           = rst;
always @ (*) r_in_ready      = in_ready;
always @ (*) r_in_command    = in_command;
always @ (*) r_in_address    = in_address;
always @ (*) r_in_data       = in_data;
always @ (*) r_in_data_count = in_data_count;
always @ (*) r_out_ready     = out_ready;
always @ (*) r_ih_reset      = ih_reset;
always @ (*) clk             = in_clk;
always @ (*) r_request_read_wait    =   request_read_wait;
always @ (*) r_request_interrupt    =   request_interrupt;


wire              phy_sd_cmd;
wire    [3:0]     phy_sd_data;

wire              dev_pll_locked;

wire              dev_sd_cmd_dir;
wire              dev_sd_cmd_in;
wire              dev_sd_cmd_out;

wire              dev_sd_data_dir;
wire    [7:0]     dev_sd_data_in;
wire    [7:0]     dev_sd_data_out;


// Function Interface From CIA
wire              fbr1_csa_en;
wire    [3:0]     fbr1_pwr_mode;
wire    [15:0]    fbr1_block_size;

wire              fbr2_csa_en;
wire    [3:0]     fbr2_pwr_mode;
wire    [15:0]    fbr2_block_size;

wire              fbr3_csa_en;
wire    [3:0]     fbr3_pwr_mode;
wire    [15:0]    fbr3_block_size;

wire              fbr4_csa_en;
wire    [3:0]     fbr4_pwr_mode;
wire    [15:0]    fbr4_block_size;

wire              fbr5_csa_en;
wire    [3:0]     fbr5_pwr_mode;
wire    [15:0]    fbr5_block_size;

wire              fbr6_csa_en;
wire    [3:0]     fbr6_pwr_mode;
wire    [15:0]    fbr6_block_size;

wire              fbr7_csa_en;
wire    [3:0]     fbr7_pwr_mode;
wire    [15:0]    fbr7_block_size;



wire    [7:0]     function_enable;
wire    [7:0]     function_ready;
wire    [2:0]     function_abort;
wire    [7:0]     function_int_en;
wire    [7:0]     function_int_pend;
reg     [7:0]     function_exec_status;

wire              function_activate;
wire              function_inc_addr;
wire              function_bock_mode;
wire              function_finished;

reg     [7:0]     function_interrupt;
wire    [3:0]     func_num;
wire              func_write_flag;
wire              func_rd_after_wr;
wire    [7:0]     func_write_data;
wire    [7:0]     func_read_data;
wire              func_data_rdy;
wire              func_wr_data_stb;
wire              func_host_rdy;
wire    [17:0]    func_addr;
wire    [9:0]     func_data_count;
wire              func_rd_data_stb;
wire              func_block_mode;


wire              i_func_num;
wire              o_read_wait;
wire              o_interrupt;

wire              demo_func_ready;
wire              demo_func_abort;
wire              demo_func_int_pend;
wire              demo_func_busy;

wire              demo_func_activate;
wire              demo_func_finished;
wire              demo_func_inc_addr;
wire              demo_func_block_mode;



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
  .o_master_ready (master_ready   ),

  .i_out_ready    (r_out_ready    ),
  .o_en           (out_en         ),
  .o_status       (out_status     ),
  .o_address      (out_address    ),
  .o_data         (out_data       ),
  .o_data_count   (out_data_count ),

  .o_per_we       (w_wbp_we       ),
  .o_per_adr      (w_wbp_adr      ),
  .o_per_dat      (w_wbp_dat_i    ),
  .i_per_dat      (w_wbp_dat_o    ),
  .o_per_stb      (w_wbp_stb      ),
  .o_per_cyc      (w_wbp_cyc      ),
  .o_per_msk      (w_wbp_msk      ),
  .o_per_sel      (w_wbp_sel      ),
  .i_per_ack      (w_wbp_ack      ),
  .i_per_int      (w_wbp_int      ),

  //memory interconnect signals
  .o_mem_we       (w_mem_we_o     ),
  .o_mem_adr      (w_mem_adr_o    ),
  .o_mem_dat      (w_mem_dat_o    ),
  .i_mem_dat      (w_mem_dat_i    ),
  .o_mem_stb      (w_mem_stb_o    ),
  .o_mem_cyc      (w_mem_cyc_o    ),
  .o_mem_sel      (w_mem_sel_o    ),
  .i_mem_ack      (w_mem_ack_i    ),
  .i_mem_int      (w_mem_int_i    )
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

//slave 1
wb_sd_host s1 (

  .clk        (clk                  ),
  .rst        (r_rst                ),

  .i_wbs_we   (w_wbs1_we            ),
  .i_wbs_sel  (4'b1111              ),
  .i_wbs_cyc  (w_wbs1_cyc           ),
  .i_wbs_dat  (w_wbs1_dat_i         ),
  .i_wbs_stb  (w_wbs1_stb           ),
  .o_wbs_ack  (w_wbs1_ack           ),
  .o_wbs_dat  (w_wbs1_dat_o         ),
  .i_wbs_adr  (w_wbs1_adr           ),
  .o_wbs_int  (w_wbs1_int           ),

  .mem_o_we   (mem_o_we             ),
  .mem_o_stb  (mem_o_stb            ),
  .mem_o_cyc  (mem_o_cyc            ),
  .mem_o_sel  (mem_o_sel            ),
  .mem_o_adr  (mem_o_adr            ),
  .mem_o_dat  (mem_o_dat            ),
  .mem_i_dat  (mem_i_dat            ),
  .mem_i_ack  (mem_i_ack            ),
  .mem_i_int  (mem_i_int            ),

  .o_sd_clk   (sd_clk               ),
  .io_sd_cmd  (phy_sd_cmd           ),
  .io_sd_data (phy_sd_data          )

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


arbiter_2_masters arb0 (
  .clk        (clk                  ),
  .rst        (r_rst                ),

  //masters
  .i_m0_we    (mem_o_we             ),
  .i_m0_stb   (mem_o_stb            ),
  .i_m0_cyc   (mem_o_cyc            ),
  .i_m0_sel   (mem_o_sel            ),
  .i_m0_dat   (mem_o_dat            ),
  .i_m0_adr   (mem_o_adr            ),
  .o_m0_dat   (mem_i_dat            ),
  .o_m0_ack   (mem_i_ack            ),
  .o_m0_int   (mem_i_int            ),


  .i_m1_we    (w_sm0_i_wbs_we       ),
  .i_m1_stb   (w_sm0_i_wbs_stb      ),
  .i_m1_cyc   (w_sm0_i_wbs_cyc      ),
  .i_m1_sel   (w_sm0_i_wbs_sel      ),
  .i_m1_dat   (w_sm0_i_wbs_dat      ),
  .i_m1_adr   (w_sm0_i_wbs_adr      ),
  .o_m1_dat   (w_sm0_o_wbs_dat      ),
  .o_m1_ack   (w_sm0_o_wbs_ack      ),
  .o_m1_int   (w_sm0_o_wbs_int      ),

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


sd_dev_platform_cocotb sdio_dev_plat(
  .clk            (clk            ),
  .rst            (r_rst          ),

  .o_locked       (dev_pll_locked ),

  .i_sd_cmd_dir   (dev_sd_cmd_dir   ),
  .o_sd_cmd_in    (dev_sd_cmd_in    ),
  .i_sd_cmd_out   (dev_sd_cmd_out   ),

  .i_sd_data_dir  (dev_sd_data_dir  ),
  .o_sd_data_in   (dev_sd_data_in   ),
  .i_sd_data_out  (dev_sd_data_out  ),

  .i_phy_clk      (sd_clk         ),
  .io_phy_sd_cmd  (phy_sd_cmd     ),
  .io_phy_sd_data (phy_sd_data    )
);

//TODO ADAPT sdio_device to use the platform based phy_sd_cmd and phy_sd_data

sdio_device_stack sdio_device (
  .sdio_clk             (sd_clk               ),
  .sdio_clk_x2          (clk                  ),
  .rst                  (r_rst || !dev_pll_locked),

  // Function Interfacee From CIA
  .o_fbr1_csa_en        (fbr1_csa_en          ),
  .o_fbr1_pwr_mode      (fbr1_pwr_mode        ),
  .o_fbr1_block_size    (fbr1_block_size      ),

  .o_fbr2_csa_en        (fbr2_csa_en          ),
  .o_fbr2_pwr_mode      (fbr2_pwr_mode        ),
  .o_fbr2_block_size    (fbr2_block_size      ),

  .o_fbr3_csa_en        (fbr3_csa_en          ),
  .o_fbr3_pwr_mode      (fbr3_pwr_mode        ),
  .o_fbr3_block_size    (fbr3_block_size      ),

  .o_fbr4_csa_en        (fbr4_csa_en          ),
  .o_fbr4_pwr_mode      (fbr4_pwr_mode        ),
  .o_fbr4_block_size    (fbr4_block_size      ),

  .o_fbr5_csa_en        (fbr5_csa_en          ),
  .o_fbr5_pwr_mode      (fbr5_pwr_mode        ),
  .o_fbr5_block_size    (fbr5_block_size      ),

  .o_fbr6_csa_en        (fbr6_csa_en          ),
  .o_fbr6_pwr_mode      (fbr6_pwr_mode        ),
  .o_fbr6_block_size    (fbr6_block_size      ),

  .o_fbr7_csa_en        (fbr7_csa_en          ),
  .o_fbr7_pwr_mode      (fbr7_pwr_mode        ),
  .o_fbr7_block_size    (fbr7_block_size      ),



  .o_func_enable        (function_enable      ),
  .i_func_ready         (function_ready       ),
  .o_func_abort         (function_abort       ),
  .o_func_int_enable    (function_int_en      ),
  .i_func_int_pending   (function_int_pend    ),
  .i_func_exec_status   (function_exec_status ),

  .o_func_inc_addr      (o_func_inc_addr      ),

  .o_func_num           (func_num             ),
  .o_func_rd_after_wr   (func_rd_after_wr     ),
  .o_func_addr          (func_addr            ),
  .o_func_data_count    (func_data_count      ),

  .i_interrupt          (function_interrupt   ),

  .o_sd_cmd_dir         (dev_sd_cmd_dir       ),
  .i_sd_cmd_in          (dev_sd_cmd_in        ),
  .o_sd_cmd_out         (dev_sd_cmd_out       ),

  .o_sd_data_dir        (dev_sd_data_dir      ),
  .o_sd_data_out        (dev_sd_data_out      ),
  .i_sd_data_in         (dev_sd_data_in       )

);

demo_function demo (
  .clk                  (clk                 ),
  .sdio_clk             (sd_clk              ),
  .rst                  (r_rst               ),

  .i_csa_en             (fbr1_csa_en         ),
  .i_block_size         (fbr1_block_size     ),
  .i_enable             (function_enable[0]  ),
  .o_ready              (demo_func_ready     ),
  .i_abort              (demo_func_abort     ),
  .i_interrupt_enable   (function_int_en[0]  ),
  .o_interrupt_pending  (demo_func_int_pend  ),
  .o_busy               (demo_func_busy      ),

  .i_activate           (demo_func_activate  ),
  .o_finished           (demo_func_finished  ),
  .i_inc_addr           (demo_func_inc_addr  ),
  .i_block_mode         (demo_func_block_mode),


/*
  .i_write_flag         (func_write_flag     ),
  .i_rd_after_wr        (func_rd_after_wr    ),
  .i_addr               (func_addr           ),
  .i_write_data         (func_write_data     ),
  .o_read_data          (func_read_data      ),
  .o_data_rdy           (func_data_rdy       ),
  .i_data_stb           (func_wr_data_stb    ),
  .i_host_rdy           (func_host_rdy       ),
  .i_data_count         (func_data_count     ),
  .o_data_stb           (func_rd_data_stb    ),
*/


  .o_read_wait          (demo_func_read_wait ),
  .o_interrupt          (demo_func_interrupt ),


  .i_request_read_wait  (r_request_read_wait ),
  .i_request_interrupt  (r_request_interrupt )

);









assign  w_wbs0_ack              = 0;
assign  w_wbs0_dat_o            = 0;
assign  start                   = 1;
assign  function_ready          = {7'b0000000, demo_func_ready};
assign  function_int_pend       = {7'b0000000, demo_func_int_pend};

//Submodules
//Asynchronous Logic
//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
