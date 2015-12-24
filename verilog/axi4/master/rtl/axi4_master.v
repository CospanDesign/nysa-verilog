/*
 This file is part of Nysa (http://nysa.cospandesign.com).

 Nysa is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 any later version.

 Nysa is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nysa; If not, see <http://www.gnu.org/licenses/>.
*/

/*
  Changelog

  1/18/2013
    -Initial commit
  8/20/2013
    -Updatad the License to GPLV3
*/

`timescale 1 ns/1 ps
`include "cbuilder_defines.v"

module axi4_master #(
  //Parameters
  parameter           HI_ADDR_WIDTH = 32,
  parameter           HI_DATA_WIDTH = 32,
  parameter           P_ADDR_WIDTH  = 32,
  parameter           P_DATA_WIDTH  = 32,
  parameter           M_ADDR_WIDTH  = 32,
  parameter           M_DATA_WIDTH  = 32

)(
  input                             clk,
  input                             rst,

  //indicate to the input that we are ready
  output  reg                       o_master_ready,

  //input handler interface
  input                             i_ih_reset,

  input                             i_ih_ready,
  input       [31:0]                i_ih_command,
  input       [HI_ADDR_WIDTH - 1:0] i_ih_address,
  input       [HI_DATA_WIDTH - 1:0] i_ih_data,
  input       [31:0]                i_ih_data_count,

  //output handler interface
  input                             i_oh_ready,
  output  reg                       o_oh_en,
  output  reg [31:0]                o_oh_status,
  output  reg [HI_ADDR_WIDTH - 1:0] o_oh_address,
  output  reg [HI_DATA_WIDTH - 1:0] o_oh_data,
  output  reg [31:0]                o_oh_data_count,



  //Axi4 Peripheral Bus
  output                            o_p_aclk,
  output                            o_p_areset_n,

  //peripheral bus write addr path
  output  reg [3:0]                 o_p_awid,         //Write ID
  output  reg [P_ADDR_WIDTH - 1:0]  o_p_awaddr,       //Write Addr Path Address
  output  reg [3:0]                 o_p_awlen,        //Write Addr Path Burst Length
  output  reg [2:0]                 o_p_awsize,       //Write Addr Path Burst Size
  output  reg [1:0]                 o_p_awburst,      //Write Addr Path Burst Type
                                                        //  0 = Fixed
                                                        //  1 = Incrementing
                                                        //  2 = wrap
  output  reg [1:0]                 o_p_awlock,       //Write Addr Path Lock (atomic) information
                                                        //  0 = Normal
                                                        //  1 = Exclusive
                                                        //  2 = Locked
  output  reg [3:0]                 o_p_awcache,      //Write Addr Path Cache Type
  output  reg [2:0]                 o_p_awprot,       //Write Addr Path Protection Type
  output  reg                       o_p_awvalid,      //Write Addr Path Address Valid
  input                             i_p_awready,      //Write Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready

    //Peripheral bus write data
  output  reg [3:0]                 o_p_wid,          //Write ID
  output  reg [P_DATA_WIDTH - 1: 0] o_p_wdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  output  reg [P_DATA_WIDTH >> 3:0] o_p_wstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  output  reg                       o_p_wlast,        //Write Last transfer in a write burst
  output  reg                       o_p_wvalid,       //Data through this bus is valid
  input                             i_p_wready,       //Slave is ready for data

    //Peripheral Write Response Channel
  input       [3:0]                 i_p_bid,          //Response ID (this must match awid)
  input       [1:0]                 i_p_bresp,        //Write Response
                                                        //  0 = OKAY
                                                        //  1 = EXOKAY
                                                        //  2 = SLVERR
                                                        //  3 = DECERR
  input                             i_p_bvalid,       //Write Response is:
                                                        //  1 = Available
                                                        //  0 = Not Available
  output  reg                       o_p_bready,       //WBM Ready

    //Peripheral bus read addr path
  output  reg  [3:0]                o_p_arid,         //Read ID
  output  reg  [P_ADDR_WIDTH - 1:0] o_p_araddr,       //Read Addr Path Address
  output  reg  [3:0]                o_p_arlen,        //Read Addr Path Burst Length
  output  reg  [2:0]                o_p_arsize,       //Read Addr Path Burst Size
  output  reg  [1:0]                o_p_arburst,      //Read Addr Path Burst Type
  output  reg  [1:0]                o_p_arlock,       //Read Addr Path Lock (atomic) information
  output  reg  [3:0]                o_p_arcache,      //Read Addr Path Cache Type
  output  reg  [2:0]                o_p_arprot,       //Read Addr Path Protection Type
  output  reg                       o_p_arvalid,      //Read Addr Path Address Valid
  input                             i_p_arready,      //Read Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready
    //Peripheral bus read data
  input       [3:0]                 i_p_rid,          //Write ID
  input       [P_DATA_WIDTH - 1: 0] i_p_rdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  input       [P_DATA_WIDTH >> 3:0] i_p_rstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  input                             i_p_rlast,        //Write Last transfer in a write burst
  input                             i_p_rvalid,       //Data through this bus is valid
  output  reg                       o_p_rready,       //WBM is ready for data
                                                        //  1 = WBM Ready
                                                        //  0 = Slave Ready

    //Low Power Bus
  output  reg                       o_p_csysreq,      //Peripheral System low power request
  input                             i_p_csysack,      //Peripheral System low pwoer acknowledgement
  input                             i_p_cactive,      //Peripheral Clock Activate: Peripheral requires it's clock
                                                        //  1 = Peripheral Clock Required
                                                        //  0 = Peripheral Clock Not Required


  //Axi4 Memory Bus

  output                            o_m_aclk,
  output                            o_m_areset_n,

    //memory bus write addr path
  output  reg [3:0]                 o_m_awid,         //Write ID
  output  reg [M_ADDR_WIDTH - 1:0]  o_m_awaddr,       //Write Addr Path Address
  output  reg [3:0]                 o_m_awlen,        //Write Addr Path Burst Length
  output  reg [2:0]                 o_m_awsize,       //Write Addr Path Burst Size
  output  reg [1:0]                 o_m_awburst,      //Write Addr Path Burst Type
  output  reg [1:0]                 o_m_awlock,       //Write Addr Path Lock (atomic) information
  output  reg [3:0]                 o_m_awcache,      //Write Addr Path Cache Type
  output  reg [2:0]                 o_m_awprot,       //Write Addr Path Protection Type
  output  reg                       o_m_awvalid,      //Write Addr Path Address Valid
  input                             o_m_awready,      //Write Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready

    //Memory bus write data
  output  reg [3:0]                 o_m_wid,          //Write ID
  output  reg [M_DATA_WIDTH - 1: 0] o_m_wdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  output  reg [M_DATA_WIDTH >> 3:0] o_m_wstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  output  reg                       o_m_wlast,        //Write Last transfer in a write burst
  output  reg                       o_m_wvalid,       //Data through this bus is valid
  input                             i_m_wready,       //Slave is ready for data

    //Memory Write Response Channel
  input       [3:0]                 i_m_bid,          //Response ID (this must match awid)
  input       [1:0]                 i_m_bresp,        //Write Response
                                                      //OKAY
                                                      //EXOKAY
                                                      //SLVERR
                                                      //DECERR
  input                             i_m_bvalid,       //Write Response is:
  output  reg                       o_m_bready,       //WBM Ready
                                                        //  1 = Available
                                                        //  0 = Not Available

    //Memory bus read addr path
  output  reg [3:0]                 o_m_arid,         //Read ID
  output  reg [M_ADDR_WIDTH - 1:0]  o_m_araddr,       //Read Addr Path Address
  output  reg [3:0]                 o_m_arlen,        //Read Addr Path Burst Length
  output  reg [2:0]                 o_m_arsize,       //Read Addr Path Burst Size
  output  reg [1:0]                 o_m_arburst,      //Read Addr Path Burst Type
  output  reg [1:0]                 o_m_arlock,       //Read Addr Path Lock (atomic) information
  output  reg [3:0]                 o_m_arcache,      //Read Addr Path Cache Type
  output  reg [2:0]                 o_m_arprot,       //Read Addr Path Protection Type
  output  reg                       o_m_arvalid,      //Read Addr Path Address Valid
  input                             i_m_arready,      //Read Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready
    //Memory bus read data
  input       [3:0]                 i_m_rid,          //Write ID
  input       [M_DATA_WIDTH - 1: 0] i_m_rdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  input       [M_DATA_WIDTH >> 3:0] i_m_rstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  input                             i_m_rlast,        //Write Last transfer in a write burst
  input                             i_m_rvalid,       //Data through this bus is valid
  output  reg                       o_m_rready,       //WBM is ready for data
                                                        //  1 = WBM Ready
                                                        //  0 = Slave Ready

    //Low Power Bus
  output  reg                       o_m_csysreq,      //Memory System low power request
  input                             i_m_csysack,      //Memory System low pwoer acknowledgement
  input                             i_m_cactive       //Memory Clock Activate: Memory requires it's clock
                                                      //  1 = Memory Clock Required
                                                      //  0 = Memory Clock Not Required
);

