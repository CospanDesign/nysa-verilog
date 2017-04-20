/*
Distributed under the MIT license.
Copyright (c) 2017 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Description:
 *
 *  When the user enters a new character on i_char and strobes 'i_char_stb'
 *  then the it will be inserted into the buffer
 *
 *
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

`timescale 1ps / 1ps
`include "char_defines.v"

module character_buffer #(
  parameter CONSOLE_DEPTH       = 12,
  parameter FONT_WIDTH          = 5,
  parameter FONT_HEIGHT         = 8,
  parameter CHAR_IMAGE_WIDTH    = 80,
  parameter CHAR_IMAGE_HEIGHT   = 34,
  parameter CHAR_IMAGE_SIZE     = CHAR_IMAGE_WIDTH * CHAR_IMAGE_HEIGHT
)(
  input                     clk,
  input                     rst,

  input                     i_alt_func_en,
  input                     i_clear_screen_stb,

  input       [2:0]         i_tab_count,
  input                     i_char_stb,
  input       [7:0]         i_char,

  input                     i_read_frame_stb,
  input                     i_char_req_en,
  output  reg               o_char_rdy,
  output      [7:0]         o_char,

  //When new frame is strobed the address is put back to the beginning of the frame
  input                     i_scroll_en,
  input                     i_scroll_up_stb,
  input                     i_scroll_down_stb
);
//local parameters
localparam      IDLE                    = 0;
localparam      PROCESS_NORMAL_CHAR     = 1;
localparam      PROCESS_BACKSPACE       = 2;
localparam      PROCESS_CARRIAGE_RETURN = 3;
localparam      PROCESS_TAB             = 4;
localparam      CLEAR_BUFFER            = 5;

localparam      START_READ_FRAME        = 1;
localparam      START_READ_FRAME_DELAY  = 2;
localparam      GET_CHAR                = 3;
localparam      GET_CHAR_DELAY          = 4;


//registes/wires
reg         [3:0]                   in_state;
reg         [3:0]                   out_state;

reg                                 r_char_stb;
reg         [CONSOLE_DEPTH - 1:0]   r_write_addr_pos;
reg         [CONSOLE_DEPTH - 1:0]   r_write_addr_end;
wire        [CONSOLE_DEPTH - 1:0]   w_write_addr_start;


reg         [7:0]                   r_char;
reg         [2:0]                   r_tab_count;
wire        [7:0]                   w_char;
wire                                w_buf_full;
reg         [CONSOLE_DEPTH - 1: 0]  r_read_addr;
reg         [CONSOLE_DEPTH - 1: 0]  r_read_char_count;

reg         [CONSOLE_DEPTH - 1: 0]  r_start_frame_addr;
reg         [CONSOLE_DEPTH - 1: 0]  r_prev_line_addr;
reg         [CONSOLE_DEPTH - 1: 0]  r_curr_line_addr;
reg         [CONSOLE_DEPTH - 1: 0]  r_next_line_addr;

wire                                w_in_busy;
wire                                w_out_busy;

reg         [3:0]                   r_font_height_pos;
reg         [7:0]                   r_read_width_pos;


//*************** DEBUG ******************************************************

wire        [CONSOLE_DEPTH - 1: 0]  w_dbg_char_image_width = CHAR_IMAGE_WIDTH;
wire        [CONSOLE_DEPTH - 1: 0]  w_dbg_char_image_height = CHAR_IMAGE_HEIGHT;
wire        [CONSOLE_DEPTH - 1: 0]  w_dbg_char_image_size = CHAR_IMAGE_SIZE;

//****************************************************************************

//submodules
bram #(
  .DATA_WIDTH       (8                  ),
  .ADDR_WIDTH       (CONSOLE_DEPTH      )   //4096 Console Depth
) char_buffer (
  .clk              (clk                ),
  .rst              (rst                ),
  .en               (1'b1               ),
  .we               (r_char_stb         ),
  .write_address    (r_write_addr_pos   ),
  .read_address     (r_read_addr        ),
  .data_in          (r_char             ),
  .data_out         (o_char             )
);

//asynchronous logic
assign  w_in_busy     = (in_state != IDLE);
assign  w_out_busy    = (out_state != IDLE);
assign  w_buf_full    = (r_write_addr_pos == r_write_addr_end);
assign  w_write_addr_start  = r_write_addr_end + 1;

//synchronous logic

//Incomming state machine
always @ (posedge clk) begin
  r_char_stb              <=  0;
  if (rst) begin
    r_char                <=  0;
    r_write_addr_pos      <=  0;
    r_write_addr_end      <=  ((1 << CONSOLE_DEPTH) - 1);
    r_tab_count           <=  0;

    r_prev_line_addr      <=  (1 << CONSOLE_DEPTH) - CHAR_IMAGE_WIDTH;
    r_curr_line_addr      <=  0;
    r_next_line_addr      <=  CHAR_IMAGE_WIDTH;
    in_state              <=  CLEAR_BUFFER;
  end
  else begin

    case (in_state)
      IDLE: begin
        if (i_clear_screen_stb) begin
          r_char_stb          <=  1;
          r_char              <=  0;
          r_write_addr_pos    <=  0;
          r_write_addr_end    <=  0;
          in_state            <=  CLEAR_BUFFER;
        end
        else if (i_char_stb) begin
          if (i_alt_func_en) begin
            //Allows user to put in special characters like hearts and clovers
              r_tab_count <=  0;
            r_char        <=  i_char;
            in_state      <=  PROCESS_NORMAL_CHAR;
          end
          else begin
            case (i_char)
              `NUL: begin     //NULL Character
              end
              `SOH: begin     //Start of Header
              end
              `STX: begin     //Start of Text
              end
              `ETX: begin     //End of Text
              end
              `EOT: begin     //End of Transmission
              end
              `ENQ: begin     //Enquiry
              end
              `ACK: begin     //Ack
              end
              `BEL: begin     //Bing!
              end
              `BS : begin     //Backspace
                r_char      <=  0;
                r_char_stb  <=  1;
                in_state    <=  PROCESS_BACKSPACE;
              end
              `HT : begin     //Horizontal Tab
                in_state    <=  PROCESS_TAB;
              end
              `LF : begin     //Line Feed
                //Simplify this, only carriage return (goes to new line too)
              end
              `VT : begin     //Vertical Tab
              end
              `FF : begin     //Form Feed
              end
              `CR : begin     //Carriage Return
                r_char      <=  0;
                in_state    <=  PROCESS_CARRIAGE_RETURN;
              end
              `SO : begin     //Shift Out
              end
              `SI : begin     //Shift In
              end
              `DLE: begin     //Data Link Escape
              end
              `DC1: begin     //Device Control 1
              end
              `DC2: begin     //Device Control 2
              end
              `DC3: begin     //Device Control 3
              end
              `DC4: begin     //Device Control 4
              end
              `NAK: begin     //Nack
              end
              `SYN: begin     //Sync
              end
              `ETB: begin     //End of Transmission Block
              end
              `CAN: begin     //Cancel
              end
              `EM : begin     //End of Medium
              end
              `SUB: begin     //Substitue
              end
              `ESC: begin     //Escape
              end
              `FS : begin     //File Seperator
              end
              `GS : begin     //Group Seperator
              end
              `RS : begin     //Record Seperator
              end
              `US : begin     //Unit Seperator
              end
              `DEL: begin     //Delete
              end
              default: begin
                //Normal Character to put into the buffer
                r_char        <=  i_char;
                r_char_stb    <=  1;
                in_state      <=  PROCESS_NORMAL_CHAR;
              end
            endcase
          end
        end
      end
      PROCESS_NORMAL_CHAR: begin
        if (w_buf_full) begin
          r_write_addr_end      <= r_write_addr_end + 1;
        end
        r_write_addr_pos      <= r_write_addr_pos + 1;
        in_state              <=  IDLE;
      end
      PROCESS_BACKSPACE: begin
        if (r_write_addr_pos != w_write_addr_start) begin
          r_write_addr_pos    <= r_write_addr_pos - 1;
        end
        in_state              <=  IDLE;
      end
      PROCESS_CARRIAGE_RETURN: begin
        if (r_write_addr_pos < r_next_line_addr) begin
          r_char              <=  0;
          r_char_stb          <=  1;
          r_write_addr_pos    <=  r_write_addr_pos + 1;
        end
        else begin
          in_state            <=  IDLE;
        end
      end
      PROCESS_TAB: begin
        if (r_tab_count < i_tab_count) begin
          r_tab_count         <=  r_tab_count + 1;
          r_char              <=  0;
          r_char_stb          <=  1;
          if (w_buf_full) begin
            r_write_addr_end  <= r_write_addr_end + 1;
          end
          r_write_addr_pos    <= r_write_addr_pos + 1;
        end
        else begin
          in_state            <=  IDLE;
        end
      end
      CLEAR_BUFFER: begin
        if (!w_buf_full) begin
          r_char_stb          <=  1;
          if (r_char_stb) begin
            r_char              <=  0;
            r_write_addr_pos    <=  r_write_addr_pos + 1;
            r_write_addr_end    <=  ((1 << CONSOLE_DEPTH) - 1);
          end
        end
        else begin
          r_write_addr_pos    <=  0;
          r_write_addr_end    <=  ((1 << CONSOLE_DEPTH) - 1);
          in_state            <=  IDLE;
        end
      end
      default: begin
        in_state              <=  IDLE;
      end
    endcase

    if (r_write_addr_pos >= r_next_line_addr) begin
      r_prev_line_addr        <=  r_prev_line_addr + CHAR_IMAGE_WIDTH;
      r_curr_line_addr        <=  r_curr_line_addr + CHAR_IMAGE_WIDTH;
      r_next_line_addr        <=  r_next_line_addr + CHAR_IMAGE_WIDTH;
    end
    if (r_write_addr_pos < r_curr_line_addr) begin
      r_next_line_addr        <=  r_next_line_addr - CHAR_IMAGE_WIDTH;
      r_curr_line_addr        <=  r_curr_line_addr - CHAR_IMAGE_WIDTH;
      r_prev_line_addr        <=  r_prev_line_addr - CHAR_IMAGE_WIDTH;
    end
  end
end

//Outgoing state machine
always @ (posedge clk) begin
  o_char_rdy                    <=  0;
  if (rst) begin
    r_read_addr                 <=  0;
    r_read_char_count           <=  0;
    r_read_width_pos            <=  0;
    r_start_frame_addr          <=  0;
    out_state                   <=  IDLE;

    r_font_height_pos           <=  0;
    o_char_rdy                  <=  0;
  end
  else begin
    case (out_state)
      IDLE: begin
        o_char_rdy              <=  0;
        r_font_height_pos       <=  0;
        if (i_read_frame_stb) begin
          out_state             <=  START_READ_FRAME;
        end
      end
      START_READ_FRAME: begin
        if (!w_in_busy) begin
          //Don't start outputting the data until the in state is idle, otherwise we may get corrupted data
          r_read_addr           <=  r_start_frame_addr;
          r_read_char_count    <=  0;
          out_state             <=  START_READ_FRAME_DELAY;
        end
      end
      START_READ_FRAME_DELAY: begin
        out_state               <=  GET_CHAR;
      end
      GET_CHAR: begin
        if (i_char_req_en) begin
          o_char_rdy            <=  1;
          if (r_read_width_pos < (CHAR_IMAGE_WIDTH - 1)) begin
            //Go to the next character positoin
            r_read_width_pos    <=  r_read_width_pos + 1;
            r_read_addr         <=  r_read_addr + 1;
          end
          else begin
            r_read_width_pos    <=  0;
            if (r_font_height_pos < (FONT_HEIGHT - 1)) begin
              //Go back to the beginning of the current line
              r_font_height_pos <=  r_font_height_pos + 1;
              r_read_addr       <=  r_read_addr - (CHAR_IMAGE_WIDTH - 1);
            end
            else begin
              //Go to the next character line
              r_read_addr       <=  r_read_addr + 1;
              r_font_height_pos <=  0;
              r_read_char_count <=  r_read_char_count + CHAR_IMAGE_WIDTH;
            end
          end
          out_state             <=  GET_CHAR_DELAY;
        end
      end
      GET_CHAR_DELAY: begin
        if (r_read_char_count < CHAR_IMAGE_SIZE) begin
          out_state             <= GET_CHAR;
        end
        else begin
          out_state             <=  IDLE;
        end

      end

      default: begin
      end
    endcase

    //When scroll en is set then the user can scroll up and down
    if (!i_scroll_en) begin
      if (i_scroll_up_stb) begin
        if ((r_start_frame_addr - CHAR_IMAGE_WIDTH) != (w_write_addr_start)) begin
          r_start_frame_addr  <=  r_start_frame_addr - CHAR_IMAGE_WIDTH;
        end
        else begin
          r_start_frame_addr  <=  w_write_addr_start;
        end
      end
      else if (i_scroll_down_stb) begin
        if (r_start_frame_addr + CHAR_IMAGE_SIZE != r_curr_line_addr) begin
          r_start_frame_addr  <=  r_start_frame_addr + CHAR_IMAGE_WIDTH;
        end
      end
    end
    else begin
      if  (r_write_addr_pos > (w_write_addr_start + CHAR_IMAGE_SIZE)) begin
        //Character has reached and went past the end of the character buffer
        r_start_frame_addr  <= r_next_line_addr - CHAR_IMAGE_SIZE;
      end
      else begin
        //Haven't written enough characters to make the char buffer start scrolling down
        r_start_frame_addr  <=  w_write_addr_start;
      end
    end
  end
end



endmodule
