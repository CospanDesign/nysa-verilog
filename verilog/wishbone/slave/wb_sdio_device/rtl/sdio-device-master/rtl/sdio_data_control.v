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
 * Author: David McCoy  (dave.mccoy@cospandesign.com)
 * Description: Arbitrates access to the command bus data interface and the
 *  Data Bus interface
 *
 * Changes:
 *  2015.09.07: Initial Commit
 */

module sdio_data_control #(
  parameter                 DEFAULT_MIN_READ_COOLDOWN = 400
)(
  input                     clk,
  input                     rst,

  output                    o_data_bus_busy,
  output                    o_data_read_avail,

  input                     i_write_flg,
  input                     i_block_mode_flg,
  input           [12:0]    i_data_cnt,
  output  reg     [12:0]    o_total_data_cnt,

  input                     i_inc_addr_flg,
  input           [17:0]    i_cmd_address,
  output  reg     [17:0]    o_address,

  input                     i_activate,
  output  reg               o_finished,

  input                     i_cmd_bus_sel,  /* If this is high we can only read/write one byte */
  input                     i_mem_sel,
  input           [3:0]     i_func_sel,

  //Command Bus Interface
  input           [7:0]     i_cmd_wr_data,
  output          [7:0]     o_cmd_rd_data,

  //Phy Data Bus Inteface
  input                     i_data_phy_wr_stb,
  input           [7:0]     i_data_phy_wr_data,
  output                    o_data_phy_rd_stb,
  output          [7:0]     o_data_phy_rd_data,
  input                     i_data_phy_hst_rdy,  /* DATA PHY -> Func: Ready for receive data */
  output                    o_data_phy_com_rdy,
  output                    o_data_phy_activate,
  input                     i_data_phy_finished,

  //CIA Interface
  output  reg               o_cia_wr_stb,
  output  reg     [7:0]     o_cia_wr_data,
  input                     i_cia_rd_stb,
  input           [7:0]     i_cia_rd_data,
  output  reg               o_cia_hst_rdy,
  input                     i_cia_com_rdy,
  output  reg               o_cia_activate,
  input           [15:0]    i_cia_block_size,

  //Function 1 Interface
  output  reg               o_func1_wr_stb,
  output  reg     [7:0]     o_func1_wr_data,
  input                     i_func1_rd_stb,
  input           [7:0]     i_func1_rd_data,
  output  reg               o_func1_hst_rdy,
  input                     i_func1_com_rdy,
  output  reg               o_func1_activate,
  input           [15:0]    i_func1_block_size,

  //Function 2 Interface
  output  reg               o_func2_wr_stb,
  output  reg     [7:0]     o_func2_wr_data,
  input                     i_func2_rd_stb,
  input           [7:0]     i_func2_rd_data,
  output  reg               o_func2_hst_rdy,
  input                     i_func2_com_rdy,
  output  reg               o_func2_activate,
  input           [15:0]    i_func2_block_size,

  //Function 3 Interface
  output  reg               o_func3_wr_stb,
  output  reg     [7:0]     o_func3_wr_data,
  input                     i_func3_rd_stb,
  input           [7:0]     i_func3_rd_data,
  output  reg               o_func3_hst_rdy,
  input                     i_func3_com_rdy,
  output  reg               o_func3_activate,
  input           [15:0]    i_func3_block_size,

  //Function 4 Interface
  output  reg               o_func4_wr_stb,
  output  reg     [7:0]     o_func4_wr_data,
  input                     i_func4_rd_stb,
  input           [7:0]     i_func4_rd_data,
  output  reg               o_func4_hst_rdy,
  input                     i_func4_com_rdy,
  output  reg               o_func4_activate,
  input           [15:0]    i_func4_block_size,

  //Function 5 Interface
  output  reg               o_func5_wr_stb,
  output  reg     [7:0]     o_func5_wr_data,
  input                     i_func5_rd_stb,
  input           [7:0]     i_func5_rd_data,
  output  reg               o_func5_hst_rdy,
  input                     i_func5_com_rdy,
  output  reg               o_func5_activate,
  input           [15:0]    i_func5_block_size,

  //Function 6 Interface
  output  reg               o_func6_wr_stb,
  output  reg     [7:0]     o_func6_wr_data,
  input                     i_func6_rd_stb,
  input           [7:0]     i_func6_rd_data,
  output  reg               o_func6_hst_rdy,
  input                     i_func6_com_rdy,
  output  reg               o_func6_activate,
  input           [15:0]    i_func6_block_size,

  //Function 7 Interface
  output  reg               o_func7_wr_stb,
  output  reg     [7:0]     o_func7_wr_data,
  input                     i_func7_rd_stb,
  input           [7:0]     i_func7_rd_data,
  output  reg               o_func7_hst_rdy,
  input                     i_func7_com_rdy,
  output  reg               o_func7_activate,
  input           [15:0]    i_func7_block_size,

  //Memory Interface
  output  reg               o_mem_wr_stb,
  output  reg     [7:0]     o_mem_wr_data,
  input                     i_mem_rd_stb,
  input           [7:0]     i_mem_rd_data,
  output  reg               o_mem_hst_rdy,
  input                     i_mem_com_rdy,
  output  reg               o_mem_activate,
  input           [15:0]    i_mem_block_size
);

