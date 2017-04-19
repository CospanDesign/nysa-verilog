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
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   (x <= 32)    ? 5 :  \
   (x <= 64)    ? 6 :  \
   (x <= 128)   ? 7 :  \
   (x <= 256)   ? 7 :  \
   (x <= 512)   ? 8 :  \
   (x <= 1024)  ? 9 :  \
   (x <= 2048)  ? 10 : \
   (x <= 4096)  ? 11 : \
   -1


`timescale 1ps / 1ps

module console_osd #(
  parameter                       CONSOLE_DEPTH     = 12,
  parameter                       IMAGE_WIDTH       = 480,
  parameter                       IMAGE_HEIGHT      = 272,
  parameter                       IMAGE_SIZE        = IMAGE_WIDTH * IMAGE_HEIGHT,
  parameter                       BUFFER_DEPTH      = `CLOG2(IMAGE_WIDTH),
  parameter                       PIXEL_WIDTH       = 24,
  parameter                       FONT_WIDTH        = 5,
  parameter                       FONT_HEIGHT       = 7
)(
  input                           clk,
  input                           rst,
  input                           i_enable,

  input     [PIXEL_WIDTH - 1: 0]  i_fg_color,
  input     [PIXEL_WIDTH - 1: 0]  i_bg_color,

  input                           i_cmd_stb,
  input     [31:0]                i_cmd,

  input                           i_char_stb,
  input     [7:0]                 i_char,

  input                           i_clear_screen_stb,
  input                           i_alt_func_en,
  input     [2:0]                 i_tab_count,

  input                           i_scroll_en,
  input                           i_scroll_up_stb,
  input                           i_scroll_down_stb,
  input       [31:0]              i_char_x_start,
  input       [31:0]              i_char_x_end,

  input       [31:0]              i_char_y_start,
  input       [31:0]              i_char_y_end,

  input       [31:0]              i_x_start,
  input       [31:0]              i_x_end,
  input       [31:0]              i_y_start,
  input       [31:0]              i_y_end,


  //PPFIFO Output
  input                           i_ppfifo_clk,
  input                           i_ppfifo_rst,
  output                          o_ppfifo_rdy,
  input                           i_ppfifo_act,
  output    [23:0]                o_ppfifo_size,
  output    [PIXEL_WIDTH: 0]      o_ppfifo_data,  //Add an extra bit to communicate start of frame
  input                           i_ppfifo_stb

);
//local parameters
localparam    IDLE                    = 0;
localparam    WRITE_LINE              = 1;
localparam    WRITE_VERTICAL_PADDING  = 2;
localparam    WRITE_HORIZONTAL_PADDING= 3;
localparam    GET_CHAR                = 4;
localparam    PROCESS_CHAR_START      = 5;
localparam    PROCESS_CHAR            = 6;

localparam    FONT_WIDTH_ADJ          = FONT_WIDTH + 1;
localparam    FONT_HEIGHT_ADJ         = FONT_HEIGHT + 1;
localparam    FONT_SIZE               = FONT_WIDTH * FONT_HEIGHT_ADJ;
localparam    CHAR_IMAGE_SIZE         = CHAR_IMAGE_WIDTH * CHAR_IMAGE_HEIGHT;
localparam    CHAR_IMAGE_WIDTH        = IMAGE_WIDTH / FONT_WIDTH_ADJ;
localparam    CHAR_IMAGE_HEIGHT       = IMAGE_HEIGHT / FONT_HEIGHT_ADJ;

//registes/wires
reg         [3:0]                     state;

wire        [1:0]                     w_write_rdy;
reg         [1:0]                     r_write_act;
wire        [23:0]                    w_write_size;
reg                                   r_write_stb;
reg         [7:0]                     r_char;
reg                                   r_char_req_en;
wire        [PIXEL_WIDTH:0]           w_write_data;

reg                                   r_start_frame;
reg         [PIXEL_WIDTH - 1: 0]      r_pixel_data;

reg         [31:0]                    r_pixel_count;
reg         [23:0]                    r_ppfifo_count;
reg         [23:0]                    r_pixel_width_count;
reg         [23:0]                    r_pixel_height_count;

wire                                  w_vertical_padding;
wire                                  w_horizontal_padding;

wire        [23:0]                    w_pixel;

wire        [(FONT_WIDTH_ADJ - 1):0]  w_char_data_map[0: ((1 << FONT_HEIGHT_ADJ) - 1)];
wire                                  w_char_rdy;
wire        [7:0]                     w_char;

