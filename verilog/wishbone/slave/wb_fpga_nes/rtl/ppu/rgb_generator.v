`include "project_defines.v"
module rgb_generator(
  input               clk,                // 100MHz system clock signal
  input               rst,                // reset signal

  //Generated Signals to Drive VGA
  output              vsync,
  output              hsync,
  output        [2:0] r_out,               // vga red signal
  output        [2:0] g_out,               // vga green signal
  output        [1:0] b_out,               // vga blue signal

  //From the below control signal, the PPU returns this value
  input         [5:0] sys_palette_idx_in,  // system palette index (selects output color)

  //X, Y, Y Next, pixel clock and a vblank
  output        [9:0] nes_x_out,           // nes x coordinate
  output        [9:0] nes_y_out,           // nes y coordinate
  output        [9:0] nes_y_next_out,      // next line's nes y coordinate
  output              pix_pulse_out,       // 1 clk pulse prior to nes_x update
  output              vblank_out           // indicates a vblank is occuring (no PPU vram access)
);

//local parameters
// NES screen dimensions (256x240).
//localparam [9:0] NES_W        = 10'h100;
//localparam [9:0] NES_H        = 10'h0F0;

localparam [9:0] NES_W        = 10'h4;
localparam [9:0] NES_H        = 10'h10;



localparam  FPS               = 60;
//localparam  VBLANK_TIMEOUT    = `CLOCK_RATE / FPS;
localparam  VBLANK_TIMEOUT    = 100;
localparam  HBLANK_TIMEOUT    = 10;

localparam  VBLANK            = 4'h0,
            PROCESS_LINE      = 4'h1,
            HBLANK            = 4'h2;

//Clock Rate = 50.0 MHz
//Number of clock Rats in 1/30th of a second
//50000000 / 30 = 1666666
//registers/wires
reg   [3:0]       q_state         = HBLANK;
reg   [3:0]       d_state;
reg   [23:0]      q_delay_count   = 24'h000000;
reg   [23:0]      d_delay_count;
reg   [23:0]      q_hdelay        = 42'h000000;
reg   [23:0]      d_hdelay;

reg               q_vsync         = 1'b0;
reg               d_vsync;
reg               q_hsync         = 1'b0;
reg               d_hsync;

reg   [9:0]       q_xpos          = 10'h000;
reg   [9:0]       d_xpos;
reg   [9:0]       q_ypos          = 10'h000;
reg   [9:0]       d_ypos;

reg   [7:0]       q_rgb           = 8'h00;
reg   [7:0]       d_rgb;  //output color, latch (1 clk delay required)
reg   [1:0]       q_mod4_cnt      = 2'b00;
reg   [1:0]       d_mod4_cnt;
//submodules

//asynchronous logic

assign { r_out, g_out, b_out } = q_rgb;
assign pix_pulse_out           = (q_mod4_cnt == 0) && q_hsync;
assign nes_x_out               = q_xpos;
assign nex_x_next_out          = d_xpos;
assign nes_y_out               = q_ypos;
assign nes_y_next_out          = d_ypos;
assign vsync                   = q_vsync;
assign hsync                   = q_hsync;
assign vblank_out              = !q_vsync;
//synchronous logic

//Synchronizer
always @(posedge clk) begin
  if (rst) begin
    q_delay_count <=  0;
    q_hdelay      <=  0;
    q_mod4_cnt    <=  0;

    q_vsync       <=  0;
    q_hsync       <=  0;

    q_rgb         <=  0;

    q_xpos        <=  0;
    q_ypos        <=  0;

    q_state       <=  VBLANK;
  end
  else begin
    q_delay_count <= d_delay_count;
    q_hdelay      <= d_hdelay;
    q_mod4_cnt    <= d_mod4_cnt;
    q_vsync       <= d_vsync;
    q_hsync       <= d_hsync;

    q_rgb         <= d_rgb;

    q_xpos        <= d_xpos;
    q_ypos        <= d_ypos;
    q_state       <= d_state;
  end
end

always @ (*) begin
  //Default Assignments
  d_delay_count   = q_delay_count;
  d_hdelay        = q_hdelay;
  d_vsync         = q_vsync;
  d_hsync         = q_hsync;

  d_xpos          = q_xpos;
  d_ypos          = q_ypos;
  d_state         = q_state;
  d_mod4_cnt      = q_mod4_cnt;

  case (q_state)
    VBLANK: begin
      d_mod4_cnt      = 0;
      //Vertical blank period
      if (d_delay_count < VBLANK_TIMEOUT) begin
        d_delay_count = q_delay_count + 1;
        d_hdelay      = 0;
        d_vsync       = 0;
        d_hsync       = 0;
                      
        d_xpos        = 0;
        d_ypos        = 0;
      end             
      else begin      
        d_state       = PROCESS_LINE;
      end
    end
    PROCESS_LINE: begin
      d_mod4_cnt      = q_mod4_cnt + 1;
      d_vsync         = 1;
      d_hsync         = 1;

      d_hdelay        = 0;
      if (pix_pulse_out) begin
        if (q_xpos + 1< NES_W) begin
          d_xpos      = q_xpos + 1;
        end
        else begin
          if (q_ypos + 1 < NES_H) begin
            d_xpos        = 0;
            d_ypos        = q_ypos + 1;
            d_state       = HBLANK;
          end
          else begin
            d_state       = VBLANK;
          end
        end
      end
    end
    HBLANK: begin
      d_delay_count   = 0;
      d_mod4_cnt      = 0;
      d_xpos          = 0;
      d_vsync         = 1;
      d_hsync         = 0;
      if (q_hdelay < HBLANK_TIMEOUT) begin
        d_hdelay      = q_hdelay + 1;
      end
      else begin
        d_state       = PROCESS_LINE;
      end
    end
    default: begin
      d_state         = VBLANK;
    end
  endcase
