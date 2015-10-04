`timescale 1ns/1ps

`define DEMO_FUNCTION_ADDR  1

module tb_cocotb (

  //Virtual Host Interface Signals
  input           clk,
  input           sdio_clk,
  input           rst,

  input           request_read_wait,
  input           request_interrupt
);


//Parameters
//Registers/Wires

reg             r_rst;
reg             r_request_read_wait;
reg             r_request_interrupt;

wire            sdio_cmd;
wire    [3:0]   sdio_data;



// Function Interface From CIA
wire            fbr1_csa_en;
wire    [3:0]   fbr1_pwr_mode;
wire    [15:0]  fbr1_block_size;

wire            fbr2_csa_en;
wire    [3:0]   fbr2_pwr_mode;
wire    [15:0]  fbr2_block_size;

wire            fbr3_csa_en;
wire    [3:0]   fbr3_pwr_mode;
wire    [15:0]  fbr3_block_size;

wire            fbr4_csa_en;
wire    [3:0]   fbr4_pwr_mode;
wire    [15:0]  fbr4_block_size;

wire            fbr5_csa_en;
wire    [3:0]   fbr5_pwr_mode;
wire    [15:0]  fbr5_block_size;

wire            fbr6_csa_en;
wire    [3:0]   fbr6_pwr_mode;
wire    [15:0]  fbr6_block_size;

wire            fbr7_csa_en;
wire    [3:0]   fbr7_pwr_mode;
wire    [15:0]  fbr7_block_size;



wire    [7:0]   function_enable;
reg     [7:0]   function_ready;
wire    [2:0]   function_abort;
wire    [7:0]   function_int_en;
reg     [7:0]   function_int_pend;
reg     [7:0]   function_exec_status;

wire            function_activate;
wire            function_inc_addr;
wire            function_bock_mode;
wire            function_finished;

reg     [7:0]   function_interrupt;
wire    [3:0]   func_num;
wire            func_write_flag;
wire            func_rd_after_wr;
wire    [7:0]   func_write_data;
wire    [7:0]   func_read_data;
wire            func_data_rdy;
wire            func_wr_data_stb;
wire            func_host_rdy;
wire    [17:0]  func_addr;
wire    [17:0]  func_data_count;
wire            func_rd_data_stb;
wire            func_block_mode;


wire            i_func_num;
wire            o_read_wait;
wire            o_interrupt;

wire            demo_func_ready;
wire            demo_func_enable;
wire            demo_func_abort;
wire            demo_func_int_en;
wire            demo_func_int_pend;
wire            demo_func_busy;

wire            demo_func_activate;
wire            demo_func_finished;
wire            demo_func_inc_addr;
wire            demo_func_block_mode;


/* COCOTB Synchronize */
always @ (*) r_rst                  =   rst;
always @ (*) r_request_read_wait    =   request_read_wait;
always @ (*) r_request_interrupt    =   request_interrupt;


