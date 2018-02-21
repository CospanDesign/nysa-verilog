//-------------------------------------------------------------------
// Title   : dc_rxd_to_rbuf
// Author  : mccoy
// Created  : 01/30/2012
// rxd rbuf memory
//-------------------------------------------------------------------

`timescale 1ns / 1ps

/* STYLE_NOTES begin
 *
 * */
module rxd_aligner
(
    input               clk,
    input               rst,
    input               i_hflag,
    output reg          o_aligned = 0,
    input       [7:0]   i_lvds,
    output reg  [7:0]   o_lvds_aligned = 0
);

localparam SAV8_VALID              = { 8'hFF,8'h00,8'h00,8'h80};
localparam SAV8_INVALID            = { 8'hFF,8'h00,8'h00,8'hAB};
localparam EAV8_VALID              = { 8'hFF,8'h00,8'h00,8'h9D};
localparam EAV8_INVALID            = { 8'hFF,8'h00,8'h00,8'hB6};

reg [39:0]  r_lvds;
reg  [2:0]  r_mode;
reg         r_aligned;
reg         r_prev_hflag;

always @(posedge clk)
  if (rst) begin
    r_lvds <= 0;
    r_mode <= 0;
    r_aligned <=  0;
    o_aligned <=  0;
  end
  else begin
    r_lvds <= {r_lvds[31:0],i_lvds};
    if (i_hflag & !r_prev_hflag) begin
      if (r_aligned) begin
        o_aligned <=  1;
      end
      else begin
        o_aligned <=  0;
      end
      r_aligned   <=  0;
    end

    if (r_lvds[31:0] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h0;
        o_lvds_aligned  <= r_lvds[31:0];
    end else
    if (r_lvds[31:0] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h0;
        o_lvds_aligned  <= r_lvds[31:0];
    end else

    if (r_lvds[32:1] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h1;
        o_lvds_aligned  <= r_lvds[32:1];
    end else
    if (r_lvds[32:1] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h1;
        o_lvds_aligned  <= r_lvds[32:1];
    end else

    if (r_lvds[33:2] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h2;
        o_lvds_aligned  <= r_lvds[33:2];
    end else
    if (r_lvds[33:2] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h2;
        o_lvds_aligned  <= r_lvds[33:2];

    end else
    if (r_lvds[34:3] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h3;
        o_lvds_aligned  <= r_lvds[34:3];
    end else
    if (r_lvds[34:3] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode <= 3'h3;
        o_lvds_aligned  <= r_lvds[34:3];

    end else
    if (r_lvds[35:4] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h4;
        o_lvds_aligned  <= r_lvds[35:4];
    end else
    if (r_lvds[35:4] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h4;
        o_lvds_aligned  <= r_lvds[35:4];

    end else
    if (r_lvds[36:5] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h5;
        o_lvds_aligned  <= r_lvds[36:5];
    end else
    if (r_lvds[36:5] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h5;
        o_lvds_aligned  <= r_lvds[36:5];

    end else
    if (r_lvds[37:6] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h6;
        o_lvds_aligned  <= r_lvds[37:6];
    end else
    if (r_lvds[37:6] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h6;
        o_lvds_aligned  <= r_lvds[37:6];

    end else
    if (r_lvds[38:7] == SAV8_VALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h7;
        o_lvds_aligned <= r_lvds[38:7];
    end else
    if (r_lvds[38:7] == SAV8_INVALID) begin
        r_aligned       <=  1;
        r_mode          <= 3'h7;
        o_lvds_aligned  <= r_lvds[38:7];

    end else
    if (r_mode == 3'h0) begin
        o_lvds_aligned  <= r_lvds[31:0];
    end else
    if (r_mode == 3'h0) begin
        o_lvds_aligned  <= r_lvds[31:0];
    end else
    if (r_mode == 3'h1) begin
        o_lvds_aligned  <= r_lvds[32:1];
    end else
    if (r_mode == 3'h2) begin
        o_lvds_aligned  <= r_lvds[33:2];
    end else
    if (r_mode == 3'h3) begin
        o_lvds_aligned  <= r_lvds[34:3];
    end else
    if (r_mode == 3'h4) begin
        o_lvds_aligned  <= r_lvds[35:4];
    end else
    if (r_mode == 3'h5) begin
        o_lvds_aligned  <= r_lvds[36:5];
    end else
    if (r_mode == 3'h6) begin
        o_lvds_aligned  <= r_lvds[37:6];

    end else begin
        o_lvds_aligned  <= r_lvds[38:7];
    end
    r_prev_hflag  <=  i_hflag;
  end
endmodule


