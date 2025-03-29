
module vdp_sprites(clk_sys, ce_vdp, ce_pix, ce_sp, sp64, table_address, char_high_bits, tall, wide, shift, smode_M1, smode_M3, smode_M4, vram_A, vram_D, x, y, collide, overflow, color);
   parameter         MAX_SPPL = 7;
   input             clk_sys;
   input             ce_vdp;
   input             ce_pix;
   input             ce_sp;
   input             sp64;
   input [13:7]      table_address;
   input [2:0]       char_high_bits;
   input             tall;
   input             wide;
   input             shift;
   input             smode_M1;
   input             smode_M3;
   input             smode_M4;
   output reg [13:0] vram_A;
   input [7:0]       vram_D;
   input [8:0]       x;
   input [8:0]       y;
   output reg        collide;
   output reg        overflow;
   output reg [3:0]  color;
   
   parameter         WAITING = 3'b000;
   parameter         COMPARE = 3'b001;
   parameter         LOAD_N = 3'b010;
   parameter         LOAD_X = 3'b011;
   parameter         LOAD_0 = 3'b100;
   parameter         LOAD_1 = 3'b101;
   parameter         LOAD_2 = 3'b110;
   parameter         LOAD_3 = 3'b111;
   
   reg [2:0]         state;
   reg [6:0]         count;
   reg [5:0]         index;
   reg [13:0]        data_address;
   wire              ce_spload;
   reg [7:0]         m2_flags;
   
   reg               enable[0:MAX_SPPL];
   reg [7:0]         spr_x[0:MAX_SPPL];
   reg [7:0]         spr_d0[0:MAX_SPPL];
   reg [7:0]         spr_d1[0:MAX_SPPL];
   reg [7:0]         spr_d2[0:MAX_SPPL];
   reg [7:0]         spr_d3[0:MAX_SPPL];
   
   wire [3:0]        spr_color[0:MAX_SPPL];
   wire [MAX_SPPL:0] spr_active;
   
   generate
      begin : xhdl0
         genvar i;
         for (i = 0; i <= MAX_SPPL; i = i + 1)
         begin : shifters
            vpd_sprite_shifter shifter(
               .clk_sys(clk_sys),
               .ce_pix(ce_pix),
               .x(x[7:0]),
               .spr_x(spr_x[i]),
               // as we pass only 8 bits for the x address, we need to make the difference
               // between x=255 and x=511 in some way inside the shifters, or we'll have spurious
               // signals difficult to filter outside them. The compare operators are kept
               // outside the module to avoid to have them duplicated 64 times.
               .load(shift == 1'b0 & x < 256),  //load range
               .x248(shift & (x < 248 | x >= 504) & smode_M4), //load range for shifted sprites
               .x224(smode_M4 == 1'b0 & (x < 223 | x >= 480)), // load range for shifted mode2 spr
               .m4(smode_M4),
               .wide_n(wide == 1'b0),
               .spr_d0(spr_d0[i]),
               .spr_d1(spr_d1[i]),
               .spr_d2(spr_d2[i]),
               .spr_d3(spr_d3[i]),
               .color(spr_color[i]),
               .active(spr_active[i])
            );		
         end
      end
   endgenerate
   
   always @* begin
      case ({smode_M4, state})
         {1'b0, COMPARE}: vram_A = {table_address, index[4:0], 2'b00};
         {1'b0, LOAD_N}:  vram_A = {table_address, index[4:0], 2'b10};
         {1'b0, LOAD_X}:  vram_A = {table_address, index[4:0], 2'b01};
         {1'b0, LOAD_0}:  vram_A = {table_address, index[4:0], 2'b11};
         {1'b0, LOAD_1}:  vram_A = data_address;
         {1'b0, LOAD_2}:  vram_A = data_address;
         
         {1'b1, COMPARE}: vram_A = {table_address[13:8], 2'b00, index};
         {1'b1, LOAD_N}:  vram_A = {table_address[13:8], 1'b1, index, 1'b1};
         {1'b1, LOAD_X}:  vram_A = {table_address[13:8], 1'b1, index, 1'b0};
         {1'b1, LOAD_0}:  vram_A = {data_address[13:2], 2'b00};
         {1'b1, LOAD_1}:  vram_A = {data_address[13:2], 2'b01};
         {1'b1, LOAD_2}:  vram_A = {data_address[13:2], 2'b10};
         {1'b1, LOAD_3}:  vram_A = {data_address[13:2], 2'b11};
         
         default:         vram_A = 14'b0;
      endcase
   end

   assign ce_spload = (MAX_SPPL < 8 | sp64 == 1'b0) ? ce_vdp : ce_sp;
   
   always @(posedge clk_sys) begin
      reg [8:0]         y9;
      reg [8:0]         d9;
      reg [8:0]         delta;

      if (ce_spload) begin
         
         if (x == 257) begin		// we need step 256 to display the very last sprite pixel
                                 // and one more pixel because the test here is made sync'ed
                                 // by ce_spload which could be very early regarding ce_vdp
            count <= 0;
            enable <= '{(MAX_SPPL+1){1'b0}};
            state <= COMPARE;
            index <= {6{1'b0}};
            overflow <= 1'b0;
         
         end else if (x == 496)		//match vdp_main.vhd (384)
            state <= WAITING;
         else begin
            
            y9 = y;
            d9 = {1'b0, vram_D};
            if (d9 >= 240)
               d9 = d9 - 256;
            delta = y9 - d9;
            //overflow <= '0';
            
            case ({smode_M4, state})
               {1'b1, COMPARE} :
                  if (d9 == 208 & smode_M1 == 1'b0 & smode_M3 == 1'b0)		// hD0 stops only in 192 mode
                     state <= WAITING;		// stop
                  //	elsif delta(8 downto 4)="00000" and (delta(3)='0' or tall='1' or wide='1') then
                  else if (delta[8:5] == 4'b0000 & 
                           (delta[4] == 1'b0 | (tall & wide)) & 
                           (delta[3] == 1'b0 | tall | wide)) begin
                     if (wide)
                        data_address[5:2] <= delta[4:1];
                     else
                        data_address[5:2] <= delta[3:0];
                     if (count >= 8 & (y < 192 | (y < 224 & smode_M1) | (y < 240 & smode_M3)))
                        overflow <= 1'b1;
                     if ((count < MAX_SPPL + 1) & (count < 8 | sp64))
                        state <= LOAD_N;
                     else
                        state <= WAITING;
                  end else
                     if (index < 63)
                        index <= index + 1;
                     else
                        state <= WAITING;
               
               {1'b1, LOAD_N} :
                  begin
                     data_address[13] <= char_high_bits[2];
                     data_address[12:6] <= vram_D[7:1];
                     if (tall == 1'b0)		// or wide='1' 
                        data_address[5] <= vram_D[0];
                     state <= LOAD_X;
                  end
               
               {1'b1, LOAD_X} :
                  begin
                     spr_x[count] <= vram_D - 1;
                     state <= LOAD_0;
                  end
               
               {1'b1, LOAD_0} :
                  begin
                     spr_d0[count] <= vram_D;
                     state <= LOAD_1;
                  end
               
               {1'b1, LOAD_1} :
                  begin
                     spr_d1[count] <= vram_D;
                     state <= LOAD_2;
                  end
               
               {1'b1, LOAD_2} :
                  begin
                     spr_d2[count] <= vram_D;
                     state <= LOAD_3;
                  end
               
               {1'b1, LOAD_3} :
                  begin
                     spr_d3[count] <= vram_D;
                     enable[count] <= 1'b1;
                     state <= COMPARE;
                     index <= index + 1;
                     count <= count + 1;
                  end
               
               // mode 2  -----------
               
               {1'b0, COMPARE} :
                  if (d9 == 208)
                     state <= WAITING;
                  else if (delta[8:5] == 4'b0000 & 
                          (delta[4] == 1'b0 | (tall & wide)) & 
                          (delta[3] == 1'b0 | tall | wide)) begin
                     data_address[13:11] <= char_high_bits;
                     if (wide)
                        data_address[3:0] <= delta[4:1];
                     else
                        data_address[3:0] <= delta[3:0];
                     if ((count < 32) & (count < 4 | sp64))
                        state <= LOAD_N;
                     else
                        state <= WAITING;
                  end 
                  else
                     if (index < 31)
                        index <= index + 1;
                     else
                        state <= WAITING;
               
               {1'b0, LOAD_N} :
                  begin
                     if (tall)
                        data_address[10:4] <= vram_D[7:1];		// quadrant C
                     else
                        data_address[10:3] <= vram_D;		// quadrant A
                     state <= LOAD_0;
                  end
               
               {1'b0, LOAD_0} :
                  begin
                     //if (delta(3)='1') then
                     //	data_address <= data_address+8 ;
                     //end if;
                     m2_flags <= vram_D;
                     state <= LOAD_X;
                  end
               
               {1'b0, LOAD_X} :
                  begin
                     if (m2_flags[7] == 1'b0)
                        spr_x[count] <= vram_D - 1;
                     else
                        spr_x[count] <= vram_D - 33;
                     state <= LOAD_1;
                  end
               
               {1'b0, LOAD_1} :
                  begin
                     // in m2 mode, spr_d0 & 1 contains 16-bit shift data
                     // and color goes to spr_d3
                     spr_d0[count] <= vram_D;
                     spr_d1[count] <= 0;
                     spr_d2[count] <= 0;
                     spr_d3[count] <= m2_flags;
                     data_address[10:4] <= data_address[10:4] + 1;		// quadrants B & D
                     state <= LOAD_2;
                  end
               
               {1'b0, LOAD_2} :
                  begin
                     if (tall)
                        spr_d1[count] <= vram_D;
                     enable[count] <= 1'b1;
                     state <= COMPARE;
                     index <= index + 1;
                     count <= count + 1;
                  end
               
               default :
                  ;
            endcase
         end
      end 
   end
   
   
   always @(posedge clk_sys) begin
      reg [7:0]         collision;
      integer           i;

      if (ce_pix) begin		// ce_vdp?? 
         color <= {4{1'b0}};
         collision = {8{1'b0}};
         for (i = MAX_SPPL; i >= 8; i = i - 1)
            if (enable[i] & spr_active[i])		// and not (spr_color(i)="0000") then
               color <= spr_color[i];
         for (i = 7; i >= 0; i = i - 1)
            if (enable[i] & spr_active[i]) begin		// and not (spr_color(i)="0000") then
               collision[i] = 1'b1;
               color <= spr_color[i];
            end 
         case (collision)
            8'h00, 8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80 :
               collide <= 1'b0;
            default :
               if (y < 192 | (y < 224 & smode_M1) | (y < 240 & smode_M3) | y[8])
                  collide <= 1'b1;
               else
                  collide <= 1'b0;
         endcase
      end 
   end
   
endmodule

