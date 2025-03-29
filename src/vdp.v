
module vdp(clk_sys, ce_vdp, ce_pix, ce_sp, gg, ggres, se_bank, sp64, HL, RD_n, WR_n, IRQ_n, WR_direct, A_direct, A, D_in, D_out, x, y, color, palettemode, y1, mask_column, black_column, smode_M1, smode_M2, smode_M3, smode_M4, ysj_quirk, reset_n);
   parameter     MAX_SPPL = 7;
   input         clk_sys;
   input         ce_vdp;
   input         ce_pix;
   input         ce_sp;
   input         gg;
   input         ggres;
   input         se_bank;
   input         sp64;
   input         HL;
   input         RD_n;
   input         WR_n;
   output reg    IRQ_n;
   input         WR_direct;
   input [13:8]  A_direct;
   input [7:0]   A;
   input [7:0]   D_in;
   output reg [7:0] D_out;
   input [8:0]   x;
   input [8:0]   y;
   output [11:0] color;
   input         palettemode;
   output        y1;
   output        mask_column;
   input         black_column;
   output        smode_M1;
   output        smode_M2;
   output        smode_M3;
   output        smode_M4;
   input         ysj_quirk;
   input         reset_n;
   
   
   reg           old_RD_n;
   reg           old_WR_n;
   reg           old_HL;
   reg           old_WR_direct;
   
   // helper bits
   reg           data_write;
   reg           address_ff;
   reg           to_cram;
   wire          spr_collide;
   wire          spr_overflow;
   
   // vram and cram lines for the cpu interface
   wire [14:0]   vram_cpu_A;
   reg [13:0]    xram_cpu_A;
   wire          vram_cpu_WE;
   wire          cram_cpu_WE;
   wire [7:0]    vram_cpu_D_out;
   reg [7:0]     vram_cpu_D_outl;
   reg           xram_cpu_A_incr;
   reg           xram_cpu_read;
   
   // vram and cram lines for the video interface
   wire [13:0]   vram_vdp_A;
   wire [7:0]    vram_vdp_D;
   wire [4:0]    cram_vdp_A;
   wire [11:0]   cram_vdp_D;
   wire [4:0]    cram_vdp_A_in;
   wire [11:0]   cram_vdp_D_in;
   
   // control bits
   reg           display_on;
   reg           disable_hscroll;
   reg           disable_vscroll;
   reg           mask_column0;
   reg [3:0]     overscan;
   reg           irq_frame_en;
   reg           irq_line_en;
   reg [7:0]     irq_line_count = 8'hFF;
   reg [3:0]     bg_address;
   reg [2:0]     m2mg_address;
   reg [7:0]     m2ct_address = 8'hFF;
   reg [7:0]     bg_scroll_x;
   reg [7:0]     bg_scroll_y;
   reg [6:0]     spr_address;
   reg           spr_shift;
   reg           spr_tall;
   reg           spr_wide;
   reg [2:0]     spr_high_bits;
   
   // various counters
   reg           last_x0;
   reg           reset_flags;
   reg [2:0]     irq_delay = 3'b111;
   reg           collide_flag;		// signal collide to cpu via reg
   wire          collide_buf;		// collide pending
   reg [13:0]    xspr_collide_shift;		// collide delay
   reg           overflow_flag;		// signal overflow to cpu via reg
   reg           line_overflow;		// overflow alread occured on this line
   reg [7:0]     hbl_counter;
   reg           vbl_irq;
   reg           hbl_irq;
   reg [7:0]     latched_x;
   
   reg [7:0]     cram_latch;
   reg           mode_M1;
   reg           mode_M2;
   reg           mode_M3;
   reg           mode_M4;
   wire          xmode_M1;
   wire          xmode_M3;
   wire          xmode_M4;
   
   assign mask_column = mask_column0;
   assign xmode_M1 = mode_M1 & mode_M2;
   assign xmode_M3 = mode_M3 & mode_M2;
   assign xmode_M4 = mode_M4;
   
   vdp_main #(.MAX_SPPL(MAX_SPPL)) vdp_main_inst(
      .clk_sys(clk_sys), .ce_vdp(ce_vdp), .ce_pix(ce_pix),
      .ce_sp(ce_sp), .ggres(ggres), .sp64(sp64),
      .vram_A(vram_vdp_A), .vram_D(vram_vdp_D), .cram_A(cram_vdp_A),
      .cram_D(cram_vdp_D), .x(x), .y(y),
      .color(color), .palettemode(palettemode), .y1(y1),
      .smode_M1(xmode_M1), .smode_M3(xmode_M3), .smode_M4(xmode_M4),
      .ysj_quirk(ysj_quirk), .display_on(display_on), .mask_column0(mask_column0),
      .black_column(black_column), .overscan(overscan), .bg_address(bg_address),
      .m2mg_address(m2mg_address), .m2ct_address(m2ct_address), .bg_scroll_x(bg_scroll_x),
      .bg_scroll_y(bg_scroll_y), .disable_hscroll(disable_hscroll), .disable_vscroll(disable_vscroll),
      .spr_address(spr_address), .spr_high_bits(spr_high_bits), .spr_shift(spr_shift),
      .spr_tall(spr_tall), .spr_wide(spr_wide), .spr_collide(spr_collide),
      .spr_overflow(spr_overflow)
   );
   
   // TODO: dpram
   dpram #(.widthad_a(15)) vdp_vram_inst(
      .clock_a(clk_sys), .address_a(vram_cpu_A), .wren_a(vram_cpu_WE),
      .data_a(D_in), .q_a(vram_cpu_D_out), 
      
      .clock_b(clk_sys), .address_b({se_bank, vram_vdp_A}), .wren_b(1'b0), 
      .data_b(1'b0), .q_b(vram_vdp_D)
   );
   
   vdp_cram vdp_cram_inst(
      .cpu_clk(clk_sys), .cpu_we(cram_cpu_WE), .cpu_a(cram_vdp_A_in),
      .cpu_d(cram_vdp_D_in), .vdp_clk(clk_sys), .vdp_a(cram_vdp_A),
      .vdp_d(cram_vdp_D)
   );
   
   assign cram_vdp_A_in = (gg == 1'b0) ? xram_cpu_A[4:0] : xram_cpu_A[5:1];
   assign cram_vdp_D_in = (gg == 1'b0) ? ({D_in[5:4], D_in[5:4], D_in[3:2], D_in[3:2], D_in[1:0], D_in[1:0]}) : 
                          ({D_in[3:0], cram_latch});
   assign cram_cpu_WE = (to_cram & ((gg == 1'b0) | (xram_cpu_A[0])) & WR_direct == 1'b0) ? data_write : 1'b0;
   assign vram_cpu_WE = ((WR_direct | (~to_cram))) ? data_write : 1'b0;
   assign vram_cpu_A = (WR_direct) ? {(~se_bank), A_direct, A} : {se_bank, xram_cpu_A};
   
   assign smode_M1 = mode_M1 & mode_M2;
   assign smode_M2 = mode_M2;
   assign smode_M3 = mode_M3 & mode_M2;
   assign smode_M4 = mode_M4;
   
   always @(posedge clk_sys or negedge reset_n) begin
      reg           reset_set;

      if (reset_n == 1'b0) begin
         disable_hscroll <= 1'b0;		//36
         disable_vscroll <= 1'b0;
         mask_column0 <= 1'b1;		//
         irq_line_en <= 1'b1;		//
         spr_shift <= 1'b0;		//
         display_on <= 1'b0;		//80
         irq_frame_en <= 1'b0;		//
         spr_tall <= 1'b0;		//
         spr_wide <= 1'b0;		//
         bg_address <= 4'b1110;		//FF
         spr_address <= 7'b1111111;		//FF
         spr_high_bits <= 3'b000;		//FB
         overscan <= 4'b0000;		//00
         bg_scroll_x <= {8{1'b0}};		//00
         bg_scroll_y <= {8{1'b0}};		//00
         irq_line_count <= {8{1'b1}};		//FF
         reset_flags <= 1'b1;
         address_ff <= 1'b0;
         xram_cpu_read <= 1'b0;
         mode_M1 <= 1'b0;
         mode_M2 <= 1'b0;
         mode_M3 <= 1'b0;
         mode_M4 <= 1'b1;
      
      end else  begin
         data_write <= 1'b0;
         reset_set = 1'b0;
         
         old_HL <= HL;
         if (old_HL == 1'b0 & HL)
            latched_x <= x[8:1];
         
         if (ce_vdp) begin
            old_WR_n <= WR_n;
            old_RD_n <= RD_n;
            old_WR_direct <= WR_direct;
            
            if (old_WR_direct == 1'b0 & WR_direct)
               data_write <= 1'b1;
            if (old_WR_n & WR_n == 1'b0) begin
               if (A[0] == 1'b0) begin
                  data_write <= 1'b1;
                  xram_cpu_A_incr <= 1'b1;
                  address_ff <= 1'b0;
                  vram_cpu_D_outl <= D_in;
                  if (to_cram & xram_cpu_A[0] == 1'b0)
                     cram_latch <= D_in;
               end else begin
                  if (address_ff == 1'b0)
                     xram_cpu_A[7:0] <= D_in;
                  else begin
                     xram_cpu_A[13:8] <= D_in[5:0];
                     to_cram <= D_in[7:6] == 2'b11;
                     if (D_in[7:6] == 2'b00)
                        xram_cpu_read <= 1'b1;
                     case ({D_in[7:6], D_in[3:0]})
                        6'b100000 :
                           begin
                              disable_vscroll <= xram_cpu_A[7];
                              disable_hscroll <= xram_cpu_A[6];
                              mask_column0 <= xram_cpu_A[5];
                              irq_line_en <= xram_cpu_A[4];
                              spr_shift <= xram_cpu_A[3];
                              mode_M4 <= xram_cpu_A[2];
                              mode_M2 <= xram_cpu_A[1];
                           end
                        6'b100001 :
                           begin
                              display_on <= xram_cpu_A[6];
                              irq_frame_en <= xram_cpu_A[5];
                              mode_M1 <= xram_cpu_A[4];		// and not xram_cpu_A(3);
                              mode_M3 <= xram_cpu_A[3];		// and not xram_cpu_A(4);
                              spr_tall <= xram_cpu_A[1];
                              spr_wide <= xram_cpu_A[0];
                           end
                        6'b100010 :
                           bg_address <= xram_cpu_A[3:0];
                        6'b100011 :
                           m2ct_address <= xram_cpu_A[7:0];
                        6'b100100 :
                           m2mg_address <= xram_cpu_A[2:0];
                        6'b100101 :
                           spr_address <= xram_cpu_A[6:0];
                        6'b100110 :
                           spr_high_bits <= xram_cpu_A[2:0];
                        6'b100111 :
                           overscan <= xram_cpu_A[3:0];
                        6'b101000 :
                           bg_scroll_x <= xram_cpu_A[7:0];
                        6'b101001 :
                           bg_scroll_y <= xram_cpu_A[7:0];
                        6'b101010 :
                           irq_line_count <= xram_cpu_A[7:0];
                        default :
                           ;
                     endcase
                  end
                  address_ff <= (~address_ff);
               end
            
            end else if (old_RD_n & RD_n == 1'b0)
               case ({A[7:6], A[0]})
                  3'b010 :		// VCounter
                     D_out <= y[7:0];
                  3'b011 :		// HCounter
                     D_out <= latched_x;
                  3'b100 :		// Data port
                     begin
                        //D_out <= vram_cpu_D_out;
                        address_ff <= 1'b0;
                        D_out <= vram_cpu_D_outl;
                        xram_cpu_A_incr <= 1'b1;
                        xram_cpu_read <= 1'b1;
                     end
                  3'b101 :		//Ctrl port
                     begin
                        address_ff <= 1'b0;
                        D_out[7] <= vbl_irq;
                        D_out[6] <= overflow_flag;
                        D_out[5] <= collide_flag;
                        D_out[4:0] <= {8{1'b1}};		// to fix PGA Tour Golf course map introduction
                        reset_flags <= 1'b1;
                        reset_set = 1'b1;
                     end
                  default :
                     ;
               endcase
            else if (xram_cpu_A_incr) begin
               xram_cpu_A <= xram_cpu_A + 1;
               xram_cpu_A_incr <= 1'b0;
               if (xram_cpu_read)
                  vram_cpu_D_outl <= vram_cpu_D_out;
               xram_cpu_read <= 1'b0;
            end else if (xram_cpu_read)
               xram_cpu_A_incr <= 1'b1;
            if ((~reset_set))
               reset_flags <= 1'b0;
         end 
      end 
   end
   
   
   always @(posedge clk_sys) begin
      if (ce_vdp) begin
         //				485 instead of 487 to please VDPTEST 
         if (x == 485 & ((y == 224 & xmode_M1) | (y == 240 & xmode_M3) | (y == 192 & xmode_M1 == 1'b0 & xmode_M3 == 1'b0)) & (~(last_x0 == (x[0]))))
            vbl_irq <= 1'b1;
         else if (reset_flags)
            vbl_irq <= 1'b0;
      end 
   end 
   
   always @(posedge clk_sys) begin
      if (ce_vdp) begin
         last_x0 <= (x[0]);
         if (x == 486 & (~(last_x0 == (x[0])))) begin
            if (y < 192 | (y < 240 & xmode_M3) | (y < 224 & xmode_M1) | y == 511) begin
               if (hbl_counter == 0) begin
                  hbl_irq <= hbl_irq | irq_line_en;		// <=> if irq_line_en then hbl_irq<=1
                  hbl_counter <= irq_line_count;
               end else
                  hbl_counter <= hbl_counter - 1;
            end else
               hbl_counter <= irq_line_count;
         end else if (reset_flags)
            hbl_irq <= 1'b0;
      end 
   end 
   
   always @(posedge clk_sys) begin
      // using the other phase of ce_vdp permits to please VDPTEST ovr HCounter
      // very tight condition; 
      if (ce_vdp == 1'b0) begin
         if ((x < 256 | x > 485) & (y < 234 | y >= 496)) begin
            if (spr_overflow & line_overflow == 1'b0) begin
               overflow_flag <= 1'b1;
               line_overflow <= 1'b1;
            end 
         end else
            line_overflow <= 1'b0;
      end 
      
      if (ce_vdp) begin
         xspr_collide_shift[13:1] <= xspr_collide_shift[12:0];
         if (x <= 256)
            xspr_collide_shift[0] <= spr_collide;
         else
            xspr_collide_shift[0] <= 1'b0;
         if (xspr_collide_shift[13] & display_on & (y < 234 | (xmode_M1 == 1'b0 & xmode_M3 == 1'b0 & y >= 496)))
            collide_flag <= 1'b1;
         
         if (reset_flags) begin
            collide_flag <= 1'b0;
            overflow_flag <= 1'b0;
            line_overflow <= 1'b1;		// Spr over many lines   
         end 
         
         if (((vbl_irq & irq_frame_en) | (hbl_irq & irq_line_en)) & (~reset_flags)) begin
            if (irq_delay == 3'b000)
               IRQ_n <= 1'b0;
            else
               irq_delay <= irq_delay - 1;
         end else begin
            IRQ_n <= 1'b1;
            irq_delay <= 3'b111;
         end
      end 
   end 
   
endmodule

