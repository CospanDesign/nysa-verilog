`include "nh_lcd_defines.v"

module nh_lcd_data_writer#(
  parameter           DATAS_WIDTH = 24,
  parameter           BUFFER_SIZE = 12
)(
  input                           rst,
  input                           clk,

  output      [31:0]              debug,

  //Control
  input                           i_enable,
  input       [31:0]              i_num_pixels,
  input                           i_enable_tearing,
  input                           i_unpack_pixels,

  input                           i_v_blank,

  //FIFO Signals
  input                           i_fifo_clk,
  input                           i_fifo_rst,
  output      [1:0]               o_fifo_rdy,
  input       [1:0]               i_fifo_act,
  input                           i_fifo_stb,
  output      [23:0]              o_fifo_size,
  input       [DATAS_WIDTH - 1:0] i_fifo_data,

  //Physical Signals
  output                          o_cmd_mode,
  output      [7:0]               o_data_out,
  input       [7:0]               i_data_in,
  output                          o_write,
  output                          o_read,
  output                          o_data_out_en,
  input                           i_tearing_effect
);

//Local Parameters
localparam  IDLE                = 4'h0;
localparam  WRITE_ADDRESS       = 4'h1;
localparam  WRITE_RED_START     = 4'h2;
localparam  WRITE_RED           = 4'h3;
localparam  WRITE_GREEN_START   = 4'h4;
localparam  WRITE_GREEN         = 4'h5;
localparam  WRITE_BLUE_START    = 4'h6;
localparam  WRITE_BLUE          = 4'h7;

//Registers/Wires
reg           [3:0]   state;

wire          [7:0]   w_red;
wire          [7:0]   w_green;
wire          [7:0]   w_blue;

wire                  w_read_stb;
wire                  w_read_rdy;
wire                  w_read_act;
wire          [23:0]  w_read_size;
wire          [23:0]  w_read_data;

reg           [31:0]  r_pixel_cnt;
reg                   r_pixel_stb;
wire                  w_pixel_rdy;


//Tear Mode select
reg                   r_write;
reg                   r_cmd_mode;
reg           [7:0]   r_data_out;

//Tear control


//Submodules
//generate a Ping Pong FIFO to cross the clock domain
ppfifo #(
  .DATA_WIDTH       (DATAS_WIDTH      ),
  .ADDRESS_WIDTH    (BUFFER_SIZE      )
)ping_pong (

  .reset           (rst || i_fifo_rst ),

  //write
  .write_clock     (i_fifo_clk        ),
  .write_ready     (o_fifo_rdy        ),
  .write_activate  (i_fifo_act        ),
  .write_fifo_size (o_fifo_size       ),
  .write_strobe    (i_fifo_stb        ),
  .write_data      (i_fifo_data       ),

  //.starved         (starved           ),

  //read
  .read_clock      (clk               ),
  .read_strobe     (w_read_stb        ),
  .read_ready      (w_read_rdy        ),
  .read_activate   (w_read_act        ),
  .read_count      (w_read_size       ),
  .read_data       (w_read_data       )
);

pixel_reader pr(
  .clk              (clk              ),
  .rst              (rst              ),

  .o_read_stb       (w_read_stb       ),
  .i_read_rdy       (w_read_rdy       ),
  .o_read_act       (w_read_act       ),
  .i_read_size      (w_read_size      ),
  .i_read_data      (w_read_data      ),

  .o_red            (w_red            ),
  .o_green          (w_green          ),
  .o_blue           (w_blue           ),

  //Pixel state machine interface, when 'rdy' is high, pixel is ready
  .o_pixel_rdy      (w_pixel_rdy      ),
  .i_pixel_stb      (r_pixel_stb      )
);

//Asynchronous Logic
assign  o_cmd_mode      = r_cmd_mode;
assign  o_data_out      = r_data_out;
assign  o_write         = r_write;
assign  o_read          = 0;
assign  o_data_out_en   = 1;

assign  debug[0]        = i_enable;
assign  debug[1]        = o_cmd_mode;
assign  debug[2]        = o_write;
assign  debug[3]        = o_read;
assign  debug[11:4]     = o_data_out_en ? o_data_out : i_data_in;
assign  debug[16:13]    = state;
assign  debug[21]       = o_data_out_en;
assign  debug[31:22]    = 10'b0;

//Synchronous Logic
always @ (posedge clk) begin
  //De-assert strobes
  r_write               <=  0;
  r_cmd_mode            <=  1;
  r_pixel_stb           <=  0;
  if (rst) begin
    state               <=  IDLE;

    //Control of Physical lines
    r_data_out          <=  0;
    r_pixel_cnt         <=  0;
  end
  else begin
    //Strobes

    //Get a ping pong FIFO
    case (state)
      IDLE: begin
        if (i_enable) begin
          if (w_pixel_rdy) begin
            if (r_pixel_cnt >= i_num_pixels) begin
                r_pixel_cnt   <=  0;
            end
            else if (r_pixel_cnt == 0) begin
              //Start a transaction
              //we are at the start of an image transaction
              if (i_tearing_effect) begin
                //We are at the beginning of a Frame, need to start writing to the
                //first address
                r_cmd_mode      <=  0;
                r_write         <=  1;
                r_data_out      <=  `CMD_START_MEM_WRITE;
                state           <=  WRITE_ADDRESS;
              end
            end
            else begin
                state           <=  WRITE_RED_START;
            end
          end
        end
        else begin
            r_pixel_cnt       <= 0;
        end
      end
      WRITE_ADDRESS: begin
        state               <=  WRITE_RED_START;
      end
      WRITE_RED_START: begin
        r_write             <=  1;
        r_data_out          <=  w_red[7:0];
        state               <=  WRITE_RED;
      end
      WRITE_RED: begin
        state               <=  WRITE_GREEN_START;
      end
      WRITE_GREEN_START: begin
        r_write             <=  1;
        r_data_out          <=  w_green[7:0];
        state               <=  WRITE_GREEN;
      end
      WRITE_GREEN: begin
        state               <=  WRITE_BLUE_START;
      end
      WRITE_BLUE_START: begin
        r_write             <=  1;
        r_data_out          <=  w_blue[7:0];
        state               <=  WRITE_BLUE;
      end
      WRITE_BLUE: begin
        r_pixel_cnt         <=  r_pixel_cnt + 1;
        if (w_pixel_rdy) begin
          state             <=  WRITE_RED_START;
          r_pixel_stb       <=  1;
        end
        else begin
          state             <=  IDLE;
        end
      end
    endcase

    //XXX: This should be debugged!
    if (i_v_blank && (o_fifo_rdy == 0)) begin
      //There is a possiblity that data comes in at the wrong time or out of sync with everythig, this should
      //reset everything back to the start of the frame, there should be no way that the FIFO RDY can be
      //zero before the vblank should go off.
      r_pixel_cnt           <= 0;
    end
  end
end
endmodule
