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
 * Description: Function Basic Register (FBR)
 *  Minimal information required to use a function in SDIO
 *
 * Changes:
 *  2015.08.16: Initial Commit
 */

module sdio_fbr #(
    parameter               INDEX           =   0,
    parameter               FUNC_TYPE       =   4'h0,
    parameter               FUNC_TYPE_EXT   =   4'h0,
    parameter               SUPPORT_PWR_SEL =   1'b0,
    parameter               CSA_SUPPORT     =   0,
    parameter               CSA_OFFSET      =   0,
    parameter               CIS_OFFSET      =   0,
    parameter               BLOCK_SIZE      =   256
)(
  input                     clk,
  input                     rst,

  //Function Configuration
  output  reg               o_csa_en,
  output  reg   [3:0]       o_pwr_mode,
  output  reg   [15:0]      o_block_size,

  input                     i_activate,
  input                     i_write_flag,
  input         [7:0]       i_address,
  input                     i_data_stb,
  input         [7:0]       i_data_in,
  output  reg   [7:0]       o_data_out

);
//local parameters
localparam     PARAM1  = 32'h00000000;
//registes/wires
wire            [7:0]       fbr [18:0];
wire            [23:0]      cis_addr;
wire            [15:0]      vendor_id = `VENDOR_ID;
wire            [15:0]      product_id  = `PRODUCT_ID; 
wire                        csa_support = CSA_SUPPORT;
wire            [3:0]       func_type_ext = FUNC_TYPE_EXT;
wire                        support_pwr_sel = SUPPORT_PWR_SEL;
//submodules
//asynchronous logic
assign  cis_addr                        = CIS_OFFSET;


assign  fbr[`FBR_FUNC_ID_ADDR]          = {o_csa_en, csa_support, 2'b00, FUNC_TYPE};
assign  fbr[`FBR_FUNC_EXT_ID_ADDR]      = {4'h0, func_type_ext};
assign  fbr[`FBR_POWER_SUPPLY_ADDR]     = {o_pwr_mode, 3'b000, support_pwr_sel};
assign  fbr[`FBR_ISDIO_FUNC_ID_ADDR]    = {8'h00};
assign  fbr[`FBR_MANF_ID_LOW_ADDR]      = {vendor_id[15:8]};
assign  fbr[`FBR_MANF_ID_HIGH_ADDR]     = {vendor_id[7:0]};
assign  fbr[`FBR_PROD_ID_LOW_ADDR]      = {product_id[15:8]};
assign  fbr[`FBR_PROD_ID_HIGH_ADDR]     = {product_id[7:0]};
assign  fbr[`FBR_ISDIO_PROD_TYPE]       = {8'h00};
assign  fbr[`FBR_CIS_LOW_ADDR]          = {cis_addr[23:16]};
assign  fbr[`FBR_CIS_MID_ADDR]          = {cis_addr[23:16]};
assign  fbr[`FBR_CIS_HIGH_ADDR]         = {cis_addr[23:16]};
assign  fbr[`FBR_CSA_LOW_ADDR]          = {8'h00}; //CSA Address
assign  fbr[`FBR_CSA_MID_ADDR]          = {8'h00}; //CSA Address
assign  fbr[`FBR_CSA_HIGH_ADDR]         = {8'h00}; //CSA Address
assign  fbr[`FBR_DATA_ACC_ADDR]         = {8'h00}; //CSA Data Access
assign  fbr[`FBR_BLOCK_SIZE_LOW_ADDR]   = {o_block_size[7:0]};
assign  fbr[`FBR_BLOCK_SIZE_HIGH_ADDR]  = {o_block_size[15:8]};

//synchronous logic
always @ (posedge clk) begin
  if (rst) begin
    o_pwr_mode              <=  0;
    o_data_out              <=  0;
    o_csa_en                <=  0;
    o_block_size            <=  BLOCK_SIZE;
  end
  else begin
    if (i_activate) begin
      if (i_data_stb) begin
        if (i_write_flag) begin
          case(i_address)
            `FBR_FUNC_ID_ADDR:
              o_csa_en            <=  i_data_in[3];
            `FBR_POWER_SUPPLY_ADDR:
              o_pwr_mode          <=  i_data_in[7:5];
            `FBR_BLOCK_SIZE_LOW_ADDR:
              o_block_size[7:0]   <=  i_data_in;
            `FBR_BLOCK_SIZE_HIGH_ADDR:
              o_block_size[15:8]  <=  i_data_in;
            default: begin
            end 
          endcase
        end
        else begin
          o_data_out          <=  fbr[i_address];
        end
      end
    end
  end
end

endmodule