//Local Parameters
localparam       IDLE                  = 4'h0;
localparam       WRITE                 = 4'h1;
localparam       READ                  = 4'h2;
localparam       DUMP_CORE             = 4'h3;

localparam       S_PING_RESP           = 32'h0000C594;

localparam       DUMP_COUNT            = 14;




localparam                          PROCESS_CMD     = 3'h1;
localparam                          PROCESS_RSP     = 3'h2;

//Registers/Wires
reg     [3:0]                       state;
reg     [3:0]                       cmd_state;
reg                                 r_prev_reset    = 0;

//XXX: This should be parameterized later
reg     [31:0]                      r_local_address;
reg     [31:0]                      r_local_data;
reg     [31:0]                      r_local_data_count;
reg                                 r_mem_bus_select;

reg     [31:0]                      r_master_flags;
reg     [31:0]                      r_rw_count;
reg                                 r_wait_for_slave;
reg                                 r_prev_int;

reg     [31:0]                      r_interrupt_mask;

wire                                w_enable_nack;
reg     [31:0]                      r_nack_timeout  = `DEF_NACK_TIMEOUT;
reg     [31:0]                      r_nack_count    = 0;


wire    [15:0]                      w_command;
wire    [15:0]                      w_command_flags;
wire                                w_posedge_reset;

//Submodules
//Asynchronous Logic
assign  o_p_aclk                    = clk;
assign  o_p_areset                  = rst;

assign  o_m_aclk                    = clk;
assign  o_m_areset                  = rst;

assign  w_posedge_reset             = rst & ~r_prev_reset;

assign  w_command                   = i_ih_command[15:0];
assign  w_command_flags             = i_ih_command[31:16];

//Master Flag assigns
assign  w_enable_nack               = r_master_flags[0];


//Synchronous Logic
always @ (posedge clk) begin
  o_oh_en                         <=  0;
  if (rst) begin
    //WBM Logic
    state                         <=  IDLE;

    //Host Interface Initialization
    o_master_ready                  <=  0;

    o_oh_status                    <=  0;
    o_oh_address                   <=  0;
    o_oh_data_count                <=  0;

    //Peripheral
    //Write Address Bus
    o_p_awid                        <=  0;
    o_p_awaddr                      <=  0;
    o_p_awlen                       <=  0;
    o_p_awsize                      <=  0;
    o_p_awburst                     <=  0;
    o_p_awlock                      <=  `AXI_LOCK_NORMAL;
    o_p_awcache                     <=  0;
    o_p_awprot                      <=  `AXI_PROT_UNUSED;
    o_p_awvalid                     <=  0;

    //Write Data Bus
    o_p_wid                         <=  0;
    o_p_wdata                       <=  0;
    o_p_wstrobe                     <=  0;
    o_p_wlast                       <=  0;
    o_p_wvalid                      <=  0;

    //Write Response Bus
    o_p_bready                      <=  0;

    //Read Address Bus
    o_p_arid                        <=  0;
    o_p_araddr                      <=  0;
    o_p_arlen                       <=  0;
    o_p_arsize                      <=  0;
    o_p_arburst                     <=  0;
    o_p_arlock                      <=  `AXI_LOCK_NORMAL;
    o_p_arcache                     <=  0;
    o_p_arprot                      <=  `AXI_PROT_UNUSED;
    o_p_arvalid                     <=  0;

    //Read Data Bus
    o_p_rready                      <=  0;

    //Low Power
    o_p_csysreq                     <=  `AXI_POWER_NORMAL;



    //Memory
    //Write Address Bus
    o_m_awid                        <=  0;
    o_m_awaddr                      <=  0;
    o_m_awlen                       <=  0;
    o_m_awsize                      <=  0;
    o_m_awburst                     <=  0;
    o_m_awlock                      <=  `AXI_LOCK_NORMAL;
    o_m_awcache                     <=  0;
    o_m_awprot                      <=  `AXI_PROT_UNUSED;
    o_m_awvalid                     <=  0;

    //Write Data Bus
    o_m_wid                         <=  0;
    o_m_wdata                       <=  0;
    o_m_wstrobe                     <=  0;
    o_m_wlast                       <=  0;
    o_m_wvalid                      <=  0;

    //Write Response Bus
    o_m_bready                      <=  0;

    //Read Address Bus
    o_m_arid                        <=  0;
    o_m_araddr                      <=  0;
    o_m_arlen                       <=  0;
    o_m_arsize                      <=  0;
    o_m_arburst                     <=  0;
    o_m_arlock                      <=  `AXI_LOCK_NORMAL;
    o_m_arcache                     <=  0;
    o_m_arprot                      <=  `AXI_PROT_UNUSED;
    o_m_arvalid                     <=  0;

    //Read Data Bus
    o_m_rready                      <=  0;

    //Low Power
    o_m_csysreq                     <=  `AXI_POWER_NORMAL;



    //Internal control registers
    r_local_address                 <=  0;
    r_local_data                    <=  0;
    r_local_data_count              <=  0;

    r_mem_bus_select                <=  0;

    r_master_flags                  <=  0;
    r_rw_count                      <=  0;
    r_wait_for_slave                <=  0;
    r_prev_int                      <=  0;
    r_interrupt_mask                <=  0;
    r_nack_timeout                  <=  `DEF_NACK_TIMEOUT;
    r_nack_count                    <=  0;

  end
  else begin
    //Strobes

    //host interface

    //Peripheral Bus Strobes
    o_p_awvalid                     <=  0;
    o_p_wvalid                      <=  0;
    o_p_wlast                       <=  0;
    o_p_arvalid                     <=  0;

    o_p_bready                      <=  0;
    o_p_rready                      <=  0;

    //Memory Bus Strobes
    o_m_awvalid                     <=  0;
    o_m_wvalid                      <=  0;
    o_m_wlast                       <=  0;
    o_m_arvalid                     <=  0;

    o_m_bready                      <=  0;
    o_m_rready                      <=  0;


    //Check for timeout conditions
    if (r_nack_count == 0) begin
