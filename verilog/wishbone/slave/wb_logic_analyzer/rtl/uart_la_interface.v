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

module uart_la_interface (

  input                       rst,
  input                       clk,

  //logic analyzer control
  output reg  [31:0]          trigger,
  output reg  [31:0]          trigger_mask,
  output reg  [31:0]          trigger_after,
  output reg  [31:0]          trigger_edge,
  output reg  [31:0]          both_edges,
  output reg  [31:0]          repeat_count,
  output reg                  set_strobe,
  input                       disable_uart,
  output reg                  enable,
  input                       finished,
  input       [31:0]          start,

  //data interface
  input       [31:0]          data_read_size,
  output reg                  data_read_strobe,
  input       [31:0]          data,

  input                       phy_rx,
  output                      phy_tx
);




parameter                   IDLE                  = 0;
parameter                   READ_COMMAND          = 1;
parameter                   READ_ENABLE_SET       = 2;
parameter                   READ_TRIGGER          = 3;
parameter                   READ_TRIGGER_MASK     = 4;
parameter                   READ_TRIGGER_AFTER    = 5;
parameter                   READ_TRIGGER_EDGE     = 6;
parameter                   READ_BOTH_EDGES       = 7;
parameter                   READ_REPEAT_COUNT     = 8;
parameter                   READ_LINE_FEED        = 9;
parameter                   SEND_RESPONSE         = 10;

//UART Control
reg                         write_strobe;
wire                        write_full;
wire  [31:0]                write_available;
reg   [7:0]                 write_data;
wire  [31:0]                write_size;

wire                        read_overflow;
reg                         read_strobe;
wire                        read_empty;
wire  [31:0]                read_size;
wire  [7:0]                 read_data;
wire  [31:0]                uart_read_count;

//Register/Wires
reg                         ready;
reg   [3:0]                 read_state;
reg   [3:0]                 write_state;

reg                         write_status;
reg                         status_written;

reg   [7:0]                 command_response;
reg   [7:0]                 response_status;
reg                         process_byte;
reg   [31:0]                read_count;

reg   [31:0]                la_data_read_count;
reg   [31:0]                la_data;
reg   [2:0]                 byte_count;

wire  [3:0]                 nibble;
wire  [7:0]                 hex_value;
reg   [3:0]                 nibble_value;
reg   [3:0]                 in_nibble;
reg   [3:0]                 size_count;
wire  [31:0]                readible_write_size;
reg   [31:0]                la_write_size;
reg   [31:0]                la_start_pos;

reg   [7:0]                 command;
wire                        init_packet_read;
reg                         prev_packet_read;
reg                         data_ready;
reg                         send_la_data;
reg   [3:0]                 sleep;


//submodules
uart_controller uc (
  .clk(clk),
  //should this be reset here?
  .rst(rst),
  .rx(phy_rx),
  .tx(phy_tx),
  .rts(0),

  .control_reset(rst),
  .cts_rts_flowcontrol(0),
  .read_overflow(read_overflow),
  .set_clock_div(0),
  .clock_div(0),

  //Data in
  .write_strobe(write_strobe),
  .write_data(write_data),
  .write_full(write_full),
  .write_available(write_available),
  .write_size(write_size),

  //Data Out
  .read_strobe(read_strobe),
  .read_data(read_data),
  .read_empty(read_empty),
  .read_count(uart_read_count),
  .read_size(read_size)
);


