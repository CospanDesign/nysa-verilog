//-------------------------------------------------------------------
//
//  COPYRIGHT (C) 207, red_digital_cinema
//
//  THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE
//  EXPRESSED WRITTEN CONSENT OF red_digital_cinema
//
//  red_digital_cinema                   http://www.red.com
//  325 e. hillcrest drive              info@red_digital_cinema.com
//  suite 10                           805 795-9925
//  thousand oaks, ca 91360
//-------------------------------------------------------------------
// Title       : rbuf_to_ddr3.v
// Author      : fred mccoy
// Created     : 12/09/2012
// Description : Move rxd data from 6 rbuf mems to 1 wbuf mem
//
// $Id$
//-------------------------------------------------------------------

`timescale 1ns / 1ps

/* STYLE_NOTES begin
  *
  * */
module serdes_scrambler
(
  input  [63:0] i_lvds,
  output [63:0] o_lvds

);

wire  [7:0] w_lvds0;
wire  [7:0] w_lvds1;
wire  [7:0] w_lvds2;
wire  [7:0] w_lvds3;
wire  [7:0] w_lvds4;
wire  [7:0] w_lvds5;
wire  [7:0] w_lvds6;
wire  [7:0] w_lvds7;

assign w_lvds7 = {i_lvds[31], i_lvds[39], i_lvds[23], i_lvds[47], i_lvds[15], i_lvds[55], i_lvds[07], i_lvds[63]}; 
assign w_lvds6 = {i_lvds[30], i_lvds[38], i_lvds[22], i_lvds[46], i_lvds[14], i_lvds[54], i_lvds[06], i_lvds[62]}; 
assign w_lvds5 = {i_lvds[29], i_lvds[37], i_lvds[21], i_lvds[45], i_lvds[13], i_lvds[53], i_lvds[05], i_lvds[61]}; 
assign w_lvds4 = {i_lvds[28], i_lvds[36], i_lvds[20], i_lvds[44], i_lvds[12], i_lvds[52], i_lvds[04], i_lvds[60]}; 
assign w_lvds3 = {i_lvds[27], i_lvds[35], i_lvds[19], i_lvds[43], i_lvds[11], i_lvds[51], i_lvds[03], i_lvds[59]}; 
assign w_lvds2 = {i_lvds[26], i_lvds[34], i_lvds[18], i_lvds[42], i_lvds[10], i_lvds[50], i_lvds[02], i_lvds[58]}; 
assign w_lvds1 = {i_lvds[25], i_lvds[33], i_lvds[17], i_lvds[41], i_lvds[09], i_lvds[49], i_lvds[01], i_lvds[57]}; 
assign w_lvds0 = {i_lvds[24], i_lvds[32], i_lvds[16], i_lvds[40], i_lvds[08], i_lvds[48], i_lvds[00], i_lvds[56]}; 

assign o_lvds = {w_lvds0, w_lvds1, w_lvds2, w_lvds3, w_lvds4, w_lvds5, w_lvds6, w_lvds7};
 
endmodule


