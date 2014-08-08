//UART Version 2
/*
Distributed under the MIT license.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

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




`include "project_defines.v"
`timescale 1 ns/1 ps

`define PRESCALER_COUNT 16

`define HALF_PERIOD (`PRESCALER_COUNT >> 1)
`define FULL_PERIOD `PRESCALER_COUNT
`define TWO_PERIODS (`PRESCALER_COUNT << 1)


module uart_v2 #(
  parameter DEFAULT_BAUDRATE = 115200
)(
  clk,
  rst,

  tx,
  transmit,
  tx_byte,
  is_transmitting,

  rx,
  rx_error,
  rx_byte,
  received,
  is_receiving,

  prescaler,
  set_clock_div,
  user_clock_div,
  default_clock_div
);


input                 clk;
input                 rst;
input                 rx;
output reg            tx;
input                 transmit;
input       [7:0]     tx_byte;
output reg            received;
output reg  [7:0]     rx_byte;
output                is_receiving;
output                is_transmitting;
output                rx_error;
output      [31:0]    prescaler;
input       [31:0]    user_clock_div;
input                 set_clock_div;
output      [31:0]    default_clock_div;


//RX state machine
localparam RX_IDLE               = 0;
localparam RX_CHECK_START        = 1;
localparam RX_READ_BITS          = 2;
localparam RX_CHECK_STOP         = 3;
localparam RX_DELAY_RESTART      = 4;
localparam RX_ERROR              = 5;
localparam RX_RECEIVED           = 6;


//TX state machine
localparam TX_IDLE               = 0;
localparam TX_SENDING            = 1;
localparam TX_DELAY_RESTART      = 2;


//Registers/Wires

reg [12:0]  rx_clk_divider;
reg [12:0]  tx_clk_divider;

reg [31:0]  clock_div;


//recever registers
reg [2:0] rx_state    = RX_IDLE;
reg [7:0] rx_countdown;
reg [7:0] rx_data;
reg [3:0] rx_bits_remaining;

//transmitter register
reg [1:0] tx_state    = TX_IDLE;
reg [7:0] tx_countdown;
reg [3:0] tx_bits_remaining;
reg [7:0] tx_data;


//Asynchronous Logic
assign    prescaler           = `CLOCK_RATE / (`PRESCALER_COUNT);
assign    default_clock_div   = `CLOCK_RATE / (`PRESCALER_COUNT * DEFAULT_BAUDRATE);
//assign    received    = (rx_state == RX_RECEIVED);
assign    rx_error            = (rx_state == RX_ERROR);
assign    is_receiving        = (rx_state != RX_IDLE);
assign    is_transmitting     = (tx_state != TX_IDLE);


always @ (posedge clk) begin

  received <= 0;

  if (rst || set_clock_div) begin
    rx_state              <= RX_IDLE;
    tx_state              <= TX_IDLE;

    tx_bits_remaining     <= 4'h0;
    rx_bits_remaining     <= 4'h0;

    rx_countdown          <= 8'h0;
    tx_countdown          <= 8'h0;

    tx_data               <= 8'h0;
    rx_data               <= 8'h0;
    rx_byte               <= 8'h0;

    tx                    <= 1;
    clock_div             <=  default_clock_div;
    rx_clk_divider        <=  0;
    tx_clk_divider        <=  0;
    if (set_clock_div) begin
      clock_div           <=  user_clock_div;
    end

//    $display ("%m clock_div: %d", default_clock_div);
//    $display ("%m half period: %d", default_clock_div * (`HALF_PERIOD));
//    $display ("%m full period: %d", default_clock_div * (`FULL_PERIOD));

  end
  else begin

    //counters


    //decrement the rx_clk_divider
    if (rx_clk_divider == 0) begin
      rx_clk_divider  <= clock_div;
      if (rx_countdown > 0) begin
        rx_countdown  <= rx_countdown - 1;
      end
    end
    else begin
      rx_clk_divider            <= rx_clk_divider - 1;
    end

    //decrement the tx_clk_divider
    if (tx_clk_divider == 0) begin
      tx_clk_divider            <= clock_div;
      if (tx_countdown > 0) begin
        tx_countdown            <= tx_countdown - 1;
      end
    end
    else begin
      tx_clk_divider            <= tx_clk_divider - 1;
    end


    //receive state machine
    case (rx_state)
      RX_IDLE: begin
//--*____|
        //A low pulse on the receive line indicates a start of data
        if (!rx) begin
          rx_clk_divider        <= clock_div;
          rx_countdown          <= `HALF_PERIOD;
          rx_state              <= RX_CHECK_START;
        end
      end
      RX_CHECK_START: begin
        //after countdown is finished
        if (rx_countdown == 0) begin
//----|__*__|????|????|????
          if (!rx) begin
            //pulse is still low
            rx_countdown        <= `FULL_PERIOD;
            rx_bits_remaining   <=  7;
            rx_state            <= RX_READ_BITS;
            rx_data             <=  0;
          end
          else begin
            rx_state            <=  RX_ERROR;
          end
        end
      end
      RX_READ_BITS: begin
        if (rx_countdown == 0) begin
          rx_data               <=  {rx, rx_data[7:1]};
          rx_countdown          <=  `FULL_PERIOD;
          //should be halfway through a bit
          //shift the data in from left to right
          if (rx_bits_remaining > 0) begin
            rx_bits_remaining   <=  rx_bits_remaining - 1;
          end
          else begin
            rx_state            <=  RX_CHECK_STOP;
          end
        end
      end
      RX_CHECK_STOP: begin
        if (rx_countdown == 0) begin
          if (rx) begin
            rx_byte             <= rx_data;
            rx_state            <= RX_RECEIVED;
          end
          else begin
            rx_state            <= RX_ERROR;
          end
        end
      end
      RX_DELAY_RESTART: begin
        if (rx_countdown == 0) begin
          rx_state              <= RX_IDLE;
        end
      end
      RX_ERROR: begin
        rx_countdown            <= `FULL_PERIOD;
        rx_state                <= RX_DELAY_RESTART;
      end
      RX_RECEIVED: begin
        received                <= 1;
        rx_state                <= RX_IDLE;
      end
      default: begin
        rx_state                <= RX_IDLE;
      end
    endcase
    //transmit state machine
    case (tx_state)
      TX_IDLE: begin
        if (transmit) begin
          //$display ("Transmit signal received");
          tx_data       <=  tx_byte;
          tx_clk_divider    <= clock_div;
          tx_countdown    <= `FULL_PERIOD;
          tx          <= 0;
          tx_bits_remaining <= 8;
          tx_state      <= TX_SENDING;
        end
      end
      TX_SENDING: begin
        if (tx_countdown == 0) begin
          if (tx_bits_remaining) begin
            tx_bits_remaining   <= tx_bits_remaining - 1;
            tx          <=  tx_data[0];
            tx_data       <= {1'b0, tx_data[7:1]};
            tx_countdown    <= `FULL_PERIOD;
          end
          else begin
            tx          <= 1;
            tx_countdown    <= `FULL_PERIOD;
            tx_state      <= TX_DELAY_RESTART;
          end
        end
        else begin
        end
      end
      TX_DELAY_RESTART: begin
        if (tx_countdown  == 0) begin
          tx_state  <= TX_IDLE;
        end
      end
      default: begin
        tx_state  <= TX_IDLE;
      end
    endcase
  end
end


endmodule