//asynchronous logic
//assign  nibble              = decode_ascii(read_data);
//assign  hex_value           = encode_ascii(in_nibble);
assign  hex_value             = (nibble_value >= 8'hA) ? (nibble_value + 8'h37) : (nibble_value + 8'h30);
assign  nibble                = (read_data >= 8'h41) ? (read_data - 8'h37) : (read_data - 8'h30);
assign  init_packet_read      = (enable & finished);
assign  pos_edge_packet_read  = (init_packet_read & ~prev_packet_read);
assign  readible_write_size   = data_read_size - 1;

//signal for sending logic signal to the UART host
always @ (posedge clk) begin
  if (rst) begin
    send_la_data  <=  0;
    data_ready    <=  0;
  end
  else begin
    send_la_data  <=  0;
    if (pos_edge_packet_read) begin
      data_ready  <=  1;
    end
    if (data_ready && (read_state == IDLE) && (write_state == IDLE)) begin
      send_la_data  <=  1;
      data_ready    <=  0;
    end
  end
end

//UART Interface Controller
always @ (posedge clk) begin
  if (rst) begin
    read_strobe             <=  0;
    trigger                 <=  0;
    repeat_count            <=  0;
    trigger_mask            <=  0;
    trigger_after           <=  0;
    trigger_edge            <=  0;
    both_edges              <=  0;
    set_strobe              <=  0;
    enable                  <=  0;

    ready                   <=  0;
    read_state              <=  IDLE;
    command_response        <=  0;
    command                 <=  0;
    response_status         <=  0;
    write_status            <=  0;
  end
  else begin
    if (disable_uart) begin
      enable                <=  0;
    end
    //read commands from the host computer
    read_strobe             <=  0;
    process_byte            <=  0;
    write_status            <=  0;
    set_strobe              <=  0;

    if (ready && !read_empty && !read_strobe) begin
      //new command data to process
      read_strobe       <=  1;
      ready             <=  0;
    end
    if (read_strobe) begin
      process_byte      <=  1;
    end
    if (read_state != READ_LINE_FEED) begin
      //reset everything
      if (process_byte) begin
        if (read_data == (`LINE_FEED)) begin
          read_state    <=  IDLE;
        end
      end
    end
    //check if incomming UART is not empty
    case (read_state)
      IDLE: begin
        ready               <=  1;
        response_status     <=  0;
        if (process_byte) begin
          if (read_data != `START_ID) begin
            $display ("Start ID not found");
            read_state             <=  IDLE;
          end
          else begin
            $display ("Start ID Found!");
            read_state            <=  READ_COMMAND;
            ready                 <=  1;
          end
        end
      end
      READ_COMMAND: begin
        ready               <=  1;
        if (process_byte) begin
          command                 <=  read_data;
          case (read_data)
            `LA_PING: begin
              command_response    <=  `RESPONSE_SUCCESS;
              read_state          <=  READ_LINE_FEED;
            end
            `LA_WRITE_TRIGGER: begin
              //disable the LA when updating settings
              $display("ULA: Write settings (Disable LA)");
              enable              <=  0;
              read_state          <=  READ_TRIGGER;
              read_count          <=  7;
            end
            `LA_WRITE_MASK: begin
              //disable the LA when updating settings
              $display("ULA: Write settings (Disable LA)");
              enable              <=  0;
              read_state          <=  READ_TRIGGER_MASK;
              read_count          <=  7;
            end
             `LA_WRITE_TRIGGER_AFTER: begin
              //disable the LA when updating settings
              $display("ULA: Write settings (Disable LA)");
              enable              <=  0;
              read_state          <=  READ_TRIGGER_AFTER;
              read_count          <=  7;
            end
             `LA_WRITE_TRIGGER_EDGE: begin
              //disable the LA when updating settings
              $display("ULA: Write settings (Disable LA)");
              enable              <=  0;
              read_state          <=  READ_TRIGGER_EDGE;
              read_count          <=  7;
            end
             `LA_WRITE_BOTH_EDGES: begin
              //disable the LA when updating settings
              $display("ULA: Write settings (Disable LA)");
              enable              <=  0;
              read_state          <=  READ_BOTH_EDGES;
              read_count          <=  7;
            end
             `LA_WRITE_REPEAT_COUNT: begin
              //disable the LA when updating settings
              $display("ULA: Write settings (Disable LA)");
              enable              <=  0;
              read_state          <=  READ_REPEAT_COUNT;
              read_count          <=  7;
            end
            `LA_SET_ENABLE: begin
              read_state          <=  READ_ENABLE_SET;
            end
            `LA_GET_ENABLE: begin
              command_response    <=  `RESPONSE_SUCCESS;
              read_state          <=  READ_LINE_FEED;
              response_status     <=  enable + `HEX_0;
            end
            `LA_GET_SIZE: begin
              read_state          <=  READ_LINE_FEED;
            end
            default: begin
              //unrecognized command
              command_response    <=  `RESPONSE_FAIL;
              read_state          <=  READ_LINE_FEED;
            end
          endcase
        end
      end
      READ_TRIGGER: begin
        ready <=  1;
        if (process_byte) begin
          trigger                 <=  {trigger[27:0], nibble};
          read_count              <=  read_count -  1;
          if (read_count == 0) begin
            set_strobe            <=  1;
            command_response      <=  `RESPONSE_SUCCESS;
            read_state            <=  READ_LINE_FEED;
          end
        end
      end
      READ_TRIGGER_MASK: begin
        ready <=  1;
        if (process_byte) begin
          trigger_mask            <=  {trigger_mask[27:0], nibble};
          read_count              <=  read_count -  1;
          if (read_count == 0) begin
            set_strobe            <=  1;
            command_response      <=  `RESPONSE_SUCCESS;
            read_state            <=  READ_LINE_FEED;
          end
        end
      end
      READ_TRIGGER_AFTER: begin
        ready <=  1;
        if (process_byte) begin
          trigger_after           <=  {trigger_after[27:0], nibble};
          read_count              <=  read_count -  1;
          if (read_count == 0) begin
            set_strobe            <=  1;
            command_response      <=  `RESPONSE_SUCCESS;
            read_state            <=  READ_LINE_FEED;
          end
        end
      end
      READ_TRIGGER_EDGE: begin
        ready <=  1;
        if (process_byte) begin
          trigger_edge            <=  {trigger_edge[27:0], nibble};
          read_count              <=  read_count -  1;
          if (read_count == 0) begin
            set_strobe            <=  1;
            command_response      <=  `RESPONSE_SUCCESS;
            read_state            <=  READ_LINE_FEED;
          end
        end
      end
      READ_BOTH_EDGES: begin
        ready <=  1;
        if (process_byte) begin
          both_edges              <=  {both_edges[27:0], nibble};
          read_count              <=  read_count -  1;
          if (read_count == 0) begin
            set_strobe            <=  1;
            command_response      <=  `RESPONSE_SUCCESS;
            read_state            <=  READ_LINE_FEED;
          end
        end

      end
      READ_REPEAT_COUNT: begin
        ready <=  1;
        if (process_byte) begin
          repeat_count            <=  {repeat_count[27:0], nibble};
          read_count              <=  read_count -  1;
          if (read_count == 0) begin
            set_strobe            <=  1;
            command_response      <=  `RESPONSE_SUCCESS;
            read_state            <=  READ_LINE_FEED;
          end
        end
      end

      READ_ENABLE_SET: begin
        ready <=  1;
        if (process_byte) begin
          if (read_data == (0 + `HEX_0)) begin
            enable              <=  0;
            command_response    <=  `RESPONSE_SUCCESS;
          end
          else if (read_data == (1 + `HEX_0)) begin
            enable              <=  1;
            command_response    <=  `RESPONSE_SUCCESS;
          end
          else begin
            command_response    <=  `RESPONSE_FAIL;
          end
          read_state            <=  READ_LINE_FEED;
        end
      end
      READ_LINE_FEED: begin
        ready <=  1;
        if (process_byte) begin
          if (read_data == (`LINE_FEED)) begin
            ready <=  0;
            read_state          <=  SEND_RESPONSE;
            write_status        <=  1;
          end
        end
      end
      SEND_RESPONSE: begin
        if (status_written) begin
          $display ("ULA: Got a response back from the write state machine that data was sent");
          read_state           <=  IDLE;
        end
      end
     default: begin
        read_state             <=  IDLE;
      end
    endcase
    //write data back to the host
  end
end

localparam                   RESPONSE_WRITE_ID     = 1;
localparam                   RESPONSE_WRITE_STATUS = 2;
localparam                   RESPONSE_WRITE_ARG    = 3;
localparam                   RESPONSE_WRITE_SIZE   = 4;
localparam                   RESPONSE_START_POS    = 5;
localparam                   GET_DATA_PACKET       = 6;
localparam                   SEND_START_POS        = 7;
localparam                   SEND_DATA_PACKET      = 8;
localparam                   SEND_CARRIAGE_RETURN  = 9;
localparam                   SEND_LINE_FEED        = 10;


//write data state machine
always @ (posedge clk) begin
  if (rst) begin
    write_strobe                <=  0;
    write_data                  <=  0;
    status_written              <=  0;
    write_state                 <=  IDLE;
    la_data_read_count          <=  0;
    la_data                     <=  0;
    size_count                  <=  0;
    byte_count                  <=  0;
    la_start_pos                <=  0;
  end
  else begin
    write_strobe                <=  0;
    status_written              <=  0;
    data_read_strobe            <=  0;

    case (write_state)
      IDLE: begin
        if (write_status) begin
          write_state           <=  RESPONSE_WRITE_ID;
        end
        if (send_la_data) begin
          write_state           <=  GET_DATA_PACKET;
          la_data_read_count    <=  data_read_size - 1;
          data_read_strobe      <=  0;
          sleep                 <=  3;
        end
      end
      RESPONSE_WRITE_ID: begin
        if (!write_full) begin
          write_data            <=  `RESPONSE_ID;
          write_strobe          <=  1;
          write_state           <=  RESPONSE_WRITE_STATUS;
        end
      end
      RESPONSE_WRITE_STATUS: begin
        if (!write_full) begin
          write_data            <=  command_response;
          write_strobe          <=  1;
          if (command == `LA_GET_ENABLE) begin
            write_state          <=  RESPONSE_WRITE_ARG;
          end
          else if (command == `LA_GET_SIZE) begin
            write_state         <=  RESPONSE_WRITE_SIZE;
            nibble_value        <=  readible_write_size[31:28];
            la_write_size       <=  {readible_write_size[27:0], 4'h0};
            size_count          <=  0;
          end
          else if (command == `LA_GET_START_POS) begin
            write_state         <=  RESPONSE_START_POS;
            la_start_pos        <=  {start[27:0], 4'h0};
            nibble_value        <=  start[31:28];
            size_count          <=  0;
          end
          else begin
            write_state         <=  SEND_CARRIAGE_RETURN;
          end
        end
      end
      RESPONSE_WRITE_ARG: begin
        if (!write_full) begin
          write_data            <=  response_status;
          write_strobe          <=  1;
          write_state           <=  SEND_CARRIAGE_RETURN;
        end
      end

      RESPONSE_WRITE_SIZE: begin
        if (!write_full) begin
          if (size_count == 8) begin
            write_state         <=  SEND_CARRIAGE_RETURN;
          end
          else begin
            //in_nibble           <=  la_write_size[31:28];
            nibble_value        <=  la_write_size[31:28];
            write_data          <=  hex_value;
            la_write_size       <=  {la_write_size[27:0], 4'h0};
            write_strobe        <=  1;
            size_count          <= size_count + 1;
          end
        end
      end
      RESPONSE_START_POS: begin
        if (!write_full) begin
          if (size_count == 8) begin
            write_state         <=  SEND_CARRIAGE_RETURN;
          end
          else begin
            nibble_value        <=  la_start_pos[31:28];
            write_data          <=  hex_value;
            la_start_pos        <=  {la_start_pos[27:0], 4'h0};
            write_strobe        <=  1;
            size_count          <= size_count + 1;
          end
        end
      end
      GET_DATA_PACKET: begin
        if (sleep > 0) begin
          sleep   <=  sleep - 1;
        end
        else begin
          byte_count              <=  0;
          la_data                 <=  data;
          data_read_strobe        <=  1;
          //write_state             <=  SEND_DATA_PACKET;

          la_start_pos            <=  {start[27:0], 4'h0};
          nibble_value            <=  start[31:28];
          size_count              <=  0;
          write_state             <=  SEND_START_POS;

        end
      end
      SEND_START_POS: begin
        if (!write_full) begin
          if (size_count == 8) begin
            write_state         <=  SEND_DATA_PACKET;
          end
          else begin
            nibble_value        <=  la_start_pos[31:28];
            write_data          <=  hex_value;
            la_start_pos        <=  {la_start_pos[27:0], 4'h0};
            write_strobe        <=  1;
            size_count          <= size_count + 1;
          end
        end
      end
      SEND_DATA_PACKET: begin
        if (write_available > 4) begin
          write_data              <=  {4'h0, la_data[31:28]};
          if (byte_count == 7) begin
            if (la_data_read_count > 0) begin
              la_data_read_count  <=  la_data_read_count - 1;
              data_read_strobe    <=  1;
              la_data             <=  data;
            end
            else begin
              write_state         <=  SEND_CARRIAGE_RETURN;
            end
          end
          else begin
            la_data               <=  {la_data[27:0], 4'h0};
          end
          write_strobe            <=  1;
          byte_count              <=  byte_count + 1;
        end
      end
      SEND_CARRIAGE_RETURN: begin
        if (!write_full) begin
          write_strobe            <=  1;
          write_data              <=  `CARRIAGE_RETURN;
          write_state             <=  SEND_LINE_FEED;
        end
      end
      SEND_LINE_FEED: begin
        if (!write_full) begin
          $display ("Writing Line Feed");
          write_strobe            <=  1;
          write_data              <=  `LINE_FEED;
          write_state             <=  IDLE;
          status_written          <=  1;
        end
      end
      default begin
        write_state               <=  IDLE;
      end
    endcase
    //Only allow this to update in an IDLE state
    prev_packet_read              <=  init_packet_read;
  end
end

/*
//nibble -> ascii
function encode_ascii;
input raw_nibble;
begin
  if (raw_nibble >= 10) begin
    encode_ascii  = raw_nibble + 55;
  end
  else begin
    encode_ascii  = raw_nibble + 32;
  end
end
endfunction

//ascii -> nibble
function decode_ascii;
input ascii_byte;
begin
  if (ascii_byte >= 8'h41) begin
    decode_ascii  =  ascii_byte - 55;
  end
  else begin
    decode_ascii  =  ascii_byte - 32;
  end
end
endfunction
*/

endmodule
