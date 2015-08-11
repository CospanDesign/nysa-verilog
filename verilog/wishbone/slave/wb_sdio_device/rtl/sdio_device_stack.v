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
wire                  cmd_phy_idle;
wire                  cmd_stb;
wire                  cmd_crc_stb;
wire          [5:0]   cmd;
wire          [31:0]  cmd_arg;

wire          [127:0] rsps;
wire          [7:0]   rsps_len;

wire                  interrupt;
wire                  read_wait;
wire                  chip_select_n;

//Function Level
wire                  func_dat_rdy;

//Submodules
sdio_device_data_link #(
  .NUM_FUNCS        (1                      ),/* Number of SDIO Functions available */
  .MEM_PRESENT      (0                      ),/* Not supported yet */
  .UHSII_AVAILABLE  (0                      ),/* UHS Mode Not available yet */
  .IO_OCR           (24'hFFF0               ) /* Operating condition mode (voltage range) */
) data_link (
  .sdio_clk         (sdio_clk               ),/* Run from the SDIO Clock */
  .rst              (rst                    ),

  .func_dat_rdy     (func_dat_rdy           ),/* DATA LINK -> FUNC: Function Layer can now send data to host */

  .cmd_phy_idle     (cmd_phy_idle           ),/* PHY -> DATA LINK: Command portion of phy layer is IDLE */
  .cmd_stb          (cmd_stb                ),/* PHY -> DATA LINK: Command signal strobe */
  .cmd_crc_good_stb (cmd_crc_good_stb       ),/* PHY -> DATA LINK: CRC is good */
  .cmd              (cmd                    ),/* PHY -> DATA LINK: Command */
  .cmd_arg          (cmd_arg                ),/* PHY -> DATA LINK: Command Arg */

  .chip_select_n    (chip_select_n          ),/* Chip Select used to determine if this is a SPI flavored host */

  .rsps             (rsps                   ),/* Response Generated by this layer*/
  .rsps_len         (rsps_len               ) /* Length of response, this could be a short 40 bit or long 128 bit */
);



sdio_device_phy phy(
  .rst              (rst                    ),

  //Configuration
  .spi_phy          (spi_phy                ),/* Flag: SPI PHY (not supported now) */
  .sd1_phy          (sd1_phy                ),/* Flag: SD  PHY with one data lane */
  .sd4_phy          (sd4_phy                ),/* Flag: SD  PHY with four data lanes */

  .cmd_phy_idle     (cmd_phy_idle           ),/* PHY -> DATA LINK: Command portion of phy layer is IDLE */

  //Data Link Interface
  .cmd_stb          (cmd_stb                ),/* PHY -> DATA LINK: Command signal strobe */
  .cmd_crc_good_stb (cmd_crc_good_stb       ),/* PHY -> DATA LINK: CRC is good */
  .cmd              (cmd                    ),/* PHY -> DATA LINK: Command */
  .cmd_arg          (cmd_arg                ),/* PHY -> DATA LINK: Command Arg */

  .rsps             (rsps                   ),/* DATA LINK -> PHY: Response Value */
  .rsps_len         (rsps_len               ),/* DATA LINK -> PHY: Response Length */

  .interrupt        (interrupt              ),/* Interrupt */
  .read_wait        (read_wait              ),/* SDIO Device is busy working on generated a read */

  //FPGA Interface
  .ddr_en           (ddr_en                 ),
  .sdio_clk         (sdio_clk               ),
  .sdio_cmd_in      (sdio_cmd_in            ),
  .sdio_cmd_out     (sdio_cmd_out           ),
  .sdio_cmd_dir     (sdio_cmd_dir           ),
  .sdio_data_in     (sdio_data_in           ),
  .sdio_data_out    (sdio_data_out          ),
  .sdio_data_dir    (sdio_data_dir          )

);


//asynchronous logic
/*
assign  sdio_cmd      = sdio_cmd_dir  ? sdio_cmd_out  : sdio_cmd_in;
assign  sdio_data     = sdio_data_dir ? sdio_data_out : sdio_data_in;
assign  chip_select_n = sdio_data[3];
*/

//synchronous logic

endmodule
