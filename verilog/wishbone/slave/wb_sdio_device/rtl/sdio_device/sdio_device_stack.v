/*
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
 * Author: David McCoy
 *
 * NOTE: Add Pullups to all the signals, this will tell the host we are
 *    an SD Device, not a SPI Device
 * Description: SDIO Stack
 *  Manages the entire SDIO communication flow, in the end users should
 *  Write into the stack and it should arrive on the other side.
 *
 *  Data Link Layer:
 *    Sends and receive commands and responses from the physical layer.
 *    Manages all register read and writes that will be used to configure
 *    the entire stack.
 *
 *  Phy Layer:
 *    Sends and receives streams of bits with the host and manages CRC
 *    generation and analysis. The bottom part of this layer is connected
 *    to the physical pins of the FPGA and the top is connected to the data
 *    link layer
 *
 * Changes:
 *  2015.08.09: Inital Commit
 */

module sdio_device_stack (

  input                     sdio_clk,
  input                     sdio_clk_x2,
  input                     rst,

  output                    o_mem_en,

  //Function Configuration
  output          [7:0]     o_func_enable,          //Bitmask Function Enable
  input           [7:0]     i_func_ready,           //Bitmask Function is Ready
  output          [2:0]     o_func_abort_stb,
  input           [7:0]     i_func_exec_status,
  input           [7:0]     i_func_ready_for_data,

  // Function Interface From CIA
  output                    o_fbr1_csa_en,
  output          [3:0]     o_fbr1_pwr_mode,
  output          [15:0]    o_fbr1_block_size,

  output                    o_fbr2_csa_en,
  output          [3:0]     o_fbr2_pwr_mode,
  output          [15:0]    o_fbr2_block_size,

  output                    o_fbr3_csa_en,
  output          [3:0]     o_fbr3_pwr_mode,
  output          [15:0]    o_fbr3_block_size,

  output                    o_fbr4_csa_en,
  output          [3:0]     o_fbr4_pwr_mode,
  output          [15:0]    o_fbr4_block_size,

  output                    o_fbr5_csa_en,
  output          [3:0]     o_fbr5_pwr_mode,
  output          [15:0]    o_fbr5_block_size,

  output                    o_fbr6_csa_en,
  output          [3:0]     o_fbr6_pwr_mode,
  output          [15:0]    o_fbr6_block_size,

  output                    o_fbr7_csa_en,
  output          [3:0]     o_fbr7_pwr_mode,
  output          [15:0]    o_fbr7_block_size,

  //Function 1 Interface
  output                    o_func1_wr_stb,
  output          [7:0]     o_func1_wr_data,
  input                     i_func1_rd_stb,
  input           [7:0]     i_func1_rd_data,
  output                    o_func1_hst_rdy,
  input                     i_func1_com_rdy,
  output                    o_func1_activate,

  //Function 2 Interface
  output                    o_func2_wr_stb,
  output          [7:0]     o_func2_wr_data,
  input                     i_func2_rd_stb,
  input           [7:0]     i_func2_rd_data,
  output                    o_func2_hst_rdy,
  input                     i_func2_com_rdy,
  output                    o_func2_activate,

  //Function 3 Interface
  output                    o_func3_wr_stb,
  output          [7:0]     o_func3_wr_data,
  input                     i_func3_rd_stb,
  input           [7:0]     i_func3_rd_data,
  output                    o_func3_hst_rdy,
  input                     i_func3_com_rdy,
  output                    o_func3_activate,

  //Function 4 Interface
  output                    o_func4_wr_stb,
  output          [7:0]     o_func4_wr_data,
  input                     i_func4_rd_stb,
  input           [7:0]     i_func4_rd_data,
  output                    o_func4_hst_rdy,
  input                     i_func4_com_rdy,
  output                    o_func4_activate,

  //Function 5 Interface
  output                    o_func5_wr_stb,
  output          [7:0]     o_func5_wr_data,
  input                     i_func5_rd_stb,
  input           [7:0]     i_func5_rd_data,
  output                    o_func5_hst_rdy,
  input                     i_func5_com_rdy,
  output                    o_func5_activate,

  //Function 6 Interface
  output                    o_func6_wr_stb,
  output          [7:0]     o_func6_wr_data,
  input                     i_func6_rd_stb,
  input           [7:0]     i_func6_rd_data,
  output                    o_func6_hst_rdy,
  input                     i_func6_com_rdy,
  output                    o_func6_activate,

  //Function 7 Interface
  output                    o_func7_wr_stb,
  output          [7:0]     o_func7_wr_data,
  input                     i_func7_rd_stb,
  input           [7:0]     i_func7_rd_data,
  output                    o_func7_hst_rdy,
  input                     i_func7_com_rdy,
  output                    o_func7_activate,

  //Memory Interface
  output                    o_mem_wr_stb,
  output          [7:0]     o_mem_wr_data,
  input                     i_mem_rd_stb,
  input           [7:0]     i_mem_rd_data,
  output                    o_mem_hst_rdy,
  input                     i_mem_com_rdy,
  output                    o_mem_activate,

  //Broadcast Values that go to all Functions/Memory
  output                    o_func_write_flag,
  output                    o_func_block_mode,
  output          [3:0]     o_func_num,
  output                    o_func_rd_after_wr,
  output                    o_func_inc_addr,
  output          [17:0]    o_func_addr,
  output          [12:0]    o_func_data_count,

  input           [7:0]     i_interrupt,

  //Platform Spectific posedge strobe
  input                     i_phy_posedge_stb,

  //FPGA Interface
  output                    o_sd_cmd_dir,
  input                     i_sd_cmd_in,
  output                    o_sd_cmd_out,

  output                    o_sd_data_dir,
  output          [7:0]     o_sd_data_out,
  input           [7:0]     i_sd_data_in

);

