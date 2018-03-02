`timescale 1ns / 1ps

module a_tb_rxd_to_rbuf;

reg         rst;
reg         camera_clk;
reg         vdma_clk;

initial begin
    camera_clk = 1'b1;
    vdma_clk  = 1'b1;
    rst       = 1'b1;
end

always
#20  rst = 1'b0;

always
#2  camera_clk = ~camera_clk;

always
#2  vdma_clk = ~vdma_clk;

wire [23:0] w_pixel;
wire        w_data_valid;
wire        w_hsync;
wire        w_vsync;
wire        w_hblanking;
wire        w_vblanking;

pat_gen_1920x1080x60_gradient    inst_pat_gen_1920x1080x60_gradient 
(
    .clk150                      (camera_clk),
    .o_pixel                     (w_pixel),
    .o_data_valid                (w_data_valid),
    .o_hsync                     (w_hsync),
    .o_vsync                     (w_vsync),
    .o_hblanking                 (w_hblanking),
    .o_vblanking                 (w_vblanking),
    .rst                         (rst)
);


//wire        vdma_clk;
//wire        i_vid_de;
//wire        i_vid_vblank;
//wire        i_vid_hblank;
//wire        i_vid_vsync;
//wire        i_vid_hsync;
//wire [11:0] i_vid_data;
//wire        i_aclk;
//wire        i_aclken;
//wire        i_aresetn;
//
//wire [15:0] o_m_axis_video_tdata;
//wire        o_m_axis_video_tvalid;
//wire        i_m_axis_video_tready;
//wire        o_m_axis_video_tuser;
//wire        o_m_axis_video_tlast;
//
//wire        o_vtd_active_video;
//wire        o_vtd_vblank;
//wire        o_vtd_hblank;
//wire        o_vtd_vsync;
//wire        o_vtd_hsync;
//wire        o_wr_error;
//wire        o_empty;
//wire        i_axis_enable;
//
//module vdma (
//    .vid_in_clk                  (vdma_clk),
//    .vid_de                      (i_vid_de),
//    .vid_vblank                  (i_vid_vblank),
//    .vid_hblank                  (i_vid_hblank),
//    .vid_vsync                   (i_vid_vsync),
//    .vid_hsync                   (i_vid_hsync),
//    .vid_data                    (i_vid_data),
//    .aclk                        (i_aclk),
//    .aclken                      (i_aclken),
//    .aresetn                     (i_aresetn),
//    .m_axis_video_tdata          (o_m_axis_video_tdata),
//    .m_axis_video_tvalid         (o_m_axis_video_tvalid),
//    .m_axis_video_tready         (i_m_axis_video_tready),
//    .m_axis_video_tuser          (o_m_axis_video_tuser),
//    .m_axis_video_tlast          (o_m_axis_video_tlast),
//    .vtd_active_video            (o_vtd_active_video),
//    .vtd_vblank                  (o_vtd_vblank),
//    .vtd_hblank                  (o_vtd_hblank),
//    .vtd_vsync                   (o_vtd_vsync),
//    .vtd_hsync                   (o_vtd_hsync),
//    .wr_error                    (o_wr_error),
//    .empty                       (o_empty),
//    .axis_enable                 (i_axis_enable),
//    .rst                         (rst)
//);



wire        w_xvs8;
wire        w_xhs8;
wire  [7:0] w_lvds8_0;
wire  [7:0] w_lvds8_1;
wire  [7:0] w_lvds8_2;
wire  [7:0] w_lvds8_3;
wire  [7:0] w_lvds8_4;
wire  [7:0] w_lvds8_5;
wire  [7:0] w_lvds8_6;
wire  [7:0] w_lvds8_7;

wire        w_xvs10;
wire        w_xhs10;
wire  [7:0] w_lvds10_00;
wire  [7:0] w_lvds10_01;
wire  [7:0] w_lvds10_02;
wire  [7:0] w_lvds10_03;
wire  [7:0] w_lvds10_04;
wire  [7:0] w_lvds10_05;
wire  [7:0] w_lvds10_06;
wire  [7:0] w_lvds10_07;

wire        w_xvs12;
wire        w_xhs12;
wire  [7:0] w_lvds12_00;
wire  [7:0] w_lvds12_01;
wire  [7:0] w_lvds12_02;
wire  [7:0] w_lvds12_03;
wire  [7:0] w_lvds12_04;
wire  [7:0] w_lvds12_05;
wire  [7:0] w_lvds12_06;
wire  [7:0] w_lvds12_07;
wire  [8:0] w_rbuf8_addrb;
wire  [8:0] w_rbuf10_addrb;
wire  [8:0] w_rbuf12_addrb;

rxd_rbuf_addrb_test              inst_rxd_rbuf_addrb_test 
(
        .camera_clk                  (camera_clk),
    .i_xhs8                      (w_xhs8),
    .i_xhs10                     (w_xhs10),
    .i_xhs12                     (w_xhs12),

    .o_rbuf8_addrb               (w_rbuf8_addrb),
    .o_rbuf10_addrb              (w_rbuf10_addrb),
    .o_rbuf12_addrb              (w_rbuf12_addrb),
    .rst                         (rst)
);

rxd_to_rbuf_8test                inst_rxd_to_rbuf_8test
(
    .camera_clk                  (camera_clk),
    .o_xvs                       (w_xvs8),
    .o_xhs                       (w_xhs8),

    .o_lvds8_0                   (w_lvds8_0),
    .o_lvds8_1                   (w_lvds8_1),
    .o_lvds8_2                   (w_lvds8_2),
    .o_lvds8_3                   (w_lvds8_3),
    .o_lvds8_4                   (w_lvds8_4),
    .o_lvds8_5                   (w_lvds8_5),
    .o_lvds8_6                   (w_lvds8_6),
    .o_lvds8_7                   (w_lvds8_7),

    .rst                         (rst)
);                               

rxd_to_rbuf_10test               inst_rxd_to_rbuf_10test
(                                
    .camera_clk                  (camera_clk),
    .o_xvs                       (w_xvs10),
    .o_xhs                       (w_xhs10),

    .o_lvds10_00                 (w_lvds10_00),
    .o_lvds10_01                 (w_lvds10_01),
    .o_lvds10_02                 (w_lvds10_02),
    .o_lvds10_03                 (w_lvds10_03),
    .o_lvds10_04                 (w_lvds10_04),
    .o_lvds10_05                 (w_lvds10_05),
    .o_lvds10_06                 (w_lvds10_06),
    .o_lvds10_07                 (w_lvds10_07),

    .rst                         (rst)
);                               

rxd_to_rbuf_12test               inst_rxd_to_rbuf_12test
(                                
    .camera_clk                  (camera_clk),
    .o_xvs                       (w_xvs12),
    .o_xhs                       (w_xhs12),

    .o_lvds12_00                 (w_lvds12_00),
    .o_lvds12_01                 (w_lvds12_01),
    .o_lvds12_02                 (w_lvds12_02),
    .o_lvds12_03                 (w_lvds12_03),
    .o_lvds12_04                 (w_lvds12_04),
    .o_lvds12_05                 (w_lvds12_05),
    .o_lvds12_06                 (w_lvds12_06),
    .o_lvds12_07                 (w_lvds12_07),

    .rst                         (rst)
);

wire [7:0]  w_mode8_0;
wire [11:0] w_rbuf_doutb8_0;
wire [ 7:0] w_rbuf_dout8_0;
wire        w_data_valid8_0;
wire  [8:0] w_data_count8_0;
assign w_rbuf_dout8_0 = w_rbuf_doutb8_0[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_0
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_0),
    .o_mode                      (w_mode8_0),
    .o_data_valid                (w_data_valid8_0),
    .o_data_count                (w_data_count8_0),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_0),
    .rst                         (rst)
);

wire [7:0]  w_mode8_1;
wire [11:0] w_rbuf_doutb8_1;
wire [ 7:0] w_rbuf_dout8_1;
wire [ 8:0] w_data_count8_1;
wire        w_data_valid8_1;
assign w_rbuf_dout8_1 = w_rbuf_doutb8_1[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_1
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_1),
    .o_mode                      (w_mode8_1),
    .o_data_count                (w_data_count8_1),
    .o_data_valid                (w_data_valid8_1),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_1),
    .rst                         (rst)
);

wire [7:0]  w_mode8_2;
wire [11:0] w_rbuf_doutb8_2;
wire [ 7:0] w_rbuf_dout8_2;
wire [ 8:0] w_data_count8_2;
wire        w_data_valid8_2;
assign w_rbuf_dout8_2 = w_rbuf_doutb8_2[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_2
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_2),
    .o_mode                      (w_mode8_2),
    .o_data_count                (w_data_count8_2),
    .o_data_valid                (w_data_valid8_2),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_2),
    .rst                         (rst)
);

wire [7:0]  w_mode8_3;
wire [11:0] w_rbuf_doutb8_3;
wire [ 7:0] w_rbuf_dout8_3;
wire [ 8:0] w_data_count8_3;
wire        w_data_valid8_3;
assign w_rbuf_dout8_3 = w_rbuf_doutb8_3[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_3
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_3),
    .o_mode                      (w_mode8_3),
    .o_data_count                (w_data_count8_3),
    .o_data_valid                (w_data_valid8_3),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_3),
    .rst                         (rst)
);

wire [7:0]  w_mode8_4;
wire [11:0] w_rbuf_doutb8_4;
wire [ 7:0] w_rbuf_dout8_4;
wire [ 8:0] w_data_count8_4;
wire        w_data_valid8_4;
assign w_rbuf_dout8_4 = w_rbuf_doutb8_4[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_4
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_4),
    .o_mode                      (w_mode8_4),
    .o_data_count                (w_data_count8_4),
    .o_data_valid                (w_data_valid8_4),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_4),
    .rst                         (rst)
);

wire [7:0]  w_mode8_5;
wire [11:0] w_rbuf_doutb8_5;
wire [ 7:0] w_rbuf_dout8_5;
wire [ 8:0] w_data_count8_5;
wire        w_data_valid8_5;
assign w_rbuf_dout8_5 = w_rbuf_doutb8_5[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_5
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_5),
    .o_mode                      (w_mode8_5),
    .o_data_count                (w_data_count8_5),
    .o_data_valid                (w_data_valid8_5),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_5),
    .rst                         (rst)
);

wire [7:0]  w_mode8_6;
wire [11:0] w_rbuf_doutb8_6;
wire [ 7:0] w_rbuf_dout8_6;
wire [ 8:0] w_data_count8_6;
wire        w_data_valid8_6;
assign w_rbuf_dout8_6 = w_rbuf_doutb8_6[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_6
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_6),
    .o_mode                      (w_mode8_6),
    .o_data_count                (w_data_count8_6),
    .o_data_valid                (w_data_valid8_6),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_6),
    .rst                         (rst)
);

wire [7:0]  w_mode8_7;
wire [11:0] w_rbuf_doutb8_7;
wire [ 7:0] w_rbuf_dout8_7;
wire [ 8:0] w_data_count8_7;
wire        w_data_valid8_7;
assign w_rbuf_dout8_7 = w_rbuf_doutb8_7[11:4];

rxd_to_rbuf                      inst_rxd_to_rbuf8_7
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs8),
    .i_lvds                      (w_lvds8_7),
    .o_mode                      (w_mode8_7),
    .o_data_count                (w_data_count8_7),
    .o_data_valid                (w_data_valid8_7),
    .i_rbuf_addrb                (w_rbuf8_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb8_7),
    .rst                         (rst)
);

wire [7:0]  w_mode10_0;
wire [11:0] w_rbuf_doutb10_0;
wire [ 9:0] w_rbuf_dout10_0;
wire [ 8:0] w_data_count10_0;
wire        w_data_valid10_0;
assign w_rbuf_dout10_0 = w_rbuf_doutb10_0[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_0
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_00),
    .o_mode                      (w_mode10_0),
    .o_data_count                (w_data_count10_0),
    .o_data_valid                (w_data_valid10_0),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_0),
    .rst                         (rst)
);

wire [7:0]  w_mode10_1;
wire [11:0] w_rbuf_doutb10_1;
wire [ 9:0] w_rbuf_dout10_1;
wire [ 8:0] w_data_count10_1;
wire        w_data_valid10_1;
assign w_rbuf_dout10_1 = w_rbuf_doutb10_1[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_1
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_01),
    .o_mode                      (w_mode10_1),
    .o_data_count                (w_data_count10_1),
    .o_data_valid                (w_data_valid10_1),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_1),
    .rst                         (rst)
);

wire [7:0]  w_mode10_2;
wire [11:0] w_rbuf_doutb10_2;
wire [ 9:0] w_rbuf_dout10_2;
wire [ 8:0] w_data_count10_2;
wire        w_data_valid10_2;
assign w_rbuf_dout10_2 = w_rbuf_doutb10_2[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_2
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_02),
    .o_mode                      (w_mode10_2),
    .o_data_count                (w_data_count10_2),
    .o_data_valid                (w_data_valid10_2),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_2),
    .rst                         (rst)
);

wire [7:0]  w_mode10_3;
wire [11:0] w_rbuf_doutb10_3;
wire [ 9:0] w_rbuf_dout10_3;
wire [ 8:0] w_data_count10_3;
wire        w_data_valid10_3;
assign w_rbuf_dout10_3 = w_rbuf_doutb10_3[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_3
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_03),
    .o_mode                      (w_mode10_3),
    .o_data_count                (w_data_count10_3),
    .o_data_valid                (w_data_valid10_3),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_3),
    .rst                         (rst)
);

wire [7:0]  w_mode10_4;
wire [11:0] w_rbuf_doutb10_4;
wire [ 9:0] w_rbuf_dout10_4;
wire [ 8:0] w_data_count10_4;
wire        w_data_valid10_4;
assign w_rbuf_dout10_4 = w_rbuf_doutb10_4[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_4
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_04),
    .o_mode                      (w_mode10_4),
    .o_data_count                (w_data_count10_4),
    .o_data_valid                (w_data_valid10_4),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_4),
    .rst                         (rst)
);

wire [7:0]  w_mode10_5;
wire [11:0] w_rbuf_doutb10_5;
wire [ 9:0] w_rbuf_dout10_5;
wire [ 8:0] w_data_count10_5;
wire        w_data_valid10_5;
assign w_rbuf_dout10_5 = w_rbuf_doutb10_5[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_5
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_05),
    .o_mode                      (w_mode10_5),
    .o_data_count                (w_data_count10_5),
    .o_data_valid                (w_data_valid10_5),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_5),
    .rst                         (rst)
);

wire [7:0]  w_mode10_6;
wire [11:0] w_rbuf_doutb10_6;
wire [ 9:0] w_rbuf_dout10_6;
wire [ 8:0] w_data_count10_6;
wire        w_data_valid10_6;
assign w_rbuf_dout10_6 = w_rbuf_doutb10_6[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_6
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_06),
    .o_mode                      (w_mode10_6),
    .o_data_count                (w_data_count10_6),
    .o_data_valid                (w_data_valid10_6),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_6),
    .rst                         (rst)
);

wire [7:0]  w_mode10_7;
wire [11:0] w_rbuf_doutb10_7;
wire [ 9:0] w_rbuf_dout10_7;
wire [ 8:0] w_data_count10_7;
wire        w_data_valid10_7;
assign w_rbuf_dout10_7 = w_rbuf_doutb10_7[11:2];

rxd_to_rbuf                      inst_rxd_to_rbuf10_7
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs10),
    .i_lvds                      (w_lvds10_07),
    .o_mode                      (w_mode10_7),
    .o_data_count                (w_data_count10_7),
    .o_data_valid                (w_data_valid10_7),
    .i_rbuf_addrb                (w_rbuf10_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb10_7),
    .rst                         (rst)
);

wire [7:0]  w_mode12_0;
wire [11:0] w_rbuf_doutb12_0;
wire  [8:0] w_data_count12_0;
wire        w_data_valid12_0;


rxd_to_rbuf                      inst_rxd_to_rbuf12_0
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_00),
    .o_mode                      (w_mode12_0),
    .o_data_count                (w_data_count12_0),
    .o_data_valid                (w_data_valid12_0),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_0),
    .rst                         (rst)
);

wire [7:0]  w_mode12_1;
wire [11:0] w_rbuf_doutb12_1;
wire  [8:0] w_data_count12_1;
wire        w_data_valid12_1;


rxd_to_rbuf                      inst_rxd_to_rbuf12_1
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_01),
    .o_mode                      (w_mode12_1),
    .o_data_count                (w_data_count12_1),
    .o_data_valid                (w_data_valid12_1),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_1),
    .rst                         (rst)
);

wire [7:0]  w_mode12_2;
wire [11:0] w_rbuf_doutb12_2;
wire  [8:0] w_data_count12_2;
wire        w_data_valid12_2;


rxd_to_rbuf                      inst_rxd_to_rbuf12_2
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_02),
    .o_mode                      (w_mode12_2),
    .o_data_count                (w_data_count12_2),
    .o_data_valid                (w_data_valid12_2),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_2),
    .rst                         (rst)
);

wire [7:0]  w_mode12_3;
wire [11:0] w_rbuf_doutb12_3;
wire  [8:0] w_data_count12_3;
wire        w_data_valid12_3;


rxd_to_rbuf                      inst_rxd_to_rbuf12_3
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_03),
    .o_mode                      (w_mode12_3),
    .o_data_count                (w_data_count12_3),
    .o_data_valid                (w_data_valid12_3),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_3),
    .rst                         (rst)
);

wire [7:0]  w_mode12_4;
wire [11:0] w_rbuf_doutb12_4;
wire  [8:0] w_data_count12_4;
wire        w_data_valid12_4;


rxd_to_rbuf                      inst_rxd_to_rbuf12_4
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_04),
    .o_mode                      (w_mode12_4),
    .o_data_count                (w_data_count12_4),
    .o_data_valid                (w_data_valid12_4),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_4),
    .rst                         (rst)
);

wire [7:0]  w_mode12_5;
wire [11:0] w_rbuf_doutb12_5;
wire  [8:0] w_data_count12_5;
wire        w_data_valid12_5;


rxd_to_rbuf                      inst_rxd_to_rbuf12_5
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_05),
    .o_mode                      (w_mode12_5),
    .o_data_count                (w_data_count12_5),
    .o_data_valid                (w_data_valid12_5),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_5),
    .rst                         (rst)
);

wire [7:0]  w_mode12_6;
wire [11:0] w_rbuf_doutb12_6;
wire  [8:0] w_data_count12_6;
wire        w_data_valid12_6;


rxd_to_rbuf                      inst_rxd_to_rbuf12_6
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_06),
    .o_mode                      (w_mode12_6),
    .o_data_count                (w_data_count12_6),
    .o_data_valid                (w_data_valid12_6),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_6),
    .rst                         (rst)
);

wire [7:0]  w_mode12_7;
wire [11:0] w_rbuf_doutb12_7;
wire  [8:0] w_data_count12_7;
wire        w_data_valid12_7;


rxd_to_rbuf                      inst_rxd_to_rbuf12_7
(
    .camera_clk                  (camera_clk),
    .vdma_clk                    (vdma_clk),
    .i_xhs                       (w_xhs12),
    .i_lvds                      (w_lvds12_07),
    .o_mode                      (w_mode12_7),
    .o_data_count                (w_data_count12_7),
    .o_data_valid                (w_data_valid12_7),
    .i_rbuf_addrb                (w_rbuf12_addrb),
    .o_rbuf_doutb                (w_rbuf_doutb12_7),
    .rst                         (rst)
);

endmodule


