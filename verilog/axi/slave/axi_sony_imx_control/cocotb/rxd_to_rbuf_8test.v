
`timescale 1ns / 1ps

/* STYLE_NOTES begin
*
* */
module rxd_to_rbuf_8test
(
input             camera_clk,
output reg        o_xvs,
output reg        o_xhs,
output reg  [7:0] o_lvds8_0,
output reg  [7:0] o_lvds8_1,
output reg  [7:0] o_lvds8_2,
output reg  [7:0] o_lvds8_3,
output reg  [7:0] o_lvds8_4,
output reg  [7:0] o_lvds8_5,
output reg  [7:0] o_lvds8_6,
output reg  [7:0] o_lvds8_7,
input             rst
);

localparam ST_IDLE       = 4'h0;
localparam ST_001        = 4'h1;
localparam ST_SAV_SYNC0  = 4'h2;
localparam ST_SAV_SYNC1  = 4'h3;
localparam ST_SAV_SYNC2  = 4'h4;
localparam ST_SAV_SYNC3  = 4'h5;
localparam ST_DATA       = 4'h6;
localparam ST_EAV_SYNC0  = 4'h7;
localparam ST_EAV_SYNC1  = 4'h8;
localparam ST_EAV_SYNC2  = 4'h9;
localparam ST_EAV_SYNC3  = 4'hA;

localparam SYNC0        = 8'hFF;
localparam SYNC1        = 8'h00;
localparam SYNC2        = 8'h00;

localparam SAV8_VALID   = 8'h80;
localparam EAV8_VALID   = 8'h9D;
localparam SAV8_INVALID = 8'hAB;
localparam EAV8_INVALID = 8'hB6;

reg  [7:0] r_dout0;
reg  [7:0] r_dout1;
reg [15:0] r_row_count;
reg [15:0] r_count;
reg  [3:0] r_state;

always @(posedge camera_clk)
  if (rst) begin
    o_xvs        <= 0;
    o_xhs        <= 0;
    r_row_count  <= 0;
    r_dout0      <= 12'h001;
    r_dout1      <= 12'h001;
    o_lvds8_0    <= 0;
    o_lvds8_1    <= 0;
    o_lvds8_2    <= 0;
    o_lvds8_3    <= 0;
    o_lvds8_4    <= 0;
    o_lvds8_5    <= 0;
    o_lvds8_6    <= 0;
    o_lvds8_7    <= 0;
    r_state      <= ST_IDLE;

  end else begin

    r_dout1 <= r_dout0;

    o_lvds8_0   <=  r_dout0;
    o_lvds8_1   <= {r_dout1[  0],r_dout0[7:1]};
    o_lvds8_2   <= {r_dout1[1:0],r_dout0[7:2]};
    o_lvds8_3   <= {r_dout1[2:0],r_dout0[7:3]};
    o_lvds8_4   <= {r_dout1[3:0],r_dout0[7:4]};
    o_lvds8_5   <= {r_dout1[4:0],r_dout0[7:5]};
    o_lvds8_6   <= {r_dout1[5:0],r_dout0[7:6]};
    o_lvds8_7   <= {r_dout1[6:0],r_dout0[7]};

    r_count <= r_count + 1;

    case (r_state)
      ST_IDLE: begin //00
        r_row_count  <= 0;
        r_count      <= 0;
        r_dout0      <= 12'h001;
        r_state      <= ST_001;
      end
      ST_001: begin //01
        r_dout0 <= 12'h001;
        if (r_row_count == 4) begin
          if (r_count == 7) begin
            o_xvs   <= 0;
          end
          if (r_count == 15) begin
            o_xvs   <= 1;
          end
        end
        if (r_count == 7) begin
          o_xhs   <= 0;
        end
        if (r_count == 15) begin
          o_xhs   <= 1;
        end
        if (r_count == 22) begin
          r_state <= ST_SAV_SYNC0;
        end
      end
      ST_SAV_SYNC0: begin //02
        r_dout0 <= SYNC0; //8'hFF
        r_state <= ST_SAV_SYNC1;
      end
      ST_SAV_SYNC1: begin //03
        r_dout0 <= SYNC1; //8'h00
        r_state <= ST_SAV_SYNC2;
      end
      ST_SAV_SYNC2: begin //04
        r_dout0 <= SYNC2; //8'h00
        if (r_row_count == 12) begin //introduce a format error
          r_state <= ST_DATA;
        end else begin
          r_state <= ST_SAV_SYNC3;
        end
      end
      ST_SAV_SYNC3: begin //05
        if (r_row_count < 8) begin
          r_dout0 <= SAV8_INVALID; //8'hAB
        end else begin
          r_dout0 <= SAV8_VALID;   //8'h80
        end
        r_count <= 0;
        r_state <= ST_DATA;
      end
      ST_DATA: begin //06
        r_dout0 <= r_count[7:0];
        if (r_count == 255) begin
          r_state <= ST_EAV_SYNC0;
        end
      end
      ST_EAV_SYNC0: begin //07
        r_dout0 <= SYNC0; //8'hFF;
        r_state <= ST_EAV_SYNC1;
      end
      ST_EAV_SYNC1: begin //08
        r_dout0 <= SYNC1; //8'h00;
        if (r_row_count == 6) begin //introduce a format error
          r_state <= ST_EAV_SYNC3;
        end else begin
          r_state <= ST_EAV_SYNC2;
        end
      end
      ST_EAV_SYNC2: begin //09
        r_dout0 <= SYNC2; //8'h000;
        r_state <= ST_EAV_SYNC3;
      end
      ST_EAV_SYNC3: begin //0A
        if (r_row_count < 8) begin
          r_dout0 <= EAV8_INVALID; //8'hB6;
        end else begin
          r_dout0 <= EAV8_VALID;   //8'h9D;   
        end
        r_count <= 0;
        if (r_row_count == 19) begin
          r_row_count <= 0;
          r_state     <= ST_IDLE;
        end else begin
          r_row_count <= r_row_count + 1;
          r_state <= ST_001;
        end
      end

      default: begin 
        r_state <= ST_IDLE;
      end
    endcase
  end

  endmodule



