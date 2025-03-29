
module vdp_background(
   input             clk_sys,
   input             ce_pix,
   input             reset,
   input [13:10]     table_address,
   input [13:11]     pt_address,
   input [13:6]      ct_address,
   input [7:0]       scroll_x,
   input             disable_hscroll,
   input             smode_M1,
   input             smode_M3,
   input             smode_M4,
   input             ysj_quirk,
   input [7:0]       y,
   input [8:0]       screen_y,
   
   output reg [13:0] vram_A,
   input [7:0]       vram_D,
   
   output reg [4:0]  color,
   output reg        PRIORITY
);   
   
   reg [8:0]     tile_index;
   reg [7:0]     x;
   reg [2:0]     tile_y;
   reg           palette;
   reg           priority_latch;
   reg           flip_x;
   
   reg [7:0]     datac;
   reg [7:0]     data0;
   reg [7:0]     data1;
   reg [7:0]     data2;
   reg [7:0]     data3;
   
   reg [7:0]     shift0;
   reg [7:0]     shift1;
   reg [7:0]     shift2;
   reg [7:0]     shift3;
   
   
   always @(posedge clk_sys)  begin
      if (ce_pix) begin
         if (reset) begin
            if (smode_M4 == 1'b0)
               x <= 8'b11110000;		// 240
            //
            // if you want to fix the last HScroll test of VDPTest, you'll need to 
            // change the values below 233=232+1 by half a pixel and make the
            // same change in vdp_main around line 79 (line_reset)
            //
            else if (disable_hscroll == 1'b0 | screen_y >= 16)
               // if you mess with this check Sangokushi3 scroll during
               // the presentation + scroll of the top line during fight
               x <= 232 - scroll_x;		// temporary workaround of 1pix roll - needs better fix!
            else
               x <= 8'b11101000;		// 256-24=232
         end else
            x <= x + 1;
      end 
   end 
   
   
   always @(posedge clk_sys) begin
      reg [12:0]    char_address;
      reg [11:0]    data_address;

      if (ce_pix) begin
         if (smode_M4) begin
            if (smode_M1 | smode_M3)
               char_address[12:5] = {table_address[13:12], (6'b011100 + y[7:3])};
            else begin
               char_address[12:10] = table_address[13:11];
               if (ysj_quirk) begin		// Enable VDP version 1 for Ys (Japan)
                  char_address[9] = table_address[10] & y[7];
                  char_address[8:5] = y[6:3];
               end else begin
                  char_address[9] = y[7];
                  char_address[8:5] = y[6:3];
               end
            end
            char_address[4:0] = x[7:3] + 1;
            data_address = {tile_index, tile_y};
            
            case (x[2:0])
               3'b000 : vram_A <= {char_address, 1'b0};
               3'b001 : vram_A <= {char_address, 1'b1};
               3'b011 : vram_A <= {data_address, 2'b00};
               3'b100 : vram_A <= {data_address, 2'b01};
               3'b101 : vram_A <= {data_address, 2'b10};
               3'b110 : vram_A <= {data_address, 2'b11};
               default : ;
            endcase
         end else
            case (x[2:0])
               3'b000 : vram_A <= {table_address, y[7:3], x[7:3]};
               3'b010 : vram_A <= {pt_address[13], (y[7:6] & pt_address[12:11]), tile_index[7:0], y[2:0]};
               3'b011 : vram_A <= {ct_address[13], (y[7:6] & ct_address[12:11]), tile_index[7:0], y[2:0]};
               default : ;
            endcase
      end 
   end
   
   
   always @(posedge clk_sys) begin
      integer       i;

      if (ce_pix) begin
         if (smode_M4)
            case (x[2:0])
               3'b001 :
                  tile_index[7:0] <= vram_D;
               3'b010 :
                  begin
                     tile_index[8] <= vram_D[0];
                     flip_x <= vram_D[1];
                     tile_y[0] <= y[0] ^ vram_D[2];
                     tile_y[1] <= y[1] ^ vram_D[2];
                     tile_y[2] <= y[2] ^ vram_D[2];
                     palette <= vram_D[3];
                     priority_latch <= vram_D[4];
                  end
               3'b100 :
                  data0 <= vram_D;
               3'b101 :
                  data1 <= vram_D;
               3'b110 :
                  data2 <= vram_D;
               //				when "111" =>
               //					data3 <= vram_D;
               default : ;
            endcase
         else
            // mode 2 and msx compat
            case (x[2:0])
               3'b001 :
                  tile_index[7:0] <= vram_D;
               3'b011 :
                  datac <= vram_D;
               3'b100 :
                  begin
                     flip_x <= 1'b0;
                     palette <= 1'b0;
                     priority_latch <= 1'b0;
                     for (i = 0; i <= 7; i = i + 1) begin
                        data0[i] <= ((~datac[i]) & vram_D[0]) | (datac[i] & vram_D[4]);
                        data1[i] <= ((~datac[i]) & vram_D[1]) | (datac[i] & vram_D[5]);
                        data2[i] <= ((~datac[i]) & vram_D[2]) | (datac[i] & vram_D[6]);
                        data3[i] <= ((~datac[i]) & vram_D[3]) | (datac[i] & vram_D[7]);
                     end
                  end
               default : ;
            endcase
      end 
   end
   
   reg palette_reg;
   always @(posedge clk_sys) begin
      if (ce_pix)
         case (x[2:0])
            3'b111 : begin
               if (flip_x == 1'b0) begin
                  shift0 <= data0;
                  shift1 <= data1;
                  shift2 <= data2;
                  if (smode_M4)
                     shift3 <= vram_D;
                  else
                     shift3 <= data3;
               end else begin
                  shift0 <= {data0[0], data0[1], data0[2], data0[3], data0[4], data0[5], data0[6], data0[7]};
                  shift1 <= {data1[0], data1[1], data1[2], data1[3], data1[4], data1[5], data1[6], data1[7]};
                  shift2 <= {data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7]};
                  shift3 <= {vram_D[0], vram_D[1], vram_D[2], vram_D[3], vram_D[4], vram_D[5], vram_D[6], vram_D[7]};
               end
               palette_reg <= palette; // nand2mario: fix mixed <= and =
               PRIORITY <= priority_latch;
            end
            default : begin
               shift0[7:1] <= shift0[6:0];
               shift1[7:1] <= shift1[6:0];
               shift2[7:1] <= shift2[6:0];
               shift3[7:1] <= shift3[6:0];
            end
         endcase
   end 
   
   assign color[0] = shift0[7];
   assign color[1] = shift1[7];
   assign color[2] = shift2[7];
   assign color[3] = shift3[7];
   assign color[4] = palette_reg;

endmodule
