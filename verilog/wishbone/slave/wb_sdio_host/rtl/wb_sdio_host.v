//wb_sdio_host.v
/*
Distributed under the MIT license.
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

/*
  Set the Vendor ID (Hexidecimal 64-bit Number)
  SDB_VENDOR_ID:0x800000000000C594

  Set the Device ID (Hexcidecimal 32-bit Number)
  SDB_DEVICE_ID:0x800000000000C594

  Set the version of the Core XX.XXX.XXX Example: 01.000.000
  SDB_CORE_VERSION:00.000.001

  Set the Device Name: 19 UNICODE characters
  SDB_NAME:wb_sdio_host

  Set the class of the device (16 bits) Set as 0
  SDB_ABI_CLASS:0

  Set the ABI Major Version: (8-bits)
  SDB_ABI_VERSION_MAJOR:0x23

  Set the ABI Minor Version (8-bits)
  SDB_ABI_VERSION_MINOR:1

  Set the Module URL (63 Unicode Characters)
  SDB_MODULE_URL:http://www.example.com

  Set the date of module YYYY/MM/DD
  SDB_DATE:2015/08/21

  Device is executable (True/False)
  SDB_EXECUTABLE:True

  Device is readable (True/False)
  SDB_READABLE:True

  Device is writeable (True/False)
  SDB_WRITEABLE:True

  Device Size: Number of Registers
  SDB_SIZE:3
*/


module wb_sdio_host (
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

  //master control signal for memory arbitration
  output              mem_o_we,
  output              mem_o_stb,
  output              mem_o_cyc,
  output      [3:0]   mem_o_sel,
  output      [31:0]  mem_o_adr,
  output      [31:0]  mem_o_dat,
  input       [31:0]  mem_i_dat,
  input               mem_i_ack,
  input               mem_i_int,


  //This interrupt can be controlled from this module or a submodule
  output  reg         o_wbs_int
  //output              o_wbs_int
);

//Local Parameters
localparam          CONTROL             = 32'h00000000;
localparam          STATUS              = 32'h00000001;
localparam          REG_MEM_0_BASE      = 32'h00000002;
localparam          REG_MEM_0_SIZE      = 32'h00000003;
localparam          REG_MEM_1_BASE      = 32'h00000004;
localparam          REG_MEM_1_SIZE      = 32'h00000005;

//Local Registers/Wires
reg         [31:0]      control;
wire        [31:0]      status;

wire                    w_mem_write_enable;
wire                    w_mem_read_enable;
wire        [31:0]      w_mem_write_debug;
wire        [31:0]      w_mem_read_debug;

wire                    w_rfifo_ready;
wire                    w_rfifo_activate;
wire                    w_rfifo_strobe;
wire        [31:0]      w_rfifo_data;
wire        [23:0]      w_rfifo_size;

reg         [31:0]      r_memory_0_base;
reg         [31:0]      r_memory_0_size;
wire        [31:0]      w_memory_0_count;
reg                     r_memory_0_ready;
wire                    w_memory_0_finished;
wire                    w_memory_0_empty;
reg                     r_memory_0_new_data;

wire        [31:0]      w_default_mem_0_base;

reg         [31:0]      r_memory_1_base;
reg         [31:0]      r_memory_1_size;
wire        [31:0]      w_memory_1_count;
reg                     r_memory_1_ready;
wire                    w_memory_1_finished;
wire                    w_memory_1_empty;
reg                     r_memory_1_new_data;

wire        [31:0]      w_default_mem_1_base;
reg                     r_flush_memory;

wire                    w_write_finished;
wire                    w_memory_idle;

wire        [23:0]      w_wfifo_size;
wire        [1:0]       w_wfifo_ready;
wire        [1:0]       w_wfifo_activate;
wire                    w_wfifo_strobe;
wire        [31:0]      w_wfifo_data;




//Submodules

