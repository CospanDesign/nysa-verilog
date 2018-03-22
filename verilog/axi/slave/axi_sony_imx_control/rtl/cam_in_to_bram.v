
`timescale 1ns / 1ps

/* STYLE_NOTES begin
*
* */
module cam_in_to_bram #(
parameter ADDR_WIDTH = 9,
parameter DATA_WIDTH = 16
)
(
  input                           camera_clk,
  input                           rst,
  input                           i_xhs,
  input                           i_xvs,
  input       [7:0]               i_lvds,
  (* KEEP *) output reg  [7:0]    o_mode,

  //Output Signal
  (* KEEP *) output reg           o_report_align,
  input                           vdma_clk,
  (* KEEP *) output reg           o_data_valid,
  (* KEEP *) output reg  [ADDR_WIDTH - 1:0]  o_data_count,
  input       [ADDR_WIDTH - 1:0]  i_rbuf_addrb,
  output      [DATA_WIDTH - 1:0]  o_rbuf_doutb,
  output                          o_frame_start
);

//Local Parameters
localparam ST_IDLE                = 4'h0;
localparam ST_INVALID_OR_END_SYNC = 4'h1;
localparam ST_FIND_SYNC_CODE      = 4'h2;
localparam ST_DATA8               = 4'h3;
localparam ST_DATA8_TO_RBUF       = 4'h4;
localparam ST_DATA10              = 4'h5;
localparam ST_DATA10_TO_RBUF      = 4'h6;
localparam ST_DATA12              = 4'h7;
localparam ST_DATA12_TO_RBUF      = 4'h8;
localparam ST_NEXT_ROW            = 4'h9;

localparam NO_SYNC                = 8'h00;
localparam INVALID_OR_END_SYNC    = 8'h01;
localparam SYNC8_SHIFT0           = 8'h80;
localparam SYNC8_SHIFT1           = 8'h81;
localparam SYNC8_SHIFT2           = 8'h82;
localparam SYNC8_SHIFT3           = 8'h83;
localparam SYNC8_SHIFT4           = 8'h84;
localparam SYNC8_SHIFT5           = 8'h85;
localparam SYNC8_SHIFT6           = 8'h86;
localparam SYNC8_SHIFT7           = 8'h87;
localparam SYNC10_SHIFT0          = 8'hA0;
localparam SYNC10_SHIFT1          = 8'hA1;
localparam SYNC10_SHIFT2          = 8'hA2;
localparam SYNC10_SHIFT3          = 8'hA3;
localparam SYNC10_SHIFT4          = 8'hA4;
localparam SYNC10_SHIFT5          = 8'hA5;
localparam SYNC10_SHIFT6          = 8'hA6;
localparam SYNC10_SHIFT7          = 8'hA7;
localparam SYNC12_SHIFT0          = 8'hc0;
localparam SYNC12_SHIFT1          = 8'hc1;
localparam SYNC12_SHIFT2          = 8'hc2;
localparam SYNC12_SHIFT3          = 8'hc3;
localparam SYNC12_SHIFT4          = 8'hc4;
localparam SYNC12_SHIFT5          = 8'hc5;
localparam SYNC12_SHIFT6          = 8'hc6;
localparam SYNC12_SHIFT7          = 8'hc7;

localparam SAV8_VALID    = { 8'hFF,   8'h00,   8'h00,   8'h80};
localparam EAV8_VALID    = { 8'hFF,   8'h00,   8'h00,   8'h9D};
localparam SAV8_INVALID  = { 8'hFF,   8'h00,   8'h00,   8'hAB};
localparam EAV8_INVALID  = { 8'hFF,   8'h00,   8'h00,   8'hB6};

localparam SAV10_VALID   = {10'h3FF, 10'h000, 10'h000, 10'h200};
localparam EAV10_VALID   = {10'h3FF, 10'h000, 10'h000, 10'h274};
localparam SAV10_INVALID = {10'h3FF, 10'h000, 10'h000, 10'h2AC};
localparam EAV10_INVALID = {10'h3FF, 10'h000, 10'h000, 10'h2D8};

localparam SAV12_VALID   = {12'hFFF, 12'h000, 12'h000, 12'h800};
localparam EAV12_VALID   = {12'hFFF, 12'h000, 12'h000, 12'h9D0};
localparam SAV12_INVALID = {12'hFFF, 12'h000, 12'h000, 12'hAB0};
localparam EAV12_INVALID = {12'hFFF, 12'h000, 12'h000, 12'hB60};

reg [55:0]                r_lvds_sr;
reg  [2:0]                r_xhs_sr;
reg  [2:0]                r_xvs_sr;
reg                       r_report_align;
reg  [7:0]                r_mode;
reg  [ADDR_WIDTH - 1:0]   r_count;
reg  [ADDR_WIDTH - 1:0]   r_temp_addra;
reg  [ADDR_WIDTH - 1:0]   r_wbuf_addra;
reg [47:0]                r_temp_dina;
reg [47:0]                r_temp_data;
(* KEEP *) reg [(DATA_WIDTH - 1):0] r_wbuf_data;
reg                       r_wbuf_wea;
reg                       r_rbuf_bank;
reg  [ADDR_WIDTH - 1:0]   r_data_count;
reg                       r_data_valid;
(* KEEP *) reg  [3:0]     r_state;
wire [9:0]                w_data;  //Only for simulation visualization top ten bits
wire [DATA_WIDTH:0]       w_rbuf_doutb;
reg                       r_frame_start;



assign w_data         = r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 10)];
assign o_rbuf_doutb   = w_rbuf_doutb[DATA_WIDTH - 1:0];
assign o_frame_start  = w_rbuf_doutb[DATA_WIDTH];





always @(posedge camera_clk)
  //De-assert Strobes
  if (rst) begin
    r_lvds_sr     <= 0;
    r_xhs_sr      <= 0;
    r_xvs_sr      <= 0;
    r_report_align<= 0;
    o_report_align<= 0;
    r_mode        <= NO_SYNC;
    o_mode        <= NO_SYNC;
    o_data_valid  <= 0;
    o_data_count  <= 0;
    r_data_valid  <= 0;
    r_data_count  <= 0;
    r_count       <= 0;
    r_temp_addra  <= 0;
    r_wbuf_addra  <= 0;
    r_temp_dina   <= 0;
    r_temp_data   <= 0;
    r_wbuf_data   <= 0;
    r_wbuf_wea    <= 0;
    r_state       <= 0;
    r_rbuf_bank   <= 0;
    r_frame_start <= 0;

  end
  else begin
    r_lvds_sr <= {r_lvds_sr[47:0],i_lvds};
    r_xhs_sr  <= {r_xhs_sr[1:0],i_xhs};
    r_xvs_sr  <= {r_xvs_sr[1:0],i_xvs};
    if (r_wbuf_wea) begin
      r_frame_start <=  0;
    end

    if (r_xvs_sr == 3'b100) begin
      //At the negative edge of vsync reset the report align register
      o_report_align  <=  r_report_align;
      r_report_align  <= 0;
    end
    if (r_xvs_sr == 3'b011) begin
      r_frame_start   <= 1;
    end

    case (r_state)
      ST_IDLE: begin // 00
        r_mode        <= NO_SYNC;
        r_temp_addra  <= 0;
        r_wbuf_addra  <= 0;
        r_wbuf_data   <= 0;
        r_wbuf_wea    <= 0;
        r_data_valid  <= 0;
        r_data_count  <= 0;
        r_count       <= 0;
        if (r_xhs_sr[2:1] == 2'b01) begin
          r_state       <= ST_FIND_SYNC_CODE;
        end
      end
      ST_FIND_SYNC_CODE: begin // 01
        //find falling edge xhs, if so then quit
        r_count <= 0;
        if (r_xhs_sr[2:1] == 2'b10) begin
          o_mode  <= NO_SYNC;
          r_state <= ST_IDLE;
        end
        if (r_lvds_sr[31:0]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT0;   r_state = ST_DATA8; end
        if (r_lvds_sr[32:1]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT1;   r_state = ST_DATA8; end
        if (r_lvds_sr[33:2]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT2;   r_state = ST_DATA8; end
        if (r_lvds_sr[34:3]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT3;   r_state = ST_DATA8; end
        if (r_lvds_sr[35:4]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT4;   r_state = ST_DATA8; end
        if (r_lvds_sr[36:5]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT5;   r_state = ST_DATA8; end
        if (r_lvds_sr[37:6]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT6;   r_state = ST_DATA8; end
        if (r_lvds_sr[38:7]  == SAV8_VALID)  begin r_mode <= SYNC8_SHIFT7;   r_state = ST_DATA8; end

        if (r_lvds_sr[39:0]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT0;  r_state = ST_DATA10; end
        if (r_lvds_sr[40:1]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT1;  r_state = ST_DATA10; end
        if (r_lvds_sr[41:2]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT2;  r_state = ST_DATA10; end
        if (r_lvds_sr[42:3]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT3;  r_state = ST_DATA10; end
        if (r_lvds_sr[43:4]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT4;  r_state = ST_DATA10; end
        if (r_lvds_sr[44:5]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT5;  r_state = ST_DATA10; end
        if (r_lvds_sr[45:6]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT6;  r_state = ST_DATA10; end
        if (r_lvds_sr[46:7]  == SAV10_VALID) begin r_mode <= SYNC10_SHIFT7;  r_state = ST_DATA10; end

        if (r_lvds_sr[47:0]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT0;  r_state = ST_DATA12; end
        if (r_lvds_sr[48:1]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT1;  r_state = ST_DATA12; end
        if (r_lvds_sr[49:2]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT2;  r_state = ST_DATA12; end
        if (r_lvds_sr[50:3]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT3;  r_state = ST_DATA12; end
        if (r_lvds_sr[51:4]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT4;  r_state = ST_DATA12; end
        if (r_lvds_sr[52:5]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT5;  r_state = ST_DATA12; end
        if (r_lvds_sr[53:6]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT6;  r_state = ST_DATA12; end
        if (r_lvds_sr[54:7]  == SAV12_VALID) begin r_mode <= SYNC12_SHIFT7;  r_state = ST_DATA12; end

        if (r_lvds_sr[31:0]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[32:1]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[33:2]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[34:3]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[35:4]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[36:5]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[37:6]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[38:7]  == SAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[39:0]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[40:1]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[41:2]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[42:3]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[43:4]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[44:5]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[45:6]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[46:7]  == SAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[47:0]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[48:1]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[49:2]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[50:3]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[51:4]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[52:5]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[53:6]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[54:7]  == SAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[31:0]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[32:1]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[33:2]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[34:3]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[35:4]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[36:5]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[37:6]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[38:7]  == EAV8_VALID)  begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[39:0]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[40:1]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[41:2]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[42:3]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[43:4]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[44:5]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[45:6]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[46:7]  == EAV10_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[47:0]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[48:1]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[49:2]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[50:3]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[51:4]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[52:5]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[53:6]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[54:7]  == EAV12_VALID) begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[31:0]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[32:1]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[33:2]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[34:3]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[35:4]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[36:5]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[37:6]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[38:7]  == EAV8_INVALID)  begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[39:0]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[40:1]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[41:2]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[42:3]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[43:4]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[44:5]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[45:6]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[46:7]  == EAV10_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end

        if (r_lvds_sr[47:0]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[48:1]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[49:2]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[50:3]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[51:4]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[52:5]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[53:6]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
        if (r_lvds_sr[54:7]  == EAV12_INVALID) begin r_state = ST_INVALID_OR_END_SYNC; end
      end
      ST_INVALID_OR_END_SYNC: begin // 02
        o_mode       <= INVALID_OR_END_SYNC;
        r_data_valid <= 0;
        if (o_data_count == 0) begin
          o_data_valid <= 0;
          r_state      <= ST_IDLE;
        end else begin
          if (r_count[ADDR_WIDTH - 1:0] == o_data_count) begin
            r_count      <= 0;
            r_state      <= ST_NEXT_ROW;
          end else begin
            r_count <= r_count + 1;
          end
        end
      end

      ST_DATA8: begin // 03
        o_mode  <= r_mode;
        if (r_count == 3) begin
          r_count <= 0;
          r_temp_dina[47:32] <= 0;
          if (r_mode == SYNC8_SHIFT0)   begin r_temp_dina[31:0] <= r_lvds_sr[31:0]; end
          if (r_mode == SYNC8_SHIFT1)   begin r_temp_dina[31:0] <= r_lvds_sr[32:1]; end
          if (r_mode == SYNC8_SHIFT2)   begin r_temp_dina[31:0] <= r_lvds_sr[33:2]; end
          if (r_mode == SYNC8_SHIFT3)   begin r_temp_dina[31:0] <= r_lvds_sr[34:3]; end
          if (r_mode == SYNC8_SHIFT4)   begin r_temp_dina[31:0] <= r_lvds_sr[35:4]; end
          if (r_mode == SYNC8_SHIFT5)   begin r_temp_dina[31:0] <= r_lvds_sr[36:5]; end
          if (r_mode == SYNC8_SHIFT6)   begin r_temp_dina[31:0] <= r_lvds_sr[37:6]; end
          if (r_mode == SYNC8_SHIFT7)   begin r_temp_dina[31:0] <= r_lvds_sr[38:7]; end
          r_state <= ST_DATA8_TO_RBUF;
        end else begin
          r_count <= r_count + 1;
        end
      end
      ST_DATA8_TO_RBUF: begin // 04
        r_temp_addra      <= r_temp_addra + 1;
        r_wbuf_addra      <= r_temp_addra;
        r_wbuf_wea        <= 1;
        r_wbuf_data[(DATA_WIDTH - (1 + 8)):0] <= 0;
        if (r_count == 0) begin
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 8)] <= r_temp_dina[31:24];
          r_temp_data <= {r_temp_data[39:0],r_temp_dina[31:24]};
        end
        if (r_count == 1) begin
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 8)] <= r_temp_dina[23:16];
          r_temp_data <= {r_temp_data[39:0],r_temp_dina[23:16]};
        end
        if (r_count == 2) begin
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 8)] <= r_temp_dina[15:8];
          r_temp_data <= {r_temp_data[39:0],r_temp_dina[15:8]};
        end
        if (r_count == 3) begin
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 8)] <= r_temp_dina[7:0];
          r_temp_data <= {r_temp_data[39:0],r_temp_dina[7:0]};
        end

        if (r_count == 3) begin
          r_count <= 0;
          r_temp_dina[47:32] <= 0;
          if (r_mode == SYNC8_SHIFT0)   begin r_temp_dina[31:0] <= r_lvds_sr[31:0]; end
          if (r_mode == SYNC8_SHIFT1)   begin r_temp_dina[31:0] <= r_lvds_sr[32:1]; end
          if (r_mode == SYNC8_SHIFT2)   begin r_temp_dina[31:0] <= r_lvds_sr[33:2]; end
          if (r_mode == SYNC8_SHIFT3)   begin r_temp_dina[31:0] <= r_lvds_sr[34:3]; end
          if (r_mode == SYNC8_SHIFT4)   begin r_temp_dina[31:0] <= r_lvds_sr[35:4]; end
          if (r_mode == SYNC8_SHIFT5)   begin r_temp_dina[31:0] <= r_lvds_sr[36:5]; end
          if (r_mode == SYNC8_SHIFT6)   begin r_temp_dina[31:0] <= r_lvds_sr[37:6]; end
          if (r_mode == SYNC8_SHIFT7)   begin r_temp_dina[31:0] <= r_lvds_sr[38:7]; end
        end else begin
          r_count <= r_count + 1;
        end

        if (r_temp_data[31:0] == EAV8_VALID) begin
          r_data_count <= r_wbuf_addra - 4;
          r_data_valid <= 1;
          r_report_align  <=  1;
          o_data_valid <= 0;
          r_state <= ST_NEXT_ROW;
        end else
        if (r_xhs_sr[2:1] == 2'b10) begin
          o_data_valid  <= 0;
          o_data_count  <= 0;
          r_state <= ST_IDLE;
        end else
        if (r_wbuf_addra == 510) begin
          o_data_valid  <= 0;
          o_data_count  <= 0;
          r_state       <= ST_NEXT_ROW;
        end
      end

      ST_DATA10: begin // 05
        o_mode  <= r_mode;
        if (r_count == 4) begin
          r_count <= 0;
          r_temp_dina[47:40] <= 0;
          if (r_mode == SYNC10_SHIFT0)  begin r_temp_dina[39:0] <= r_lvds_sr[39:0]; end
          if (r_mode == SYNC10_SHIFT1)  begin r_temp_dina[39:0] <= r_lvds_sr[40:1]; end
          if (r_mode == SYNC10_SHIFT2)  begin r_temp_dina[39:0] <= r_lvds_sr[41:2]; end
          if (r_mode == SYNC10_SHIFT3)  begin r_temp_dina[39:0] <= r_lvds_sr[42:3]; end
          if (r_mode == SYNC10_SHIFT4)  begin r_temp_dina[39:0] <= r_lvds_sr[43:4]; end
          if (r_mode == SYNC10_SHIFT5)  begin r_temp_dina[39:0] <= r_lvds_sr[44:5]; end
          if (r_mode == SYNC10_SHIFT6)  begin r_temp_dina[39:0] <= r_lvds_sr[45:6]; end
          if (r_mode == SYNC10_SHIFT7)  begin r_temp_dina[39:0] <= r_lvds_sr[46:7]; end
          r_state <= ST_DATA10_TO_RBUF;
        end else begin
          r_count <= r_count + 1;
        end
      end
      ST_DATA10_TO_RBUF: begin // 06
        r_wbuf_wea          <= 1;
        r_wbuf_data[(DATA_WIDTH - (1 + 10)):0] <= 0;
        if (r_count == 0) begin
          r_temp_addra      <= r_temp_addra + 1;
          r_wbuf_addra      <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 10)] <= r_temp_dina[39:30];
          r_temp_data       <= {r_temp_data[37:0],r_temp_dina[39:30]};
        end
        if (r_count == 1) begin
          r_temp_addra      <= r_temp_addra + 1;
          r_wbuf_addra      <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 10)] <= r_temp_dina[29:20];
          r_temp_data       <= {r_temp_data[37:0],r_temp_dina[29:20]};
        end
        if (r_count == 2) begin
          r_temp_addra      <= r_temp_addra + 1;
          r_wbuf_addra      <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 10)] <= r_temp_dina[19:10];
          r_temp_data       <= {r_temp_data[37:0],r_temp_dina[19:10]};
        end
        if (r_count == 3) begin
          r_temp_addra      <= r_temp_addra + 1;
          r_wbuf_addra      <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 10)] <= r_temp_dina[9:0];
          r_temp_data       <= {r_temp_data[37:0],r_temp_dina[9:0]};
        end

        if (r_count == 4) begin
          r_count <= 0;
          r_temp_dina[47:40] <= 0;
          if (r_mode == SYNC10_SHIFT0)  begin r_temp_dina[39:0] <= r_lvds_sr[39:0]; end
          if (r_mode == SYNC10_SHIFT1)  begin r_temp_dina[39:0] <= r_lvds_sr[40:1]; end
          if (r_mode == SYNC10_SHIFT2)  begin r_temp_dina[39:0] <= r_lvds_sr[41:2]; end
          if (r_mode == SYNC10_SHIFT3)  begin r_temp_dina[39:0] <= r_lvds_sr[42:3]; end
          if (r_mode == SYNC10_SHIFT4)  begin r_temp_dina[39:0] <= r_lvds_sr[43:4]; end
          if (r_mode == SYNC10_SHIFT5)  begin r_temp_dina[39:0] <= r_lvds_sr[44:5]; end
          if (r_mode == SYNC10_SHIFT6)  begin r_temp_dina[39:0] <= r_lvds_sr[45:6]; end
          if (r_mode == SYNC10_SHIFT7)  begin r_temp_dina[39:0] <= r_lvds_sr[46:7]; end
          r_state <= ST_DATA10_TO_RBUF;
        end else begin
          r_count <= r_count + 1;
        end
        if (r_temp_data[39:0] == EAV10_VALID) begin
          r_data_count  <= r_wbuf_addra - 4;
          r_data_valid  <= 1;
          r_report_align  <= 1;
          o_data_valid  <= 0;
          r_state       <= ST_NEXT_ROW;
        end else
        if (r_xhs_sr[2:1] == 2'b10) begin
          o_data_valid  <= 0;
          o_data_count  <= 0;
          r_state       <= ST_IDLE;
        end else
        if (r_wbuf_addra == 510) begin
          o_data_valid  <= 0;
          o_data_count  <= 0;
          r_state       <= ST_NEXT_ROW;
        end
      end

      ST_DATA12: begin // 07
        o_mode  <= r_mode;
        if (r_count == 5) begin
          r_count <= 0;
          if (r_mode == SYNC12_SHIFT0)  begin r_temp_dina <= r_lvds_sr[47:0]; end
          if (r_mode == SYNC12_SHIFT1)  begin r_temp_dina <= r_lvds_sr[48:1]; end
          if (r_mode == SYNC12_SHIFT2)  begin r_temp_dina <= r_lvds_sr[49:2]; end
          if (r_mode == SYNC12_SHIFT3)  begin r_temp_dina <= r_lvds_sr[50:3]; end
          if (r_mode == SYNC12_SHIFT4)  begin r_temp_dina <= r_lvds_sr[51:4]; end
          if (r_mode == SYNC12_SHIFT5)  begin r_temp_dina <= r_lvds_sr[52:5]; end
          if (r_mode == SYNC12_SHIFT6)  begin r_temp_dina <= r_lvds_sr[53:6]; end
          if (r_mode == SYNC12_SHIFT7)  begin r_temp_dina <= r_lvds_sr[54:7]; end
          r_state <= ST_DATA12_TO_RBUF;
        end else begin
          r_count <= r_count + 1;
        end
      end

      ST_DATA12_TO_RBUF: begin // 08
        r_wbuf_wea        <= 1;
        if (DATA_WIDTH > 12) begin
          r_wbuf_data[(DATA_WIDTH - (1 + 12)):0] <= 0;
        end
        if (r_count == 0) begin
          r_temp_addra <= r_temp_addra + 1;
          r_wbuf_addra <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 12)]  <= r_temp_dina[47:36];
          r_temp_data <= {r_temp_data[35:0],r_temp_dina[47:36]};
        end
        if (r_count == 1) begin
          r_temp_addra <= r_temp_addra + 1;
          r_wbuf_addra <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 12)]  <= r_temp_dina[35:24];
          r_temp_data <= {r_temp_data[35:0],r_temp_dina[35:24]};
        end
        if (r_count == 2) begin
          r_temp_addra <= r_temp_addra + 1;
          r_wbuf_addra <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 12)]  <= r_temp_dina[23:12];
          r_temp_data <= {r_temp_data[35:0],r_temp_dina[23:12]};
        end
        if (r_count == 3) begin
          r_temp_addra <= r_temp_addra + 1;
          r_wbuf_addra <= r_temp_addra;
          r_wbuf_data[(DATA_WIDTH - 1):(DATA_WIDTH - 12)]  <= r_temp_dina[11:0];
          r_temp_data <= {r_temp_data[35:0],r_temp_dina[11:0]};
        end

        if (r_count == 5) begin
          r_count <= 0;
          if (r_mode == SYNC12_SHIFT0)  begin r_temp_dina <= r_lvds_sr[47:0]; end
          if (r_mode == SYNC12_SHIFT1)  begin r_temp_dina <= r_lvds_sr[48:1]; end
          if (r_mode == SYNC12_SHIFT2)  begin r_temp_dina <= r_lvds_sr[49:2]; end
          if (r_mode == SYNC12_SHIFT3)  begin r_temp_dina <= r_lvds_sr[50:3]; end
          if (r_mode == SYNC12_SHIFT4)  begin r_temp_dina <= r_lvds_sr[51:4]; end
          if (r_mode == SYNC12_SHIFT5)  begin r_temp_dina <= r_lvds_sr[52:5]; end
          if (r_mode == SYNC12_SHIFT6)  begin r_temp_dina <= r_lvds_sr[53:6]; end
          if (r_mode == SYNC12_SHIFT7)  begin r_temp_dina <= r_lvds_sr[54:7]; end
          r_state <= ST_DATA12_TO_RBUF;
        end else begin
          r_count <= r_count + 1;
        end
        if (r_temp_data == EAV12_VALID) begin
          r_data_count <= r_wbuf_addra - 4;
          r_data_valid <= 1;
          r_report_align  <= 1;
          o_data_valid <= 0;
          r_state <= ST_NEXT_ROW;
        end else
        if (r_xhs_sr[2:1] == 2'b10) begin //Rising Edge of HSYNC
          o_data_valid  <= 0;
          o_data_count  <= 0;
          r_state       <= ST_IDLE;
        end else
        if (r_wbuf_addra == 510) begin
          o_data_valid  <= 0;
          o_data_count  <= 0;
          r_state       <= ST_NEXT_ROW;
        end
      end
      ST_NEXT_ROW: begin // 09
        if (r_xhs_sr[2:1] == 2'b10) begin
          o_data_count  <= r_data_count;
          o_data_valid  <= r_data_valid;
          r_rbuf_bank   <= ~r_rbuf_bank;
          r_state       <= ST_IDLE;
        end
      end
      default: begin
        r_state <= ST_IDLE;
      end
    endcase
  end

  blk_mem #
  (
    .DATA_WIDTH                    (DATA_WIDTH + 1              ),
    .ADDRESS_WIDTH                 (ADDR_WIDTH + 1              )
  )
  u_rbuf_mem
  (
    .clka                        (camera_clk                  ),
    .addra                       ({r_rbuf_bank,r_wbuf_addra  }),
    .dina                        ({r_frame_start, r_wbuf_data}),
    .wea                         (r_wbuf_wea                  ),

    .clkb                        (vdma_clk                    ),
    .addrb                       ({~r_rbuf_bank,i_rbuf_addrb }),
    .doutb                       (w_rbuf_doutb                )
  );

endmodule