//local parameters
//registes/wires
wire        [3:0]   sdio_state;
wire                sdio_cmd_in;
wire                sdio_cmd_out;
wire                sdio_cmd_dir;

wire        [3:0]   sdio_data_in;
wire        [3:0]   sdio_data_out;
wire                sdio_data_dir;

//Phy Configuration
wire                spi_phy;
wire                sd1_phy;
wire                sd4_phy;

//Phy Interface
wire                cmd_phy_idle;
wire                cmd_stb;
wire                cmd_crc_stb;
wire        [5:0]   cmd;
wire        [31:0]  cmd_arg;
wire        [17:0]  cmd_addr;
wire        [12:0]  cmd_data_cnt;

wire        [39:0]  rsps;
wire        [7:0]   rsps_len;
wire                rsps_fail;
wire                rsps_idle;

wire                interrupt;
wire                chip_select_n;

//Function Level
wire                cmd_bus_sel;

wire                tunning_block;

wire                soft_reset;

//SDIO Configuration Flags
wire                en_card_detect_n;
wire                en_4bit_block_int;
wire                bus_release_req_stb;
wire        [15:0]  f0_block_size;

wire                cfg_1_bit_mode;
wire                cfg_4_bit_mode;
wire                cfg_8_bit_mode;

wire                sdr_12;
wire                sdr_25;
wire                sdr_50;
wire                ddr_50;
wire                sdr_104;

wire                driver_type_a;
wire                driver_type_b;
wire                driver_type_c;
wire                driver_type_d;
wire                enable_async_interrupt;


wire        [7:0]   i_func_ready;
wire        [7:0]   func_int_enable;
wire        [7:0]   func_int_pending;
wire                data_bus_busy;
wire                data_read_avail;

wire        [7:0]   cmd_func_write_data;
wire        [7:0]   cmd_func_read_data;
wire                cmd_func_data_rdy;
wire                cmd_func_host_rdy;
wire        [17:0]  cmd_func_data_count;
wire                cmd_func_activate;
wire                cmd_func_finished;

wire                data_phy_activate;
wire                data_phy_finished;
wire                data_phy_wr_stb;
wire        [7:0]   data_phy_wr_data;
wire                data_phy_rd_stb;
wire        [7:0]   data_phy_rd_data;
wire                data_phy_hst_rdy;
wire                data_phy_com_rdy;

wire                cia_wr_stb;
wire        [7:0]   cia_wr_data;
wire                cia_rd_stb;
wire        [7:0]   cia_rd_data;
wire                cia_hst_rdy;
wire                cia_com_rdy;
wire                cia_activate;
wire                cia_finished;


