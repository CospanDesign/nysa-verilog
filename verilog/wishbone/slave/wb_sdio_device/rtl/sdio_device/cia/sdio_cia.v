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
 * Author: David McCoy (dave.mccoy@cospandesign.com)
 * Description: Common Interface Access (CIA)
 *  Controls many aspects of the card.
 *  Define values are values that do not change with implementation, for
 *    for example: CCCR version number and SDIO version number
 *  Parameter values change with every implementation, examples include
 *    Buffer depth and function numbers
 *
 * Changes:
 *  2015.13.09: Inital Commit
 */

`include "sdio_cia_defines.v"

module sdio_cia (
  input                     clk,    // SDIO PHY Clock
  input                     rst,

  output  reg               o_ready,
  input                     i_activate,
  input                     i_ready,
  output  reg               o_finished,
  input                     i_write_flag,
  input                     i_inc_addr,
  input         [17:0]      i_address,
  input                     i_data_stb,
  input         [12:0]      i_data_count,
  input         [7:0]       i_data_in,
  output        [7:0]       o_data_out,
  output  reg               o_data_stb,  //If reading, this strobes a new piece of data in, if writing strobes data out

  //FBR Interface
  output                    o_fbr1_csa_en,
  output        [3:0]       o_fbr1_pwr_mode,
  output        [15:0]      o_fbr1_block_size,

  output                    o_fbr2_csa_en,
  output        [3:0]       o_fbr2_pwr_mode,
  output        [15:0]      o_fbr2_block_size,

  output                    o_fbr3_csa_en,
  output        [3:0]       o_fbr3_pwr_mode,
  output        [15:0]      o_fbr3_block_size,

  output                    o_fbr4_csa_en,
  output        [3:0]       o_fbr4_pwr_mode,
  output        [15:0]      o_fbr4_block_size,

  output                    o_fbr5_csa_en,
  output        [3:0]       o_fbr5_pwr_mode,
  output        [15:0]      o_fbr5_block_size,

  output                    o_fbr6_csa_en,
  output        [3:0]       o_fbr6_pwr_mode,
  output        [15:0]      o_fbr6_block_size,

  output                    o_fbr7_csa_en,
  output        [3:0]       o_fbr7_pwr_mode,
  output        [15:0]      o_fbr7_block_size,

  //output        [7:0]       o_fbr_select,
  output                    o_fbr_activate,
  output                    o_fbr_ready,
  output                    o_fbr_write_flag,
  output                    o_fbr_addr_in,
  output        [17:0]      o_fbr_address,
  output                    o_fbr_data_stb,
  output        [12:0]      o_fbr_data_count,
  output        [7:0]       o_fbr_data_in,

  output                    o_fbr1_en,
  output                    o_fbr2_en,
  output                    o_fbr3_en,
  output                    o_fbr4_en,
  output                    o_fbr5_en,
  output                    o_fbr6_en,
  output                    o_fbr7_en,


  //Function Configuration Interface
  output        [7:0]       o_func_enable,
  input         [7:0]       i_func_ready,
  output        [7:0]       o_func_int_enable,
  input         [7:0]       i_func_int_pending,
  output                    o_soft_reset,
  output        [2:0]       o_func_abort_stb,
  output                    o_en_card_detect_n,
  output                    o_en_4bit_block_int, /* Enable interrupts durring 4-bit block data mode */
  input                     i_data_bus_busy,
  output                    o_bus_release_req_stb,
  output        [3:0]       o_func_select,
  input                     i_data_read_avail,
  input         [7:0]       i_func_exec_status,
  input         [7:0]       i_func_ready_for_data,
  output        [15:0]      o_f0_block_size,

  output                    o_1_bit_mode,
  output                    o_4_bit_mode,
  output                    o_8_bit_mode,

  output                    o_sdr_12,
  output                    o_sdr_25,
  output                    o_sdr_50,
  output                    o_ddr_50,
  output                    o_sdr_104,

  output                    o_driver_type_a,
  output                    o_driver_type_b,
  output                    o_driver_type_c,
  output                    o_driver_type_d,
  output                    o_enable_async_interrupt
);

//Local Parameters

localparam                      IDLE        = 4'h0;
localparam                      WRITE_START = 4'h1;
localparam                      WRITE       = 4'h2;
localparam                      READ_DELAY1 = 4'h3;
localparam                      READ_DELAY2 = 4'h4;
localparam                      READ_START  = 4'h5;
localparam                      READ        = 4'h6;
localparam                      FINISHED    = 4'h7;

//Local Registers/Wires
wire                            cia_i_activate[0:`NO_SELECT_INDEX + 1];
wire            [7:0]           cia_o_data_out[0:`NO_SELECT_INDEX + 1];
//wire                            cia_o_ready   [0:`NO_SELECT_INDEX + 1];
//wire                            cia_o_finished[0:`NO_SELECT_INDEX + 1];
//wire                            cia_o_data_stb[0:`NO_SELECT_INDEX + 1];
reg             [3:0]           func_sel;