//local parameters
localparam                  IDLE          = 4'h0;
localparam                  CONFIG        = 4'h1;
localparam                  ACTIVATE      = 4'h2;
localparam                  WRITE         = 4'h3;
localparam                  READ          = 4'h4;
localparam                  WAIT_FOR_PHY  = 4'h5;
localparam                  READ_COOLDOWN = 4'h6;
localparam                  FINISHED      = 4'h7;

//registes/wires
reg           rd_stb;
reg   [7:0]   rd_data;
wire          wr_stb;
wire  [7:0]   wr_data;
reg           com_rdy;
wire  [3:0]   func_select;
reg   [15:0]  block_size;

reg   [9:0]   total_block_count;    //Total number of blocks to transfer
reg   [9:0]   block_count;
reg   [9:0]   data_count;           //Current byte we are working on
reg           continuous;           //This is a continuous transfer, don't stop till i_activate is deasserted
reg           data_cntrl_rdy;
reg           data_activate;
reg   [31:0]  read_cooldown;


reg           lcl_wr_stb;
wire          lcl_rd_stb;
reg           lcl_hst_rdy;
reg           lcl_activate;
//wire        lcl_finished;

wire          d_activate;

reg   [3:0] state;

reg   [3:0] ld_state;

//submodules
//asynchronous logic
assign  lcl_rd_stb          = i_cmd_bus_sel   ? rd_stb        : 1'b0;
assign  o_cmd_rd_data       = i_cmd_bus_sel   ? rd_data       : 8'h00;

assign  o_data_phy_rd_stb   = !i_cmd_bus_sel  ? rd_stb        : 1'b0;
assign  o_data_phy_rd_data  = !i_cmd_bus_sel  ? rd_data       : 8'h00;
assign  o_data_phy_com_rdy  = !i_cmd_bus_sel  ? com_rdy       : 1'b0;
assign  o_data_phy_activate = !i_cmd_bus_sel  ? data_activate : 1'b0;

assign  wr_stb              = i_cmd_bus_sel   ? lcl_wr_stb    : i_data_phy_wr_stb;
assign  wr_data             = i_cmd_bus_sel   ? i_cmd_wr_data : i_data_phy_wr_data;
//assign  data_cntrl_rdy             = i_cmd_bus_sel   ? lcl_hst_rdy   : i_data_phy_hst_rdy;

//assign  lcl_finished        = i_cmd_bus_sel   ? finished      : 1'b0;
//assign  i_activate            = i_cmd_bus_sel   ? lcl_activate  : i_data_phy_activate;
assign  d_activate          = i_cmd_bus_sel   ? i_activate    : data_activate;
assign  func_select         = i_mem_sel       ? 4'h8          : {1'b0, i_func_sel};
assign  o_data_bus_busy     = (state == ACTIVATE);
//TODO: Not implemented yet
assign  o_data_read_avail   = 1'b0;

