//uart_io_handler.v
/*
Distributed under the MIT licesnse.
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

//generalize the uart handler
`include "cbuilder_defines.v"

module uart_io_handler #(
  parameter BAUDRATE  = 115200
)(
  //input/output signals
  input               clk,
  input               rst,

  //input handler
  output reg          o_ih_ready,
  output              o_ih_reset,
  input               i_master_ready,

  output reg [31:0]   o_in_command,
  output reg [31:0]   o_in_address,
  output reg [31:0]   o_in_data,
  output     [27:0]   o_in_data_count,


  //output handler
  output  reg         o_oh_ready,
  input               i_oh_en,

  input [31:0]        i_out_status,
  input [31:0]        i_out_address,
  input [31:0]        i_out_data,
  input [27:0]        i_out_data_count,

  //these are the only thing that are different between xxx_io_handler
  input               i_phy_uart_in,
  output              o_phy_uart_out
);


//STATES
localparam IDLE                 = 4'h0;
localparam READ_ID              = 4'hC;
localparam READ_DATA_COUNT      = 4'h2;
localparam READ_CONTROL         = 4'h3;
localparam READ_ADDRESS         = 4'h4;
localparam READ_DATA            = 4'h5;
localparam SEND_TO_MASTER       = 4'h6;
                                
localparam WRITE_DATA_COUNT     = 4'h1;
localparam WRITE_STATUS         = 4'h2;
localparam WRITE_ADDRESS        = 4'h3;
localparam WRITE_DATA           = 4'h4;
localparam CHECK_FINISHED       = 4'h5;
                                
localparam ID_BYTE              = 8'hCD;
localparam ID_RESP              = 8'hDC;

localparam IN_DATA_COUNT_SIZE   = 4;
localparam IN_CONTROL_SIZE      = 4;
localparam IN_ADDRESS_SIZE      = 4;
localparam IN_DATA_SIZE         = 4;


localparam OUT_DATA_COUNT_SIZE  = 4;
localparam OUT_STATUS_SIZE      = 4;
localparam OUT_ADDRESS_SIZE     = 4;
localparam OUT_DATA_SIZE        = 4;

//Registers/Wires
reg     [3:0]       in_state;
reg     [3:0]       out_state;

reg     [3:0]       in_byte_count;
reg     [3:0]       out_nibble_count;
reg     [15:0]      r_count;


wire    [15:0]      user_command;
wire                is_writing;
wire                is_reading;

reg     [7:0]       out_byte;
wire                in_byte_available;
wire    [7:0]       in_byte;
wire                uart_in_busy;

wire                uart_out_busy;
wire                uart_tx_ready;
reg                 uart_out_byte_en;
reg                 oh_finished;

reg     [31:0]      li_out_data_count;
reg     [27:0]      li_out_data_count_buf;
reg     [31:0]      out_data_count;
reg     [31:0]      li_out_data;
reg     [31:0]      li_out_status;
reg     [31:0]      li_out_address;


reg     [31:0]      li_data_count;
reg     [31:0]      in_data_count;


reg     [31:0]      out_byte_count;

reg     [31:0]      out_data_pos;

//Submodules
uart_v3 #(
  .DEFAULT_BAUDRATE   (BAUDRATE           )
)uart(
  .clk                (clk                ),
  .rst                (rst                ),

  .tx                 (o_phy_uart_out     ),
  .transmit           (uart_out_byte_en   ),
  .tx_byte            (out_byte           ),
  .is_transmitting    (uart_out_busy      ),

  .rx                 (i_phy_uart_in      ),
  .rx_error           (                   ),
  .rx_byte            (in_byte            ),
  .received           (in_byte_available  ),
  .is_receiving       (uart_in_busy       ),

  .prescaler          (                   ),

  .set_clock_div      (1'b0               ),

  .user_clock_div     (def_clock_div      ),
  .default_clock_div  (def_clock_div      )
);

//Asynchronous Logic
assign          user_command      =  o_in_command[15:0];
assign          is_writing        = (user_command == `COMMAND_WRITE);
assign          is_reading        = (user_command == `COMMAND_READ);
assign          o_ih_reset        =  0;
assign          uart_tx_ready     =  ~uart_out_busy;
assign          o_in_data_count   = in_data_count[27:0];

//Synchronous Logic
//input handler
always @ (posedge clk) begin

  o_ih_ready                <= 0;

  if (rst) begin
    o_in_command            <= 32'h0000;
    o_in_address            <= 32'h0000;
    o_in_data               <= 32'h0000;
    in_state                <= IDLE;
    in_byte_count           <= 4'h0;

    in_data_count           <=  0;
    li_data_count           <=  0;
  end
  else begin
    //main state machine goes here
    case (in_state)
      IDLE: begin
        if (in_byte_available) begin
          in_state     <= READ_ID;
        end
      end
      READ_ID: begin
        //putting this here lets master hold onto the data for
        //a longer time
        o_in_command      <= 32'h0000;
        o_in_address      <= 32'h0000;
        o_in_data         <= 32'h0000;
        li_data_count     <=  0;
        if (in_byte == ID_BYTE) begin
          //read the first of in_byte
          in_state        <= READ_DATA_COUNT;
          in_byte_count   <= 4'h0;
        end
        else begin
          in_state    <= IDLE;
        end
      end
      READ_DATA_COUNT: begin
          if (in_byte_count < IN_DATA_COUNT_SIZE) begin
            if (in_byte_available) begin
              in_data_count   <=  {in_data_count[23:0], in_byte};
              in_byte_count   <= in_byte_count + 1;
            end
          else begin
            state           <=  READ_CONTROL;
            in_byte_count   <=  0;
          end
        end
      end
      READ_CONTROL: begin
        if (in_byte_count < IN_CONTROL_SIZE) begin
          if (in_byte_available) begin
              o_in_command    <=  {o_in_command[23:0], in_byte};
              in_byte_count   <=  in_byte_count + 1;
          end
        end
        else begin
          state             <= READ_ADDRESS;
          in_byte_count     <=  0;
        end
      end
      READ_ADDRESS: begin
        if (in_byte_count < IN_ADDRESS_SIZE) begin
          if (in_byte_avalable) begin
            o_in_address      <=  {o_in_address[23:0], in_byte};
            in_byte_count     <=  in_byte_count + 1;
          end
        end
        else begin
          state               <=  READ_DATA;
          in_byte_count       <=  0;
        end
      end
      READ_DATA : begin
        if (in_byte_count < IN_DATA_SIZE) begin
          if (in_byte_available) begin
            o_in_data         <=  {o_in_address[23:0], in_byte};
            in_byte_count     <=  in_byte_count + 1;
          end
        end
        else begin
          in_byte_count       <=  0;
          state               <=  SEND_TO_MASTER;
          li_data_count       <=  li_data_count + 1;
        end
      end
      SEND_TO_MASTER: begin
        if (i_master_ready) begin
          o_ih_ready          <= 1;
          if (is_writing && (li_data_count < in_data_count)) begin
            in_state          <=  READ_DATA;
          end
          else begin
            in_state          <=  IDLE;
          end
        end
      end
      default: begin
        o_in_command          <= 8'h0;
        in_state              <= IDLE;
      end
     endcase
  end
end





//output handler
always @ (posedge clk) begin

  //uart_out_byte_en should only be high for one clock cycle

  oh_finished               <= 0;
  uart_out_byte_en          <= 0;

  if (rst) begin
    out_state               <=  IDLE;
    out_nibble_count        <=  4'h0;
    out_byte                <=  8'h0;
    li_out_data_count       <= 27'h0;
    li_out_data_count_buf   <= 27'h0;
    li_out_data             <= 32'h0;
    li_out_status           <= 32'h0;
    li_out_address          <= 32'h0;
    o_oh_ready              <= 0;
    out_data_count          <= 0;
    out_byte_count          <= 0;
    out_data_pos            <= 0;
  end

  else begin
    //don't do anything until the UART is ready
    if (!uart_out_byte_en & uart_tx_ready) begin
    case (out_state)
      IDLE: begin
        out_byte_count      <=  0;
        out_data_pos        <=  0;
        out_byte            <=  8'h0;
        o_oh_ready          <=  1'h1;
        if (i_oh_en) begin
          o_oh_ready        <= 0;
//moved this outside because by the time it reaches this part, the out data_count is
//changed
          //Local version
          li_out_status     <= i_out_status;
          li_out_address    <= i_out_address;
          li_out_data       <= i_out_data;

          out_byte          <= ID_RESP;




          out_state         <= WRITE_DATA_COUNT;
          uart_out_byte_en  <= 1;
          uart_wait_for_tx  <= 1;
        end
        else begin
          li_out_data_count     <= 0;
          li_out_data_count     <= i_out_data_count;
          out_data_count        <= i_out_data_count;
        end
      end
      WRITE_DATA_COUNT: begin
        if (out_byte_count < OUT_DATA_COUNT_SIZE) begin
          out_byte              <=  li_out_data_count[31:24];
          li_out_data_count     <=  {li_out_data_count[23:0], 8'h00};
          out_byte_count        <=  out_byte_count + 1;
        end
        else begin
          out_byte_count        <=  0;
          state                 <= WRITE_STATUS;
        end
      end
      WRITE_STATUS: begin
        if (out_byte_count < OUT_STATUS_SIZE) begin
          out_byte              <=  li_out_status[31:24];
          li_out_status         <=  {li_out_status[23:0], 8'h00};
          out_byte_count        <=  out_byte_count + 1;
        end
        else begin 
          out_byte_count        <=  0;
          state                 <= WRITE_ADDRESS;
        end
      end
      WRITE_ADDRESS: begin
        if (out_byte_count < OUT_ADDRESS_SIZE) begin
          out_byte              <=  li_out_address[31:24];
          li_out_address        <=  {li_out_address[23:0], 8'h00};
          out_byte_count        <=  out_byte_count + 1;
        end
        else begin
          out_byte_count        <=  0;
          state                 <=  WRITE_DATA;
        end
      end
      WRITE_DATA: begin
        if (out_byte_count < OUT_DATA_SIZE) begin
          out_byte              <=  li_out_data[31:24];
          li_out_data           <=  {li_out_data[23:0], 8'h00};
          out_byte_count        <=  out_byte_count + 1;
        end
        else begin
          out_byte_count        <=  0;
          out_state             <=  CHECK_FINISHED;
          out_data_pos          <=  out_data_pos + 1;
        end
      end
      CHECK_FINISHED: begin
        if (is_reading && (out_data_pos < out_data_count)) begin
          o_oh_ready            <=  1;
          if (i_oh_en) begin
            o_oh_ready          <=  0;
            out_state           <=  WRITE_DATA;
            li_out_data         <=  i_out_data;
          end
        end
        else begin
          out_state             <= IDLE;
        end 
      end
      default: begin
        out_state               <=  IDLE;
      end
      endcase
    end
  end
end
endmodule
