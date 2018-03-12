//-------------------------------------------------------------------
// Author      : fred mccoy
//-------------------------------------------------------------------

`timescale 1ns / 1ps

/* STYLE_NOTES begin
  *
  * */
module serdes_descramble
(
  input  [63:0] i_lvds,
  output  [7:0] o_lvds0,
  output  [7:0] o_lvds1,
  output  [7:0] o_lvds2,
  output  [7:0] o_lvds3,
  output  [7:0] o_lvds4,
  output  [7:0] o_lvds5,
  output  [7:0] o_lvds6,
  output  [7:0] o_lvds7
);

assign o_lvds0 = {i_lvds[07],i_lvds[15],i_lvds[23],i_lvds[31],i_lvds[39],i_lvds[47],i_lvds[55],i_lvds[63]};
assign o_lvds1 = {i_lvds[06],i_lvds[14],i_lvds[22],i_lvds[30],i_lvds[38],i_lvds[46],i_lvds[54],i_lvds[62]};
assign o_lvds2 = {i_lvds[05],i_lvds[13],i_lvds[21],i_lvds[29],i_lvds[37],i_lvds[45],i_lvds[53],i_lvds[61]};
assign o_lvds3 = {i_lvds[04],i_lvds[12],i_lvds[20],i_lvds[28],i_lvds[36],i_lvds[44],i_lvds[52],i_lvds[60]};
assign o_lvds4 = {i_lvds[03],i_lvds[11],i_lvds[19],i_lvds[27],i_lvds[35],i_lvds[43],i_lvds[51],i_lvds[59]};
assign o_lvds5 = {i_lvds[02],i_lvds[10],i_lvds[18],i_lvds[26],i_lvds[34],i_lvds[42],i_lvds[50],i_lvds[58]};
assign o_lvds6 = {i_lvds[01],i_lvds[09],i_lvds[17],i_lvds[25],i_lvds[33],i_lvds[41],i_lvds[49],i_lvds[57]};
assign o_lvds7 = {i_lvds[00],i_lvds[08],i_lvds[16],i_lvds[24],i_lvds[32],i_lvds[40],i_lvds[48],i_lvds[56]};
 
endmodule


