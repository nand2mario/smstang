
module video(clk, ce_pix, pal, border, ggres, mask_column, cut_mask, smode_M1, smode_M3, x, y, hsync, vsync, hblank, vblank);
   input        clk;
   input        ce_pix;
   input        pal;
   input        border;
   input        ggres;
   input        mask_column;
   input        cut_mask;
   input        smode_M1;
   input        smode_M3;
   
   output [8:0] x;
   output [8:0] y;
   output reg   hsync;
   output reg   vsync;
   output reg   hblank;
   output reg   vblank;
   
   reg [8:0]    hcount;
   reg [8:0]    vcount;
   
   wire [8:0]   vbl_st;
   wire [8:0]   vbl_end;
   wire [8:0]   hbl_st;
   wire [8:0]   hbl_end;
   
   always @(posedge clk) begin
      if (ce_pix) begin
         if (hcount == 487) begin
            vcount <= vcount + 1;
            if (pal) begin
               // VCounter: 0-258, 458-511 = 313 steps
               if (smode_M1) begin
                  if (vcount == 258)
                     vcount <= 458;
                  else if (vcount == 461)
                     vsync <= 1'b1;
                  else if (vcount == 464)
                     vsync <= 1'b0;
               end else if (smode_M3) begin
                  if (vcount == 266)
                     vcount <= 482;
                  else if (vcount == 482)
                     vsync <= 1'b1;
                  else if (vcount == 485)
                     vsync <= 1'b0;
               end else
                  // VCounter: 0-242, 442-511 = 313 steps
                  if (vcount == 242)
                     vcount <= 442;
                  else if (vcount == 442)
                     vsync <= 1'b1;
                  else if (vcount == 445)
                     vsync <= 1'b0;
            end else
               // NTSC mode 224 lines ...
               if (smode_M1) begin
                  if (vcount == 234)
                     vcount <= 485;
                  else if (vcount == 487)
                     vsync <= 1'b1;
                  else if (vcount == 490)
                     vsync <= 1'b0;
               // NTSC mode 240 lines -- this mode is not suposed to work anyway
               end else if (smode_M3) begin
                  if (vcount == 261)		// needs to be > 240 to generate an IRQ
                     vcount <= 0;
                  else if (vcount == 257)
                     vsync <= 1'b1;
                  else if (vcount == 260)
                     vsync <= 1'b0;
               end else
                  // VCounter: 0-218, 469-511 = 262 steps
                  if (vcount == 218)
                     vcount <= 469;
                  else if (vcount == 471)
                     vsync <= 1'b1;
                  else if (vcount == 474)
                     vsync <= 1'b0;
         end 
         
         hcount <= hcount + 1;
         // HCounter: 0-295, 466-511 = 342 steps
         if (hcount == 295)
            hcount <= 466;
         if (hcount == 280)
            hsync <= 1'b1;
         else if (hcount == 474)
            hsync <= 1'b0;
      end 
   end 
   
   assign x = hcount;
   assign y = vcount;
   
   assign vbl_st = ((smode_M1 & ggres)) ? 184 : 
                   (smode_M1) ? 224 : 
                   (smode_M3) ? 240 : 
                   (border & pal == 1'b0) ? 216 : 
                   (border) ? 240 : 
                   (ggres == 1'b0) ? 192 : 
                   168;
   
   assign vbl_end = ((smode_M1 & ggres)) ? 40 : 
                    (smode_M1 | smode_M3 | (border == 1'b0 & ggres == 1'b0)) ? 000 : 
                    (border & pal == 1'b0) ? 488 : 
                    (border) ? 458 : 
                    024;
   
   assign hbl_st = (border & ggres == 1'b0) ? 270 : 
                   ((border ^ ggres) == 1'b0) ? 256 : 
                   208;
   
   assign hbl_end = (border & ggres == 1'b0) ? 500 : 
                    ((border ^ ggres) == 1'b0 & mask_column & cut_mask) ? 008 : 
                    ((border ^ ggres) == 1'b0) ? 000 : 
                    048;
   
   always @(posedge clk) begin
      if (ce_pix) begin
         if (hcount == hbl_end)
            hblank <= 1'b0;
         else if (hcount == hbl_st)
            hblank <= 1'b1;
         
         if (vcount == vbl_end)
            vblank <= 1'b0;
         else if (vcount == vbl_st)
            vblank <= 1'b1;
      end 
   end 
   
endmodule
