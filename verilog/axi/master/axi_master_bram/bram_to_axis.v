/*
Distributed under the MIT license.
Copyright (c) 2018 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Author:
 * Description: Convert any size BRAM to any size AXI Stream
 *
 *  There are three conditions
 *  1. BRAM data width is the same as the AXI Stream Width
 *  2. BRAM data width is less than the the AXI Stream Width
 *  3. BRAM data width is greater than the AXI Stream Width
 *
 *  Strobe is a work in progress, currently it only supports modifying
 *  The strobes at the end of a transaction
 *  TODO: Support strobes at the beginning of a transaction
 *
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

`timescale 1ps / 1ps

`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   (x <= 32)    ? 5 :  \
   (x <= 64)    ? 6 :  \
   (x <= 128)   ? 7 :  \
   (x <= 256)   ? 8 :  \
   (x <= 512)   ? 9 :  \
   (x <= 1024)  ? 10 : \
   (x <= 2048)  ? 11 : \
   (x <= 4096)  ? 12 : \
   -1


module bram_to_axis #(
  parameter     BRAM_DATA_WIDTH       = 32,
  parameter     BRAM_ADDR_WIDTH       = 10,
  parameter     AXIS_DATA_WIDTH       = 32,
  parameter     AXIS_STROBE_WIDTH     = (AXIS_DATA_WIDTH >> 3),
  parameter     AXIS_MAX_BURST_LENGTH = 256,
  parameter     AXIS_BRAM_BYTE_DEPTH  = CLOG2(AXIS_MAX_BURST_LENGTH),
  parameter     DECOUPLE_DEPTH        = 4,
  parameter     DECOUPLE_COUNT_SIZE   = 2
)(
  input                                       clk,
  input                                       rst,
  //Command
  input       [AXIS_BRAM_BYTE_DEPTH - 1: 0]   i_byte_write_size,
  input                                       i_en,
  output  reg                                 o_ack,

  //BRAM Interface
  input                                       i_bram_data_valid,
  input       [BRAM_DATA_WIDTH - 1: 0]        i_bram_data,
  input       [BRAM_ADDR_WIDTH - 1: 0]        i_bram_size,
  output  reg [BRAM_ADDR_WIDTH - 1: 0]        o_bram_addr,

  //AXIS Interface
  output                                      o_axis_valid,
  input                                       i_axis_ready,
  output      [AXIS_DATA_WIDTH - 1: 0]        o_axis_data,
  output      [AXIS_STROBE_WIDTH - 1: 0]      o_axis_strobe
);

localparam                        AXIS_BYTE_WIDTH = CLOG2(AXIS_DATA_WIDTH);
localparam                        BRAM_BYTE_WIDTH = CLOG2(BRAM_DATA_WIDTH);
//local parameters
localparam                        IDLE        = 0;
localparam                        BRAM_START  = 1;
localparam                        BRAM_DELAY  = 2;
localparam                        BRAM_READ   = 3;
localparam                        BRAM_FIN    = 4;
//registes/wires
reg [3:0]                         state;

reg   [AXIS_BRAM_BYTE_DEPTH - 1: 0] r_byte_count;
wire  [AXIS_BRAM_BYTE_DEPTH - 1: 0] w_byte_count_next;
//Account for byte sizes for 4096
wire  [9: 0]                        w_bram_inc;
wire  [9: 0]                        w_axis_inc;

//submodules
//asynchronous logic
assign  w_bram_inc    = BRAM_BYTE_WIDTH;
assign  w_axis_inc    = AXIS_BYTE_WIDTH;
assign  w_fifo_enable = (state != IDLE) && (w_full || (state == BRAM_FIN)); //XXX: Not sure if this is going to work
//assign  w_byte_count_next = (r_byte_count + w_axis_inc);
//synchronous logic

integer i;
integer j;

`define FIFO_DATA_SECTION   AXIS_STROBE_WIDTH + AXIS_DATA_WIDTH -1: AXIS_STROBE_WIDTH
`define FIFO_STROBE_SECTION AXIS_STROBE_WIDTH - 1: 0

/*****************************************************************************/
if (BRAM_DATA_WIDTH == AXIS_DATA_WIDTH) begin
//Need a FIFO for the decoupled depth
reg [DECOUPLE_COUNT_SIZE - 1: 0]    r_start;
reg [DECOUPLE_COUNT_SIZE - 1: 0]    r_end;
reg [(AXIS_DATA_WIDTH + BRAM_BYTE_WIDTH) - 1: 0]        r_axis_fifo[0:DECOUPLE_DEPTH - 1];
wire                                w_empty;
wire                                w_full;
wire                                w_almost_full;
wire                                w_last;
wire  [AXIS_DATA_WIDTH - 1: 0]      w_current_data;