//Submodules
sdio_device_stack sdio_device (
  .sdio_clk            (sdio_clk            ),
  .rst                 (rst                 ),

  // Function Interface From CIA
  .o_fbr1_csa_en       (fbr1_csa_en         ),
  .o_fbr1_pwr_mode     (fbr1_pwr_mode       ),
  .o_fbr1_block_size   (fbr1_block_size     ),

  .o_fbr2_csa_en       (fbr2_csa_en         ),
  .o_fbr2_pwr_mode     (fbr2_pwr_mode       ),
  .o_fbr2_block_size   (fbr2_block_size     ),

  .o_fbr3_csa_en       (fbr3_csa_en         ),
  .o_fbr3_pwr_mode     (fbr3_pwr_mode       ),
  .o_fbr3_block_size   (fbr3_block_size     ),

  .o_fbr4_csa_en       (fbr4_csa_en         ),
  .o_fbr4_pwr_mode     (fbr4_pwr_mode       ),
  .o_fbr4_block_size   (fbr4_block_size     ),

  .o_fbr5_csa_en       (fbr5_csa_en         ),
  .o_fbr5_pwr_mode     (fbr5_pwr_mode       ),
  .o_fbr5_block_size   (fbr5_block_size     ),

  .o_fbr6_csa_en       (fbr6_csa_en         ),
  .o_fbr6_pwr_mode     (fbr6_pwr_mode       ),
  .o_fbr6_block_size   (fbr6_block_size     ),

  .o_fbr7_csa_en       (fbr7_csa_en         ),
  .o_fbr7_pwr_mode     (fbr7_pwr_mode       ),
  .o_fbr7_block_size   (fbr7_block_size     ),



  .o_func_enable       (function_enable     ),
  .i_func_ready        (function_ready      ),
  .o_func_abort        (function_abort      ),
  .o_func_int_en       (function_int_en     ),
  .i_func_int_pending  (function_int_pend   ),
  .i_func_exec_status  (function_exec_status),

  .o_func_activate     (o_func_activate     ),
  .i_func_finished     (i_func_finished     ),

  .o_func_inc_addr     (o_func_inc_addr     ),
  .o_func_block_mode   (o_func_block_mode   ),

  .o_func_num          (func_num          ),
  .o_func_write_flag   (func_write_flag   ),
  .o_func_rd_after_wr  (func_rd_after_wr  ),
  .o_func_addr         (func_addr         ),
  .o_func_write_data   (func_write_data   ),
  .i_func_read_data    (func_read_data    ),
  .o_func_data_rdy     (func_data_rdy     ),
  .i_func_host_rdy     (func_host_rdy     ),
  .o_func_data_count   (func_data_count   ),

  .i_interrupt         (function_interrupt),

  .o_ddr_en            (o_ddr_en          ),
  .i_sdio_cmd          (sdio_cmd          ),
  .io_sdio_data        (sdio_data         )
);

demo_function demo (
  .clk                  (clk                 ),
  .sdio_clk             (sdio_clk            ),
  .rst                  (r_rst               ),

  .i_csa_en             (fbr1_csa_en         ),
  .i_block_size         (fbr1_block_size     ),
  .i_enable             (demo_func_enable    ),
  .o_ready              (demo_func_ready     ),
  .i_abort              (demo_func_abort     ),
  .i_interrupt_enable   (demo_func_int_en    ),
  .o_interrupt_pending  (demo_func_int_pend  ),
  .o_busy               (demo_func_busy      ),

  .i_activate           (demo_func_activate  ),
  .o_finished           (demo_func_finished  ),
  .i_inc_addr           (demo_func_inc_addr  ),
  .i_block_mode         (demo_func_block_mode),


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


  .o_read_wait          (demo_func_read_wait ),
  .o_interrupt          (demo_func_interrupt ),


  .i_request_read_wait  (r_request_read_wait ),
  .i_request_interrupt  (r_request_interrupt )

);

//Asynchronous Logic
assign  sdio_cmd                            = 0;
assign  sdio_data                           = 0;

assign  demo_func_enable                    = function_enable[`DEMO_FUNCTION_ADDR];
assign  demo_func_abort                     = (function_abort == `DEMO_FUNCTION_ADDR);
assign  demo_func_int_en                    = function_int_en[`DEMO_FUNCTION_ADDR];

assign  demo_func_activate                  = (func_num == `DEMO_FUNCTION_ADDR) ? function_activate : 1'b0;
assign  demo_func_inc_addr                  = (func_num == `DEMO_FUNCTION_ADDR) ? function_inc_addr : 18'h0;
assign  demo_func_block_mode                = (func_num == `DEMO_FUNCTION_ADDR) ? func_block_mode : 1'b0;

/* Make a multiplexer that will handle multiple function */
assign  function_finished                   = (func_num == `DEMO_FUNCTION_ADDR) ? demo_func_finished : 1'b0;
assign  function_read_wait                  = (func_num == `DEMO_FUNCTION_ADDR) ? demo_func_read_wait : 1'b0;

//Synchronous Logic
always @ (posedge sdio_clk) begin
  if (r_rst) begin
    function_ready                                  <= 0;
    function_int_pend                               <= 0;
    function_exec_status                            <= 0;
    function_interrupt                              <= 0;
  end
  else begin
    function_ready[`DEMO_FUNCTION_ADDR]             <= demo_func_ready;
    function_int_pend[`DEMO_FUNCTION_ADDR]          <= demo_func_int_pend;
    function_exec_status[`DEMO_FUNCTION_ADDR]       <= demo_func_busy;
    function_interrupt[`DEMO_FUNCTION_ADDR]         <= demo_func_interrupt;
  end
end

//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
