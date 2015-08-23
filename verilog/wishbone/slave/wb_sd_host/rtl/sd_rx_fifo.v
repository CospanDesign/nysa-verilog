`include "sd_defines.v"
//`include "timescale.v"


module sd_rx_fifo (
   input            rst,
   input [3:0]      d,
   input            wr,
   input            wclk,

   output [31:0]    q,
   input            rd,
   output           full,
   output           empty,
   output [1:0]     mem_empt,
   input            rclk
);

//Local Parameters

//Registers/Wires
reg     [31:0]                      ram [0:`FIFO_RX_MEM_DEPTH-1]; //synthesis syn_ramstyle = "no_rw_check
reg     [`FIFO_RX_MEM_ADR_SIZE-1:0] adr_i;
reg     [`FIFO_RX_MEM_ADR_SIZE-1:0] adr_o;
wire                                ram_we;
wire    [31:0]                      ram_din;
reg     [7:0]                       we;
reg     [31:0]                      tmp;
reg                                 ft;

//Submodules

//Asynchronous Logic

//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------

assign full =  (adr_i[`FIFO_RX_MEM_ADR_SIZE-2:0] == adr_o[`FIFO_RX_MEM_ADR_SIZE-2:0] ) & (adr_i[`FIFO_RX_MEM_ADR_SIZE-1] ^ adr_o[`FIFO_RX_MEM_ADR_SIZE-1]) ;
assign empty = (adr_i == adr_o) ;

assign mem_empt = ( adr_i-adr_o);
assign q = ram[adr_o[`FIFO_RX_MEM_ADR_SIZE-2:0]];

//Synchronous Logic
always @ (posedge wclk or posedge rst) begin
  if (rst)
    we <= 8'h1;
  else begin
    if (wr)
      we <= {we[6:0],we[7]};
  end
end

always @ (posedge wclk or posedge rst) begin
  if (rst) begin
    tmp <= {4*(7){1'b0}};
    ft<=0;
  end
  else begin
    `ifdef BIG_ENDIAN

    if (wr & we[7]) begin
      tmp[3:0] <= d;
      ft<=1;
    end
    if (wr & we[6])
      tmp[7:4] <= d;
    if (wr & we[5])
      tmp[11:8] <= d;
    if (wr & we[4])
      tmp[15:12] <= d;
    if (wr & we[3])
      tmp[19:16] <= d;
    if (wr & we[2])
      tmp[23:20] <= d;
    if (wr & we[1])
      tmp[27:24] <= d;
    if (wr & we[0])
      tmp[31:24] <= d;
    `endif
    `ifdef LITTLE_ENDIAN
    if (wr & we[0])
     tmp[3:0] <= d;
    if (wr & we[1])
      tmp[7:4] <= d;
    if (wr & we[2])
      tmp[11:8] <= d;
    if (wr & we[3])
     tmp[15:12] <= d;
    if (wr & we[4])
     tmp[19:16] <= d;
    if (wr & we[5])
     tmp[23:20] <= d;
    if (wr & we[6])
     tmp[27:24] <= d;
    if (wr & we[7]) begin
     tmp[31:28] <= d;
         ft<=1;
     end
   `endif
  end
end

//Asynchonrous Logic
assign ram_we = wr & we[0] &ft;
assign ram_din = tmp;

//Synchrnous Logic
always @ (posedge wclk) begin
  if (ram_we) begin
    ram[adr_i[`FIFO_RX_MEM_ADR_SIZE-2:0]] <= ram_din;
  end
end

always @ (posedge wclk or posedge rst) begin
  if (rst) begin
    adr_i <= `FIFO_RX_MEM_ADR_SIZE'h0;
  end
  else begin
    if (ram_we) begin
      if (adr_i == `FIFO_RX_MEM_DEPTH-1) begin
        adr_i[`FIFO_RX_MEM_ADR_SIZE-2:0] <=0;
        adr_i[`FIFO_RX_MEM_ADR_SIZE-1]<=~adr_i[`FIFO_RX_MEM_ADR_SIZE-1];
      end
    end
    else begin
      adr_i <= adr_i + `FIFO_RX_MEM_ADR_SIZE'h1;
    end
  end
end

always @ (posedge rclk or posedge rst) begin
  if (rst) begin
    adr_o <= `FIFO_RX_MEM_ADR_SIZE'h0;
  end
  else begin
    if (!empty & rd) begin
      if (adr_o == `FIFO_RX_MEM_DEPTH-1) begin
         adr_o[`FIFO_RX_MEM_ADR_SIZE-2:0] <=0;
         adr_o[`FIFO_RX_MEM_ADR_SIZE-1] <=~adr_o[`FIFO_RX_MEM_ADR_SIZE-1];
      end
    end
    else begin
        adr_o <= adr_o + `FIFO_RX_MEM_ADR_SIZE'h1;
    end
  end
end

endmodule
