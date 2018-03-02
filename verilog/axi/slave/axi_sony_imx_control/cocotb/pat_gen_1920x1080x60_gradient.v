//-------------------------------------------------------------------
//
// COPYRIGHT (C) 2012, red_digital_cinema
//
// THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE
// EXPRESSED WRITTEN CONSENT OF red_digital_cinema
//
// red_digital_cinema          http://www.red.com
// 325 e. hillcrest drive       info@red_digital_cinema.com
// suite 100              805 795-9925
// thousand oaks, ca 91360
//
// ver171 changed cml clock to gtx0 instead of gtx4
//        added dc_led for led version blinking
//
//-------------------------------------------------------------------
// Title    : dc_led.v
// Author   : fred mccoy
// Created   : 12/31/2012
// Description : 
// LED1 should pulse for 8msec every frame transition
// LED2 should pulse for 8msec every 3200 row transitions
//(about a frame time)
// LED3 is loopback active
// LED4 is DONE LED
//
// $Id$
//-------------------------------------------------------------------

`timescale 1ns / 1ps

/* STYLE_NOTES begin
 *
 * */
module pat_gen_1920x1080x60_gradient
(
    input             clk150,
    output     [23:0] o_pixel,
    output reg        o_data_valid,
    output reg        o_hsync,
    output reg        o_vsync,
    output reg        o_hblanking,
    output reg        o_vblanking,
    input             rst
);

localparam K_VROW_COUNT = 16'h0463; // 1124 1123 0463
localparam K_HCOL_COUNT = 16'h08AF; // 2224 2223 08AF
                                              // 
                                                     // #rows  position  dec2hex()
localparam K_VPRE_BLANKING               = 16'h0016; // 22       21       0016
localparam K_VIMAGE                      = 16'h044E; // 1080     1102     044E
localparam K_VPOST_BLANKING              = 16'h0464; // 22       1124     0464

                                                     // #COLs  position  dec2hex()
localparam K_HPRE_BLANKING               = 16'h0098; // 152       152     0098
localparam K_HIMAGE                      = 16'h0818; // 1920      2072    0818
localparam K_HPOST_BLANKING              = 16'h08B0; // 152       2224    08b0
                                               
reg [15:0] r_vcount;
reg [15:0] r_hcount;
reg [11:0] r_data;

assign o_pixel[23:20] = r_data[11:8];
assign o_pixel[19:16] = 4'h0;
assign o_pixel[15:12] = r_data[7:4];
assign o_pixel[11:8]  = 4'h0;
assign o_pixel[7:4]   = r_data[3:0];
assign o_pixel[3:0]   = 4'h0;
/* STYLE_NOTES begin
 * Only synchronous assigns done here. Always use non-blocking <=
 * STYLE_NOTES end*/
//
// SYNCHRONOUS
//

always @(posedge clk150)
if (rst) begin
    o_data_valid <= 0;
    o_hsync      <= 0;
    o_vsync      <= 0;
    o_hblanking  <= 0;
    o_vblanking  <= 0;
    r_vcount     <= 0;
    r_hcount     <= 0;
    r_data       <= 0;
end
else begin


    if (r_hcount == K_HCOL_COUNT) begin
        r_hcount <= 0;
        if (r_vcount == K_VROW_COUNT) begin
            r_vcount <= 0;
        end else begin
            r_vcount <= r_vcount + 1;
        end
    end else begin
        r_hcount <= r_hcount + 1;
    end


    if (r_hcount == 0) begin
        o_hsync <= 1;
    end else
    if (r_hcount == 3) begin
        o_hsync <= 0;
    end

    if (r_vcount == 0) begin
        o_vsync <= 1;
    end else begin
        o_vsync <= 0;
    end

    if (r_hcount < K_HPRE_BLANKING) begin
        o_hblanking  <= 1;
        o_data_valid <= 0;
    end else
    if (r_hcount < K_HIMAGE) begin
        o_hblanking <= 0;
        if (o_vblanking == 0) begin
            o_data_valid <= 1;
        end
    end else begin
        o_hblanking  <= 1;
        o_data_valid <= 0;
    end

    if (r_vcount < K_VPRE_BLANKING) begin
        o_vblanking <= 1;
    end else
    if (r_vcount < K_VIMAGE) begin
        o_vblanking <= 0;
    end else begin
        o_vblanking <= 1;
    end

    if (o_data_valid) begin
        r_data <= r_data + 1;
    end else begin
        r_data <= 0;
    end
end

endmodule