wire                                w_fifo_enable;
reg   [AXIS_BYTE_WIDTH - 1: 0]      r_axis_strobe;

assign  w_empty       = (w_start == w_end);
assign  w_full        = (w_end == (1 << DECOUPLE_COUNT_SIZE) - 1) ? (w_start == 0) : ((w_end + 1) == w_start);
assign  w_almost_full = (w_end == (1 << DECOUPLE_COUNT_SIZE) - 2) ? (w_start == 0) : (w_end == (1 << DECOUPLE_COUNT_SIZE) - 1);
assign  w_last        = (w_start == (1 << DECOUPLE_COUNT_SIZE) - 1) ? (w_end == 0) : ((w_start + 1) == w_end);
assign  o_axis_valid  = !w_empty && w_fifo_enable;


assign  o_axis_data   = r_axis_fifo[w_start][FIFO_DATA_SECTION];
assign  o_axis_strobe = r_axis_fifo[w_start][FIFO_STROBE_SECTION];
always @ (posedge clk) begin
  o_ack               <=  0;
  if (rst) begin
    r_start           <=  0;
    r_end             <=  0;

    r_byte_count      <=  0;
    o_bram_addr       <=  0;
    state             <=  IDLE;
    r_axis_strobe     <=  (AXIS_BYTE_WIDTH - 1);
  end
  else begin
    case (state)
      IDLE: begin
        r_byte_count  <=  0;
        o_bram_addr   <=  0;
        if (i_en && (i_byte_write_size > 0)) begin
          state       <=  BRAM_START;
        end
      end
      BRAM_START: begin
        /*
          The first peice of data from the FIFO is always available
        */
        if (!w_full) begin
          r_end         <=  r_end + 1;
          o_bram_addr   <=  o_bram_addr + 1;
          r_byte_count  <=  r_byte_count + w_axis_inc;
          r_axis_fifo[w_end][FIFO_DATA_SECTION]   <=  i_bram_data;
          r_axis_fifo[w_end][FIFO_STROBE_SECTION] <=  (AXIS_BYTE_WIDTH - 1);
          if ((r_byte_count + w_axis_inc) >= i_byte_write_size) begin
            state       <=  BRAM_FIN;
            if (r_byte_count + w_axis_inc > i_byte_write_size) begin
              for (i = 0; i < AXIS_BYTE_WIDTH; i = i + 1) begin
                if ((r_byte_count + w_axis_inc + i) > i_byte_write_size)
                  r_axis_fifo[w_start][i] <= 0;
                else
                  r_axis_fifo[w_start][i] <= 1;
              end
            end
          end
          else begin
            state       <=  BRAM_DELAY;
          end
        end
      end
      BRAM_DELAY: begin
        /*
          When we want to get the second peice of data we need to wait one
          clock cycle for the data to be valid, so just fall through this
          step
        */
        if (o_bram_addr >= i_byte_write_size) begin
          state       <=  BRAM_FIN;
        end
        else if (w_full) begin
          state       <=  BRAM_START;
        end
        else begin
          state       <=  BRAM_READ;
        end

      end
      BRAM_READ: begin
        /*
          Condition where the address is updating and the data is valid
          at the same time. if the address is updated at the same speed
          data is exiting then data will continuously flow
        */
        if (w_full || w_almost_full) begin
          state       <=  BRAM_START;
        end
        else begin
          if ((r_byte_count + w_axis_inc) == i_byte_write_size) begin
            state       <=  BRAM_FIN;
          end
          else if ((r_byte_count + r_axis_inc) > i_byte_write_size) begin
            for (j = 0; j < AXIS_BYTE_WIDTH; j = j + 1) begin
              if ((r_byte_count + w_axis_inc + j) > i_byte_write_size)
                r_axis_fifo[w_start][j] <= 0;
              else
                r_axis_fifo[w_start][j] <= 1;
            end
          end

          r_axis_byte_count <=  r_axis_byte_count + w_axis_inc;
          o_bram_addr   <=  o_bram_addr + 1;
          o_end         <=  o_end + 1;
          r_axis_fifo[w_end][FIFO_DATA_SECTION]   <=  i_bram_data;
          r_axis_fifo[w_end][FIFO_STROBE_SECTION] <=  (AXIS_BYTE_WIDTH - 1);
        end
      end
      BRAM_FIN: begin
        o_axk         <=  1;
        if (!i_ack) begin
          state       <=  IDLE;
        end
      end
    endcase
  end
end

end
/*****************************************************************************/
else if (BRAM_DATA_WIDTH < AXIS_DATA_WIDTH) begin
reg   [AXIS_DATA_WIDTH - 1: 0]        o_axis_data;
reg   [AXIS_DATA_WIDTH - 1: 0]        r_axis_data;

