module sync_fifo #(
  parameter MEM_DEPTH   = 8,
  parameter DATA_WIDTH  = 32
)(
  input                           in_clk,
  input                           out_clk,
  input                           rst,

  output                          full,
  output  reg                     empty,

  input       [DATA_WIDTH - 1: 0] i_in_data,
  input                           i_in_stb,

  input                           i_out_stb,
  output      [DATA_WIDTH - 1: 0] o_out_data
);

//localparameters
localparam  MEM_SIZE = (2 ** (MEM_DEPTH));
//Registers/Wires
reg [DATA_WIDTH - 1: 0] mem[0:MEM_SIZE];
reg [MEM_DEPTH - 1: 0]      r_in_pointer;
reg [MEM_DEPTH - 1: 0]      r_out_pointer;
wire                        w_empty;
//Submodules
//Asynchronous Logic
assign  w_empty = (r_in_pointer == r_out_pointer);
assign  full  = (r_out_pointer == 0) ? (r_in_pointer == (MEM_SIZE - 1)) : ((r_in_pointer + 1) == r_out_pointer);
assign  o_out_data  = mem[r_out_pointer];
//Synchronous Logic

always @ (posedge in_clk) begin
  if (rst) begin
    r_in_pointer  <=  0;
  end
  else begin
    if (i_in_stb && !full) begin
      mem[r_in_pointer] <=  i_in_data;
      r_in_pointer      <=  r_in_pointer + 1;
    end
  end
end

always @ (posedge out_clk) begin
  if (rst) begin
    //o_out_data    <=  0;
    r_out_pointer <=  0;
    empty         <=  1;
  end
  else begin
    empty               <=  w_empty;
    //o_out_data          <=  mem[r_out_pointer];
    if(i_out_stb && !empty) begin
      r_out_pointer     <=  r_out_pointer + 1;
    end
  end

end
 
endmodule