//Multiplexer: Cmd Layer, Data Phy Layer -> Func Layer
always @ (*) begin
  if (rst) begin
    o_cia_wr_stb             = 0;
    o_cia_wr_data            = 0;
    o_cia_hst_rdy            = 0;

    o_func1_wr_stb           = 0;
    o_func1_wr_data          = 0;
    o_func1_hst_rdy          = 0;

    o_func2_wr_stb           = 0;
    o_func2_wr_data          = 0;
    o_func2_hst_rdy          = 0;

    o_func3_wr_stb           = 0;
    o_func3_wr_data          = 0;
    o_func3_hst_rdy          = 0;

    o_func4_wr_stb           = 0;
    o_func4_wr_data          = 0;
    o_func4_hst_rdy          = 0;

    o_func5_wr_stb           = 0;
    o_func5_wr_data          = 0;
    o_func5_hst_rdy          = 0;

    o_func6_wr_stb           = 0;
    o_func6_wr_data          = 0;
    o_func6_hst_rdy          = 0;

    o_func7_wr_stb           = 0;
    o_func7_wr_data          = 0;
    o_func7_hst_rdy          = 0;

    o_mem_wr_stb             = 0;
    o_mem_wr_data            = 0;
    o_mem_hst_rdy            = 0;
  end
  else begin
    //If nothing overrides these values, just set them to zero
    o_cia_wr_stb             = 0;
    o_cia_wr_data            = 0;
    o_cia_hst_rdy            = 0;
    o_cia_activate           = 0;

    o_func1_wr_stb           = 0;
    o_func1_wr_data          = 0;
    o_func1_hst_rdy          = 0;
    o_func1_activate         = 0;

    o_func2_wr_stb           = 0;
    o_func2_wr_data          = 0;
    o_func2_hst_rdy          = 0;
    o_func2_activate         = 0;

    o_func3_wr_stb           = 0;
    o_func3_wr_data          = 0;
    o_func3_hst_rdy          = 0;
    o_func3_activate         = 0;

    o_func4_wr_stb           = 0;
    o_func4_wr_data          = 0;
    o_func4_hst_rdy          = 0;
    o_func4_activate         = 0;

    o_func5_wr_stb           = 0;
    o_func5_wr_data          = 0;
    o_func5_hst_rdy          = 0;
    o_func5_activate         = 0;

    o_func6_wr_stb           = 0;
    o_func6_wr_data          = 0;
    o_func6_hst_rdy          = 0;
    o_func6_activate         = 0;

    o_func7_wr_stb           = 0;
    o_func7_wr_data          = 0;
    o_func7_hst_rdy          = 0;
    o_func7_activate         = 0;

    o_mem_wr_stb             = 0;
    o_mem_wr_data            = 0;
    o_mem_hst_rdy            = 0;
    o_mem_activate           = 0;

    case (func_select)
      0: begin
        o_cia_wr_stb         = wr_stb;
        o_cia_wr_data        = wr_data;
        o_cia_hst_rdy        = data_cntrl_rdy;
        o_cia_activate       = d_activate;
      end
      1: begin
        o_func1_wr_stb       = wr_stb;
        o_func1_wr_data      = wr_data;
        o_func1_hst_rdy      = data_cntrl_rdy;
        o_func1_activate     = d_activate;
      end
      2: begin
        o_func2_wr_stb       = wr_stb;
        o_func2_wr_data      = wr_data;
        o_func2_hst_rdy      = data_cntrl_rdy;
        o_func2_activate     = d_activate;
      end
      3: begin
        o_func3_wr_stb       = wr_stb;
        o_func3_wr_data      = wr_data;
        o_func3_hst_rdy      = data_cntrl_rdy;
        o_func3_activate     = d_activate;
      end
      4: begin
        o_func4_wr_stb       = wr_stb;
        o_func4_wr_data      = wr_data;
        o_func4_hst_rdy      = data_cntrl_rdy;
        o_func4_activate     = d_activate;
      end
      5: begin
        o_func5_wr_stb       = wr_stb;
        o_func5_wr_data      = wr_data;
        o_func5_hst_rdy      = data_cntrl_rdy;
        o_func5_activate     = d_activate;
      end
      6: begin
        o_func6_wr_stb       = wr_stb;
        o_func6_wr_data      = wr_data;
        o_func6_hst_rdy      = data_cntrl_rdy;
        o_func6_activate     = d_activate;
      end
      7: begin
        o_func7_wr_stb       = wr_stb;
        o_func7_wr_data      = wr_data;
        o_func7_hst_rdy      = data_cntrl_rdy;
        o_func7_activate     = d_activate;
      end
      8: begin
        o_mem_wr_stb         = wr_stb;
        o_mem_wr_data        = wr_data;
        o_mem_hst_rdy        = data_cntrl_rdy;
        o_mem_activate       = d_activate;
      end
      default: begin
      end
    endcase
  end
