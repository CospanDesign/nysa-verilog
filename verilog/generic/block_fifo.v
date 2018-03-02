/*
Distributed under the MIT licesnse.
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

`timescale 1ns/1ps

//XXX: NOTE: All counts are 24bits long, this could be a parameter in the future


module block_fifo
#(parameter     DATA_WIDTH    = 8,
                ADDRESS_WIDTH = 4
)(

  //universal input
  input                             reset,

  //write side
  input                             write_clock,
  output                            write_ready,
  input                             write_activate,
  output      [23:0]                write_fifo_size,
  input                             write_strobe,
  input       [DATA_WIDTH - 1: 0]   write_data,
  output reg                        starved,

  //read side
  input                             read_clock,
  input                             read_strobe,
  output reg                        read_ready,
  input                             read_activate,
  output reg  [23:0]                read_count,
  output      [DATA_WIDTH - 1: 0]   read_data,

  output                            inactive

);

localparam FIFO_DEPTH = (1 << ADDRESS_WIDTH);

//Local Registers/Wires

//Write Side
reg   [1:0]                 r_write_ready;
reg   [1:0]                 r_write_activate;

wire                        ppfifo_ready;  // The write side only needs to
                                           // know were ready if we don't
                                           // write anything read won't start
wire  [ADDRESS_WIDTH: 0]    addr_in;       // Actual address to the BRAM
reg   [ADDRESS_WIDTH - 1: 0]write_address;
reg                         r_wselect;      // Select the FIFO to work with
reg                         write_enable;  // Enable a write to the BRAM

reg   [1:0]                 wcc_read_ready;// Tell read side a FIFO is ready
reg   [1:0]                 wcc_read_done;
                                            // write status of the read
                                            // available
reg                         wcc_tie_select; //because it's possible if the read
                                            //side is slower than the write
                                            //side it might be unknown which
                                            //side was selected first, so use
                                            //this signal to break ties

reg   [23:0]                w_count[1:0];   // save the write count for the read
                                            // side
reg                         w_empty[1:0];
reg                         w_reset;        //write side reset
reg   [4:0]                 w_reset_timeout;
wire                        ready;

//Read Side
wire  [ADDRESS_WIDTH: 0]    addr_out;     //Actual address to the BRAM
reg                         r_reset;
reg   [4:0]                 r_reset_timeout;

reg   [ADDRESS_WIDTH - 1: 0]r_address;    //Address to access a bank
reg                         r_rselect;     //Select a bank (Select a FIFO)

reg   [1:0]                 rcc_read_ready;
                                          // Write side says X is ready
reg   [1:0]                 rcc_read_done;// Tell write side X is ready
reg                         rcc_tie_select;
                                          //If there is a tie, then this will
                                          //break it

reg   [23:0]                r_size[1:0];  // Size of FX read

reg   [1:0]                 r_ready;      //FIFO is ready
reg   [1:0]                 r_wait;       //Waiting for write side to send data
reg   [1:0]                 r_activate;   //Controls which FIFO is activated

reg                         r_next_fifo;  //If both FIFOs are availalbe use this

reg   [1:0]                 r_pre_activate; //Used to delay the clock cycle by
                                            //one when the user activates the
                                            //FIFO

reg                         r_pre_strobe;
reg                         r_pre_read_wait;//Wait an extra cycle so the registered data has a chance to set
                                            //the data to be registered
reg   [DATA_WIDTH - 1: 0]   r_br_read_data; //data from the read FIFO
reg   [DATA_WIDTH - 1: 0]   r_read_data;    //data from the read FIFO

assign  write_fifo_size     = FIFO_DEPTH;

assign  addr_in             = {r_wselect, write_address};
//assign  write_enable        = (r_write_activate > 0) && write_strobe;
assign  ppfifo_ready        = !(w_reset || r_reset);
assign  ready               = ppfifo_ready;


assign  addr_out            = {r_rselect, r_address};
assign  inactive            = (w_count[0] == 0) &&
                              (w_count[1] == 0) &&
                              (r_write_ready == 2'b11) &&
                              (!write_strobe);


assign  read_data           = (r_pre_strobe) ? r_br_read_data : r_read_data;
assign  write_ready         = (r_write_ready > 0);


//Submodules
reg [DATA_WIDTH - 1:0] mem [0:2 ** (ADDRESS_WIDTH + 1)];
always @ (posedge write_clock)
begin
  if ( write_enable ) begin
     mem[addr_in]   <= write_data;
  end
end

//read only on the b side
always @ (posedge read_clock)
begin
     r_br_read_data    <= mem[addr_out];
end

//Cross Clock (Write -> Read)

reg         [2:0] ccfw0;  //W - R FIFO0 Read FIFO Ready
reg         [2:0] ccfw1;  //W - R FIFO1 Read FIFO Ready
reg         [2:0] ccts;   //W - R Tie Select

always @ (posedge read_clock) begin
  if (reset) begin
    ccfw0             <=  3'b000;
    ccfw1             <=  3'b000;
    ccts              <=  3'b000;
    rcc_read_ready[0] <=  0;
    rcc_read_ready[1] <=  0;
    rcc_tie_select    <=  0;
   end
  else begin
    if (ccfw0[2:1] == 2'b11) begin
      rcc_read_ready[0] <=  1;
    end
    else if (ccfw0[2:1] == 2'b00) begin
      rcc_read_ready[0] <=  0;
    end

    if (ccfw1[2:1] == 2'b11) begin
      rcc_read_ready[1] <=  1;
    end
    else if (ccfw1[2:1] == 2'b00) begin
      rcc_read_ready[1] <=  0;
    end

    if (ccts[2:1] == 2'b11) begin
      rcc_tie_select    <=  1;
    end
    else if (ccts[2:1] == 2'b00) begin
      rcc_tie_select    <=  0;
    end

    //Clock in everything on the local clock
    ccfw0     <=  {ccfw0[1:0], wcc_read_ready[0]};
    ccfw1     <=  {ccfw1[1:0], wcc_read_ready[1]};
    ccts      <=  {ccts[1:0],  wcc_tie_select};
  end
end

reg         [2:0] ccrf0;  //R - W FIFO0 Read Done
reg         [2:0] ccrf1;  //R - W FIFO2 Read Done
reg         [2:0] ccstv;  //R - W No data in the FIFO

always @ (posedge write_clock) begin
  if (reset) begin
    ccrf0             <=  3'b000;
    ccrf1             <=  3'b000;
    ccstv             <=  3'b000;

    wcc_read_done[0]  <=  0;
    wcc_read_done[1]  <=  0;
    starved           <=  0;
  end
  else begin

    if (ccrf0[2:1] == 2'b11) begin
      wcc_read_done[0]  <=  1;
    end
    else if (ccrf0[2:1] == 2'b00) begin
      wcc_read_done[0]  <=  0;
    end

    if (ccrf1[2:1] == 2'b11) begin
      wcc_read_done[1]  <=  1;
    end
    else if (ccrf1[2:1] == 2'b00) begin
      wcc_read_done[1]  <=  0;
    end

    if (ccstv[2:1] == 2'b11) begin
      starved           <=  1;
    end
    else if (ccstv[2:1] == 2'b00) begin
      starved           <=  0;
    end

    ccrf0     <=  {ccrf0[1:0], rcc_read_done[0]};
    ccrf1     <=  {ccrf1[1:0], rcc_read_done[1]};
    ccstv     <=  {ccstv[1:0], (!read_ready && !read_activate)};
  end
end


//asynchronous logic
always @ (*) begin
  case (wcc_read_ready)
    2'b00: begin
      wcc_tie_select  = 1'b0;
    end
    2'b01: begin
      wcc_tie_select  = 1'b0;
    end
    2'b10: begin
      wcc_tie_select  = 1'b1;
    end
    default: begin
      wcc_tie_select  = 1'b0;
    end
  endcase
end
always @ (*) begin
  if (write_ready && write_activate && !r_write_activate) begin
    if (r_write_ready[0]) begin
      r_write_activate  = 2'b01;
    end
    else begin
      r_write_activate  = 2'b10;
    end
  end
  else if (!write_activate) begin
    r_write_activate    = 2'b00;
  end
end
always @ (*) begin
  case (r_write_activate)
    2'b00: begin
      r_wselect   = 1'b0;
    end
    2'b01: begin
      r_wselect   = 1'b0;
    end
    2'b10: begin
      r_wselect   = 1'b1;
    end
    default: begin
      r_wselect   = 1'b0;
    end
  endcase
end

always @ (*) begin
  if (r_write_activate > 0 && write_strobe) begin
    write_enable  = 1'b1;
  end
  else begin
    write_enable  = 1'b0;
  end
end
//synchronous logic

//Reset Logic
always @ (posedge write_clock) begin
  if (reset) begin
    w_reset         <=  1;
    w_reset_timeout <=  0;
  end
  else begin
    if (w_reset && (w_reset_timeout < 5'h4)) begin
      w_reset_timeout <=  w_reset_timeout + 5'h1;
    end
    else begin
      w_reset       <=  0;
    end
  end
end

always @ (posedge read_clock) begin
  if (reset) begin
    r_reset           <=  1;
    r_reset_timeout   <=  0;
  end
  else begin
    if (r_reset && (r_reset_timeout < 5'h4)) begin
      r_reset_timeout <= r_reset_timeout + 5'h1;
    end
    else begin
      r_reset         <=  0;
    end
  end
end

//---------------Write Side---------------
initial begin
  write_address     = 0;

  wcc_read_ready    = 2'b00;
  r_write_ready       = 2'b00;
  w_reset           = 1;
  w_reset_timeout   = 0;
  write_enable      = 0;
  r_wselect         = 0;
  wcc_tie_select    = 0;
end

always @ (posedge write_clock) begin
  if (reset) begin
    r_write_ready     <=  0;
  end
  else if (ready) begin
    //Logic for the Write Enable
    if (r_write_activate[0] && write_strobe) begin
      r_write_ready[0] <=  1'b0;
    end
    if (r_write_activate[1] && write_strobe) begin
      r_write_ready[1] <=  1'b0;
    end

    if (!r_write_activate[0] && (w_count[0] == 0) && wcc_read_done[0]) begin
      //FIFO 0 is not accessed by the read side, and user has not activated
      r_write_ready[0]  <=  1;
    end
    if (!r_write_activate[1] && (w_count[1] == 0) && wcc_read_done[1]) begin
      //FIFO 1 is not accessed by the read side, and user has not activated
      r_write_ready[1]  <=  1;
    end

    //When the user is finished reading the ready signal might go high
    //I SHOULD MAKE A CONDITION WHERE THE WRITE COUND MUST BE 0
  end
end

always @ (posedge write_clock) begin
  if (reset) begin  //Asynchronous Reset
    wcc_read_ready  <=  2'b00;
    write_address   <=  0;
    w_count[0]      <=  24'h0;
    w_count[1]      <=  24'h0;
  end
  else begin
    if (r_write_activate > 0 && write_strobe) begin
      write_address <=  write_address + 1;
      if (r_write_activate[0]) begin
        w_count[0]  <=  w_count[0] + 1;
      end
      if (r_write_activate[1]) begin
        w_count[1]  <=  w_count[1] + 1;
      end
    end
    if (r_write_activate == 0) begin
      write_address     <=  0;
      if (w_count[0] > 0) begin
        wcc_read_ready[0]  <=  1;
      end
      if (w_count[1] > 0) begin
        wcc_read_ready[1]  <=  1;
      end
    end
    //I can't reset the w_count until the read side has indicated that it
    //is done but that may be mistriggered when the write side finishes
    //a write. So how do

    //Only reset the write count when the done signal has been de-asserted

    //Deassert w_readX_ready when we see the read has de-asserted r_readX_done
    if (!wcc_read_done[0]) begin
      //Only reset write count when the read side has said it's busy so it
      //must be done reading
      w_count[0]        <=  0;
      wcc_read_ready[0] <=  0;
    end
    if (!wcc_read_done[1]) begin
      w_count[1]        <=  0;
      wcc_read_ready[1] <=  0;
    end
  end
end


//---------------Read Side---------------
initial begin
  r_rselect       = 0;
  r_address       = 0;

  rcc_read_done   = 2'b00;

  r_size[0]       = 24'h0;
  r_size[1]       = 24'h0;

  r_wait          = 2'b11;
  r_ready         = 2'b00;
  r_activate      = 2'b00;
  r_pre_activate  = 0;

  r_next_fifo     = 0;
  r_reset         = 1;
  r_reset_timeout = 0;
  read_ready      = 0;
  r_read_data     = 32'h0;
  r_pre_read_wait = 0;
end

always @ (posedge read_clock) begin
  if (reset) begin  //Asynchronous Reset
    r_rselect                       <=  0;
    r_address                       <=  0;
    rcc_read_done                   <=  2'b11;
    read_count                      <=  0;
    r_activate                      <=  2'b00;
    r_pre_activate                  <=  2'b00;
    r_pre_read_wait                 <=  0;

    r_size[0]                       <=  24'h0;
    r_size[1]                       <=  24'h0;

    //are these signals redundant?? can I just use the done?
    r_wait                          <=  2'b11;

    r_ready                         <=  2'b00;

    r_next_fifo                     <=  0;
    r_read_data                     <=  0;
    read_ready                      <=  0;

  end
  else begin
    r_pre_strobe                    <=  read_strobe;
    //Handle user enable and ready
    if (!read_activate && !r_pre_activate) begin
      //User has not activated the read side

      //Prepare the read side
      //Reset the address
      if (r_activate == 0) begin
        read_count                      <=  0;
        r_address                       <=  0;
        r_pre_read_wait                 <=  0;
        if (r_ready > 0) begin
          //This goes to one instead of activate
          //Output select
          //read_ready                  <=  1;

          if (r_ready[0] && r_ready[1]) begin
            //$display ("Tie");
            //Tie
            r_rselect                   <=  r_next_fifo;
            r_pre_activate[r_next_fifo] <=  1;
            r_pre_activate[~r_next_fifo]<=  0;
            r_next_fifo                 <=  ~r_next_fifo;
            read_count                  <=  r_size[r_next_fifo];
          end
          else begin
            //Only one side is ready
            if (r_ready[0]) begin
              //$display ("select 0");
              r_rselect                 <=  0;
              r_pre_activate[0]         <=  1;
              r_pre_activate[1]         <=  0;
              r_next_fifo               <=  1;
              read_count                <=  r_size[0];
            end
            else begin
              //$display ("select 1");
              r_rselect                 <=  1;
              r_pre_activate[0]         <=  0;
              r_pre_activate[1]         <=  1;
              r_next_fifo               <=  0;
              read_count                <=  r_size[1];
            end
          end
        end
      end
      //User has finished reading something
      else if (r_activate[r_rselect] && !r_ready[r_rselect]) begin
        r_activate[r_rselect]          <=  0;
        rcc_read_done[r_rselect]       <=  1;
      end
    end
    else begin
      if ((r_pre_activate > 0) && r_pre_read_wait) begin
        read_ready                      <=  1;
      end


      if (r_activate) begin
        read_ready                    <=  0;
        //User is requesting an accss
        //Handle read strobes
        //Only handle strobes when we are enabled
        r_ready[r_rselect]            <=  0;
      end

      //XXX: There should be a better way to handle these edge conditions
      if (!r_activate && r_pre_read_wait) begin
        r_read_data                     <=  r_br_read_data;
        r_address                       <=  r_address + 1;
        r_activate                      <=  r_pre_activate;
        r_pre_activate                  <=  0;
      end
      else if (!r_pre_read_wait) begin
        r_pre_read_wait                 <=  1;
      end

      if (read_strobe && (r_address < (r_size[r_rselect] + 1))) begin
        //Increment the address
        r_read_data                     <=  r_br_read_data;
        r_address                       <=  r_address + 1;
      end
      if (r_pre_strobe && !read_strobe) begin
        r_read_data                     <=  r_br_read_data;
      end
    end
    if (!rcc_read_ready[0] && !r_ready[0] && !r_activate[0]) begin
      r_wait[0]                       <=  1;
    end
    if (!rcc_read_ready[1] && !r_ready[1] && !r_activate[1]) begin
      r_wait[1]                       <=  1;
    end

    //Check if the write side has sent over some data
    if (rcc_read_ready > 0) begin
      if ((r_wait == 2'b11) && (rcc_read_ready == 2'b11) && (w_count[0] > 0) && (w_count[1] > 0)) begin
        //An ambiguous sitution that can arrise if the read side is much
        //slower than the write side, both sides can arrise seemingly at the
        //same time, so there needs to be a tie breaker
        //$display ("Combo breaker goes to: %h", rcc_tie_select);
        r_next_fifo         <= rcc_tie_select;
      end
      if (r_wait[0] && rcc_read_ready[0]) begin
        //$display ("write has send over data t othe 0 side");
        //Normally it would not be cool to transfer data over a clock domain
        //but the w_count[x] is stable before the write side sends over a write
        //strobe
        if (w_count[0] > 0) begin
          //Only enable when count > 0
          if ((r_activate == 0) && (!rcc_read_ready[1])) begin
            //$display ("select 0");
            r_next_fifo   <=  0;
          end
          r_size[0]         <=  w_count[0];
          r_ready[0]        <=  1;
          r_wait[0]         <=  0;
          rcc_read_done[0]  <=  0;
        end
      end

      if (r_wait[1] && rcc_read_ready[1]) begin
        //$display ("write has send over data t othe 1 side");
        //Write side has sent some data over
        if (w_count[1] > 0) begin
          if ((r_activate == 0) && (!rcc_read_ready[0])) begin
            //$display ("select 1");
            r_next_fifo   <=  1;
          end
          r_size[1]         <=  w_count[1];
          r_ready[1]        <=  1;
          r_wait[1]         <=  0;
          rcc_read_done[1]  <=  0;
        end
      end
    end
  end
end

endmodule
