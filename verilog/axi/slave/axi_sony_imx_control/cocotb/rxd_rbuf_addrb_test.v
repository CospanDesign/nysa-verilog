
`timescale 1ns / 1ps

/* STYLE_NOTES begin
 *
 * */
module rxd_rbuf_addrb_test
(
    input             camera_clk,
    input             i_xhs8,
    input             i_xhs10,
    input             i_xhs12,

    output reg  [8:0] o_rbuf8_addrb,
    output reg  [8:0] o_rbuf10_addrb,
    output reg  [8:0] o_rbuf12_addrb,
    input             rst
);

reg [2:0] r_xhs8_sr;
reg [2:0] r_xhs10_sr;
reg [2:0] r_xhs12_sr;
reg [8:0] r_rbuf8_addrb;
reg [8:0] r_rbuf10_addrb;
reg [8:0] r_rbuf12_addrb;

always @(posedge camera_clk)
if (rst) begin
    o_rbuf8_addrb  <= 0;
    o_rbuf10_addrb <= 0;
    o_rbuf12_addrb <= 0;
    r_xhs8_sr      <= 0;
    r_xhs10_sr     <= 0;
    r_xhs12_sr     <= 0;
    r_rbuf8_addrb  <= 0;
    r_rbuf10_addrb <= 0;
    r_rbuf12_addrb <= 0;

end else begin

    o_rbuf8_addrb  <= r_rbuf8_addrb;
    o_rbuf10_addrb <= r_rbuf10_addrb;
    o_rbuf12_addrb <= r_rbuf12_addrb;

    r_xhs8_sr  <= {r_xhs8_sr[1:0], i_xhs8};
    r_xhs10_sr <= {r_xhs10_sr[1:0],i_xhs10};
    r_xhs12_sr <= {r_xhs12_sr[1:0],i_xhs12};

    if (r_xhs8_sr[1:0] == 2'b10) begin
        r_rbuf8_addrb  <= 0;
    end
    if (r_rbuf8_addrb != 260) begin
        r_rbuf8_addrb <= r_rbuf8_addrb + 1;
    end

    if (r_xhs10_sr[1:0] == 2'b10) begin
        r_rbuf10_addrb  <= 0;
    end
    if (r_rbuf10_addrb != 260) begin
        r_rbuf10_addrb <= r_rbuf10_addrb + 1;
    end

    if (r_xhs12_sr[1:0] == 2'b10) begin
        r_rbuf12_addrb  <= 0;
    end
    if (r_rbuf12_addrb != 260) begin
        r_rbuf12_addrb <= r_rbuf12_addrb + 1;
    end

end

endmodule




