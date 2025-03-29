
module vpd_sprite_shifter(clk_sys, ce_pix, x, spr_x, load, x248, x224, m4, wide_n, spr_d0, spr_d1, spr_d2, spr_d3, color, active);
   input        clk_sys;
   input        ce_pix;
   input [7:0]  x;
   input [7:0]  spr_x;
   input        load;
   input        x248;		// idem load but for shifted sprites
   input        x224;		// idem load but for shifted mode2 sprites
   input        m4;		// 1 if mode4
   input        wide_n;		// if sprites are wide reg1 bit 0
   input [7:0]  spr_d0;
   input [7:0]  spr_d1;
   input [7:0]  spr_d2;
   input [7:0]  spr_d3;
   output reg [3:0] color;
   output reg   active;
   
   reg          wideclock;
   reg [7:0]    shift0;
   reg [7:0]    shift1;
   reg [7:0]    shift2;
   reg [7:0]    shift3;
   
   always @(posedge clk_sys) begin
      if (ce_pix) begin
         if (  (spr_x == x & (load & (m4 | spr_d3[7] == 1'b0) | x224 & spr_d3[7])) 
             | (spr_x == x + 8 & x248)) begin
            shift0 <= spr_d0;
            shift1 <= spr_d1;
            shift2 <= spr_d2;
            shift3 <= spr_d3;
            wideclock <= 1'b0;
         end else begin
            if (wide_n | wideclock) begin
               shift0[7:1] <= shift0[6:0];
               if (m4) begin
                  shift0[0] <= 1'b0;
                  shift3 <= {shift3[6:0], 1'b0};
               end else
                  // mode 2 we use a 16-bit shift, shift2 is ignored and shift3 retains color 
                  shift0[0] <= shift1[7];
               shift1 <= {shift1[6:0], 1'b0};
               shift2 <= {shift2[6:0], 1'b0};
            end 
            wideclock <= ~wideclock;
         end
      end 
   end 
   
   
   always @*
      if (m4) begin
         color = {shift3[7], shift2[7], shift1[7], shift0[7]};
         active = shift3[7] | shift2[7] | shift1[7] | shift0[7];
      end else begin
         if (shift0[7])
            color = shift3[3:0];
         else
            color = 4'b0000;
         active = shift0[7];
      end
   
endmodule
