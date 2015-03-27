//wb_dma_writer.v
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

/* Log
  5/08/2013:
    -Added a test for ack on the read section so that there is no double reads
  4/16/2011:
    -implemented style i_: input, o_: output, r_: register, w_: wire
    -moved the entire port declaration within the module declaration
    -changed Parameters to localparams so the address cannot be inadvertently
      changed with a parameter statement outside the module
    -refactored the logs so they don't take up as much space
  10/29/2011:
    -added 'else' statement for reset
  10/23/2011:
    -fixed the wbs_ack_i to wbs_ack
    -added the default entires for read and write to illustrate different
      communication
    -added license
  9/10/2011:
    -removed duplicate wbs_dat_i
    -added the wbs_sel_i port
*/
/*
  Use this to tell Nysa how to populate the Device ROM table
  so that users can interact with your slave

  META DATA

  identification of your device 0 - 65536
  DRT_ID:101

  flags (read drt.txt in the slave/device_rom_table directory 1 means
  a standard device
  DRT_FLAGS:1

  number of registers this should be equal to the nubmer of ADDR_???
  parameters
  DRT_SIZE:6

*/

`include "dma_writer_defines.v"

module wb_dma_writer #(
  parameter           BUFFER_SIZE = 12
)(
  input               clk,
  input               rst,

  //Add signals to control your device here

  //Wishbone Bus Signals
  input               i_wbs_we,
  input               i_wbs_cyc,
  input       [3:0]   i_wbs_sel,
  input       [31:0]  i_wbs_dat,
  input               i_wbs_stb,
  output  reg         o_wbs_ack,
  output  reg [31:0]  o_wbs_dat,
  input       [31:0]  i_wbs_adr,
  output  reg         o_wbs_int,

  //master control signal for memory arbitration
  output              mem_o_we,
  output              mem_o_stb,
  output              mem_o_cyc,
  output      [3:0]   mem_o_sel,
  output      [31:0]  mem_o_adr,
  output      [31:0]  mem_o_dat,
  input       [31:0]  mem_i_dat,
  input               mem_i_ack,
  input               mem_i_int
);

//Local Parameters
localparam           REG_CONTROL          = 32'h00000000;
localparam           REG_STATUS           = 32'h00000001;
localparam           REG_MEM_0_BASE       = 32'h00000002;
localparam           REG_MEM_0_SIZE       = 32'h00000003;
localparam           REG_MEM_1_BASE       = 32'h00000004;
localparam           REG_MEM_1_SIZE       = 32'h00000005;
localparam           REG_TOTAL_WRITE_SIZE = 32'h00000006;

//Local Registers/Wires
reg         [31:0]  r_control;
wire        [31:0]  w_status;

//Control Signals
wire                w_enable;
wire                w_enable_interrupt;
wire                w_control_reset;

//PPFIFO Signals
wire        [23:0]  w_wfifo_size;
wire        [1:0]   w_wfifo_ready;
wire        [1:0]   w_wfifo_activate;
wire                w_wfifo_strobe;
wire        [31:0]  w_wfifo_data;

wire        [23:0]  w_rfifo_size;
wire                w_rfifo_ready;
wire                w_rfifo_activate;
wire                w_rfifo_strobe;
wire        [31:0]  w_rfifo_data;

reg         [31:0]  r_ppfifo_size_request;

//Mem 2 PPFIFO
reg         [31:0]  r_memory_0_base;
reg         [31:0]  r_memory_0_size;
wire        [31:0]  w_memory_0_count;
reg                 r_memory_0_new_data;
wire                w_memory_0_empty;

wire        [31:0]  w_default_mem_0_base;

reg         [31:0]  r_memory_1_base;
reg         [31:0]  r_memory_1_size;
wire        [31:0]  w_memory_1_count;
reg                 r_memory_1_new_data;
wire                w_memory_1_empty;

wire        [31:0]  w_default_mem_1_base;

wire                w_read_finished;

//Submodules
wb_mem_2_ppfifo m2p(

  .clk                  (clk                      ),
  .rst                  (rst || w_control_reset   ),
  //.debug                (debug                    ),

  //Control
  .i_enable             (w_enable                 ),

  .i_memory_0_base      (r_memory_0_base          ),
  .i_memory_0_size      (r_memory_0_size          ),
  .o_memory_0_count     (w_memory_0_count         ),
  .i_memory_0_new_data  (r_memory_0_new_data      ),
  .o_memory_0_empty     (w_memory_0_empty         ),

  .o_default_mem_0_base (w_default_mem_0_base     ),

  .i_memory_1_base      (r_memory_1_base          ),
  .i_memory_1_size      (r_memory_1_size          ),
  .o_memory_1_count     (w_memory_1_count         ),
  .i_memory_1_new_data  (r_memory_1_new_data      ),
  .o_memory_1_empty     (w_memory_1_empty         ),

  .o_default_mem_1_base (w_default_mem_1_base     ),

  .o_read_finished      (w_read_finished          ),

  //master control signal for memory arbitration
  .o_mem_we             (mem_o_we                 ),
  .o_mem_stb            (mem_o_stb                ),
  .o_mem_cyc            (mem_o_cyc                ),
  .o_mem_sel            (mem_o_sel                ),
  .o_mem_adr            (mem_o_adr                ),
  .o_mem_dat            (mem_o_dat                ),
  .i_mem_dat            (mem_i_dat                ),
  .i_mem_ack            (mem_i_ack                ),
  .i_mem_int            (mem_i_int                ),

  //Ping Pong FIFO Interface
  .i_ppfifo_rdy         (w_wfifo_ready            ),
  .o_ppfifo_act         (w_wfifo_activate         ),
  .i_ppfifo_size        (w_wfifo_size             ),
  .o_ppfifo_stb         (w_wfifo_strobe           ),
  .o_ppfifo_data        (w_wfifo_data             )
);

/*
* It may be better if the Ping Pong FIFO is in another core, especially you
* are clocking the data in with a seperate clock
*/
ppfifo #(
  .DATA_WIDTH           (32                       ),
                        //Size will always be 32 bits for mem
  .ADDRESS_WIDTH        (BUFFER_SIZE              )
                        //Parameterize the depth of the PPFIFO
) ping_pong (
  .reset                (rst |  w_control_reset   ),

  //write
  .write_clock          (clk                      ),
  .write_ready          (w_wfifo_ready            ),
  .write_activate       (w_wfifo_activate         ),
  .write_fifo_size      (w_wfifo_size             ),
  .write_strobe         (w_wfifo_strobe           ),
  .write_data           (w_wfifo_data             ),

  //read
  .read_clock           (clk                      ),
  .read_strobe          (w_rfifo_strobe           ),
  .read_ready           (w_rfifo_ready            ),
  .read_activate        (w_rfifo_activate         ),
  .read_count           (w_rfifo_size             ),
  .read_data            (w_rfifo_data             )
);

ppfifo_data_sink sink(
  .clk                  (clk                      ),
  .rst                  (rst  | w_control_reset   ),

  .i_rd_rdy             (w_rfifo_ready            ),
  .o_rd_act             (w_rfifo_activate         ),
  .i_rd_size            (w_rfifo_size             ),
  .o_rd_stb             (w_rfifo_strobe           ),
  .i_rd_data            (w_rfifo_data             )
);



//Asynchronous Logic
assign  w_enable            = r_control[`CONTROL_ENABLE];
assign  w_enable_interrupt  = r_control[`CONTROL_ENABLE_INTERRUPT];
assign  w_control_reset     = r_control[`CONTROL_RESET];

