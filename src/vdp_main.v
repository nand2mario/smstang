
module vdp_main(clk_sys, ce_vdp, ce_pix, ce_sp, ggres, sp64, vram_A, vram_D, cram_A, cram_D, x, y, color, palettemode, y1, display_on, mask_column0, black_column, smode_M1, smode_M3, smode_M4, ysj_quirk, overscan, bg_address, m2mg_address, m2ct_address, bg_scroll_x, bg_scroll_y, disable_hscroll, disable_vscroll, spr_address, spr_high_bits, spr_shift, spr_tall, spr_wide, spr_collide, spr_overflow);
   parameter     MAX_SPPL = 7;

   input         clk_sys;
   input         ce_vdp;
   input         ce_pix;
   input         ce_sp;
   input         ggres;
   input         sp64;
   output [13:0] vram_A;
   input [7:0]   vram_D;
   output reg [4:0]  cram_A;
   input [11:0]  cram_D;
   
   input [8:0]   x;
   input [8:0]   y;
   
   output [11:0] color;
   input         palettemode;
   output reg    y1;
   
   input         display_on;
   input         mask_column0;
   input         black_column;
   input         smode_M1;
   input         smode_M3;
   input         smode_M4;
   input         ysj_quirk;
   input [3:0]   overscan;
   
   input [3:0]   bg_address;
   input [2:0]   m2mg_address;
   input [7:0]   m2ct_address;
   input [7:0]   bg_scroll_x;
   input [7:0]   bg_scroll_y;
   input         disable_hscroll;
   input         disable_vscroll;
   
   input [6:0]   spr_address;
   input [2:0]   spr_high_bits;
   input         spr_shift;
   input         spr_tall;
   input         spr_wide;
   output        spr_collide;
   output        spr_overflow;
   
   
   reg [7:0]     bg_y;
   wire [13:0]   bg_vram_A;
   wire [4:0]    bg_color;
   wire          bg_priority;
   reg [3:0]     out_color;
   wire [13:0]   spr_vram_A;
   wire [3:0]    spr_color;
   
   wire          line_reset;
   
   
   always @* begin
      reg [8:0]     sum;
      sum = 0;
      if (disable_vscroll == 1'b0 | x + 16 < 25 * 8) begin
         sum = y + ({1'b0, bg_scroll_y});
         if (smode_M1 == 1'b0 & smode_M3 == 1'b0) begin
            if (sum >= 224)
               sum = sum - 224;
         end 
         // else
         //	sum(8)$'0';
         bg_y = sum[7:0];
      end else
         bg_y = y[7:0];
   end
   
   // see vdp_background comment around line 53
   assign line_reset = (x == 512 - 24) ? 1'b1 : 1'b0; // offset should be 25 to please VDPTEST
   
   vdp_background vdp_bg_inst(
      .clk_sys(clk_sys),          .ce_pix(ce_pix),           .table_address(bg_address), .pt_address(m2mg_address),
      .ct_address(m2ct_address),   .reset(line_reset),        .disable_hscroll(disable_hscroll), .scroll_x(bg_scroll_x),
      .y(bg_y),                    .screen_y(y),              .vram_A(bg_vram_A),        .vram_D(vram_D),
      .color(bg_color),            .smode_M1(smode_M1),       .smode_M3(smode_M3),       .smode_M4(smode_M4),
      .ysj_quirk(ysj_quirk),       .PRIORITY(bg_priority)
   );
   
   vdp_sprites #(MAX_SPPL) vdp_spr_inst(
      .clk_sys(clk_sys),          .ce_vdp(ce_vdp),           .ce_pix(ce_pix),           .ce_sp(ce_sp),
      .sp64(sp64),                .table_address(spr_address), .char_high_bits(spr_high_bits), .tall(spr_tall),
      .wide(spr_wide),            .shift(spr_shift),          .x(x),                     .y(y),
      .collide(spr_collide),      .overflow(spr_overflow),    .smode_M1(smode_M1),       .smode_M3(smode_M3),
      .smode_M4(smode_M4),        .vram_A(spr_vram_A),        .vram_D(vram_D),           .color(spr_color)
   );
   
   always @* begin
      reg           spr_active;
      reg           bg_active;

      spr_active = 1'b0;
      bg_active = 1'b0;
      y1 = 1'b1;
      if (((x > 48 & x <= 208) | (ggres == 1'b0 & x <= 256 & x > 0)) &     // thank you slingshot
           (mask_column0 == 1'b0 | x >= 9) & display_on) begin		
         if (((y >= 24 & y < 168) & smode_M1 == 1'b0) 
           | ((y >= 40 & y < 184) & smode_M1) 
           | (ggres == 1'b0 & y < 192) 
           | (smode_M1 & y < 224 & ggres == 1'b0) 
           | (smode_M3 & y < 240 & ggres == 1'b0)) begin
            
            spr_active = ~(spr_color == 4'b0000);
            bg_active = ~(bg_color[3:0] == 4'b0000);
            if ((~spr_active) & (~bg_active)) begin
               out_color = overscan;
               cram_A = {bg_color[4], 4'b0000};
               y1 = 1'b0;
            end else if ((bg_priority == 1'b0 & spr_active) | (bg_priority & (~bg_active))) begin
               out_color = spr_color;
               cram_A = {1'b1, spr_color};
            end else begin
               cram_A = bg_color;
               if (bg_color[3:0] == 4'b0000)
                  out_color = overscan;
               else
                  out_color = bg_color[3:0];
            end
         end else begin
            cram_A = {1'b1, overscan};
            out_color = overscan;
         end
      end else begin
         cram_A = {1'b1, overscan};
         out_color = overscan;
      end
   end
   
   assign vram_A = (x >= 256 & x < 496) ? spr_vram_A : bg_vram_A; // Does bg only need x<504 only?
                   
   assign color = (black_column & mask_column0 & x > 0 & x < 9) ? 12'b000000000000 : 
                  (smode_M4) ? cram_D : 
                  // How an SMS VDP handles Legacy TMS Modes to produce these values
                  (out_color == 4'b0000 | out_color == 4'b0001) ? 12'h000 : 		// Transparent or Black
                  (out_color == 4'b0010 & palettemode == 1'b0) ? 12'h4A2 : 		// Medium Green
                  (out_color == 4'b0011 & palettemode == 1'b0) ? 12'h7E6 : 		// Light Green
                  (out_color == 4'b0100 & palettemode == 1'b0) ? 12'hF55 : 		// Dark Blue
                  (out_color == 4'b0101 & palettemode == 1'b0) ? 12'hF88 : 		// Light Blue
                  (out_color == 4'b0110 & palettemode == 1'b0) ? 12'h55D : 		// Dark red
                  (out_color == 4'b0111 & palettemode == 1'b0) ? 12'hFF4 : 		// Cyan
                  (out_color == 4'b1000 & palettemode == 1'b0) ? 12'h55F : 		// Medium Red
                  (out_color == 4'b1001 & palettemode == 1'b0) ? 12'h88F : 		// Light Red
                  (out_color == 4'b1010 & palettemode == 1'b0) ? 12'h5DD : 		// Dark Yellow
                  (out_color == 4'b1011 & palettemode == 1'b0) ? 12'h8DE : 		// Light Yellow
                  (out_color == 4'b1100 & palettemode == 1'b0) ? 12'h4B2 : 		// Dark Green
                  (out_color == 4'b1101 & palettemode == 1'b0) ? 12'hA6B : 		// Magenta
                  (out_color == 4'b1110 & palettemode == 1'b0) ? 12'hBBB : 		// Gray
                  // Equivalent values to original TMS chip output from SG-1000
                  (out_color == 4'b0010 & palettemode == 1'b1) ? 12'h4C2 : 		// Medium Green
                  (out_color == 4'b0011 & palettemode == 1'b1) ? 12'h7D5 : 		// Light Green
                  (out_color == 4'b0100 & palettemode == 1'b1) ? 12'hE55 : 		// Dark Blue
                  (out_color == 4'b0101 & palettemode == 1'b1) ? 12'hF77 : 		// Light Blue
                  (out_color == 4'b0110 & palettemode == 1'b1) ? 12'h45D : 		// Dark red
                  (out_color == 4'b0111 & palettemode == 1'b1) ? 12'hFE4 : 		// Cyan
                  (out_color == 4'b1000 & palettemode == 1'b1) ? 12'h55F : 		// Medium Red
                  (out_color == 4'b1001 & palettemode == 1'b1) ? 12'h77F : 		// Light Red
                  (out_color == 4'b1010 & palettemode == 1'b1) ? 12'h5CD : 		// Dark Yellow
                  (out_color == 4'b1011 & palettemode == 1'b1) ? 12'h8CE : 		// Light Yellow
                  (out_color == 4'b1100 & palettemode == 1'b1) ? 12'h3B2 : 		// Dark Green
                  (out_color == 4'b1101 & palettemode == 1'b1) ? 12'hB5C : 		// Magenta
                  (out_color == 4'b1110 & palettemode == 1'b1) ? 12'hCCC : 		// Gray
                  12'hFFF;		// White
   
endmodule