//Submodules
sdio_card_control card_controller (

  .sdio_clk                 (sdio_clk                   ),/* Run from the SDIO Clock */
  .rst                      (rst                        ),
  .i_soft_reset             (i_soft_reset               ),
  .i_func_interrupt         (i_interrupt                ),
  .i_func_interrupt_en      (func_int_enable            ),
  .o_interrupt              (interrupt                  ),

  .o_mem_en                 (o_mem_en                   ),
  .o_func_num               (o_func_num                 ),/* CMD -> FUNC: Function Number to activate */
  .o_func_inc_addr          (o_func_inc_addr            ),/* CMD -> FUNC: Inc address after every read/write */
  .o_func_block_mode        (o_func_block_mode          ),/* CMD -> FUNC: This is a block level transfer, not byte */
  .o_func_write_flag        (o_func_write_flag          ),/* CMD -> FUNC: We are writing */
  .o_func_rd_after_wr       (o_func_rd_after_wr         ),/* CMD -> FUNC: Read the value after a write */
  .o_func_addr              (cmd_addr                   ),/* CMD -> FUNC: Address we are talking to */
  .o_func_data_count        (cmd_data_cnt               ),/* CMD -> FUNC: number of data bytes/blocks to read/write */

  //Command Data Bus
  .o_cmd_bus_sel            (cmd_bus_sel                ),/* CMD -> FUNC: Indicate that data will be on command bus */
  .o_func_activate          (cmd_func_activate          ),/* CMD -> FUNC: Start a function layer transaction */
  .i_func_finished          (cmd_func_finished          ),/* FUNC -> CMD: Function has finished */
  .o_func_write_data        (cmd_func_write_data        ),/* CMD -> FUNC: Data to Write */
  .i_func_read_data         (cmd_func_read_data         ),/* FUNC -> CMD: Read Data */

  .o_tunning_block          (tunning_block              ),

  .i_cmd_phy_idle           (cmd_phy_idle               ),/* PHY -> CMD: Command portion of phy layer is IDLE */
  .i_cmd_stb                (cmd_stb                    ),/* PHY -> CMD: Command signal strobe */
  .i_cmd_crc_good_stb       (cmd_crc_good_stb           ),/* PHY -> CMD: CRC is good */
  .i_cmd                    (cmd                        ),/* PHY -> CMD: Command */
  .i_cmd_arg                (cmd_arg                    ),/* PHY -> CMD: Command Arg */

  .i_chip_select_n          (chip_select_n              ),/* Chip Select used to determine if this is a SPI host */

  .o_rsps                   (rsps                       ),/* Response Generated by this layer*/
  .o_rsps_len               (rsps_len                   ),/* Length of response*/
  .o_rsps_stb               (rsps_stb                   ),
  .o_rsps_fail              (rsps_fail                  ),
  .i_rsps_idle              (rsps_idle                  )
);

