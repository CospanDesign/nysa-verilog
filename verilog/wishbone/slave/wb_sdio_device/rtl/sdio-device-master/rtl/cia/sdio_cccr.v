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
 * Author: David McCoy (dave.mccoy@cospandesign.com)
 * Description: Common Card Control Registers (CCCR)
 *  Controls many aspects of the card.
 *  Define values are values that do not change with implementation, for
 *    for example: CCCR version number and SDIO version number
 *  Parameter values change with every implementation, examples include
 *    Buffer depth and function numbers
 *
 * Changes:
 */

`include "sdio_cia_defines.v"

module sdio_cccr (
  input                     clk,
  input                     rst,

  input                     i_activate,
  input                     i_write_flag,
  input         [7:0]       i_address,
  input                     i_data_stb,
  input         [7:0]       i_data_in,
  output        [7:0]       o_data_out,

  //Function Interface
  output  reg   [7:0]       o_func_enable,
  input         [7:0]       i_func_ready,
  output  reg   [7:0]       o_func_int_enable,
  input         [7:0]       i_func_int_pending,
  output  reg               o_soft_reset,
  output  reg   [2:0]       o_func_abort_stb,
  output  reg               o_en_card_detect_n,
  output  reg               o_en_4bit_block_int, /* Enable interrupts durring 4-bit block data mode */
  input                     i_data_bus_busy,
  output  reg               o_bus_release_req_stb,
  output  reg   [3:0]       o_func_select,
  input                     i_data_read_avail,
  input         [7:0]       i_func_exec_status,
  input         [7:0]       i_func_ready_for_data,
  output  reg   [15:0]      o_f0_block_size,

  output                    o_1_bit_mode,
  output                    o_4_bit_mode,
  output                    o_8_bit_mode,

  output                    o_sdr_12,
  output                    o_sdr_25,
  output                    o_sdr_50,
  output                    o_ddr_50,
  output                    o_sdr_104,

  output                    o_driver_type_a,
  output                    o_driver_type_b,
  output                    o_driver_type_c,
  output                    o_driver_type_d,
  output  reg               o_enable_spi_interrupt,
  output  reg               o_enable_async_interrupt

);

//local parameters
localparam     IDLE         = 4'h0;
localparam     READ         = 4'h1;
localparam     WRITE        = 4'h2;

//registes/wires
reg             [1:0]       driver_type;
reg             [3:0]       state;

wire            [7:0]       cccr_map [0:22];

output  reg     [1:0]       bus_width;
reg             [2:0]       bus_speed_select;
reg             [2:0]       abort_sel;
wire            [17:0]      reg_addr;
wire            [17:0]      main_cis_addr;

//wire            [7:0]       cccr_value;



//submodules
//asynchronous logic
assign  main_cis_addr   = `MAIN_CIS_START_ADDR;
//assign  cccr_value      = cccr_map[i_address];
assign  o_data_out      = cccr_map[i_address];

assign  o_1_bit_mode    = (bus_width == `D1_BIT_MODE);
assign  o_4_bit_mode    = (bus_width == `D4_BIT_MODE);
assign  o_8_bit_mode    = (bus_width == `D8_BIT_MODE);

assign  o_sdr_12        = (bus_speed_select == `SDR12);
assign  o_sdr_25        = (bus_speed_select == `SDR25);
assign  o_sdr_50        = (bus_speed_select == `SDR50);
assign  o_ddr_50        = (bus_speed_select == `DDR50);
assign  o_sdr_104       = (bus_speed_select == `SDR104);

assign  o_driver_type_a = (driver_type == `DRIVER_TYPE_A);
assign  o_driver_type_b = (driver_type == `DRIVER_TYPE_B);
assign  o_driver_type_c = (driver_type == `DRIVER_TYPE_C);
assign  o_driver_type_d = (driver_type == `DRIVER_TYPE_D);