wire        [FONT_SIZE - 1: 0]        w_font_data;
reg         [FONT_HEIGHT_ADJ - 1:0]   r_font_height_count;
reg         [FONT_WIDTH_ADJ - 1:0]    r_font_width_count;
reg         [23:0]                    r_char_width_count;
reg                                   r_read_frame_stb;

//XXX Need to figure this out
wire                                  w_valid_char_pixel;



//*************** DEBUG ******************************************************

wire        [31: 0]  w_dbg_font_width      = FONT_WIDTH;
wire        [31: 0]  w_dbg_font_width_adj  = FONT_WIDTH_ADJ;
wire        [31: 0]  w_dbg_font_height     = FONT_HEIGHT;
wire        [31: 0]  w_dbg_font_height_adj = FONT_HEIGHT_ADJ;

//****************************************************************************

assign  w_valid_char_pixel  = (r_pixel_width_count  >= i_x_start)  && (r_pixel_width_count  <= i_x_end) &&
                              (r_pixel_height_count >= i_y_start)  && (r_pixel_height_count <= i_y_end);

assign  w_vertical_padding  = (r_pixel_height_count < i_y_start) || (r_pixel_height_count > i_y_end);
assign  w_horizontal_padding= (r_pixel_width_count  < i_x_start) || (r_pixel_width_count  > i_x_end);

//Font

//submodules
ppfifo #(
  .DATA_WIDTH           (PIXEL_WIDTH + 1      ),  //Add an extra bit to hold the 'frame sync' signal
  .ADDRESS_WIDTH        (BUFFER_DEPTH         )
)ping_pong (

  .reset                (rst || i_ppfifo_rst  ),

  //write
  .write_clock          (clk                  ),
  .write_ready          (w_write_rdy          ),
  .write_activate       (r_write_act          ),
  .write_fifo_size      (w_write_size         ),
  .write_strobe         (r_write_stb          ),
  .write_data           (w_write_data         ),

  //read
  .read_clock           (i_ppfifo_clk         ),
  .read_strobe          (i_ppfifo_stb         ),
  .read_ready           (o_ppfifo_rdy         ),
  .read_activate        (i_ppfifo_act         ),
  .read_count           (o_ppfifo_size        ),
  .read_data            (o_ppfifo_data        )
);

character_buffer#(
  .CONSOLE_DEPTH        (CONSOLE_DEPTH        ),
  .FONT_WIDTH           (FONT_WIDTH_ADJ       ),
  .FONT_HEIGHT          (FONT_HEIGHT_ADJ      ),
  .CHAR_IMAGE_WIDTH     (CHAR_IMAGE_WIDTH     ),
  .CHAR_IMAGE_HEIGHT    (CHAR_IMAGE_HEIGHT    ),
  .CHAR_IMAGE_SIZE      (CHAR_IMAGE_WIDTH * CHAR_IMAGE_HEIGHT)
)cb (
  .clk                  (clk                  ),
  .rst                  (rst                  ),

  .i_alt_func_en        (i_alt_func_en        ),
  .i_clear_screen_stb   (i_clear_screen_stb   ),

  .i_tab_count          (i_tab_count          ),
  .i_char_stb           (i_char_stb           ),
  .i_char               (i_char               ),
  .o_busy               (o_busy               ),

  .i_read_frame_stb     (r_read_frame_stb     ),
  .i_read_char_req_stb  (i_read_char_req_stb  ),

  .i_char_req_en        (r_char_req_en        ),
  .o_char_rdy           (w_char_rdy           ),
  .o_char               (w_char               ),

  .i_scroll_en          (i_scroll_en          ),
  .i_scroll_up_stb      (i_scroll_up_stb      ),
  .i_scroll_down_stb    (i_scroll_down_stb    )
);