end

//Multiplexer: Func -> Cmd Layer, Data Phy Layer
always @ (*) begin
  if (rst) begin
    rd_stb                  = 0;
    rd_data                 = 0;
    com_rdy                 = 0;
    block_size              = 0;

  end
  else begin
    case (func_select)
      0: begin
        rd_stb            = i_cia_rd_stb;
        rd_data           = i_cia_rd_data;
        com_rdy           = i_cia_com_rdy & data_cntrl_rdy;
        block_size        = i_cia_block_size;
        //finished          = i_cia_finished;
      end
      1: begin
        rd_stb            = i_func1_rd_stb;
        rd_data           = i_func1_rd_data;
        com_rdy           = i_func1_com_rdy & data_cntrl_rdy;
        block_size        = i_func1_block_size;
        //finished          = i_func1_finished;
      end
      2: begin
        rd_stb            = i_func2_rd_stb;
        rd_data           = i_func2_rd_data;
        com_rdy           = i_func2_com_rdy & data_cntrl_rdy;
        block_size        = i_func2_block_size;
        //finished          = i_func2_finished;
      end
      3: begin
        rd_stb            = i_func3_rd_stb;
        rd_data           = i_func3_rd_data;
        com_rdy           = i_func3_com_rdy & data_cntrl_rdy;
        block_size        = i_func3_block_size;
        //finished          = i_func3_finished;
      end
      4: begin
        rd_stb            = i_func4_rd_stb;
        rd_data           = i_func4_rd_data;
        com_rdy           = i_func4_com_rdy & data_cntrl_rdy;
        block_size        = i_func4_block_size;
        //finished          = i_func4_finished;
      end
      5: begin
        rd_stb            = i_func5_rd_stb;
        rd_data           = i_func5_rd_data;
        com_rdy           = i_func5_com_rdy & data_cntrl_rdy;
        block_size        = i_func5_block_size;
        //finished          = i_func5_finished;
      end
      6: begin
        rd_stb            = i_func6_rd_stb;
        rd_data           = i_func6_rd_data;
        com_rdy           = i_func6_com_rdy & data_cntrl_rdy;
        block_size        = i_func6_block_size;
        //finished          = i_func6_finished;
      end
      7: begin
        rd_stb            = i_func7_rd_stb;
        rd_data           = i_func7_rd_data;
        com_rdy           = i_func7_com_rdy & data_cntrl_rdy;
        block_size        = i_func7_block_size;
        //finished          = i_func7_finished;
      end
      8: begin
        rd_stb            = i_mem_rd_stb;
        rd_data           = i_mem_rd_data;
        com_rdy           = i_mem_com_rdy & data_cntrl_rdy;
        block_size        = i_mem_block_size;
        //finished          = i_mem_finished;
      end
      default: begin
        rd_stb            = 1'b0;
        rd_data           = 8'h0;
        com_rdy           = 1'b0;
      end
    endcase
  end
end