//XXX: This may not be a valid when working with a normal AXI4 Slave
      if (state != IDLE && w_enable_nack) begin
        $display ("WBM: Timed out");
        state                       <=  IDLE;
        o_oh_status                 <=  32'h00000000;
        o_oh_address                <=  32'h00000000;
        o_oh_en                     <=  1;
      end
    end

    case (state)
      IDLE: begin
        //Listen for commands or responses from the host or the slave
        o_master_ready    <=  1;
        r_mem_bus_select  <=  0;
        if (i_ih_ready) begin
           
          case (w_command)
            `COMMAND_PING: begin
              $display ("WBM: Ping Command");
              o_oh_status       <=  ~w_command;
              o_oh_address      <=  32'h00000000;
              o_oh_data         <=  S_PING_RESP;
              o_oh_en           <=  1;
              state             <=  IDLE;
            end
            `COMMAND_WRITE: begin
              $display ("WBM: Write Command");
              o_oh_status       <=  ~w_command;
              r_local_data_count<=  i_ih_data_count;
//AXI Stuff
              if (w_command_flags & `FLAG_MEM_BUS) begin
                r_mem_bus_select<=  1;
              end
              else begin
                r_mem_bus_select<=  0;
              end
              o_oh_address      <=  i_ih_address;
              o_oh_data         <=  i_ih_data;
              o_master_ready    <=  0;
              state             <=  WRITE;
            end
            `COMMAND_READ:  begin
              $display ("WBM: Read Command");
              o_oh_status       <=  ~w_command;
              r_local_data_count<=  i_ih_data_count;
//AXI Stuff
              if (w_command_flags & `FLAG_MEM_BUS) begin
                r_mem_bus_select<=  1;
              end
              else begin
                r_mem_bus_select<=  0;
              end
              o_oh_address      <=  i_ih_address;
              o_master_ready    <=  0;
              state             <=  READ;
            end
            `COMMAND_MASTER_ADDR: begin
              $display ("WBM: WBM Interface Command");
              o_oh_status           <=  ~w_command;
              r_master_flags        <=  i_ih_data;
              o_oh_address          <=  i_ih_address;
              case (i_ih_address)
                `MADDR_WR_FLAGS: begin
                  r_master_flags    <=  i_ih_data;
                end
                `MADDR_RD_FLAGS: begin
                  o_oh_data         <= r_master_flags;
                end
                `MADDR_WR_INT_EN: begin
                  r_interrupt_mask  <= i_ih_data;
                  o_oh_data         <=  i_ih_data;
                  $display("WBM: setting interrupt enable to: %h", i_ih_data); 
                end
                `MADDR_RD_INT_EN: begin
                  o_oh_data         <= r_interrupt_mask;
                end
                `MADDR_NACK_TO_WR: begin
                  r_nack_timeout    <= i_ih_data;
                end
                `MADDR_NACK_TO_RD: begin
                  o_oh_data         <= r_nack_timeout;
                end
                default: begin
                  //unrecognized command
                  o_oh_status       <=  32'h00000000;
               end
              endcase
              o_oh_en               <=  1;
              state                 <=  IDLE;

            end
            `COMMAND_CORE_DUMP: begin
              $display ("WBM: Core Dump Command");
              o_oh_status       <=  ~w_command;
            end
            default: begin
              $display ("WBM: Invalid Command: %h", w_command);
              o_oh_status       <=  ~w_command;
            end
          endcase

        end
      end
      READ: begin
        //Received a command from the host, process it
      end
      WRITE: begin
        //Received a response from a slave, process it
      end
      DUMP_CORE: begin
        //Dump the contents of the master
      end
      default: begin
      end
    endcase
  end
  r_prev_reset  <=  rst;
end

endmodule
