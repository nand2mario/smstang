
module system(clk_sys, ce_cpu, ce_vdp, ce_pix, ce_sp, turbo, gg, ggres, systeme, bios_en, GG_EN, GG_CODE, GG_RESET, GG_AVAIL, RESET_n, rom_rd, rom_a, rom_do, j1_up, j1_down, j1_left, j1_right, j1_tl, j1_tr, j1_th, j1_start, j1_coin, j1_a3, j2_up, j2_down, j2_left, j2_right, j2_tl, j2_tr, j2_th, j2_start, j2_coin, j2_a3, pause, E0Type, E1Use, E2Use, E0, F2, F3, has_paddle, has_pedal, paddle, paddle2, pedal, j1_tr_out, j1_th_out, j2_tr_out, j2_th_out, x, y, color, palettemode, mask_column, black_column, smode_M1, smode_M2, smode_M3, ysj_quirk, pal, region, mapper_lock, vdp_enables, psg_enables, audioL, audioR, fm_ena, dbr, sp64, ram_a, ram_d, ram_we, ram_q, nvram_a, nvram_d, nvram_we, nvram_q, encrypt, key_a, key_d, ROMCL, ROMAD, ROMDT, ROMEN);
   parameter          MAX_SPPL = 7;
   parameter [32*8:1] BASE_DIR = "";
   input              clk_sys;
   input              ce_cpu;
   input              ce_vdp;
   input              ce_pix;
   input              ce_sp;
   input              turbo;
   input              gg;
   input              ggres;
   input              systeme;
   // sg:			in	 STD_LOGIC;		-- sg1000
   input              bios_en;
   
   input              GG_EN;		// Game Genie not game gear
   input [128:0]      GG_CODE;		// game genie code
   input              GG_RESET;
   output             GG_AVAIL;
   
   input              RESET_n;
   
   output             rom_rd;    // cartridge read
   output reg [21:0]  rom_a;
   input [7:0]        rom_do;
   
   input              j1_up;
   input              j1_down;
   input              j1_left;
   input              j1_right;
   input              j1_tl;     // button1: trigger left
   input              j1_tr;     // button2: trigger right
   input              j1_th;     // TH pin used for controller type detection and paddle/lightgun. see also j1_th_out
   input              j1_start;  // start button (SMS Power Base Converter/pause button)
   input              j1_coin;   // coin button (for arcade games)
   input              j1_a3;     // extra button input (for some peripherals)
   input              j2_up;
   input              j2_down;
   input              j2_left;
   input              j2_right;
   input              j2_tl;
   input              j2_tr;
   input              j2_th;
   input              j2_start;
   input              j2_coin;
   input              j2_a3;
   input              pause;
   
   input [1:0]        E0Type;
   input              E1Use;
   input              E2Use;
   input [7:0]        E0;
   input [7:0]        F2;
   input [7:0]        F3;
   
   input              has_paddle;
   input              has_pedal;
   input [7:0]        paddle;
   input [7:0]        paddle2;
   input [7:0]        pedal;
   
   output             j1_tr_out;
   output             j1_th_out;
   output             j2_tr_out;
   output             j2_th_out;
   
   input [8:0]        x;
   input [8:0]        y;
   output [11:0]      color;
   input              palettemode;
   output             mask_column;
   input              black_column;
   output             smode_M1;
   output             smode_M2;
   output             smode_M3;
   input              ysj_quirk;
   input              pal;
   input              region;
   input              mapper_lock;
   input [1:0]        vdp_enables;
   input [1:0]        psg_enables;
   
   output [15:0]      audioL;
   output [15:0]      audioR;
   input              fm_ena;
   
   input              dbr;
   input              sp64;
   
   // Work RAM
   output [13:0]      ram_a;
   output [7:0]       ram_d;
   output             ram_we;
   input [7:0]        ram_q;
   
   // Backup RAM
   output [14:0]      nvram_a;
   output [7:0]       nvram_d;
   output             nvram_we;
   input [7:0]        nvram_q;
   
   // MC8123 decryption
   input [1:0]        encrypt;
   output [12:0]      key_a;
   input [7:0]        key_d;
   
   input              ROMCL;
   input [24:0]       ROMAD;
   input [7:0]        ROMDT;
   input              ROMEN;
   
   
   wire               RD_n;
   wire               WR_n;
   wire               IRQ_n;
   wire               IORQ_n;
   wire               M1_n;
   wire               MREQ_n;
   wire [15:0]        A;
   wire [7:0]         D_in;
   reg [7:0]          D_out;
   reg [15:0]         last_read_addr;
   wire               ce_z80;
   
   wire               vdp_RD_n;
   wire               vdp_WR_n;
   wire [7:0]         vdp_D_out;
   wire               vdp_IRQ_n;
   wire [11:0]        vdp_color;
   //	signal vdp_y1:				std_logic;
   wire               vdp2_RD_n;
   wire               vdp2_WR_n;
   wire [7:0]         vdp2_D_out;
   wire               vdp2_IRQ_n;
   wire [11:0]        vdp2_color;
   wire               vdp2_y1;
   
   wire               ctl_WR_n;
   
   wire               io_RD_n;
   wire               io_WR_n;
   wire [7:0]         io_D_out;
   
   wire               ram_WR;
   wire [7:0]         ram_D_out;
   
   wire               vram_WR;
   wire               vram2_WR;
   
   wire [7:0]         boot_rom_D_out;
   
   reg                bootloader_n;
   wire [7:0]         irom_D_out;
   wire               irom_RD_n;
   
   reg [7:0]          bank0;
   reg [7:0]          bank1;
   reg [7:0]          bank2;
   reg [7:0]          bank3;
   
   wire               vdp_se_bank;
   wire               vdp2_se_bank;
   wire               vdp_cpu_bank;
   wire [3:0]         rom_bank;
   
   wire               PSG_disable;
   wire [10:0]        PSG_outL;
   wire [10:0]        PSG_outR;
   reg [7:0]          PSG_mux;
   wire               psg_WR_n;
   wire               bal_WR_n;
   wire [10:0]        PSG2_outL;
   wire [10:0]        PSG2_outR;
   wire               psg2_WR_n;
   wire               bal2_WR_n;
   
   wire [13:0]        FM_out;
   wire [12:0]        FM_gated;
   `define FM_sign FM_out[13]
   `define FM_adj FM_out[12]
   reg                fm_a;
   reg [7:0]          fm_d;
   wire               fm_WR_n;
   
   wire [12:0]        mix_inL;
   wire [12:0]        mix_inR;
   wire [12:0]        mix2_inL;
   wire [12:0]        mix2_inR;
   
   reg [2:0]          det_D;
   wire               det_WR_n;
   
   wire               HL;
   wire               TH_Ain;
   wire               TH_Bin;
   
   wire               nvram_WR;
   reg                nvram_e;
   reg                nvram_ex;
   reg                nvram_p;
   reg                nvram_cme;		// codemasters ram extension
   wire [7:0]         nvram_D_out;
   
   reg                lock_mapper_B;
   reg                mapper_codies;		// Ernie Els Golf mapper
   reg                mapper_codies_lock;
   
   reg                mapper_msx_check0;
   reg                mapper_msx_check1;
   reg                mapper_msx_lock0;
   reg                mapper_msx_lock;
   reg                mapper_msx;
   
   wire [7:0]         mc8123_D_out;
   wire [7:0]         segadect2_D_out;
   
   wire               GENIE;
   wire [7:0]         GENIE_DO;
   wire [7:0]         GENIE_DI;
   
   // Game Genie
   CODES #(.ADDR_WIDTH(16), .DATA_WIDTH(8)) GAMEGENIE(
      .clk(clk_sys), 
      .reset(GG_RESET), 
      .enable((~GG_EN)), 
      .addr_in(A), 
      .data_in(D_out), 
      .code(GG_CODE), 
      .available(GG_AVAIL), 
      .genie_ovr(GENIE), 
      .genie_data(GENIE_DO));
   
   assign GENIE_DI = (GENIE) ? GENIE_DO : D_out;
   
   T80s #(.T2Write(0)) z80_inst(
      .RESET_n(RESET_n), 
      .CLK(clk_sys), 
      .CEN(ce_z80), 
      .INT_n(IRQ_n), 
      .NMI_n(pause | gg), 
      .MREQ_n(MREQ_n), 
      .IORQ_n(IORQ_n), 
      .M1_n(M1_n), 
      .RD_n(RD_n), 
      .WR_n(WR_n), 
      .A(A), 
      .DI(GENIE_DI), 
      .DO(D_in),
      .WAIT_n(1'b1),
      .BUSRQ_n(1'b1) );
   
   vdp #(MAX_SPPL) vdp_inst(
      .clk_sys(clk_sys), 
      .ce_vdp(ce_vdp), 
      .ce_pix(ce_pix), 
      .ce_sp(ce_sp), 
      .sp64(sp64), 
      .HL(HL), 
      .gg(gg), 
      .ggres(ggres), 
      .se_bank(vdp_se_bank), 
      .RD_n(vdp_RD_n), 
      .WR_n(vdp_WR_n), 
      .IRQ_n(vdp_IRQ_n), 
      .WR_direct(vram_WR), 
      .A_direct(A[13:8]), 
      .A(A[7:0]), 
      .D_in(D_in), 
      .D_out(vdp_D_out), 
      .x(x), 
      .y(y), 
      .color(vdp_color), 
      .palettemode(palettemode), 
      .smode_M1(smode_M1), 
      .smode_M2(smode_M2), 
      .smode_M3(smode_M3), 
      .ysj_quirk(ysj_quirk), 
      .mask_column(mask_column), 
      .black_column(black_column), 
      .reset_n(RESET_n));
   
   vdp #(MAX_SPPL) vdp2_inst(
      .clk_sys(clk_sys),
      .ce_vdp(ce_vdp),
      .ce_pix(ce_pix),
      .ce_sp(ce_sp),
      .sp64(sp64),
      .HL(HL),
      .gg(gg),
      .ggres(ggres),
      .se_bank(vdp2_se_bank),
      .RD_n(vdp2_RD_n),
      .WR_n(vdp2_WR_n),
      .IRQ_n(vdp2_IRQ_n),
      .WR_direct(vram2_WR),
      .A_direct(A[13:8]),
      .A(A[7:0]),
      .D_in(D_in),
      .D_out(vdp2_D_out),
      .x(x),
      .y(y),
      .color(vdp2_color),
      .palettemode(palettemode),
      .y1(vdp2_y1),
      .ysj_quirk(ysj_quirk),
      .black_column(black_column),
      .reset_n(RESET_n)
   );
   
   jt89 psg_inst(
      .clk(clk_sys),
      .clk_en(ce_cpu),
      .wr_n(psg_WR_n),
      .din(D_in),
      .mux(PSG_mux),
      .soundL(PSG_outL),
      .soundR(PSG_outR),
      .rst((~RESET_n))
   );
   
   jt89 psg2_inst(
      .clk(clk_sys),
      .clk_en(ce_cpu),
      .wr_n(psg2_WR_n),
      .din(D_in),
      .mux(PSG_mux),
      .soundL(PSG2_outL),
      .soundR(PSG2_outR),
      .rst((~RESET_n))
   );

   opll fm(
      .xin(clk_sys),
      .xena(ce_cpu),
      .d(fm_d),
      .a(fm_a),
      .cs_n(1'b0),
      .we_n(1'b0),
      .ic_n(RESET_n),
      .mixout(FM_out)
   );

   always @(posedge clk_sys) begin
      if (RESET_n == 1'b0) begin
         fm_d <= {8{1'b0}};
         fm_a <= 1'b0;
      end else if (fm_WR_n == 1'b0) begin
         fm_d <= D_in;
         fm_a <= A[0];
      end 
   end 
   
   // AMR - Clamped volume boosting - if the top two bits match, truncate the topmost bit.
   // If the top two bits don't match, duplicate the second bit across the output.
   
   assign FM_gated = (fm_ena == 1'b0 | det_D[0] == 1'b0) ? {13{1'b0}} : 		// All zero if FM is disabled
                     (`FM_sign == `FM_adj) ? FM_out[13 - 1:0] : 		// Pass through
                     {`FM_sign, {12{`FM_adj}}};		// Clamp
   
   assign PSG_disable = systeme == 1'b0 & fm_ena & ~det_D[1] == det_D[0] ? 1'b1 : 1'b0;
   
   assign mix_inL = (psg_enables[0] | PSG_disable) ? {13{1'b0}} : {PSG_outL[10], PSG_outL, 1'b0};
   assign mix_inR = (psg_enables[0] | PSG_disable) ? {13{1'b0}} : {PSG_outR[10], PSG_outR, 1'b0};
   assign mix2_inL = psg_enables[1] ? {13{1'b0}} : systeme ? {PSG2_outL[10], PSG2_outL, 1'b0} : FM_gated;
   assign mix2_inR = psg_enables[1] ? {13{1'b0}} : systeme ? {PSG2_outR[10], PSG2_outR, 1'b0} : FM_gated;
   
   // The old code shifts FM right by one place and PSG right by three places.
   // This version shift FM left one place and PSG right by one place, so the volume
   // is four times higher.  I haven't yet found a game in which this clips.
   
   AudioMix mix(
      .clk(clk_sys),
      .reset_n(RESET_n),
      .audio_in_l1(signed'({mix_inL, 3'b000})),
      .audio_in_l2(signed'({mix2_inL, 3'b000})),
      .audio_in_r1(signed'({mix_inR, 3'b000})),
      .audio_in_r2(signed'({mix2_inR, 3'b000})),
      .audio_l(audioL),
      .audio_r(audioR)
   );
   
   //	audioL <= (PSG_outL(10) & PSG_outL(10) & PSG_outL(10) & PSG_outL & "00") + (FM_out(13) & FM_out & "0") when fm_ena = '1'
   //	     else (PSG_outL(10) & PSG_outL(10) & PSG_outL(10) & PSG_outL & "00");
   //	audioR <= (PSG_outR(10) & PSG_outR(10) & PSG_outR(10) & PSG_outR & "00") + (FM_out(13) & FM_out & "0") when fm_ena = '1'
   //	     else (PSG_outR(10) & PSG_outR(10) & PSG_outR(10) & PSG_outL & "00");
   
   io io_inst(
      .clk(clk_sys), .WR_n(io_WR_n), .RD_n(io_RD_n), .A(A[7:0]),
      .D_in(D_in), .D_out(io_D_out), .HL_out(HL), .vdp1_bank(vdp_se_bank),
      .vdp2_bank(vdp2_se_bank), .vdp_cpu_bank(vdp_cpu_bank), .rom_bank(rom_bank), .J1_tr_out(j1_tr_out),
      .J1_th_out(j1_th_out), .J2_tr_out(j2_tr_out), .J2_th_out(j2_th_out), .J1_up(j1_up),
      .J1_down(j1_down), .J1_left(j1_left), .J1_right(j1_right), .J1_tl(j1_tl),
      .J1_tr(j1_tr), .J1_th(j1_th), .J1_start(j1_start), .J1_coin(j1_coin),
      .J1_a3(j1_a3), .J2_up(j2_up), .J2_down(j2_down), .J2_left(j2_left),
      .J2_right(j2_right), .J2_tl(j2_tl), .J2_tr(j2_tr), .J2_th(j2_th),
      .J2_start(j2_start), .J2_coin(j2_coin), .J2_a3(j2_a3), .Pause(pause),
      .E0Type(E0Type), .E1Use(E1Use), .E2Use(E2Use), .E0(E0),
      .F2(F2), .F3(F3), .has_paddle(has_paddle), .has_pedal(has_pedal),
      .paddle(paddle), .paddle2(paddle2), .pedal(pedal), .pal(pal),
      .gg(gg), .systeme(systeme), .region(region), .RESET_n(RESET_n)
   );
   
   assign ce_z80 = (systeme | turbo) ? ce_pix : ce_cpu;
   
   assign ram_a = systeme ? A[13:0] : {1'b0, A[12:0]};
   assign ram_we = ram_WR;
   assign ram_d = D_in;
   assign ram_D_out = ram_q;
   
   assign nvram_a = {(nvram_p & (~A[14])), A[13:0]};
   assign nvram_we = nvram_WR;
   assign nvram_d = D_in;
   assign nvram_D_out = nvram_q;
   
   // 16KB Boot ROM
   sprom #(.widthad_a(14), .init_file("mboot.hex")) boot_rom_inst(
      .clock(clk_sys), .address(A[13:0]), .q(boot_rom_D_out));
   
   MC8123_rom_decrypt mc8123_inst(
      .clk(clk_sys), .m1((~M1_n)), .a(A), .d(mc8123_D_out), .prog_d(rom_do), .key_a(key_a), .key_d(key_d));
   
   SEGASYS1_DECT2 segadect2_inst(
      .clk(clk_sys), .mrom_m1((~M1_n)), .mrom_ad(A[14:0]), .mrom_dt(segadect2_D_out), 
      .rdt(rom_do), .ROMCL(ROMCL), .ROMAD(ROMAD), .ROMDT(ROMDT), .ROMEN(ROMEN));
   
   // glue logic
   assign bal_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:0] == 8'b00000110 & gg) ? WR_n : 1'b1;
   assign vdp_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:6] == 2'b10 & (A[2] == 1'b0 | systeme == 1'b0)) ? WR_n : 1'b1;
   assign vdp2_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:6] == 2'b10 & (A[2] & systeme)) ? WR_n : 1'b1;
   assign vdp_RD_n = (IORQ_n == 1'b0 & M1_n & (A[7:6] == 2'b01 | A[7:6] == 2'b10) & (A[2] == 1'b0 | systeme == 1'b0)) ? RD_n : 1'b1;
   assign vdp2_RD_n = (IORQ_n == 1'b0 & M1_n & (A[7:6] == 2'b01 | A[7:6] == 2'b10) & (A[2] & systeme)) ? RD_n : 1'b1;
   assign psg_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:6] == 2'b01 & (A[2] == 1'b0 | systeme == 1'b0)) ? WR_n : 1'b1;
   assign psg2_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:6] == 2'b01 & (A[2] & systeme)) ? WR_n : 1'b1;
   assign ctl_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:6] == 2'b00 & A[0] == 1'b0) ? WR_n : 1'b1;
   assign io_WR_n = (IORQ_n == 1'b0 & M1_n & ((A[7:6] == 2'b00 & (A[0] | (gg & A[5:3] == 3'b000))) | (A[7:6] == 2'b11 & systeme))) ? WR_n : 1'b1;
   assign io_RD_n = (IORQ_n == 1'b0 & M1_n & (A[7:6] == 2'b11 | (gg & A[7:3] == 5'b00000 & A[2:1] != 2'b11))) ? RD_n : 1'b1;
   assign fm_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:1] == 7'b1111000) ? WR_n : 1'b1;
   assign det_WR_n = (IORQ_n == 1'b0 & M1_n & A[7:0] == 8'hF2) ? WR_n : 1'b1;
   assign IRQ_n = (systeme == 1'b0) ? vdp_IRQ_n : vdp2_IRQ_n;
   
   assign ram_WR = (MREQ_n == 1'b0 & A[15:14] == 2'b11) ? (~WR_n) : 1'b0;
   assign vram_WR = (MREQ_n == 1'b0 & A[15:14] == 2'b10 & vdp_cpu_bank & systeme) ? (~WR_n) : 1'b0;
   assign vram2_WR = (MREQ_n == 1'b0 & A[15:14] == 2'b10 & vdp_cpu_bank == 1'b0 & systeme) ? (~WR_n) : 1'b0;
   assign nvram_WR = (MREQ_n == 1'b0 & ((A[15:14] == 2'b10 & nvram_e) 
                                      | (A[15:14] == 2'b11 & nvram_ex) 
                                      | (A[15:13] == 3'b101 & nvram_cme))) ? (~WR_n) : 1'b0;
   assign rom_rd = (MREQ_n == 1'b0 & A[15:14] != 2'b11) ? (~RD_n) : 1'b0;
   assign color = (vdp2_y1 & systeme & vdp_enables[1] == 1'b0) ? vdp2_color : 
                  vdp_enables[0] == 1'b0 ? vdp_color : 
                  12'h000;
   
   always @(posedge clk_sys) begin
      if (RESET_n == 1'b0)
         bootloader_n <= ~bios_en;
      else if (ctl_WR_n == 1'b0 & bootloader_n == 1'b0)
         bootloader_n <= 1'b1;
   end 
   
   assign irom_D_out = (bootloader_n == 1'b0 & A[15:14] == 2'b00) ? boot_rom_D_out : 
                       (encrypt[1:0] == 2'b10 & A[15] == 1'b0) ? segadect2_D_out : 
                       (encrypt[0] & A[15] == 1'b0 | encrypt[1:0] == 2'b11 & A[14] == 1'b0) ? mc8123_D_out : 
                       rom_do;
   
   always @(posedge clk_sys) begin
      if (RESET_n == 1'b0) begin
         det_D <= 3'b111;
         PSG_mux <= 8'hFF;
      end else if (det_WR_n == 1'b0)
         det_D <= D_in[2:0];
      else if (bal_WR_n == 1'b0)
         PSG_mux <= D_in;
   end 
   
   
   always @*
      if (IORQ_n == 1'b0) begin
         if (A[7:0] == 8'hF2 & fm_ena & systeme == 1'b0)
            D_out = {5'b11111, det_D};
         else if (A[7:6] == 2'b11 | (gg & A[7:3] == 5'b00000 & A[2:0] != 3'b111)) begin
            D_out[6:0] = io_D_out[6:0];
            // during bootload, we trick the io ports so bit 7 indicates gg or sms game
            if (bootloader_n == 1'b0)
               D_out[7] = gg;
            else
               D_out[7] = io_D_out[7];
         end else if (A[2] & systeme)
            D_out = vdp2_D_out;
         else
            D_out = vdp_D_out;
      end else
         if (A[15:14] == 2'b11 & nvram_ex)
            D_out = nvram_D_out;
         else if (A[15:14] == 2'b11 & nvram_ex == 1'b0)
            D_out = ram_D_out;
         else if (A[15:13] == 3'b101 & nvram_cme)
            D_out = nvram_D_out;
         else if (A[15:14] == 2'b10 & nvram_e)
            D_out = nvram_D_out;
         else
            D_out = irom_D_out;
   
   // detect MSX mapper : we check the two first bytes of the rom, must be 41:42
   always @(negedge RESET_n or posedge clk_sys)
      if (RESET_n == 1'b0) begin
         mapper_msx_check0 <= 1'b0;
         mapper_msx_check1 <= 1'b0;
         mapper_msx_lock0 <= 1'b0;
         mapper_msx_lock <= 1'b0;
         mapper_msx <= 1'b0;
      end else begin
         if (bootloader_n & (~mapper_msx_lock)) begin
            if (MREQ_n == 1'b0) begin
               // in this state, A is stable but not D_out
               if (A == 16'h0000)
                  mapper_msx_check0 <= (D_out == 8'h41);
               else if (A == 16'h0001) begin
                  mapper_msx_check1 <= (D_out == 8'h42);
                  mapper_msx_lock0 <= 1'b1;
               end 
            end else begin
               // this state is similar to old_MREQ_n
               // now we can lock values depending on D_out
               if (mapper_msx_check0 & mapper_msx_check1)
                  mapper_msx <= 1'b1;		// if 4142 lock msx mapper on
               // be paranoid : give only 1 chance to the mapper to lock on
               mapper_msx_lock <= mapper_msx_lock0;
            end
         end 
      end 
   
   // external ram control
   always @(negedge RESET_n or posedge clk_sys)
      if (RESET_n == 1'b0) begin
         bank0 <= 8'b00000000;
         bank1 <= 8'b00000001;
         bank2 <= 8'b00000010;
         bank3 <= 8'b00000011;
         nvram_e <= 1'b0;
         nvram_ex <= 1'b0;
         nvram_p <= 1'b0;
         nvram_cme <= 1'b0;
         lock_mapper_B <= 1'b0;
         mapper_codies <= 1'b0;
         mapper_codies_lock <= 1'b0;
      end else begin
         if (WR_n & MREQ_n == 1'b0)
            last_read_addr <= A;		// gyurco anti-ldir patch
         if (systeme)
            ;
         // no systeme mappers
         else if (mapper_msx) begin
            if (WR_n == 1'b0 & A[15:2] == 14'b00000000000000)
               case (A[1:0])
                  2'b00 :
                     bank2 <= D_in;
                  2'b01 :
                     bank3 <= D_in;
                  2'b10 :
                     bank0 <= D_in;
                  2'b11 :
                     bank1 <= D_in;
               endcase
         end 
         else begin
            if (WR_n == 1'b0 & A[15:2] == 14'b11111111111111) begin
               mapper_codies <= 1'b0;
               case (A[1:0])
                  2'b00 :
                     begin
                        nvram_ex <= D_in[4];
                        nvram_e <= D_in[3];
                        nvram_p <= D_in[2];
                     end
                  2'b01 :
                     bank0 <= D_in;
                  2'b10 :
                     bank1 <= D_in;
                  2'b11 :
                     bank2 <= D_in;
               endcase
            end 
            if (WR_n == 1'b0 & nvram_e == 1'b0 & mapper_lock == 1'b0)
               case (A[15:0])
                  // Codemasters
                  // do not accept writing in adr $0000 (canary) unless we are sure that Codemasters mapper is in use
                  16'h0000 :
                     if (lock_mapper_B) begin
                        bank0 <= D_in;
                        // we need a strong criteria to set mapper_codies, hopefully only Ernie Els Golf
                        // will have written a zero in $4000 before coming here
                        if (D_in != 8'b00000000 & mapper_codies_lock == 1'b0) begin
                           if (bank1 == 8'b00000001)
                              mapper_codies <= 1'b1;
                           mapper_codies_lock <= 1'b1;
                        end 
                     end 
                  16'h4000 :
                     if (last_read_addr != 16'h4000) begin		// gyurco anti-ldir patch
                        bank1[6:0] <= D_in[6:0];
                        bank1[7] <= 1'b0;
                        // mapper_codies <= mapper_codies or D_in(7) ;
                        nvram_cme <= D_in[7];
                        lock_mapper_B <= 1'b1;
                     end 
                  16'h8000 :
                     if (last_read_addr != 16'h8000) begin		// gyurco anti-ldir patch
                        bank2 <= D_in;
                        lock_mapper_B <= 1'b1;
                     end 
                  // Korean mapper (Sangokushi 3, Dodgeball King)
                  16'hA000 :
                     if (last_read_addr != 16'hA000) begin		// gyurco anti-ldir patch
                        if (mapper_codies == 1'b0)
                           bank2 <= D_in;
                     end 
                  default :
                     ;
               endcase
         end
      end 
   
   assign rom_a[12:0] = A[12:0];
   
   always @*
      if (systeme)
         case (A[15:14])
            2'b10 :
               rom_a[21:13] = {4'b0000, rom_bank, A[13]};
            default :
               rom_a[21:13] = {6'b000100, A[15:13]};
         endcase
      else if (mapper_msx)
         case (A[15:13])
            3'b010 :
               rom_a[21:13] = {1'b0, bank0};
            3'b011 :
               rom_a[21:13] = {1'b0, bank1};
            3'b100 :
               rom_a[21:13] = {1'b0, bank2};
            3'b101 :
               rom_a[21:13] = {1'b0, bank3};
            default :
               rom_a[21:13] = {6'b000000, A[15:13]};
         endcase
      else begin
         rom_a[13] = A[13];
         case (A[15:14])
            2'b00 :
               // first kilobyte is always from bank 0
               if (A[13:10] == 4'b0000 & mapper_codies == 1'b0)
                  rom_a[21:14] = {22{1'b0}};
               else
                  rom_a[21:14] = bank0;
            
            2'b01 :
               rom_a[21:14] = bank1;
            
            default :
               rom_a[21:14] = bank2;
         endcase
      end
   
endmodule

