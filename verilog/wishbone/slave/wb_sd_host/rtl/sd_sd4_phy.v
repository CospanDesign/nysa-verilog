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
 * Author: Dave McCoy (dave.mccoy@cospandesign.com)
 * Description: Phy layer SD host controller for 1 bit SD mode
 *    When the i_data_en signal goes high the core will read in the
 *    i_write_flag.
 *    Writing:
 *      If high then it will read in the i_data_h2s data until
 *      it reads i_data_count bytes from the host, each i_data_stb will tell
 *      the above phy to present a new byte to on the i_data_h2s register.
 *
 *    Reading:
 *      read the number of bytes on i_data_count. when a new byte is finished
 *      the new byte will be on o_data_s2h.
 *
 *    To activate a transaction set i_en along with i_write_flag to 1 for write
 *    or 0 for read, the core will strobe in/out data on it's own, it's
 *    up to the above layer to make sure there is enough data or space
 *    available, the maximum space should be 2048 bytes. when a transaction is
 *    finished the o_finished flag will go high, the controlling core must
 *    de-assert i_en in order to reset the core to get ready for new
 *    transactions. This signal will go high for one clock cycle if the host
 *    de-asserts i_en before a transaction is finished.
 *
 *    clk           : sdio_clk
 *    rst           : reset core
 *    i_en          : Enable a data transaction
 *    o_finished    : transaction is finished (de-assert i_en to reset)
 *    i_write_flag  : 1 = Write, 0 = Read
 *    i_data_h2s    : Data from host to SD card
 *    o_data_h2s    : Data from SD card to host
 *    i_data_count  : Number of bytes to read/write
 *    o_data_stb    : request or strobe in a byte
 *    o_crc_err     : CRC error occured during read
 *    o_sd_data_dir : Direction of the data
 *    i_sd_data     : raw data in
 *    o_sd_data     : raw data out
 *
 * Changes:
 *  2015.08.24: Initial commit
 */


//RIGHT NOW WE ARE ALWAYS ENABLED!

module sd_sd4_phy (
  input                     clk,
  input                     clk_x2,
  input                     rst,

//  input                     ddr_en, //ALWAYS ENABLED FOR NOW!
  input                     i_en,
  output  reg               o_finished,
  input                     i_write_flag,

  output  reg               o_crc_err,      //Detected a CRC error during read

  output  reg               o_data_stb,
  input       [11:0]        i_data_count,
  input       [7:0]         i_data_h2s,
  output  reg [7:0]         o_data_s2h,

  output                    o_sd_data_dir,
  input       [7:0]         i_sd_data,
  output      [7:0]         o_sd_data

);
//local parameters
localparam  IDLE          = 4'h0;
localparam  WRITE         = 4'h2;
localparam  WRITE_CRC     = 4'h3;
localparam  WRITE_FINISHED= 4'h4;
localparam  READ_START    = 4'h5;
localparam  READ          = 4'h6;
localparam  READ_CRC      = 4'h7;
localparam  FINISHED      = 4'h8;

//registes/wires
reg       [3:0]             state;
reg       [7:0]             sd_data;
wire                        sd_data_bit;
wire      [15:0]            gen_crc[0:3];
reg       [15:0]            crc[0:3];
reg                         crc_rst;
reg                         crc_en;
wire                        sd_clk;
reg                         posedge_clk;
wire      [3:0]             crc_sd_bit;
wire      [7:0]             in_remap;
reg       [11:0]            data_count;

integer                     i = 0;

//submodules

//Generate 4 Copies of the CRC, data will be read in and out in parallel
genvar gv_crc;
generate
for (gv_crc = 0; gv_crc > 3; gv_crc = gv_crc + 1) begin
sd_crc_16 crc16 (
  .clk          (clk_x2             ),
  .rst          (crc_rst            ),
  .en           (crc_en             ),  //Need to make sure this CRC_EN goes low when a new clock cycle starts, may need mealy state machine
  .bitval       (crc_sd_bit[gv_crc] ),
  .crc          (gen_crc[gv_crc]    )
);
assign  crc_sd_bit  = posedge_clk ? io_sd_data[7 - gv_crc] : io_sd_data[7 - gv_crc - 4];

end
endgenerate

//asynchronous logic
assign  o_sd_data_dir = i_write_flag;
assign  in_remap   = { i_sd_data[0],
                       i_sd_data[1],
                       i_sd_data[2],
                       i_sd_data[3],
                       i_sd_data[4],
                       i_sd_data[5],
                       i_sd_data[6],
                       i_sd_data[7]};

