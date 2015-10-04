`timescale 1ns/1ps

`include "sata_defines.v"

module tb_cocotb (

//Parameters
//Registers/Wires
input               rst,              //reset
input               clk,

);
reg     [31:0]      test_id = 0;



//There is a bug in COCOTB when stiumlating a signal, sometimes it can be corrupted if not registered
always @ (*) r_rst                = rst;

//Submodules

//Asynchronous Logic
//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