bram #(
  .DATA_WIDTH           (40                   ),
  .ADDR_WIDTH           (8                    ),
  .MEM_FILE             ("fontdata.mif"       ),
  .MEM_FILE_LENGTH      (256                  )
) font_buffer (
  .clk                  (clk                  ),
  .rst                  (rst                  ),
  .en                   (1'b1                 ),
  .we                   (1'b0                 ),
  .write_address        (8'h00                ),
  .data_in              (40'h0                ),
  .read_address         (r_char               ),  //Use the char data to get the font data
  .data_out             (w_font_data          )
);

//asynchronous logic

assign  w_write_data = {r_start_frame, r_pixel_data};

generate
genvar y;
genvar x;

for (y = 0; y < FONT_HEIGHT_ADJ; y = y + 1) begin: FOR_HEIGHT
  for (x = 0; x < (FONT_WIDTH_ADJ); x = x + 1) begin: FOR_WIDTH
    if (x < (FONT_WIDTH)) begin
      assign  w_char_data_map[y][x] = w_font_data[(x * 8) + y];
    end
    else begin
      assign  w_char_data_map[y][x] = 0;
    end
  end
end
endgenerate

/*
assign  w_char_data_map[0][0] = w_font_data[0];
assign  w_char_data_map[0][1] = w_font_data[8];
assign  w_char_data_map[0][2] = w_font_data[16];
assign  w_char_data_map[0][3] = w_font_data[24];
assign  w_char_data_map[0][4] = w_font_data[32];
assign  w_char_data_map[0][5] = 1'b0;

assign  w_char_data_map[1][0] = w_font_data[1];
assign  w_char_data_map[1][1] = w_font_data[9];
assign  w_char_data_map[1][2] = w_font_data[17];
assign  w_char_data_map[1][3] = w_font_data[25];
assign  w_char_data_map[1][4] = w_font_data[33];
assign  w_char_data_map[1][5] = 1'b0;

assign  w_char_data_map[2][0] = w_font_data[2];
assign  w_char_data_map[2][1] = w_font_data[10];
assign  w_char_data_map[2][2] = w_font_data[18];
assign  w_char_data_map[2][3] = w_font_data[26];
assign  w_char_data_map[2][4] = w_font_data[34];
assign  w_char_data_map[2][5] = 1'b0;

assign  w_char_data_map[3][0] = w_font_data[3];
assign  w_char_data_map[3][1] = w_font_data[11];
assign  w_char_data_map[3][2] = w_font_data[19];
assign  w_char_data_map[3][3] = w_font_data[27];
assign  w_char_data_map[3][4] = w_font_data[35];
assign  w_char_data_map[3][5] = 1'b0;

assign  w_char_data_map[4][0] = w_font_data[4];
assign  w_char_data_map[4][1] = w_font_data[12];
assign  w_char_data_map[4][2] = w_font_data[20];
assign  w_char_data_map[4][3] = w_font_data[28];
assign  w_char_data_map[4][4] = w_font_data[36];
assign  w_char_data_map[4][5] = 1'b0;

assign  w_char_data_map[5][0] = w_font_data[5];
assign  w_char_data_map[5][1] = w_font_data[13];
assign  w_char_data_map[5][2] = w_font_data[21];
assign  w_char_data_map[5][3] = w_font_data[29];
assign  w_char_data_map[5][4] = w_font_data[37];
assign  w_char_data_map[5][5] = 1'b0;

assign  w_char_data_map[6][0] = w_font_data[6];
assign  w_char_data_map[6][1] = w_font_data[14];
assign  w_char_data_map[6][2] = w_font_data[22];
assign  w_char_data_map[6][3] = w_font_data[30];
assign  w_char_data_map[6][4] = w_font_data[38];
assign  w_char_data_map[6][5] = 1'b0;

assign  w_char_data_map[7][0] = w_font_data[7];
assign  w_char_data_map[7][1] = w_font_data[15];
assign  w_char_data_map[7][2] = w_font_data[23];
assign  w_char_data_map[7][3] = w_font_data[31];
assign  w_char_data_map[7][4] = w_font_data[39];
assign  w_char_data_map[7][5] = 1'b0;
*/

assign  w_pixel               = (!w_valid_char_pixel) ? i_bg_color:
                                  (w_char_data_map[r_font_height_count][r_font_width_count]) ?
                                    i_fg_color :
                                    i_bg_color;

//synchronous logic

//Construct a frame one line at a time.
always @ (posedge clk) begin
  r_write_stb       <=  0;
  r_read_frame_stb  <=  0;
  if (rst) begin
    state           <=  IDLE;
    r_write_act     <=  2'b00;
    r_start_frame   <=  0;
    r_pixel_data    <=  0;
    r_pixel_count   <=  0;
    r_ppfifo_count  <=  0;

    r_font_width_count  <=  0;
    r_font_height_count <=  0;
    r_char_width_count  <=  0;
    r_char              <=  0;
    r_char_req_en       <=  0;
    r_pixel_width_count <=  0;
    r_pixel_height_count<=  0;
  end
  else begin
    //Grab a FIFO
    if ((w_write_rdy > 0) && (r_write_act == 0)) begin
      r_ppfifo_count      <=  0;
      if (w_write_rdy[0]) begin
        r_write_act[0]    <=  1;
      end
      else begin
        r_write_act[1]    <=  1;
      end
    end

    case (state)
      IDLE: begin
        r_pixel_count         <=  0;
        r_font_width_count    <=  0;
        r_font_height_count   <=  0;
        //set the frame strobe signal to high
        if (r_write_act && i_enable) begin
          r_read_frame_stb    <=  1;
          r_pixel_width_count <=  0;
          r_pixel_height_count<=  0;
          r_char_width_count  <=  0;
          r_start_frame       <= 1;
          state               <=  WRITE_LINE;
        end
      end
      WRITE_LINE: begin
        r_char_width_count    <=  0;
        if (r_write_act) begin
          if (w_vertical_padding) begin
            state             <=  WRITE_VERTICAL_PADDING;
          end
          else begin
            state             <=  WRITE_HORIZONTAL_PADDING;
          end
        end
      end
      WRITE_VERTICAL_PADDING: begin
        if (r_pixel_width_count < IMAGE_WIDTH) begin
          r_pixel_count       <=  r_pixel_count + 1;
          r_ppfifo_count      <=  r_ppfifo_count + 1;
          r_pixel_width_count <=  r_pixel_width_count + 1;
          r_pixel_data        <=  w_pixel;
          r_write_stb         <=  1;
        end
        else begin
          r_pixel_height_count<=  r_pixel_height_count + 1;
          r_pixel_width_count <=  0;
          r_write_act         <=  0;
          state               <=  WRITE_LINE;
        end
      end
      WRITE_HORIZONTAL_PADDING: begin
        if (w_horizontal_padding) begin
          r_pixel_count       <=  r_pixel_count + 1;
          r_ppfifo_count      <=  r_ppfifo_count + 1;
          r_pixel_width_count <=  r_pixel_width_count + 1;
          r_pixel_data        <=  w_pixel;
          r_write_stb         <=  1;
        end
        else begin
          state               <=  GET_CHAR;
        end
      end
      GET_CHAR: begin
        r_char_req_en         <=  1;
        r_font_width_count    <=  0;
        if (w_char_rdy) begin
          r_char_req_en       <=  0;
          r_char              <=  w_char; //Store the character locally
          state               <=  PROCESS_CHAR_START;
        end
      end
      PROCESS_CHAR_START: begin
        r_ppfifo_count        <=  r_ppfifo_count + 1;
        r_pixel_count         <=  r_pixel_count + 1;
        r_pixel_width_count   <=  r_pixel_width_count + 1;
        r_pixel_data          <=  w_pixel;
        r_write_stb           <=  1;
        state                 <=  PROCESS_CHAR;
      end
      PROCESS_CHAR: begin
        //Need to read the
        if (r_font_width_count < (FONT_WIDTH_ADJ - 1)) begin
          r_write_stb         <=  1;
          r_pixel_data        <=  w_pixel;
          r_ppfifo_count      <=  r_ppfifo_count + 1;
          r_pixel_count       <=  r_pixel_count + 1;
          r_font_width_count  <=  r_font_width_count + 1;
          r_pixel_width_count <=  r_pixel_width_count + 1;
        end
        else begin
          //Release the FIFO, we reached the end of the line
          if (r_font_height_count < (FONT_HEIGHT_ADJ - 1)) begin
            r_font_height_count <= r_font_height_count + 1;
          end
          else begin
            r_font_height_count <= 0;
          end

          if (r_pixel_count >= IMAGE_SIZE) begin
            //Finished sending image
            state               <=  IDLE;
          end
          else if (r_char_width_count >= (CHAR_IMAGE_WIDTH - 1)) begin
            state               <=  WRITE_VERTICAL_PADDING;
          end
          else begin
            r_char_width_count  <=  r_char_width_count  + 1;
            //The only other option is that we need to send the next character
            state               <=  GET_CHAR;
          end
        end
      end
    endcase
    if (r_write_stb && r_start_frame) begin
      r_start_frame       <=  0;
    end
  end
end


endmodule