end

always @ (*) begin
  if (d_hsync == 0) begin
    d_rgb             = 0;
  end
  else begin
    // Lookup RGB values based on sys_palette_idx.  Table is an approximation of the NES
    // system palette.  Taken from http://nesdev.parodius.com/NESTechFAQ.htm#nessnescompat.
    case (sys_palette_idx_in)
      6'h00:  d_rgb = { 3'h3, 3'h3, 2'h1 };
      6'h01:  d_rgb = { 3'h1, 3'h0, 2'h2 };
      6'h02:  d_rgb = { 3'h0, 3'h0, 2'h2 };
      6'h03:  d_rgb = { 3'h2, 3'h0, 2'h2 };
      6'h04:  d_rgb = { 3'h4, 3'h0, 2'h1 };
      6'h05:  d_rgb = { 3'h5, 3'h0, 2'h0 };
      6'h06:  d_rgb = { 3'h5, 3'h0, 2'h0 };
      6'h07:  d_rgb = { 3'h3, 3'h0, 2'h0 };
      6'h08:  d_rgb = { 3'h2, 3'h1, 2'h0 };
      6'h09:  d_rgb = { 3'h0, 3'h2, 2'h0 };
      6'h0a:  d_rgb = { 3'h0, 3'h2, 2'h0 };
      6'h0b:  d_rgb = { 3'h0, 3'h1, 2'h0 };
      6'h0c:  d_rgb = { 3'h0, 3'h1, 2'h1 };
      6'h0d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h0e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h0f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

      6'h10:  d_rgb = { 3'h5, 3'h5, 2'h2 };
      6'h11:  d_rgb = { 3'h0, 3'h3, 2'h3 };
      6'h12:  d_rgb = { 3'h1, 3'h1, 2'h3 };
      6'h13:  d_rgb = { 3'h4, 3'h0, 2'h3 };
      6'h14:  d_rgb = { 3'h5, 3'h0, 2'h2 };
      6'h15:  d_rgb = { 3'h7, 3'h0, 2'h1 };
      6'h16:  d_rgb = { 3'h6, 3'h1, 2'h0 };
      6'h17:  d_rgb = { 3'h6, 3'h2, 2'h0 };
      6'h18:  d_rgb = { 3'h4, 3'h3, 2'h0 };
      6'h19:  d_rgb = { 3'h0, 3'h4, 2'h0 };
      6'h1a:  d_rgb = { 3'h0, 3'h5, 2'h0 };
      6'h1b:  d_rgb = { 3'h0, 3'h4, 2'h0 };
      6'h1c:  d_rgb = { 3'h0, 3'h4, 2'h2 };
      6'h1d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h1e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h1f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

      6'h20:  d_rgb = { 3'h7, 3'h7, 2'h3 };
      6'h21:  d_rgb = { 3'h1, 3'h5, 2'h3 };
      6'h22:  d_rgb = { 3'h2, 3'h4, 2'h3 };
      6'h23:  d_rgb = { 3'h5, 3'h4, 2'h3 };
      6'h24:  d_rgb = { 3'h7, 3'h3, 2'h3 };
      6'h25:  d_rgb = { 3'h7, 3'h3, 2'h2 };
      6'h26:  d_rgb = { 3'h7, 3'h3, 2'h1 };
      6'h27:  d_rgb = { 3'h7, 3'h4, 2'h0 };
      6'h28:  d_rgb = { 3'h7, 3'h5, 2'h0 };
      6'h29:  d_rgb = { 3'h4, 3'h6, 2'h0 };
      6'h2a:  d_rgb = { 3'h2, 3'h6, 2'h1 };
      6'h2b:  d_rgb = { 3'h2, 3'h7, 2'h2 };
      6'h2c:  d_rgb = { 3'h0, 3'h7, 2'h3 };
      6'h2d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h2e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h2f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

      6'h30:  d_rgb = { 3'h7, 3'h7, 2'h3 };
      6'h31:  d_rgb = { 3'h5, 3'h7, 2'h3 };
      6'h32:  d_rgb = { 3'h6, 3'h6, 2'h3 };
      6'h33:  d_rgb = { 3'h6, 3'h6, 2'h3 };
      6'h34:  d_rgb = { 3'h7, 3'h6, 2'h3 };
      6'h35:  d_rgb = { 3'h7, 3'h6, 2'h3 };
      6'h36:  d_rgb = { 3'h7, 3'h5, 2'h2 };
      6'h37:  d_rgb = { 3'h7, 3'h6, 2'h2 };
      6'h38:  d_rgb = { 3'h7, 3'h7, 2'h2 };
      6'h39:  d_rgb = { 3'h7, 3'h7, 2'h2 };
      6'h3a:  d_rgb = { 3'h5, 3'h7, 2'h2 };
      6'h3b:  d_rgb = { 3'h5, 3'h7, 2'h3 };
      6'h3c:  d_rgb = { 3'h4, 3'h7, 2'h3 };
      6'h3d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h3e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
      6'h3f:  d_rgb = { 3'h0, 3'h0, 2'h0 };
    endcase
  end
end

endmodule