reg             [3:0]           state;
reg             [17:0]          data_count;
wire            [17:0]          address;

//submodules
sdio_cccr cccr (
  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .i_activate                   (cia_i_activate[`CCCR_INDEX]  ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`CCCR_INDEX]  ),

  .o_func_enable                (o_func_enable                ),
  .i_func_ready                 (i_func_ready                 ),
  .o_func_int_enable            (o_func_int_enable            ),
  .i_func_int_pending           (i_func_int_pending           ),
  .o_soft_reset                 (o_soft_reset                 ),
  .o_func_abort_stb             (o_func_abort_stb             ),
  .o_en_card_detect_n           (o_en_card_detect_n           ),
  .o_en_4bit_block_int          (o_en_4bit_block_int          ),
  .i_data_bus_busy              (i_data_bus_busy              ),
  .o_bus_release_req_stb        (o_bus_release_req_stb        ),
  .o_func_select                (o_func_select                ),
  .i_data_read_avail            (i_data_read_avail            ),
  .i_func_exec_status           (i_func_exec_status           ),
  .i_func_ready_for_data        (i_func_ready_for_data        ),
  .o_f0_block_size              (o_f0_block_size              ),

  .o_1_bit_mode                 (o_1_bit_mode                 ),
  .o_4_bit_mode                 (o_4_bit_mode                 ),
  .o_8_bit_mode                 (o_8_bit_mode                 ),

  .o_sdr_12                     (o_sdr_12                     ),
  .o_sdr_25                     (o_sdr_25                     ),
  .o_sdr_50                     (o_sdr_50                     ),
  .o_ddr_50                     (o_ddr_50                     ),
  .o_sdr_104                    (o_sdr_104                    ),

  .o_driver_type_a              (o_driver_type_a              ),
  .o_driver_type_b              (o_driver_type_b              ),
  .o_driver_type_c              (o_driver_type_c              ),
  .o_driver_type_d              (o_driver_type_d              ),
  .o_enable_async_interrupt     (o_enable_async_interrupt     )
);

