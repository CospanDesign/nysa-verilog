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
  input               clk,
  input               rst,


  //FPGA Interface
  output              ddr_en,
  input               sdio_clk,
  inout               sdio_cmd,
  inout   [3:0]       sdio_data

);
//local parameters
//registes/wires
wire          [3:0]   sdio_state;
wire                  sdio_cmd_in;
wire                  sdio_cmd_out;
wire                  sdio_cmd_dir;

wire          [3:0]   sdio_data_in;
wire          [3:0]   sdio_data_out;
wire                  sdio_data_dir;

//Phy Configuration
wire                  spi_phy;
wire                  sd1_phy;
wire                  sd4_phy;

//Phy Interface
wire                  cmd_stb;
wire                  cmd_crc_stb;
wire          [5:0]   cmd;
wire          [31:0]  cmd_arg;

wire          [127:0] rsps;
wire          [7:0]   rsps_len;


wire                  interrupt;
wire                  read_wait;


//Submodules
sdio_device_phy phy(
  //.clk                  (clk              ),
  .rst                  (rst              ),

  //Configuration
  .spi_phy              (spi_phy          ),
  .sd1_phy              (sd1_phy          ),
  .sd4_phy              (sd4_phy          ),

  //Data Link Interface
  .cmd_stb              (cmd_stb          ),
  .cmd_crc_good_stb     (cmd_crc_good_stb ),
  .cmd                  (cmd              ),
  .cmd_arg              (cmd_arg          ),

  .rsps                 (rsps             ),
  .rsps_len             (rsps_len         ),

  .interrupt            (interrupt        ),
  .read_wait            (read_wait        ),

  //FPGA Interface
  .ddr_en               (ddr_en           ),
  .sdio_clk             (sdio_clk         ),
  .sdio_cmd_in          (sdio_cmd_in      ),
  .sdio_cmd_out         (sdio_cmd_out     ),
  .sdio_cmd_dir         (sdio_cmd_dir     ),
  .sdio_data_in         (sdio_data_in     ),
  .sdio_data_out        (sdio_data_out    ),
  .sdio_data_dir        (sdio_data_dir    )

);

//asynchronous logic
assign  sdio_cmd  = sdio_cmd_dir  ? sdio_cmd_out  : sdio_cmd_in;
assign  sdio_data = sdio_data_dir ? sdio_data_out : sdio_data_in;

//synchronous logic



endmodule