sdio_data_control data_bus_interconnect(
  .clk                      (sdio_clk                   ),
  .rst                      (rst                        ),

  .o_data_bus_busy          (data_bus_busy              ),
  .o_data_read_avail        (data_read_avail            ),

  .i_write_flg              (o_func_write_flag          ),  /* CMD -> *: We are writing */
  .i_block_mode_flg         (o_func_block_mode          ),  /* CMD -> DATA CNTRL: this is a block mode transfer */
  .i_data_cnt               (cmd_data_cnt               ),
  .o_total_data_cnt         (o_func_data_count          ),

  .i_inc_addr_flg           (o_func_inc_addr            ),
  .i_cmd_address            (cmd_addr                   ),
  .o_address                (o_func_addr                ),

  .i_activate               (cmd_func_activate          ),  /* CMD -> DATA CNTRL: Activate transaction */
  .o_finished               (cmd_func_finished          ),  /* DATA CNTRL -> CMD: Finished with transaction */

  .i_cmd_bus_sel            (cmd_bus_sel                ),  /* If this is high we can only read/write one byte */
  .i_mem_sel                (o_mem_en                   ),  /* When high this selects the memory */
  .i_func_sel               (o_func_num                 ),  /* Select the function number */

  //Command Bus Interface
  .i_cmd_wr_data            (cmd_func_write_data        ),  /* CMD -> FUNC: Write Data */
  .o_cmd_rd_data            (cmd_func_read_data         ),  /* FUNC -> CMD: Data from func to host */

  //Phy Data Bus Inteface
  .i_data_phy_wr_stb        (data_phy_wr_stb            ),
  .i_data_phy_wr_data       (data_phy_wr_data           ),
  .o_data_phy_rd_stb        (data_phy_rd_stb            ),
  .o_data_phy_rd_data       (data_phy_rd_data           ),
  .i_data_phy_hst_rdy       (data_phy_hst_rdy           ), /* DATA PHY -> Func: Ready for receive data */
  .o_data_phy_com_rdy       (data_phy_com_rdy           ),
  .o_data_phy_activate      (data_phy_activate          ), /* DATA CNTRL -> DATA PHY: tell the phy that it should be ready */
  .i_data_phy_finished      (data_phy_finished          ),

  //CIA Interface
  .o_cia_wr_stb             (cia_wr_stb                 ),
  .o_cia_wr_data            (cia_wr_data                ),
  .i_cia_rd_stb             (cia_rd_stb                 ),
  .i_cia_rd_data            (cia_rd_data                ),
  .o_cia_hst_rdy            (cia_hst_rdy                ),
  .i_cia_com_rdy            (cia_com_rdy                ),
  .o_cia_activate           (cia_activate               ),
  .i_cia_block_size         (f0_block_size              ),

  //Function Interface
  .o_func1_wr_stb           (o_func1_wr_stb             ),
  .o_func1_wr_data          (o_func1_wr_data            ),
  .i_func1_rd_stb           (i_func1_rd_stb             ),
  .i_func1_rd_data          (i_func1_rd_data            ),
  .o_func1_hst_rdy          (o_func1_hst_rdy            ),
  .i_func1_com_rdy          (i_func1_com_rdy            ),
  .o_func1_activate         (o_func1_activate           ),
  .i_func1_block_size       (o_fbr1_block_size          ),


  //Function Interface
  .o_func2_wr_stb           (o_func2_wr_stb             ),
  .o_func2_wr_data          (o_func2_wr_data            ),
  .i_func2_rd_stb           (i_func2_rd_stb             ),
  .i_func2_rd_data          (i_func2_rd_data            ),
  .o_func2_hst_rdy          (o_func2_hst_rdy            ),
  .i_func2_com_rdy          (i_func2_com_rdy            ),
  .o_func2_activate         (o_func2_activate           ),
  .i_func2_block_size       (o_fbr2_block_size          ),

  //Function Interface
  .o_func3_wr_stb           (o_func3_wr_stb             ),
  .o_func3_wr_data          (o_func3_wr_data            ),
  .i_func3_rd_stb           (i_func3_rd_stb             ),
  .i_func3_rd_data          (i_func3_rd_data            ),
  .o_func3_hst_rdy          (o_func3_hst_rdy            ),
  .i_func3_com_rdy          (i_func3_com_rdy            ),
  .o_func3_activate         (o_func3_activate           ),
  .i_func3_block_size       (o_fbr3_block_size          ),

  //Function Interface
  .o_func4_wr_stb           (o_func4_wr_stb             ),
  .o_func4_wr_data          (o_func4_wr_data            ),
  .i_func4_rd_stb           (i_func4_rd_stb             ),
  .i_func4_rd_data          (i_func4_rd_data            ),
  .o_func4_hst_rdy          (o_func4_hst_rdy            ),
  .i_func4_com_rdy          (i_func4_com_rdy            ),
  .o_func4_activate         (o_func4_activate           ),
  .i_func4_block_size       (o_fbr4_block_size          ),

  //Function Interface
  .o_func5_wr_stb           (o_func5_wr_stb             ),
  .o_func5_wr_data          (o_func5_wr_data            ),
  .i_func5_rd_stb           (i_func5_rd_stb             ),
  .i_func5_rd_data          (i_func5_rd_data            ),
  .o_func5_hst_rdy          (o_func5_hst_rdy            ),
  .i_func5_com_rdy          (i_func5_com_rdy            ),
  .o_func5_activate         (o_func5_activate           ),
  .i_func5_block_size       (o_fbr5_block_size          ),

  //Function Interface
  .o_func6_wr_stb           (o_func6_wr_stb             ),
  .o_func6_wr_data          (o_func6_wr_data            ),
  .i_func6_rd_stb           (i_func6_rd_stb             ),
  .i_func6_rd_data          (i_func6_rd_data            ),
  .o_func6_hst_rdy          (o_func6_hst_rdy            ),
  .i_func6_com_rdy          (i_func6_com_rdy            ),
  .o_func6_activate         (o_func6_activate           ),
  .i_func6_block_size       (o_fbr6_block_size          ),

  //Function Interface
  .o_func7_wr_stb           (o_func7_wr_stb             ),
  .o_func7_wr_data          (o_func7_wr_data            ),
  .i_func7_rd_stb           (i_func7_rd_stb             ),
  .i_func7_rd_data          (i_func7_rd_data            ),
  .o_func7_hst_rdy          (o_func7_hst_rdy            ),
  .i_func7_com_rdy          (i_func7_com_rdy            ),
  .o_func7_activate         (o_func7_activate           ),
  .i_func7_block_size       (o_fbr7_block_size          ),

  //Memory Interface
  .o_mem_wr_stb             (o_mem_wr_stb               ),
  .o_mem_wr_data            (o_mem_wr_data              ),
  .i_mem_rd_stb             (i_mem_rd_stb               ),
  .i_mem_rd_data            (i_mem_rd_data              ),
  .o_mem_hst_rdy            (o_mem_hst_rdy              ),
  .i_mem_com_rdy            (i_mem_com_rdy              ),
  .o_mem_activate           (o_mem_activate             ),
  .i_mem_block_size         (16'h0000                   )
);


sdio_cia cia (
  .clk                      (sdio_clk                   ),
  .rst                      (rst                        ),

  .i_write_flag             (o_func_write_flag          ),
  .i_address                (o_func_addr                ),
  .i_inc_addr               (o_func_inc_addr            ),
  .i_data_count             (o_func_data_count          ),

  //SDIO Data Interface
  .i_activate               (cia_activate               ),
  .o_finished               (cia_finished               ),
  .i_ready                  (cia_hst_rdy                ),
  .i_data_stb               (cia_wr_stb                 ),
  .i_data_in                (cia_wr_data                ),
  .o_ready                  (cia_com_rdy                ),
  .o_data_out               (cia_rd_data                ),
  .o_data_stb               (cia_rd_stb                 ),

  //FBR Interface
  .o_fbr1_csa_en            (o_fbr1_csa_en              ),
  .o_fbr1_pwr_mode          (o_fbr1_pwr_mode            ),
  .o_fbr1_block_size        (o_fbr1_block_size          ),

  .o_fbr2_csa_en            (o_fbr2_csa_en              ),
  .o_fbr2_pwr_mode          (o_fbr2_pwr_mode            ),
  .o_fbr2_block_size        (o_fbr2_block_size          ),

  .o_fbr3_csa_en            (o_fbr3_csa_en              ),
  .o_fbr3_pwr_mode          (o_fbr3_pwr_mode            ),
  .o_fbr3_block_size        (o_fbr3_block_size          ),

  .o_fbr4_csa_en            (o_fbr4_csa_en              ),
  .o_fbr4_pwr_mode          (o_fbr4_pwr_mode            ),
  .o_fbr4_block_size        (o_fbr4_block_size          ),

  .o_fbr5_csa_en            (o_fbr5_csa_en              ),
  .o_fbr5_pwr_mode          (o_fbr5_pwr_mode            ),
  .o_fbr5_block_size        (o_fbr5_block_size          ),

  .o_fbr6_csa_en            (o_fbr6_csa_en              ),
  .o_fbr6_pwr_mode          (o_fbr6_pwr_mode            ),
  .o_fbr6_block_size        (o_fbr6_block_size          ),

  .o_fbr7_csa_en            (o_fbr7_csa_en              ),
  .o_fbr7_pwr_mode          (o_fbr7_pwr_mode            ),
  .o_fbr7_block_size        (o_fbr7_block_size          ),


  //Function Configuration Interface
  .o_func_enable            (o_func_enable              ),
  .i_func_ready             (i_func_ready               ),
  .o_func_int_enable        (func_int_enable            ),
  .i_func_int_pending       (func_int_pending           ),
  .i_func_ready_for_data    (i_func_ready_for_data      ),
  .o_func_abort_stb         (o_func_abort_stb           ),
//  .o_func_select            (o_func_select              ),  //XXX: Track this down!
  .i_func_exec_status       (i_func_exec_status         ),

  .i_data_bus_busy          (data_bus_busy              ),

  //SDCard Configuration Interface
  .o_en_card_detect_n       (en_card_detect_n           ),
  .o_en_4bit_block_int      (en_4bit_block_int          ),
  .o_bus_release_req_stb    (bus_release_req_stb        ),

  .o_soft_reset             (soft_reset                 ),
  .i_data_read_avail        (data_read_avail            ),

  .o_f0_block_size          (f0_block_size              ),

  .o_1_bit_mode             (cfg_1_bit_mode             ),
  .o_4_bit_mode             (cfg_4_bit_mode             ),
  .o_8_bit_mode             (cfg_8_bit_mode             ),

  .o_sdr_12                 (sdr_12                     ),
  .o_sdr_25                 (sdr_25                     ),
  .o_sdr_50                 (sdr_50                     ),
  .o_ddr_50                 (ddr_50                     ),
  .o_sdr_104                (sdr_104                    ),

  .o_driver_type_a          (driver_type_a              ),
  .o_driver_type_b          (driver_type_b              ),
  .o_driver_type_c          (driver_type_c              ),
  .o_driver_type_d          (driver_type_d              ),
  .o_enable_async_interrupt (enable_async_interrupt     )
);


sdio_device_phy phy(
  .rst                      (rst                        ),
  .i_posedge_stb            (i_phy_posedge_stb          ),

  //Configuration
  .i_spi_phy                (spi_phy                    ),/* Flag: SPI PHY (not supported now) */
  .i_sd1_phy                (sd1_phy                    ),/* Flag: SD  PHY with one data lane */
  .i_sd4_phy                (sd4_phy                    ),/* Flag: SD  PHY with four data lanes */

  .o_cmd_phy_idle           (cmd_phy_idle               ),/* PHY -> CMD: Command portion of phy layer is IDLE */

  //Command Interface
  .o_cmd_stb                (cmd_stb                    ),/* PHY -> CMD: Command signal strobe */
  .o_cmd_crc_good_stb       (cmd_crc_good_stb           ),/* PHY -> CMD: CRC is good */
  .o_cmd                    (cmd                        ),/* PHY -> CMD: Command */
  .o_cmd_arg                (cmd_arg                    ),/* PHY -> CMD: Command Arg */

  .i_rsps_stb               (rsps_stb                   ),/* CMD -> PHY: Response initiate */
  .i_rsps                   (rsps                       ),/* CMD -> PHY: Response Value */
  .i_rsps_len               (rsps_len                   ),/* CMD -> PHY: Response Length */
  .i_rsps_fail              (rsps_fail                  ),/* CMD -> PHY: Response Failed */
  .o_rsps_idle              (rsps_idle                  ),/* PHY -> CMD: Response is IDLE */

  .i_interrupt              (interrupt                  ),/* Interrupt */
  .i_data_count             (o_func_data_count          ),/* CMD -> PHY: Number of bytes to read/write */

  //Data Interface
  .i_data_activate          (data_phy_activate          ),
  .o_data_finished          (data_phy_finished          ),
  .i_write_flag             (o_func_write_flag          ),

  .o_data_wr_stb            (data_phy_wr_stb            ),
  .o_data_wr_data           (data_phy_wr_data           ),
  .i_data_rd_stb            (data_phy_rd_stb            ),
  .i_data_rd_data           (data_phy_rd_data           ),
  .o_data_hst_rdy           (data_phy_hst_rdy           ),
  .i_data_com_rdy           (data_phy_com_rdy           ),

  //FPGA Interface
  .i_sdio_clk               (sdio_clk                   ),
  .i_sdio_clk_x2            (sdio_clk_x2                ),

  .o_sdio_cmd_dir           (o_sd_cmd_dir               ),
  .i_sdio_cmd_in            (i_sd_cmd_in                ),
  .o_sdio_cmd_out           (o_sd_cmd_out               ),

  .o_sdio_data_dir          (o_sd_data_dir              ),
  .i_sdio_data_in           (i_sd_data_in               ),
  .o_sdio_data_out          (o_sd_data_out              )

);


//asynchronous logic
/*
assign  sdio_cmd      = sdio_cmd_dir  ? sdio_cmd_out  : sdio_cmd_in;
assign  sdio_data     = sdio_data_dir ? sdio_data_out : sdio_data_in;
assign  chip_select_n = sdio_data[3];
*/
assign  func_int_pending  = i_interrupt;


//synchronous logic

endmodule
