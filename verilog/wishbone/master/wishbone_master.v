//wishbone_master
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

/*
  05/06/2013
    -Changed mg_defines to cbuilder_defines
  06/24/2012
    -added the i_ih_rst port to indicate that the input handler is resetting
    the incomming data state machine
  02/02/2012
    -changed the read state machine to use local_data_count instead of
      o_data_count
  11/12/2011
    -added support for burst read and writes
    -added support for nacks when the slave doesn't respond in time
  11/07/2011
    -added interrupt handling to the master
    -when the master is idle the interconnect will output the interrupt
      on the wbs data
  10/30/2011
    -fixed the memory bus issue where that master was not responding
      to a slave ack
    -changed the READ and WRITE command to call either the memory
      bus depending on the
    flags in the command sent from the user
  10/25/2011
    -added the interrupt input pin for both busses
  10/23/2011
    -commented out the debug message "GOT AN ACK!!", we're passed this
  10/26/2011
    -removed the stream commands, future versions will use flags instead of
      separate commands
*/
`include "cbuilder_defines.v"

module wishbone_master (

  input               clk,
  input               rst,

  //indicate to the input that we are ready
  output reg          o_master_ready,

  //input handler interface
  input               i_ih_rst,

  input               i_ready,
  input       [31:0]  i_command,
  input       [31:0]  i_address,
  input       [31:0]  i_data,
  input       [27:0]  i_data_count,

  //output handler interface
  input               i_out_ready,
  output reg          o_en        = 0,
  output reg  [31:0]  o_status    = 32'h0,
  output reg  [31:0]  o_address   = 32'h0,
  output reg  [31:0]  o_data      = 32'h0,
  output wire [27:0]  o_data_count,

  //debug output
  output reg  [31:0]  o_debug,

  //wishbone peripheral bus
  output reg  [31:0]  o_per_adr,
  output reg  [31:0]  o_per_dat,
  input       [31:0]  i_per_dat,
  output reg          o_per_stb,
  output reg          o_per_cyc,
  output reg          o_per_we,
  output reg          o_per_msk,
  output reg  [3:0]   o_per_sel,
  input               i_per_ack,
  input               i_per_int,

  //wishbone memory bus
  output reg          o_mem_we,
  output reg  [31:0]  o_mem_adr,
  output reg  [31:0]  o_mem_dat,
  input       [31:0]  i_mem_dat,
  output reg          o_mem_stb,
  output reg          o_mem_cyc,
  output reg          o_mem_msk,
  output reg  [3:0]   o_mem_sel,
  input               i_mem_ack,
  input               i_mem_int

);
//debug output


  //parameters
  localparam       IDLE                  = 32'h00000000;
  localparam       WRITE                 = 32'h00000001;
  localparam       READ                  = 32'h00000002;
  localparam       DUMP_CORE             = 32'h00000003;

  localparam       S_PING_RESP           = 32'h0000C594;

  localparam       DUMP_COUNT            = 14;


  // registers

  reg [31:0]          state             = IDLE;
  reg [31:0]          local_address     = 32'h0;
  reg [31:0]          local_data        = 32'h0;
  reg [27:0]          local_data_count  = 27'h0;
  reg                 mem_bus_select;

  reg [31:0]          master_flags      = 32'h0;
  reg [31:0]          rw_count          = 32'h0;
  reg                 wait_for_slave    = 0;


  reg                 prev_int          = 0;


  reg                 interrupt_mask    = 32'h00000000;

  reg [31:0]          nack_timeout      = `DEF_NACK_TIMEOUT;
  reg [31:0]          nack_count        = 0;

  //core dump
  reg [31:0]          dump_count        = 0;

  reg [31:0]          dump_state        = 0;
  reg [31:0]          dump_status       = 0;
  reg [31:0]          dump_flags        = 0;
  reg [31:0]          dump_nack_count   = 0;
  reg [31:0]          dump_lcommand     = 0;
  reg [31:0]          dump_laddress     = 0;
  reg [31:0]          dump_ldata_count  = 0;
  reg [31:0]          dump_per_state     = 0;
  reg [31:0]          dump_per_p_addr    = 0;
  reg [31:0]          dump_per_p_dat_in  = 0;
  reg [31:0]          dump_per_p_dat_out = 0;
  reg [31:0]          dump_per_m_addr    = 0;
  reg [31:0]          dump_per_m_dat_in  = 0;
  reg [31:0]          dump_per_m_dat_out = 0;

  reg                 prev_reset        = 0;

  // wires
  wire [15:0]         command_flags;
  wire                enable_nack;

  wire [15:0]         real_command;

  wire                pos_edge_reset;

  // assigns
  assign              o_data_count      = ((state == READ) || (state == DUMP_CORE)) ? local_data_count : 0;
  assign              command_flags     = i_command[31:16];
  assign              real_command      = i_command[15:0];

  assign              enable_nack       = master_flags[0];

  assign              pos_edge_reset    = rst & ~prev_reset;


