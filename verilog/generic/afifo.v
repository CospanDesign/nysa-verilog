//==========================================
// Function : Asynchronous FIFO (w/ 2 asynchronous clocks).
// Coder    : Alex Claros F.
// Date     : 15/May/2005.
// Notes    : This implementation is based on the article
//            'Asynchronous FIFO in Virtex-II FPGAs'
//            writen by Peter Alfke. This TechXclusive
//            article can be downloaded from the
//            Xilinx website. It has some minor modifications.
//=========================================

`timescale 1ns/1ps

module afifo
  #(parameter   DATA_WIDTH    = 8,
                ADDRESS_WIDTH = 4,
                FIFO_DEPTH    = (1 << ADDRESS_WIDTH))(

  //Reading port
  output reg  [DATA_WIDTH-1:0]        data_out,
  output reg                          empty,
  input wire                          rd_en,
  input wire                          dout_clk,
  //Writing port.
  input wire  [DATA_WIDTH-1:0]        data_in,
  output reg                          full,
  output wire                         almost_full,
  input wire                          wr_en,
  input wire                          din_clk,
  input wire                          rst);

  /////Internal connections & variables//////
  reg   [DATA_WIDTH-1:0]              mem [FIFO_DEPTH-1:0];
  wire  [ADDRESS_WIDTH-1:0]           p_next_word_to_write, p_next_word_to_read;
  wire                                equal_addresses;
  wire                                NextWriteAddressEn, NextReadAddressEn;
  wire                                set_status, rst_status;
  reg                                 status;
  wire                                preset_full, preset_empty;


  assign                              almost_full = status;

    //////////////Code///////////////
    //Data ports logic:
    //(Uses a dual-port RAM).
    //'data_out' logic:
//  assign data_out = mem[p_next_word_to_read];
    always @ (posedge dout_clk)
        if (rd_en & !empty)
            data_out <= mem[p_next_word_to_read];

    //'data_in' logic:
    always @ (posedge din_clk)
        if (wr_en & !full)
            mem[p_next_word_to_write] <= data_in;

    //Fifo addresses support logic:
    //'Next Addresses' enable logic:
    assign NextWriteAddressEn = wr_en & ~full;
    assign NextReadAddressEn  = rd_en  & ~empty;

    //Addreses (Gray counters) logic:
    GrayCounter
    #(
      .COUNTER_WIDTH(ADDRESS_WIDTH)
    )GrayCounter_pWr
       (.gray_count_out(p_next_word_to_write),
        .en(NextWriteAddressEn),
        .rst(rst),
        .clk(din_clk)
       );

    GrayCounter
    #(
      .COUNTER_WIDTH(ADDRESS_WIDTH)
    )GrayCounter_pRd
       (.gray_count_out(p_next_word_to_read),
        .en(NextReadAddressEn),
        .rst(rst),
        .clk(dout_clk)
       );


    //'equal_addresses' logic:
    assign equal_addresses = (p_next_word_to_write == p_next_word_to_read);

    //'Quadrant selectors' logic:
    assign set_status = (p_next_word_to_write[ADDRESS_WIDTH-2] ~^ p_next_word_to_read[ADDRESS_WIDTH-1]) &
                         (p_next_word_to_write[ADDRESS_WIDTH-1] ^  p_next_word_to_read[ADDRESS_WIDTH-2]);

    assign rst_status = (p_next_word_to_write[ADDRESS_WIDTH-2] ^  p_next_word_to_read[ADDRESS_WIDTH-1]) &
                         (p_next_word_to_write[ADDRESS_WIDTH-1] ~^ p_next_word_to_read[ADDRESS_WIDTH-2]);

    //'status' latch logic:
    always @ (set_status, rst_status, rst) //D Latch w/ Asynchronous Clear & Preset.
        if (rst_status | rst)
            status = 0;  //Going 'Empty'.
        else if (set_status)
            status = 1;  //Going 'Full'.

    //'full' logic for the writing port:
    assign preset_full = status & equal_addresses;  //'Full' Fifo.

    always @ (posedge din_clk, posedge preset_full) //D Flip-Flop w/ Asynchronous Preset.
        if (preset_full)
            full <= 1;
        else
            full <= 0;

    //'empty' logic for the reading port:
    assign preset_empty = ~status & equal_addresses;  //'Empty' Fifo.

    always @ (posedge dout_clk, posedge preset_empty)  //D Flip-Flop w/ Asynchronous Preset.
        if (preset_empty)
            empty <= 1;
        else
            empty <= 0;

endmodule
