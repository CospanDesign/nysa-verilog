`include "sd_defines.v"//nononw
module sd_clock_divider (
  input                 clk,
  input                 rst,
  input         [7:0]   divider,
  output  reg           sd_clk
);

//Local Parameters

//Registers/Wires
reg [7:0] clock_div;

//Submodules
//Asynchronous Logic
//Synchronous Logic
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    clock_div   <= 8'b0000_0000;
    sd_clk      <= 0;
  end
  else if (clock_div == divider )begin
    clock_div   <= 0;
    sd_clk      <= ~sd_clk;
  end
  else begin
    clock_div   <= clock_div + 1;
    sd_clk      <= sd_clk;
  end
end
endmodule