assign  o_sd_data  = { sd_data[0],
                       sd_data[1],
                       sd_data[2],
                       sd_data[3],
                       sd_data[4],
                       sd_data[5],
                       sd_data[6],
                       sd_data[7]};



//synchronous logic
always @ (posedge clk_x2) begin
  if (clk) begin
    posedge_clk   <=  1;
  end
  else begin
    posedge_clk   <=  0;
  end
end

always @ (posedge clk) begin
  //De-assert Strobes
  o_data_stb          <=  0;

  if (rst) begin
    sd_data           <=  0;
    state             <=  IDLE;
    crc_rst           <=  1;
    crc_en            <=  0;
    o_finished        <=  0;
    data_count        <=  0;
    o_crc_err         <=  0;
    for (i = 0; i < 4; i = i + 1) begin
      crc[i]          <=  16'h0000;
    end
  end
  else begin
    case (state)
      IDLE: begin
        crc_en        <=  0;
        crc_rst       <=  1;
        o_finished    <=  0;
        data_count    <=  0;
        o_crc_err     <=  0;
        sd_data       <=  8'hFF;
        if (i_en) begin
          crc_rst     <=  0;
          if(i_write_flag) begin
            state     <=  WRITE;
            sd_data   <=  8'h00;  //Is this only on the positive edge we need this start bit to be set?
            crc_en    <=  1;
          end
          else begin
            state     <=  READ_START;
          end
        end
      end
      WRITE: begin
        sd_data           <=  i_data_h2s;
        data_count        <=  data_count + 1;
        o_data_stb        <=  1;
        if (data_count >= i_data_count) begin
          state           <=  WRITE_CRC;
          for (i = 0; i < 4; i = i + 1) begin
            crc[i]        <=  gen_crc[i];
          end
          crc_en          <=  0;
          data_count      <=  0;
        end
      end
      WRITE_CRC: begin
        sd_data           <=  {crc[0][0], crc[1][0], crc[2][0], crc[3][0],
                               crc[0][1], crc[1][1], crc[2][1], crc[3][1]};
        for (i = 0; i < 4; i = i + 1) begin
          crc[i]          <=  {crc[i][13:0], 2'b0};
        end
        data_count        <=  data_count + 1;
        if (data_count >= 7) begin
          state           <=  WRITE_FINISHED;
        end
      end
      WRITE_FINISHED: begin
        //Pass through, assign statement will set the value to 1
        state             <=  FINISHED;
      end
      READ_START: begin
        //Wait for data bit to go low
        if (!in_remap[0]) begin
          crc_en          <=  1;
          state           <=  READ;
        end
      end
      READ: begin
        //Shift the bits in
        o_data_s2h        <=  in_remap;
        o_data_stb        <=  1;  //Will this give me enough time for the new data to get clocked in?
        if (data_count < i_data_count) begin
          data_count      <=  data_count + 1;
        end
        else begin
          //Finished reading all bytes
          state           <=  READ_CRC;
          crc_en          <=  0;    //XXX: should this be in the previous state??
          data_count      <=  0;
        end
      end
      READ_CRC: begin
        crc[0][0]         <=  in_remap[0];
        crc[0][1]         <=  in_remap[1];
        crc[1][0]         <=  in_remap[2];
        crc[1][1]         <=  in_remap[3];
        crc[2][0]         <=  in_remap[4];
        crc[2][1]         <=  in_remap[5];
        crc[3][0]         <=  in_remap[6];
        crc[3][1]         <=  in_remap[7];

        for (i = 0; i < 4; i = i + 1) begin
          crc[i]          <=  {crc[i][13:0], 2'b0};
        end
        if (data_count >= 7) begin
          state           <=  FINISHED;
        end
      end
      FINISHED: begin
        o_finished        <=  1;
        if (crc[0]        <=  gen_crc[0]) begin
          o_crc_err       <=  1;
        end
        if (crc[1]        <=  gen_crc[1]) begin
          o_crc_err       <=  1;
        end
        if (crc[2]        <=  gen_crc[2]) begin
          o_crc_err       <=  1;
        end
        if (crc[3]        <=  gen_crc[3]) begin
          o_crc_err       <=  1;
        end

        if (!i_en) begin
          o_finished      <=  0;
          state           <=  IDLE;
        end
      end
      default: begin
      end
    endcase
  end
end



endmodule
