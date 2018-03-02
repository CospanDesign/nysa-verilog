
`timescale 1ns / 1ps

/* STYLE_NOTES begin
 *
 * */
module rxd_to_rbuf_10test
(
    input             camera_clk,
    output reg        o_xvs,
    output reg        o_xhs,

    output reg  [7:0] o_lvds10_00,
    output reg  [7:0] o_lvds10_01,
    output reg  [7:0] o_lvds10_02,
    output reg  [7:0] o_lvds10_03,
    output reg  [7:0] o_lvds10_04,
    output reg  [7:0] o_lvds10_05,
    output reg  [7:0] o_lvds10_06,
    output reg  [7:0] o_lvds10_07,
    input             rst
);

localparam ST_IDLE       = 4'h0;
localparam ST_001        = 4'h1;
localparam ST_SAV_SYNC0  = 4'h3;
localparam ST_SAV_SYNC1  = 4'h4;
localparam ST_SAV_SYNC2  = 4'h5;
localparam ST_SAV_SYNC3  = 4'h6;
localparam ST_DATA       = 4'h7;
localparam ST_EAV_SYNC0  = 4'h8;
localparam ST_EAV_SYNC1  = 4'h9;
localparam ST_EAV_SYNC2  = 4'hA;
localparam ST_EAV_SYNC3  = 4'hB;

localparam SYNC0 = 10'h3FF;
localparam SYNC1 = 10'h000;
localparam SYNC2 = 10'h000;

localparam SAV10_VALID   = 10'h200;
localparam SAV10_INVALID = 10'h2AC;
localparam EAV10_VALID   = 10'h274;
localparam EAV10_INVALID = 10'h2D8;

reg  [9:0] r_dout0;
reg  [9:0] r_dout1;
reg  [9:0] r_dout2;
reg  [9:0] r_dout3;
reg  [9:0] r_dout4;
reg [49:0] r_dout;
reg [15:0] r_row_count;
reg [15:0] r_dcount;
reg [15:0] r_count;
reg  [3:0] r_state;

always @(posedge camera_clk)
if (rst) begin
    o_xvs         <= 0;
    o_xhs         <= 0;
    r_row_count   <= 0;
    r_dcount      <= 0;
    r_count       <= 0;
    r_dout        <= 0;
    r_dout0       <= 0;             
    r_dout1       <= 0;
    r_dout2       <= 0;
    r_dout3       <= 0;
    r_dout4       <= 0;
    r_state       <= ST_IDLE;

end else begin



    if (r_dcount == 4) begin
        r_dcount <= 0;
        r_dout <= {r_dout4,r_dout3,r_dout2,r_dout1,r_dout0};
    end else begin
        r_dcount <= r_dcount + 1;
    end

    if (r_dcount == 0) begin
        o_lvds10_00 <= r_dout[39:32];
        o_lvds10_01 <= r_dout[40:33];
        o_lvds10_02 <= r_dout[41:34];
        o_lvds10_03 <= r_dout[42:35];
        o_lvds10_04 <= r_dout[43:36];
        o_lvds10_05 <= r_dout[44:37];
        o_lvds10_06 <= r_dout[45:38];
        o_lvds10_07 <= r_dout[46:39];
    end
    if (r_dcount == 1) begin
        o_lvds10_00 <= r_dout[31:24];
        o_lvds10_01 <= r_dout[32:25];
        o_lvds10_02 <= r_dout[33:26];
        o_lvds10_03 <= r_dout[34:27];
        o_lvds10_04 <= r_dout[35:28];
        o_lvds10_05 <= r_dout[36:29];
        o_lvds10_06 <= r_dout[37:30];
        o_lvds10_07 <= r_dout[38:31];
    end
    if (r_dcount == 2) begin
        o_lvds10_00 <= r_dout[23:16];
        o_lvds10_01 <= r_dout[24:17];
        o_lvds10_02 <= r_dout[25:18];
        o_lvds10_03 <= r_dout[26:19];
        o_lvds10_04 <= r_dout[27:20];
        o_lvds10_05 <= r_dout[28:21];
        o_lvds10_06 <= r_dout[29:22];
        o_lvds10_07 <= r_dout[30:23];
    end
    if (r_dcount == 3) begin
        o_lvds10_00 <= r_dout[15:8];
        o_lvds10_01 <= r_dout[16:9];
        o_lvds10_02 <= r_dout[17:10];
        o_lvds10_03 <= r_dout[18:11];
        o_lvds10_04 <= r_dout[19:12];
        o_lvds10_05 <= r_dout[20:13];
        o_lvds10_06 <= r_dout[21:14];
        o_lvds10_07 <= r_dout[22:15];
    end
    if (r_dcount == 4) begin
        o_lvds10_00 <= r_dout[7:0];
        o_lvds10_01 <= r_dout[8:1];
        o_lvds10_02 <= r_dout[9:2];
        o_lvds10_03 <= r_dout[10:3];
        o_lvds10_04 <= r_dout[11:4];
        o_lvds10_05 <= r_dout[12:5];
        o_lvds10_06 <= r_dout[13:6];
        o_lvds10_07 <= r_dout[14:7];
    end

    if (r_dcount < 4) begin

        r_dout1 <= r_dout0;
        r_dout2 <= r_dout1;
        r_dout3 <= r_dout2;
        r_dout4 <= r_dout3;
        r_count <= r_count + 1;

        case (r_state)
        ST_IDLE: begin
            r_row_count  <= 0;
            r_count      <= 0;
            r_dout0      <= 10'h001;
            r_state      <= ST_001;
        end
        ST_001: begin
            r_dout0 <= 10'h001;
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
        ST_SAV_SYNC0: begin
            r_dout0 <= SYNC0; // 10'h3FF
            r_state <= ST_SAV_SYNC1;
        end
        ST_SAV_SYNC1: begin
            r_dout0 <= SYNC1; // 10'h000
            r_state <= ST_SAV_SYNC2;
        end
        ST_SAV_SYNC2: begin
            r_dout0 <= SYNC2; // 10'h000
            if (r_row_count == 12) begin //introduce a format error
                r_state <= ST_DATA;
            end else begin
                r_state <= ST_SAV_SYNC3;
            end
        end
        ST_SAV_SYNC3: begin
            if (r_row_count < 8) begin
                r_dout0 <= SAV10_INVALID; //10'h28C
            end else begin
                r_dout0 <= SAV10_VALID;   //10'h200
            end
            r_count <= 0;
            r_state <= ST_DATA;
        end
        ST_DATA: begin
            r_dout0[9:0] <= r_count[9:0];
            if (r_count == 255) begin
                r_state <= ST_EAV_SYNC0;
            end
        end
        ST_EAV_SYNC0: begin       
            r_dout0 <= SYNC0; // 10'hFFF;
            r_state <= ST_EAV_SYNC1;
        end
        ST_EAV_SYNC1: begin
            r_dout0 <= SYNC1; // 10'h000;
            if (r_row_count == 6) begin //introduce a format error
                r_state <= ST_EAV_SYNC3;
            end else begin
                r_state <= ST_EAV_SYNC2;
            end
        end
        ST_EAV_SYNC2: begin
            r_dout0 <= SYNC2; // 10'h000;
            r_state <= ST_EAV_SYNC3;
        end
        ST_EAV_SYNC3: begin
            if (r_row_count < 8) begin
                r_dout0 <= EAV10_INVALID; //10'h2D8;
            end else begin
                r_dout0 <= EAV10_VALID;   //10'h274;   
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
end

endmodule