always @ (posedge clk) begin
  o_ack               <=  0;
  if (rst) begin
    r_start           <=  0;
    r_end             <=  0;

    r_byte_count      <=  0;
    o_bram_addr       <=  0;
    state             <=  IDLE;

    o_axis_data       <=  0;
    r_axis_data       <=  0;  //Work In Progress Register
    o_axis_strobe     <=  (AXIS_STROBE_WIDTH - 1);
  end
  else begin
    case (state)
      IDLE: begin
      end
      BRAM_START: begin
      end
      BRAM_FIN: begin
        o_axk         <=  1;
        if (!i_ack) begin
          state       <=  IDLE;
        end
      end
      default: begin
        state         <=  IDLE;
      end
    endcase
  end
end

end

/*****************************************************************************/
else begin //BRAM_DATA_WIDTH > AXIS_DATA_WIDTH
/*
 Because the AXIS pipe is smaller than the BRAM pipe I don't
 Need to be worried about BRAM delay
 */
localparam                            BRAM_DIV = (BRAM_DATA_WIDTH / AXIS_DATA_WIDTH);
reg   [AXIS_DATA_WIDTH - 1: 0]        o_axis_data;
reg                                   o_axis_valid;
reg   [9:0]                           r_b2a_count;
wire  [AXIS_DATA_WIDTH - 1: 0]        w_bram_block_data[0: BRAM_DIV - 1];
wire                                  w_axis_active;
reg   [AXIS_DATA_WIDTH - 1: 0]        r_axis_data;


assign                                w_axis_active = (i_axis_ready && o_axis_valid);

//This will make it easier to select blocks out of
genvar gv;
generate
for (gv = 0; gv < BRAM_DIV; gv = gv + 1) begin : BRAM_DIV_LOOP
assign  w_bram_block_data[gv] = i_bram_data[(gv * AXIS_DATA_WIDTH) + (AXIS_DATA_WIDTH) - 1 : (gv * AXIS_DATA_WIDTH)];
end
endgenerate

reg r_axis_strobe;


always @ (posedge clk) begin
  o_ack               <=  0;
  if (rst) begin
    r_start           <=  0;
    r_end             <=  0;

    r_byte_count      <=  0;
    o_bram_addr       <=  0;
    state             <=  IDLE;

    o_axis_valid      <=  0;
    o_axis_data       <=  0;
    r_b2a_count       <=  0;
    r_axis_data       <=  0;
    r_axis_strobe     <=  (AXIS_STROBE_WIDTH - 1);
  end
  else begin
    if (w_axis_active) begin
      o_axis_valid    <=  0;
    end
    case (state)
      IDLE: begin
        r_byte_count  <=  0;
        r_b2a_count   <=  0;
        o_bram_addr   <=  0;
        r_axis_strobe  <=  (AXIS_STROBE_WIDTH - 1);
        if (i_en && (i_byte_write_size > 0)) begin
          state       <=  BRAM_READ;
        end
      end
      BRAM_DELAY: begin
        //Need a delay of one clock cycle for the data to go to the next clock
        state         <=  BRAM_READ;
      end
      BRAM_READ: begin
        if ((r_byte_count + w_axis_inc) == i_byte_write_size) begin
          //We're done
          state       <=  BRAM_FIN;
        end
        else begin
          if ((r_byte_count + w_axis_inc) > i_byte_write_size) begin
            //Unaligned transfer
            //Modify the strobes
            for (i = 0; i < AXIS_BYTE_WIDTH; i = i + 1) begin 
              if ((r_byte_count + w_axis_inc + i) > i_byte_write_size)
                r_axis_strobe[i]  <=  0;
              else begin
                r_axis_strobe[i]  <=  1;
            end
            state       <=  BRAM_FIN;
          end

          if (w_axis_active) begin
            o_axis_data   <=  w_bram_block_data[r_b2a_count];
            r_byte_count  <=  (r_byte_count + w_axis_inc);
            if (r_b2a_count >= BRAM_DIV - 1) begin
              //We are at the last element of the BRAM data
              state       <=  BRAM_DELAY;
              o_bram_addr <=  o_bram_addr + 1;
              r_b2a_count <=  r_b2a_count = 0;
            end
            else begin
              r_b2a_count <=  r_b2a_count + 1;
            end
          end
        end
      end
      BRAM_FIN: begin
        o_axk         <=  1;
        if (!i_ack) begin
          state       <=  IDLE;
        end
      end
      default: begin
        state         <=  IDLE;
      end
    endcase
  end
end
end

endmodule