//Read Only
assign  cccr_map[`CCCR_SDIO_REV_ADDR   ] = {`SDIO_VERSION, `CCCR_FORMAT};
assign  cccr_map[`SD_SPEC_ADDR         ] = {4'h0, `SD_PHY_VERSION};
assign  cccr_map[`IO_FUNC_ENABLE_ADDR  ] = o_func_enable;
assign  cccr_map[`IO_FUNC_READY_ADDR   ] = i_func_ready;
assign  cccr_map[`INT_ENABLE_ADDR      ] = o_func_int_enable;
assign  cccr_map[`INT_PENDING_ADDR     ] = i_func_int_pending;
assign  cccr_map[`IO_ABORT_ADDR        ] = {4'h0, o_soft_reset, abort_sel};
assign  cccr_map[`BUS_IF_CONTROL_ADDR  ] = {o_en_card_detect_n, `SCSI, 2'b00, o_enable_spi_interrupt, `S8B, bus_width};
assign  cccr_map[`CARD_COMPAT_ADDR     ] = {`S4BLS, `LSC, o_en_4bit_block_int, `S4MI, `SBS, `SRW, `SMB, `SDC};
assign  cccr_map[`CARD_CIS_LOW_ADDR    ] = main_cis_addr[7:0];
assign  cccr_map[`CARD_CIS_MID_ADDR    ] = main_cis_addr[15:8];
assign  cccr_map[`CARD_CIS_HIGH_ADDR   ] = {6'b000000, main_cis_addr[17:16]};
assign  cccr_map[`BUS_SUSPEND_ADDR     ] = {6'b000000, o_bus_release_req_stb, i_data_bus_busy};
assign  cccr_map[`FUNC_SELECT_ADDR     ] = {i_data_read_avail, 3'b000, o_func_select};
assign  cccr_map[`EXEC_SELECT_ADDR     ] = {i_func_exec_status};
assign  cccr_map[`READY_SELECT_ADDR    ] = {i_func_ready_for_data};
assign  cccr_map[`FN0_BLOCK_SIZE_0_ADDR] = {o_f0_block_size[7:0]};
assign  cccr_map[`FN0_BLOCK_SIZE_1_ADDR] = {o_f0_block_size[15:8]};
assign  cccr_map[`POWER_CONTROL_ADDR   ] = {4'h0, `TPC,`EMPC, `SMPC};
assign  cccr_map[`BUS_SPD_SELECT_ADDR  ] = {4'h0, bus_speed_select, `SHS};
assign  cccr_map[`UHS_I_SUPPORT_ADDR   ] = {5'h0, `SSDR50, `SSDR104, `SSDR50};
assign  cccr_map[`DRIVE_STRENGTH_ADDR  ] = {2'b00, driver_type, 1'b0, `SDTC, `SDTC, `SDTA};
assign  cccr_map[`INTERRUPT_EXT_ADDR   ] = {6'h00, o_enable_async_interrupt, `SAI};

//synchronous logic
always @ (posedge clk) begin
  //De-assert strobes
  o_soft_reset              <=  0;
  o_func_abort_stb          <=  8'h0;
  abort_sel                 <=  0;
  o_bus_release_req_stb     <=  0;

  if (rst) begin
    state                   <=  IDLE;

    o_func_enable           <=  8'h0; //No functions are enabled
    o_func_int_enable       <=  8'h0; //No function interrupts are enabled

    o_en_4bit_block_int     <=  0;
    o_en_card_detect_n      <=  0;
    o_en_4bit_block_int     <=  0;

    o_en_4bit_block_int     <=  0;  //Do not enable this in SDR50, SDR104, DDR50 modes

    o_func_select           <=  0;
    o_f0_block_size     <=  0;  //Max Block Size is set by host
    bus_speed_select        <=  0;
    driver_type             <=  0;
    o_enable_async_interrupt<=  0;
    o_enable_spi_interrupt  <=  0;
    bus_width               <=  0;


  end
  else begin
    if (abort_sel == 0) begin
      o_func_abort_stb                    <=  0;
    end
    else begin
      o_func_abort_stb[abort_sel]         <=  1;
    end

    if (i_activate) begin
      if (i_data_stb) begin
        if (i_write_flag) begin
          case (i_address)
            `IO_FUNC_ENABLE_ADDR:
              o_func_enable             <=  i_data_in;
            `INT_ENABLE_ADDR:
              o_func_int_enable         <=  i_data_in;
            `IO_ABORT_ADDR: begin
              o_soft_reset              <=  i_data_in[3];
              abort_sel                 <=  i_data_in[2:0];
            end
            `BUS_IF_CONTROL_ADDR: begin
              o_en_card_detect_n        <=  i_data_in[7];
              bus_width                 <=  i_data_in[1:0];
              o_enable_spi_interrupt    <=  i_data_in[5];
            end
            `BUS_SUSPEND_ADDR:
              o_bus_release_req_stb     <=  i_data_in[1];
            `FUNC_SELECT_ADDR:
              o_func_select             <=  i_data_in[3:0];
            `FN0_BLOCK_SIZE_0_ADDR:
              o_f0_block_size[7:0]      <=  i_data_in;
            `FN0_BLOCK_SIZE_1_ADDR:
              o_f0_block_size[15:8]     <=  i_data_in;
            `BUS_SPD_SELECT_ADDR:
              bus_speed_select          <=  i_data_in[3:1];
            `DRIVE_STRENGTH_ADDR:
              driver_type               <=  i_data_in[6:4];
            `INTERRUPT_EXT_ADDR:
              o_enable_async_interrupt  <=  i_data_in[1];

            default: begin
            end
          endcase
        end
      end
    end
  end
end




endmodule
