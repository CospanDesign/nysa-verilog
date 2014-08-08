/*
Distributed under the MIT license.
Copyright (c) 2012 Dave McCoy (dave.mccoy@cospandesign.com)

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

`include "logic_analyzer_defines.v"

module logic_analyzer #(
  parameter CAPTURE_WIDTH    = 32,
  parameter CAPTURE_DEPTH    = 10
)(

  input                               rst,
  input                               clk,

  //logic analyzer capture data
  input                               cap_clk,
  input                               cap_external_trigger,
  input       [31:0]                  cap_data,
  input       [31:0]                  clk_div,
  input                               clk_select,

  //logic analyzer control
  input       [31:0]                  trigger,
  input       [31:0]                  trigger_mask,
  input       [31:0]                  trigger_after,
  input       [31:0]                  trigger_edge,
  input       [31:0]                  both_edges,
  input       [31:0]                  repeat_count,
  input                               set_strobe,
  input                               enable,
  input                               restart,
  output                              finished,

  output  reg [CAPTURE_DEPTH - 1: 0]  capture_start,
  input                               data_out_read_strobe,
  output      [31:0]                  data_out_read_size,
  output      [31:0]                  data_out

);
localparam FIFO_WIDTH = (1 << CAPTURE_DEPTH);
localparam FIFO_DEPTH = (FIFO_WIDTH - 1);
//localparams

//capture states
localparam       IDLE      = 0;
localparam       SETUP     = 1;
localparam       CONT_READ = 2;
localparam       CAPTURE   = 3;
localparam       FINISHED  = 4;


//read states
localparam       READ      = 1;


//reg/wires
reg     [CAPTURE_DEPTH - 1: 0]        in_pointer;
reg     [CAPTURE_DEPTH - 1: 0]        out_pointer;
reg     [CAPTURE_DEPTH - 1: 0]        start;
wire    [CAPTURE_DEPTH - 1: 0]        last;
wire                                  full;
wire                                  empty;

reg     [3:0]                         cap_state;
reg                                   cap_write_strobe;
wire                                  cap_start;
wire                                  cap_pos_start;
wire                                  cap_neg_start;

reg                                   div_clk;
wire                                  out_clk;
reg     [31:0]                        clk_count;

reg     [3:0]                         read_state;
reg     [31:0]                        rep_count;
reg     [31:0]                        prev_cap;
wire    [31:0]                        cap_pos_edge;
wire    [31:0]                        cap_neg_edge;
wire    [31:0]                        cap_sig_start;



//submodules
dual_port_bram #(
  .DATA_WIDTH(CAPTURE_WIDTH),
  .ADDR_WIDTH(CAPTURE_DEPTH)
) dpb (
  //Port A
  .a_clk     (cap_clk          ),
  .a_wr      (cap_write_strobe ),
  .a_addr    (in_pointer       ),
  .a_din     (prev_cap         ),

  //Port B
  .b_clk     (clk              ),
  .b_wr      (1'b0             ),
  .b_addr    (out_pointer      ),
  .b_din     (0                ),
  .b_dout    (data_out         )

);

//asynchronous logic

assign  data_out_read_size  = (FIFO_WIDTH);
//assign  last                = start - 1;
assign  last                = start + (FIFO_DEPTH - trigger_after);
assign  full                = (in_pointer == last);
assign  empty               = ((out_pointer == last) && (finished));
//this may not be the best place for this
assign  finished            = (cap_state == FINISHED);

assign cap_start            = cap_sig_start == 32'hFFFFFFFF;

genvar i;
generate
  for (i = 0; i < 32; i = i + 1) begin : tsbuf
    assign cap_pos_edge[i] = cap_data[i] & ~prev_cap[i];
    assign cap_neg_edge[i] = ~cap_data[i] & prev_cap[i];
    assign cap_sig_start[i]   =
            (~trigger_mask[i]) ? 1 :                                            //if the mask is 0 then this is true
              (trigger_edge[i]) ?                                               //if edge trigger is enabled
                (both_edges[i] & (cap_pos_edge[i] | cap_neg_edge[i])) |         //if both edges detected
                (trigger[i] & cap_pos_edge[i]) | (~trigger[i] & cap_neg_edge[i]) : //if only one edge is sensative
              (trigger[i] & cap_data[i]) | (~trigger[i] & ~cap_data[i]);        //not edge but level and data matches
  end
endgenerate

always @ (posedge cap_clk) begin
  if (rst) begin
    in_pointer            <=  0;
    start                 <=  0;
    capture_start         <=  0;
    cap_state             <=  IDLE;
    rep_count             <=  0;
    cap_write_strobe      <=  0;
    prev_cap              <=  0;
  end
  else begin
    prev_cap              <=  cap_data;
    cap_write_strobe      <=  0;
    //if trigger_after > 0 then I have to continuously read data
    case (cap_state)
      IDLE: begin
        if (enable) begin
          if (trigger_after > 0 || repeat_count > 0) begin
            //this is the special case where we need to continus reading data
            //all the time just in case a trigger even happens we have the history
            in_pointer          <=  start;
            rep_count           <=  repeat_count;
            cap_state           <=  CONT_READ;
          end
          else begin
            start               <=  0;
            in_pointer          <=  0;
            capture_start       <=  0;
            if (cap_start) begin
              cap_state         <=  CAPTURE;
              cap_write_strobe  <=  1;
              in_pointer        <=  in_pointer + 1;
            end
            if (cap_external_trigger) begin
              cap_state         <=  CAPTURE;
              cap_write_strobe  <=  1;
              in_pointer        <=  in_pointer + 1;
            end
          end
        end

        if (set_strobe) begin
          cap_state             <=  SETUP;
        end
      end
      SETUP: begin
        rep_count               <=  repeat_count;
        start                   <=  0;
        in_pointer              <=  0;
        cap_state               <=  IDLE;
      end
      CONT_READ: begin
        if (set_strobe) begin
          cap_state             <=  SETUP;
        end
        else if (enable) begin
          cap_write_strobe      <=  1;
          start                 <=  start + 1;
          //in_pointer            <=  start + trigger_after;
          in_pointer            <=  start;
          if (cap_start) begin
            if (rep_count == 0) begin
              $display ("logic_analyzer: Capture! @ %t", $time);
              cap_state         <=  CAPTURE;
            end
            else begin
              rep_count         <=  rep_count - 1;
            end
          end
        end
      end
      CAPTURE: begin
        if (enable) begin
          if (full) begin
            cap_state           <=  FINISHED;
            //capture_start       <=  last - data_out_read_size;
            capture_start       <=  last + 1;
          end
          else begin
            cap_write_strobe    <=  1;
            in_pointer          <=  in_pointer + 1;
          end
        end
      end
      FINISHED: begin
        if (!enable || restart) begin
          cap_state             <=  IDLE;
        end
      end
      default: begin
        cap_state               <=  IDLE;
      end
    endcase
  end
end


//Reading state
always @ (posedge clk) begin
  if (rst) begin
    out_pointer                 <=  0;
    read_state                  <=  IDLE;
  end
  else begin
    
    case (read_state)
      IDLE: begin
        if (finished) begin
          //out_pointer           <=  capture_start;
          out_pointer           <=  last + 1;
          //out_pointer           <=  in_pointer - data_out_read_size;
          read_state            <=  READ;
        end
      end
      READ: begin
        if (cap_state == FINISHED && enable) begin
          if (data_out_read_strobe) begin
            out_pointer         <=  out_pointer + 1;
          end
          if (empty) begin
            read_state               <=  IDLE;
          end
        end
        else begin
          read_state                 <=  IDLE;
        end
      end
      default: begin
        read_state                 <=  IDLE;
      end
    endcase
  end
end

endmodule