//synchronous logic
always @ (posedge clk) begin
  if (rst) begin
    state                       <=  IDLE;
    o_finished                  <=  0;
    total_block_count           <=  0;
    o_total_data_cnt            <=  0;
    block_count                 <=  0;
    data_count                  <=  0;
    continuous                  <=  0;
    data_cntrl_rdy              <=  0;
    o_address                   <=  0;
    data_activate               <=  0;
    read_cooldown               <=  DEFAULT_MIN_READ_COOLDOWN;
  end
  else begin
    case (state)
      IDLE: begin
        o_finished              <=  0;
        continuous              <=  0;
        total_block_count       <=  0;
        o_total_data_cnt        <=  0;
        data_count              <=  0;
        block_count             <=  0;
        data_cntrl_rdy          <=  0;
        o_address               <=  i_cmd_address;
        data_activate           <=  0;
        if (i_block_mode_flg) begin
          if (i_data_cnt == 0) begin
            continuous          <=  1;
            total_block_count   <=  0;
          end
          else begin
            total_block_count   <=  i_data_cnt;
          end
        end
        else begin
          total_block_count     <=  0;
        end
        if (i_activate) begin
          state                 <=  CONFIG;
        end
      end
      CONFIG: begin
        //We are ready to go, activate is high
        //Is this block mode?
        //Check to see if we need to adjust data_count (from 0 -> 512)
        data_count              <=  0;
        if (i_block_mode_flg) begin
          o_total_data_cnt      <=  block_size;
          if (!continuous) begin
            block_count         <=  block_count + 1;
          end
        end
        else begin
          if (i_data_cnt == 0) begin
            o_total_data_cnt    <=  512;
          end
          else begin
            o_total_data_cnt    <=  i_data_cnt;
          end
        end
        state                   <=  ACTIVATE;
      end
      ACTIVATE: begin
        data_activate             <=  1;
        if (i_cmd_bus_sel || i_data_phy_hst_rdy) begin
          data_cntrl_rdy          <=  1;
          if (data_count < o_total_data_cnt) begin
            if (wr_stb || rd_stb) begin
              data_count          <=  data_count + 1;
              if (i_inc_addr_flg) begin
                o_address         <=  o_address + 1;
              end
            end
          end
          else begin
            data_cntrl_rdy        <=  0;
            if (i_block_mode_flg) begin
              if (i_write_flg) begin
                state             <= WAIT_FOR_PHY;
              end
              else begin
                data_count        <= 0;
                state             <= READ_COOLDOWN;
              end
            end
            else begin
              state               <= FINISHED;
            end
          end
        end
      end
      WAIT_FOR_PHY: begin
        if (i_data_phy_finished) begin
          if (continuous || (block_count < total_block_count)) begin
            state               <= CONFIG;
          end
          else begin
            state               <= FINISHED;
          end
          data_activate         <=  0;
        end
      end
      READ_COOLDOWN: begin
        if (data_count < read_cooldown) begin
          data_count            <=  data_count + 1;
        end
        else begin
          data_activate         <=  0;
          if (continuous || (block_count < total_block_count)) begin
            state               <= CONFIG;
          end
          else begin
            state               <= FINISHED;
          end
        end
      end
      FINISHED: begin
        data_activate           <=  0;
        o_finished              <=  1;
      end
      default: begin
        state                   <=  FINISHED;
      end
    endcase

    if (!i_activate) begin
      //When !i_activate go back to IDLE, this can effectively cancel transactions or is used when finished is detected
      state                   <=  IDLE;
    end
  end
end

//Local Data Reader/Writer
always @ (posedge clk) begin
  lcl_wr_stb              <=  0;
  if (rst) begin
    ld_state              <=  IDLE;
    lcl_hst_rdy           <=  0;
  end
  else begin
    case (ld_state)
      IDLE: begin
        lcl_hst_rdy       <=  0;
        if (i_cmd_bus_sel) begin
          if (i_activate) begin
            if (i_write_flg) begin
              lcl_hst_rdy <=  1;
              ld_state    <=  WRITE;
            end
            else begin
              ld_state    <=  READ;
            end
          end
        end
      end
      WRITE: begin
        if (com_rdy) begin
          lcl_wr_stb      <=  1;
          ld_state        <=  FINISHED;
        end
      end
      READ: begin
        lcl_hst_rdy       <=  1;
        if (lcl_rd_stb) begin
          ld_state        <=  FINISHED;
        end
      end
      FINISHED: begin
        lcl_hst_rdy       <=  0;
        if (!i_activate) begin
          ld_state        <=  IDLE;
        end
      end
      default: begin
        ld_state          <=  FINISHED;
      end
    endcase
  end
end


endmodule