sdio_cis #(
  .FILE_LENGTH                  (`CIS_FILE_LENGTH             ),
  .FILENAME                     (`CIS_FILENAME                )
)cis(
  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .i_activate                   (i_activate                   ),
  .i_address                    (i_address                    ),
  .i_data_stb                   (i_data_stb                   ),
  .o_data_out                   (cia_o_data_out[`CIS_INDEX]   )
);

generate
if (`FUNC1_EN) begin
sdio_fbr #(
  .INDEX                        (1                            ),
  .FUNC_TYPE                    (`FUNC1_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC1_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC1_BLOCK_SIZE            )

) fbr1 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr1_csa_en                ),
  .o_pwr_mode                   (o_fbr1_pwr_mode              ),
  .o_block_size                 (o_fbr1_block_size            ),

  .i_activate                   (cia_i_activate[`FUNC1_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC1_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC1_INDEX]  = 8'h0;
assign  o_fbr1_csa_en                 = 1'b0;
assign  o_fbr1_pwr_mode               = 4'h0;
assign  o_fbr1_block_size             = 16'h0000;
end
endgenerate

generate
if (`FUNC2_EN) begin
sdio_fbr #(
  .INDEX                        (`FUNC2_INDEX                 ),
  .FUNC_TYPE                    (`FUNC2_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC2_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC2_BLOCK_SIZE            )

) fbr2 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr2_csa_en                ),
  .o_pwr_mode                   (o_fbr2_pwr_mode              ),
  .o_block_size                 (o_fbr2_block_size            ),

  .i_activate                   (cia_i_activate[`FUNC2_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC2_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC2_INDEX]  = 8'b0;
assign  o_fbr2_csa_en                 = 1'b0;
assign  o_fbr2_pwr_mode               = 4'h0;
assign  o_fbr2_block_size             = 16'h0000;

end
endgenerate

generate
if (`FUNC3_EN) begin
sdio_fbr #(
  .INDEX                        (1                            ),
  .FUNC_TYPE                    (`FUNC3_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC3_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC3_BLOCK_SIZE            )

) fbr3 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr3_csa_en                ),
  .o_pwr_mode                   (o_fbr3_pwr_mode              ),
  .o_block_size                 (o_fbr3_block_size            ),


  .i_activate                   (cia_i_activate[`FUNC3_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC3_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC3_INDEX]  =  8'b0;
assign  o_fbr3_csa_en                 = 1'b0;
assign  o_fbr3_pwr_mode               = 4'h0;
assign  o_fbr3_block_size             = 16'h0000;

end
endgenerate

generate
if (`FUNC4_EN) begin
sdio_fbr #(
  .INDEX                        (1                            ),
  .FUNC_TYPE                    (`FUNC4_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC4_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC4_BLOCK_SIZE            )

) fbr4 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr4_csa_en                ),
  .o_pwr_mode                   (o_fbr4_pwr_mode              ),
  .o_block_size                 (o_fbr4_block_size            ),


  .i_activate                   (cia_i_activate[`FUNC4_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC4_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC4_INDEX]  =  8'b0;
assign  o_fbr4_csa_en                 = 1'b0;
assign  o_fbr4_pwr_mode               = 4'h0;
assign  o_fbr4_block_size             = 16'h0000;

end
endgenerate

generate
if (`FUNC5_EN) begin
sdio_fbr #(
  .INDEX                        (1                            ),
  .FUNC_TYPE                    (`FUNC5_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC5_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC5_BLOCK_SIZE            )

) fbr5 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr5_csa_en                ),
  .o_pwr_mode                   (o_fbr5_pwr_mode              ),
  .o_block_size                 (o_fbr5_block_size            ),


  .i_activate                   (cia_i_activate[`FUNC5_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC5_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC5_INDEX]  =  8'b0;
assign  o_fbr5_csa_en                 = 1'b0;
assign  o_fbr5_pwr_mode               = 4'h0;
assign  o_fbr5_block_size             = 16'h0000;

end
endgenerate

generate
if (`FUNC6_EN) begin
sdio_fbr #(
  .INDEX                        (1                            ),
  .FUNC_TYPE                    (`FUNC6_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC6_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC6_BLOCK_SIZE            )

) fbr6 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr6_csa_en                ),
  .o_pwr_mode                   (o_fbr6_pwr_mode              ),
  .o_block_size                 (o_fbr6_block_size            ),


  .i_activate                   (cia_i_activate[`FUNC6_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC6_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC6_INDEX]  =  8'b0;
assign  o_fbr6_csa_en                 = 1'b0;
assign  o_fbr6_pwr_mode               = 4'h0;
assign  o_fbr6_block_size             = 16'h0000;

end
endgenerate

generate
if (`FUNC7_EN) begin
sdio_fbr #(
  .INDEX                        (1                            ),
  .FUNC_TYPE                    (`FUNC7_TYPE                  ),
  .FUNC_TYPE_EXT                (4'h0                         ),    //TODO
  .SUPPORT_PWR_SEL              (1'b0                         ),    //TODO
  .CSA_SUPPORT                  (0                            ),    //TODO
  .CSA_OFFSET                   (0                            ),    //TODO
  .CIS_OFFSET                   (`MAIN_CIS_START_ADDR + `FUNC7_CIS_OFFSET),
  .BLOCK_SIZE                   (`FUNC7_BLOCK_SIZE            )

) fbr7 (

  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .o_csa_en                     (o_fbr7_csa_en                ),
  .o_pwr_mode                   (o_fbr7_pwr_mode              ),
  .o_block_size                 (o_fbr7_block_size            ),


  .i_activate                   (cia_i_activate[`FUNC7_INDEX] ),
  .i_write_flag                 (i_write_flag                 ),
  .i_address                    (i_address[7:0]               ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`FUNC7_INDEX] )
);
end
else begin
assign  cia_o_data_out[`FUNC7_INDEX]  =  8'b0;
assign  o_fbr7_csa_en                 = 1'b0;
assign  o_fbr7_pwr_mode               = 4'h0;
assign  o_fbr7_block_size             = 16'h0000;

assign  o_data_out                        =  cia_o_data_out[func_sel];


end
endgenerate

//asynchronous logic
assign  address                 =   i_address + data_count;

//Address Multiplexer
always @ (*) begin
  if (rst || o_soft_reset) begin
    func_sel      <=  `NO_SELECT_INDEX;
  end
  else begin
    if      ((address >= `CCCR_FUNC_START_ADDR)  && (address <= `CCCR_FUNC_END_ADDR )) begin
      //CCCR Selected
      func_sel      <=  `CCCR_INDEX;
    end
    else if ((address >= `FUNC1_START_ADDR)     && (address <= `FUNC1_END_ADDR    )) begin
      //Fuction 1 Sected
      func_sel      <=  `FUNC1_INDEX;
    end
    else if ((address >= `FUNC2_START_ADDR)     && (address <= `FUNC2_END_ADDR    )) begin
      //Fuction 2 Sected
      func_sel      <=  `FUNC2_INDEX;
    end
    else if ((address >= `FUNC3_START_ADDR)     && (address <= `FUNC3_END_ADDR    )) begin
      //Fuction 3 Sected
      func_sel      <=  `FUNC3_INDEX;
    end
    else if ((address >= `FUNC4_START_ADDR)     && (address <= `FUNC4_END_ADDR    )) begin
      //Fuction 4 Sected
      func_sel      <=  `FUNC4_INDEX;
    end
    else if ((address >= `FUNC5_START_ADDR)     && (address <= `FUNC5_END_ADDR    )) begin
      //Fuction 5 Sected
      func_sel      <=  `FUNC5_INDEX;
    end
    else if ((address >= `FUNC6_START_ADDR)     && (address <= `FUNC6_END_ADDR    )) begin
      //Fuction 6 Sected
      func_sel      <=  `FUNC6_INDEX;
    end
    else if ((address >= `FUNC7_START_ADDR)     && (address <= `FUNC7_END_ADDR    )) begin
      //Fuction 7 Sected
      func_sel      <=  `FUNC7_INDEX;
    end
    else if ((address >= `MAIN_CIS_START_ADDR)  && (address <= `MAIN_CIS_END_ADDR      )) begin
      //Main CIS Region
      func_sel      <=  `CIS_INDEX;
    end
    else begin
      func_sel      <=  `NO_SELECT_INDEX;
    end
  end
end


//All FPR Channel Specific interfaces are broght ito the multiplexer
/*
assign  cia_o_finished[`FUNC1_INDEX]      = i_fbr1_finished;
assign  cia_o_ready   [`FUNC1_INDEX]      = i_fbr1_ready;
assign  cia_o_data_out[`FUNC1_INDEX]      = i_fbr1_data_out;
assign  cia_o_data_stb[`FUNC1_INDEX]      = i_fbr1_data_stb;

assign  cia_o_finished[`FUNC2_INDEX]      = i_fbr2_finished;
assign  cia_o_ready   [`FUNC2_INDEX]      = i_fbr2_ready;
assign  cia_o_data_out[`FUNC2_INDEX]      = i_fbr2_data_out;
assign  cia_o_data_stb[`FUNC2_INDEX]      = i_fbr2_data_stb;

assign  cia_o_finished[`FUNC3_INDEX]      = i_fbr3_finished;
assign  cia_o_ready   [`FUNC3_INDEX]      = i_fbr3_ready;
assign  cia_o_data_out[`FUNC3_INDEX]      = i_fbr3_data_out;
assign  cia_o_data_stb[`FUNC3_INDEX]      = i_fbr3_data_stb;

assign  cia_o_finished[`FUNC4_INDEX]      = i_fbr4_finished;
assign  cia_o_ready   [`FUNC4_INDEX]      = i_fbr4_ready;
assign  cia_o_data_out[`FUNC4_INDEX]      = i_fbr4_data_out;
assign  cia_o_data_stb[`FUNC4_INDEX]      = i_fbr4_data_stb;

assign  cia_o_finished[`FUNC5_INDEX]      = i_fbr5_finished;
assign  cia_o_ready   [`FUNC5_INDEX]      = i_fbr5_ready;
assign  cia_o_data_out[`FUNC5_INDEX]      = i_fbr5_data_out;
assign  cia_o_data_stb[`FUNC5_INDEX]      = i_fbr5_data_stb;

assign  cia_o_finished[`FUNC6_INDEX]      = i_fbr6_finished;
assign  cia_o_ready   [`FUNC6_INDEX]      = i_fbr6_ready;
assign  cia_o_data_out[`FUNC6_INDEX]      = i_fbr6_data_out;
assign  cia_o_data_stb[`FUNC6_INDEX]      = i_fbr6_data_stb;

assign  cia_o_finished[`FUNC7_INDEX]      = i_fbr7_finished;
assign  cia_o_ready   [`FUNC7_INDEX]      = i_fbr7_ready;
assign  cia_o_data_out[`FUNC7_INDEX]      = i_fbr7_data_out;
assign  cia_o_data_stb[`FUNC7_INDEX]      = i_fbr7_data_stb;
*/


assign  cia_i_activate[`CCCR_INDEX ]      = (func_sel == `CCCR_INDEX )    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC1_INDEX]      = (func_sel == `FUNC1_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC2_INDEX]      = (func_sel == `FUNC2_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC3_INDEX]      = (func_sel == `FUNC3_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC4_INDEX]      = (func_sel == `FUNC4_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC5_INDEX]      = (func_sel == `FUNC5_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC6_INDEX]      = (func_sel == `FUNC6_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`FUNC7_INDEX]      = (func_sel == `FUNC7_INDEX)    ? i_activate        : 1'b0;
assign  cia_i_activate[`CIS_INDEX  ]      = (func_sel == `CIS_INDEX  )    ? i_activate        : 1'b0;

/*
assign  o_ready                           =  cia_o_ready[func_sel];
assign  o_finished                        =  cia_o_finished[func_sel];
assign  o_data_out                        =  cia_o_data_out[func_sel];
assign  o_data_stb                        =  cia_o_data_stb[func_sel];

assign  cia_o_ready   [`NO_SELECT_INDEX]  = 1'b0;
assign  cia_o_finished[`NO_SELECT_INDEX]  = 1'b1; //Always Done
assign  cia_o_data_out[`NO_SELECT_INDEX]  = 8'h0;
assign  cia_o_data_stb[`NO_SELECT_INDEX]  = 1'b0;

assign  o_fbr_select                      = func_sel;
assign  o_fbr_activate                    = i_activate;
assign  o_fbr_ready                       = i_ready;
assign  o_fbr_write_flag                  = i_write_flag;
assign  o_fbr_address                     = i_address;
assign  o_fbr_inc_addr                    = i_inc_addr;
assign  o_fbr_data_stb                    = i_data_stb;
assign  o_fbr_data_count                  = i_data_count;
assign  o_fbr_data_in                     = i_data_in;
*/


//synchronous Logic

always @ (posedge clk) begin
  //De-assert Strobes
  o_data_stb      <=  0;

  if (rst) begin
    state               <=  IDLE;
    data_count          <=  0;
    o_ready             <=  0;
    o_finished          <=  0;
  end
  else begin
    case (state)
      IDLE: begin
        o_finished      <=  0;
        data_count      <=  0;
        o_ready         <=  0;
        if (i_activate && i_ready) begin
          if (i_write_flag) begin
            state       <=  WRITE_START;
          end
          else begin
            state       <=  READ_DELAY1;
            o_ready     <=  1;
          end
        end
      end
      WRITE_START: begin
        //Need one clock cycle to get things going with block RAM, this
        //  Doesn't hurt anything with the non block RAM interfaces
        //data_count      <=  data_count + 1;
        o_ready         <=  1;
        //if (data_count + 1 >= i_data_count) begin
        //  state         <=  FINISHED;
        //end
        //else begin
          state         <= WRITE;
        //end
      end
      WRITE: begin
        if (data_count < i_data_count) begin
          if (i_data_stb) begin
            data_count    <=  data_count + 1;
          end
        end
        else begin
          state         <=  FINISHED;
          o_ready       <=  0;
        end
      end
      READ_DELAY1: begin
        state           <=  READ_DELAY2;
      end
      READ_DELAY2: begin
        state           <=  READ_START;
      end
      READ_START: begin
        o_data_stb      <=  1;
        data_count      <=  1;
        //data_count      <=  data_count + 1;
        //o_data_stb      <=  1;
        state           <=  READ;
      end
      READ: begin
        if (data_count < i_data_count) begin
          o_data_stb    <=  1;
          data_count    <=  data_count + 1;
        end
        else begin
          state         <=  FINISHED;
        end
      end
      FINISHED: begin
      o_finished        <=  1;
      if (!i_activate) begin
        state           <=  IDLE;
      end
      end
    endcase
  end
end
endmodule