initial begin
//$monitor("%t, int: %h, ih_ready: %h, ack: %h, stb: %h, cyc: %h", $time, i_per_int, i_ready, i_per_ack, o_per_stb_o, o_per_cyc_o);
//$monitor( "%t, cyc: %h, stb: %h, ack: %h, i_ready: %h, o_en: %h, o_master_ready: %h",
//          $time, o_per_cyc, o_per_stb, i_per_ack, i_ready, o_en, o_master_ready);

//$monitor( "%t, addr: %h, data: %h", $time, o_per_adr, o_per_dat);

end


//blocks
always @ (posedge clk) begin

  o_en              <= 0;

//master ready should be used as a flow control, for now its being reset every
//clock cycle, but in the future this should be used to regulate data comming in so that the master can send data to the slaves without overflowing any buffers
  //o_master_ready  <= 1;
  if (pos_edge_reset) begin
    dump_state        <=  state;
    dump_status       <=  {26'h0, i_ih_rst, i_out_ready, o_en, i_ready, o_master_ready, mem_bus_select};
    dump_flags        <=  master_flags;
    dump_nack_count   <=  nack_count;
    dump_lcommand     <=  {command_flags, real_command};
    dump_laddress     <=  i_address;
    dump_ldata_count  <=  local_data_count;
    dump_per_state     <=  {11'h0, o_per_cyc, o_per_stb, o_per_we, i_per_ack, i_per_int,  12'h0, o_mem_cyc, o_mem_stb, o_mem_we, i_mem_ack};
    dump_per_p_addr    <=  o_per_adr;
    dump_per_p_dat_in  <=  i_per_dat;
    dump_per_p_dat_out <=  o_per_dat;
    dump_per_m_addr    <=  o_mem_adr;
    dump_per_m_dat_in  <=  i_mem_dat;
    dump_per_m_dat_out <=  o_mem_dat;



  end

  if (rst || i_ih_rst) begin



    o_status        <= 32'h0;
    o_address       <= 32'h0;
    o_data          <= 32'h0;
    //o_data_count  <= 28'h0;
    local_address     <= 32'h0;
    local_data        <= 32'h0;
    local_data_count  <= 27'h0;
    master_flags      <= 32'h0;
    rw_count          <= 0;
    state             <= IDLE;
    mem_bus_select    <= 0;
    prev_int          <= 0;

    wait_for_slave    <= 0;

    o_debug         <= 32'h00000000;

    //wishbone reset
    o_per_we           <= 0;
    o_per_adr          <= 32'h0;
    o_per_dat          <= 32'h0;
    o_per_stb          <= 0;
    o_per_cyc          <= 0;
    o_per_msk          <= 0;

    //select is always on
    o_per_sel          <= 4'hF;

    //wishbone memory reset
    o_mem_we          <= 0;
    o_mem_adr         <= 32'h0;
    o_mem_dat         <= 32'h0;
    o_mem_stb         <= 0;
    o_mem_cyc         <= 0;
    o_mem_msk         <= 0;

    //select is always on
    o_mem_sel         <= 4'hF;

    //interrupts
    interrupt_mask    <= 32'h00000000;
    nack_timeout      <= `DEF_NACK_TIMEOUT;
    nack_count        <= 0;


  end

  else begin

    //check for timeout conditions
    if (nack_count == 0) begin
      if (state != IDLE && enable_nack) begin
        o_debug[4]  <= ~o_debug[4];
        $display ("WBM: Timed out");
        //timeout occured, send a nack and go back to IDLE
        state         <= IDLE;
        o_status    <= `NACK_TIMEOUT;
        o_address   <= 32'h00000000;
        o_data      <= 32'h00000000;
        o_en        <= 1;
      end
    end
    else begin
      nack_count <= nack_count - 1;
    end

    //check if the input handler reset us
    case (state)
      READ: begin
        if (mem_bus_select) begin
          if (i_mem_ack) begin
            //put the strobe down to say we got that double word
            o_mem_stb <= 0;
          end
          else if (~o_mem_stb && i_out_ready) begin
            $display("WBM: local_data_count = %h", local_data_count);
            o_data    <= i_mem_dat;
            o_en      <= 1;
            if (local_data_count > 1) begin
              o_debug[9]  <=  ~o_debug[9];
              //finished the next double word
              nack_count    <= nack_timeout;
              local_data_count  <= local_data_count - 1;
              $display ("WBM: (burst mode) reading double word from memory");
              o_mem_adr   <= o_mem_adr + 1;
              o_mem_stb   <= 1;
              //initiate an output transfer
            end
            else begin
              //finished all the reads de-assert the cycle
              o_debug[10]  <=  ~o_debug[10];
              o_mem_cyc   <=  0;
              state       <=  IDLE;
            end
          end
        end
        else begin
          //Peripheral BUS
          if (i_per_ack) begin
            o_per_stb    <= 0;
          end
          else if (~o_per_stb && i_out_ready) begin
            $display("WBM: local_data_count = %h", local_data_count);
           //put the data in the otput
           o_data    <= i_per_dat;
           //tell the io_handler to send data
           o_en    <= 1;

            if (local_data_count > 1) begin
              o_debug[8]  <=  ~o_debug[8];
//the nack count might need to be reset outside of these conditionals becuase
//at this point we are waiting on the io handler
              nack_count    <= nack_timeout;
              local_data_count  <= local_data_count - 1;
              $display ("WBM: (burst mode) reading double word from peripheral");
              o_per_adr    <= o_per_adr + 1;
              o_per_stb    <= 1;
            end
            else begin
              //finished all the reads, put de-assert the cycle
              o_debug[7]  <= ~o_debug[7];
              o_per_cyc    <= 0;
              state       <= IDLE;
            end
          end
        end
      end
      WRITE: begin
        if (mem_bus_select) begin
          if (i_mem_ack) begin
            o_mem_stb               <= 0;
            if (o_mem_stb) begin
              o_mem_adr               <= o_mem_adr + 1;
            end
            if (local_data_count <= 1) begin
              //finished all writes
              $display ("WBM: i_data_count == 0");
              o_debug[12]           <= ~o_debug[12];
              o_mem_cyc             <= 0;
              state                 <= IDLE;
              o_en                  <= 1;
              o_mem_we              <= 0;
            end
            //tell the IO handler were ready for the next one
            o_master_ready          <=  1;
          end
          else if ((local_data_count > 1) && i_ready && (o_mem_stb == 0)) begin
            local_data_count        <= local_data_count - 1;
            $display ("WBM: (burst mode) writing another double word to memory");
            o_master_ready          <= 0;
            o_mem_stb               <= 1;
            o_mem_dat               <= i_data;
            nack_count              <= nack_timeout;
            o_debug[13]             <= ~o_debug[13];
          end
        end //end working with mem_bus
        else begin //peripheral bus
          if (i_per_ack) begin
            o_per_stb               <= 0;
            if (local_data_count    <= 1) begin
              $display ("WBM: i_data_count == 0");
              o_per_cyc             <= 0;
              state                 <= IDLE;
              o_en                  <= 1;
              o_per_we              <= 0;
            end
            //tell the IO handler were ready for the next one
            o_master_ready  <= 1;
          end
          else if ((local_data_count > 1) && i_ready && (o_per_stb == 0)) begin
            local_data_count        <= local_data_count - 1;
            o_debug[5]              <= ~o_debug[5];
            $display ("WBM: (burst mode) writing another double word to peripheral");
            o_master_ready          <=  0;
            o_per_stb               <= 1;
            o_per_adr               <= o_per_adr + 1;
            o_per_dat               <= i_data;
            nack_count              <= nack_timeout;
          end
        end
      end
      DUMP_CORE: begin
        if (i_out_ready && !o_en) begin
          case (dump_count)
            0:  begin
              o_data          <=  dump_state;
            end
            1:  begin
              o_data          <=  dump_status;
            end
            2:  begin
              o_data          <=  dump_flags;
            end
            3:  begin
              o_data          <=  dump_nack_count;
            end
            4:  begin
              o_data          <=  dump_lcommand;
            end
            5:  begin
              o_data          <=  dump_laddress;
            end
            6:  begin
              o_data          <=  dump_ldata_count;
            end
            7:  begin
              o_data          <=  dump_per_state;
            end
            8:  begin
              o_data          <=  dump_per_p_addr;
            end
            9:  begin
              o_data          <=  dump_per_p_dat_in;
            end
            10: begin
              o_data          <=  dump_per_p_dat_out;
            end
            11: begin
              o_data          <=  dump_per_m_addr;
            end
            12: begin
              o_data          <=  dump_per_m_dat_in;
            end
            13: begin
              o_data          <=  dump_per_m_dat_out;
            end
            default: begin
              o_data            <=  32'hFFFFFFFF;
            end
          endcase
          if (local_data_count > 0) begin
             local_data_count <= local_data_count - 1;
           end
           else begin
            state                  <=  IDLE;
           end
           o_status                <=  ~i_command;
           o_address               <=  0;
           o_en                    <=  1;
           dump_count              <=  dump_count + 1;
        end
      end
      IDLE: begin
        //handle input
        o_master_ready             <= 1;
        mem_bus_select             <= 0;
        if (i_ready) begin
          o_debug[6]               <= ~o_debug[6];
          mem_bus_select           <= 0;
          nack_count               <= nack_timeout;

          local_address            <= i_address;
          local_data               <= i_data;
          //o_data_count           <= 0;

          case (real_command)

            `COMMAND_PING: begin
              $display ("WBM: ping");
              o_master_ready       <= 0;
              o_debug[0]           <= ~o_debug[0];
              o_status             <= ~i_command;
              o_address            <= 32'h00000000;
              o_data               <= S_PING_RESP;
              o_en                 <= 1;
              state                <= IDLE;
            end
            `COMMAND_WRITE: begin
              o_status             <= ~i_command;
              o_debug[1]           <= ~o_debug[1];
              local_data_count     <= i_data_count;
              if (command_flags & `FLAG_MEM_BUS) begin
                mem_bus_select     <= 1;
                o_mem_adr          <= i_address;
                o_mem_stb          <= 1;
                o_mem_cyc          <= 1;
                o_mem_we           <= 1;
                o_mem_dat          <= i_data;
              end
              else begin
                mem_bus_select     <= 0;
                o_per_adr          <= i_address;
                o_per_stb          <= 1;
                o_per_cyc          <= 1;
                o_per_we           <= 1;
                o_per_dat          <= i_data;
              end
              o_address            <= i_address;
              o_data               <= i_data;
              o_master_ready       <= 0;
              state                <= WRITE;
            end
            `COMMAND_READ:  begin
              $display ("WBM: Received Read Command");
              local_data_count    <=  i_data_count;
              o_debug[2]          <= ~o_debug[2];
              if (command_flags & `FLAG_MEM_BUS) begin
                mem_bus_select    <= 1;
                o_mem_adr         <= i_address;
                o_mem_stb         <= 1;
                o_mem_cyc         <= 1;
                o_mem_we          <= 0;
                o_status          <= ~i_command;
              end
              else begin
                mem_bus_select    <= 0;
                o_per_adr         <= i_address;
                o_per_stb         <= 1;
                o_per_cyc         <= 1;
                o_per_we          <= 0;
                o_status          <= ~i_command;
              end
              o_master_ready      <= 0;
              o_address           <= i_address;
              state               <= READ;
            end
            `COMMAND_MASTER_ADDR: begin
              o_address           <=  i_address;
              o_status            <= ~i_command;
              case (i_address)
                `MADDR_WR_FLAGS: begin
                  master_flags    <= i_data;
                end
                `MADDR_RD_FLAGS: begin
                  o_data          <= master_flags;
                end
                `MADDR_WR_INT_EN: begin
                  interrupt_mask  <= i_data;
                  o_data          <=  i_data;
                  $display("WBM: setting interrupt enable to: %h", i_data);
                end
                `MADDR_RD_INT_EN: begin
                  o_data          <= interrupt_mask;
                end
                `MADDR_NACK_TO_WR: begin
                  nack_timeout    <= i_data;
                end
                `MADDR_NACK_TO_RD: begin
                  o_data          <= nack_timeout;
                end
                default: begin
                  //unrecognized command
                  o_status        <=  32'h00000000;
               end
              endcase
              o_en                <=  1;
              state               <=  IDLE;
            end
            `COMMAND_CORE_DUMP: begin
              local_data_count    <=  DUMP_COUNT + 1;
              dump_count          <=  0;
              state               <=  DUMP_CORE;
            end
            default:    begin
            end
          endcase
        end
        //not handling an input, if there is an interrupt send it to the user
        else if (!i_per_ack && !o_per_stb && !o_per_cyc && i_out_ready) begin
          //hack for getting the i_data_count before the io_handler decrements it
            //local_data_count  <= i_data_count;
            //work around to add a delay
            o_per_adr             <= local_address;
            //handle input
            local_address         <= 32'hFFFFFFFF;
          //check if there is an interrupt
          //if the i_per_int goes positive then send a nortifiction to the user
          if ((~prev_int) & i_per_int) begin
            o_debug[11]           <= ~o_debug[11];
            $display("WBM: found an interrupt!");
            o_status              <= `PERIPH_INTERRUPT;
            //only supporting interrupts on slave 0 - 31
            o_address             <= 32'h00000000;
            o_data                <= i_per_dat;
            o_en                  <= 1;
          end
          prev_int  <= i_per_int;
        end
      end
      default: begin
      state <= IDLE;
      end
    endcase
    if (!i_per_int) begin
      prev_int <= 0;
    end
  end
  //handle output
  prev_reset  <=  rst;
end

endmodule