wb_ppfifo_2_mem p2m(

  .clk                  (clk                      ),
  .rst                  (rst                      ),
  .debug                (w_mem_write_debug        ),

  //Control
  .i_enable             (w_mem_write_enable       ),
  .i_flush              (r_flush_memory           ),

  .i_memory_0_base      (r_memory_0_base          ),
  .i_memory_0_size      (r_memory_0_size          ),
  .o_memory_0_count     (w_memory_0_count         ),
  .i_memory_0_ready     (r_memory_0_ready         ),
  .o_memory_0_finished  (w_memory_0_finished      ),
  .o_memory_0_empty     (w_memory_0_empty         ),

  .o_default_mem_0_base (w_default_mem_0_base     ),

  .i_memory_1_base      (r_memory_1_base          ),
  .i_memory_1_size      (r_memory_1_size          ),
  .o_memory_1_count     (w_memory_1_count         ),
  .i_memory_1_ready     (r_memory_1_ready         ),
  .o_memory_1_finished  (w_memory_1_finished      ),
  .o_memory_1_empty     (w_memory_1_empty         ),

  .o_default_mem_1_base (w_default_mem_1_base     ),

  .o_write_finished     (w_write_finished         ),

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

  //Ping Pong FIFO Interface (Read)
  .i_ppfifo_rdy         (w_rfifo_ready            ),
  .o_ppfifo_act         (w_rfifo_activate         ),
  .i_ppfifo_size        (w_rfifo_size             ),
  .o_ppfifo_stb         (w_rfifo_strobe           ),
  .i_ppfifo_data        (w_rfifo_data             )
);


wb_mem_2_ppfifo m2p(

  .clk                  (clk                      ),
  .rst                  (rst                      ),
  .debug                (w_mem_read_debug         ),

  //Control
  .i_enable             (w_mem_read_enable        ),

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



//Asynchronous Logic
//Synchronous Logic

always @ (posedge clk) begin
  if (rst) begin
    o_wbs_dat <= 32'h0;
    o_wbs_ack <= 0;
  end
  else begin
    //when the master acks our ack, then put our ack down
    if (o_wbs_ack && ~i_wbs_stb)begin
      o_wbs_ack <= 0;
    end

    if (i_wbs_stb && i_wbs_cyc) begin
      //master is requesting somethign
      if (!o_wbs_ack) begin
        if (i_wbs_we) begin
          //write request
          case (i_wbs_adr)
            CONTROL: begin
              $display("ADDR: %h user wrote %h", i_wbs_adr, i_wbs_dat);
              control               <=  i_wbs_dat;
            end
            STATUS: begin
              $display("ADDR: %h user wrote %h", i_wbs_adr, i_wbs_dat);
            end
            REG_MEM_0_BASE: begin
              r_memory_0_base       <=  i_wbs_dat;
            end
            REG_MEM_0_SIZE: begin
              r_memory_0_size       <=  i_wbs_dat;
              if (i_wbs_dat > 0) begin
                r_memory_0_ready    <=  1;
              end
            end
            REG_MEM_1_BASE: begin
              r_memory_1_base       <=  i_wbs_dat;
            end
            REG_MEM_1_SIZE: begin
              r_memory_1_size       <=  i_wbs_dat;
              if (i_wbs_dat > 0) begin
                r_memory_1_ready    <=  1;
              end
            end
            default: begin
            end
          endcase
        end
        else begin
          //read request
          case (i_wbs_adr)
            CONTROL: begin
              $display("user read %h", CONTROL);
              o_wbs_dat           <= control;
            end
            STATUS: begin
              $display("user read %h", STATUS);
              o_wbs_dat           <= status;
              if (w_memory_0_finished) begin
                $display ("Reset size 0");
                r_memory_0_size   <=  0;
              end
              if (w_memory_1_finished) begin
                $display ("Reset size 1");
                r_memory_1_size   <=  0;
              end
            end
            REG_MEM_0_BASE: begin
              o_wbs_dat <=  r_memory_0_base;
            end
            REG_MEM_0_SIZE: begin
              o_wbs_dat <=  w_memory_0_count;
            end
            REG_MEM_1_BASE: begin
              o_wbs_dat <=  r_memory_1_base;
            end
            REG_MEM_1_SIZE: begin
              o_wbs_dat <=  w_memory_1_count;
            end
            default: begin
              o_wbs_dat <=  32'h00;
            end

          endcase
        end
      o_wbs_ack <= 1;
    end
    end
  end
end

//initerrupt controller
always @ (posedge clk) begin
  if (rst) begin
    o_wbs_int <=  0;
  end
  //Memory Read Interface
  else if (w_mem_read_enable) begin
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
  //Write Memory Controller
  else if (w_mem_write_enable) begin
    if (i_wbs_stb) begin
      o_wbs_int         <=  0;
    end
    else if (w_memory_0_finished || w_memory_1_finished) begin
      o_wbs_int         <=  1;
    end
    else if (!w_memory_0_finished && !w_memory_1_finished) begin
      o_wbs_int         <=  0;
    end

  end
  else begin
    //if we're not enable de-assert interrupt
    o_wbs_int <=  0;
  end
end


endmodule