assign  w_default_mem_0_base= `DEFAULT_MEM_0_BASE;
assign  w_default_mem_1_base= `DEFAULT_MEM_1_BASE;

assign  w_status            = {30'h0,
                               w_memory_1_empty,
                               w_memory_0_empty};

//Synchronous Logic

always @ (posedge clk) begin
  if (rst) begin
    o_wbs_dat             <= 32'h0;
    o_wbs_ack             <= 0;

    r_control             <=  0;

    //Default base, user can change this from the API
    r_memory_0_base       <=  w_default_mem_0_base;
    r_memory_1_base       <=  w_default_mem_1_base;

    //Nothing in the memory initially
    r_memory_0_size       <=  0;
    r_memory_1_size       <=  0;

    r_memory_0_new_data   <=  0;
    r_memory_1_new_data   <=  0;

    r_ppfifo_size_request <=  0;

  end

  else begin
    //Strobes
    r_memory_0_new_data   <=  0;
    r_memory_1_new_data   <=  0;

    //when the master acks our ack, then put our ack down
    if (o_wbs_ack && ~i_wbs_stb)begin
      o_wbs_ack <= 0;
    end

    if (i_wbs_stb && i_wbs_cyc) begin
      //master is requesting somethign
      if (i_wbs_we) begin
        //write request
        case (i_wbs_adr)
          REG_CONTROL: begin
            r_control             <=  i_wbs_dat;
          end
          REG_MEM_0_BASE: begin
            r_memory_0_base       <=  i_wbs_dat;
          end
          REG_MEM_0_SIZE: begin
            r_memory_0_size       <=  i_wbs_dat;
            r_ppfifo_size_request <=  i_wbs_dat;
            if (i_wbs_dat > 0) begin
              r_memory_0_new_data <=  1;
            end
          end
          REG_MEM_1_BASE: begin
            r_memory_1_base       <=  i_wbs_dat;
          end
          REG_MEM_1_SIZE: begin
            r_memory_1_size       <=  i_wbs_dat;
            r_ppfifo_size_request <=  i_wbs_dat;
            if (i_wbs_dat > 0) begin
              r_memory_1_new_data <=  1;
            end
          end
          REG_TOTAL_WRITE_SIZE: begin
          end
          default: begin
          end
        endcase
      end
      else begin
        if (!o_wbs_ack) begin //Fix double reads
          //read request
          case (i_wbs_adr)
            REG_CONTROL: begin
              o_wbs_dat           <= r_control;
            end
            REG_STATUS: begin
              o_wbs_dat           <= w_status;
            end
            REG_MEM_0_BASE: begin
              o_wbs_dat           <=  r_memory_0_base;
            end
            REG_MEM_0_SIZE: begin
              o_wbs_dat           <=  w_memory_0_count;
            end
            REG_MEM_1_BASE: begin
              o_wbs_dat           <=  r_memory_1_base;
            end
            REG_MEM_1_SIZE: begin
              o_wbs_dat           <=  w_memory_1_count;
            end
            REG_TOTAL_WRITE_SIZE: begin
              o_wbs_dat           <=  r_ppfifo_size_request;
            end
            default: begin
              o_wbs_dat           <=  32'h00;
            end
          endcase
        end
      end
      o_wbs_ack                   <= 1;
    end
  end
end

//initerrupt controller
always @ (posedge clk) begin
  if (rst) begin
    o_wbs_int <=  0;
  end
  else if (w_enable) begin
    if (!w_memory_0_empty && !w_memory_1_empty) begin
      o_wbs_int <=  0;
    end
    if (i_wbs_stb) begin
      //de-assert the interrupt on wbs transactions so I can launch another
      //interrupt when the wbs is de-asserted
      o_wbs_int <=  0;
    end
    else if (w_memory_0_empty || w_memory_1_empty) begin
      o_wbs_int <=  1;
    end
  end
  else begin
    //if we're not enable de-assert interrupt
    o_wbs_int <=  0;
  end
end



endmodule
