/*
 * Sega Master System for Tang FPGAs
 * 
 * nand2mario, 3/2025
 */
module smstang_top(
    input clk_g,                    // crystal clock

    input s1,

	input UART_RXD,
	output UART_TXD,

    output [7:0] led,

    // dualshock controller
    output ds_clk,
    input ds_miso,
    output ds_mosi,
    output ds_cs,
    output ds_clk2,
    input ds_miso2,
    output ds_mosi2,
    output ds_cs2,

    // USB1 and USB2
    inout usb1_dp,
    inout usb1_dn,
    inout usb2_dp,
    inout usb2_dn,

	// SDRAM
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            // chip select
    output O_sdram_cas_n,           // columns address select
    output O_sdram_ras_n,           // row address select
    output O_sdram_wen_n,           // write enable
    inout [15:0] IO_sdram_dq,       // bidirectional data bus
    output [12:0] O_sdram_addr,     // multiplexed address bus
    output [1:0] O_sdram_ba,        // two banks
    output [1:0] O_sdram_dqm,  

    // HDMI TX
    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p


`ifdef VERILATOR
	,
    input  [11:0] joy1,
    input  [11:0] joy2,
	input         rom_loading,
	input  [7:0]  rom_do,
	input         rom_do_valid
`endif
);

// System output
reg ce_pix         /* verilator public */;
wire [8:0]  x      /* verilator public */;
wire [8:0]  y      /* verilator public */;
wire [11:0] color  /* verilator public */;  // BGR444
wire HS            /* verilator public */;
wire VS            /* verilator public */;
wire [15:0] audio_l/* verilator public */;
wire [15:0] audio_r/* verilator public */;

////////////////// Clocks & CE //////////////////

// 53.70Mhz (~=53.693175) system clock
wire clk_sys, clk27;
wire clk_pixel, clk_5x_pixel;
wire locked;

`ifdef VERILATOR
assign clk_sys = clk_g;
assign locked = 1'b1;
`else
pll_53 pll_53_inst(
    .clkin(clk_g),
    .clkout0(clk_sys),
	.clkout1(O_sdram_clk),
    .lock(locked)
);
pll_27 pll_27_inst(
    .clkin(clk_g),
    .clkout0(clk27)
);
pll_74 pll_74_inst(
    .clkin(clk27),
    .clkout0(clk_pixel),
    .clkout1(clk_5x_pixel)
);
`endif

reg ce_cpu;
reg ce_snd;
reg ce_vdp;
reg ce_sp;
reg [4:0] clkd;
always @(posedge clk_sys) begin

	ce_sp <= clkd[0];
	ce_vdp <= 0;//div5
	ce_pix <= 0;//div10
	ce_cpu <= 0;//div15
	clkd <= clkd + 1'd1;
	if (clkd==29) begin
		clkd <= 0;
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==24) begin
		ce_cpu <= 1;  //-- changed cpu phase to please VDPTEST HCounter test;
		ce_vdp <= 1;
	end else if (clkd==19) begin
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==14) begin
		ce_vdp <= 1;
	end else if (clkd==9) begin
		ce_cpu <= 1;
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==4) begin
		ce_vdp <= 1;
	end
end

////////////////// SMS System //////////////////

wire [63:0] status;           // iosys will set this

reg        gg          = 0;
reg        systeme     = 0;
reg        palettemode = 0;
reg [21:0] cart_mask, cart_mask512;
reg        cart_sz512;

reg reset /* verilator public */ = 1;

wire mask_column;
wire smode_M1, smode_M2, smode_M3;
wire pal  /* verilator public */ = status[2];
wire border = status[13] & ~gg;
wire ggres = ~status[39] & gg;
wire turbo = status[40];

wire [15:0] joy_0, joy_1, joy_2, joy_3;
wire      joya_tr_out;
wire      joya_th_out;
wire      joyb_tr_out;
wire      joyb_th_out;
wire      joya_th;
wire      joyb_th;
wire      swap = status[1];

`ifndef VERILATOR
wire [11:0] joy1;   // SNES layout: (R L  X A RT LT DN UP START SELECT Y B)
wire [11:0] joy2;   //              11 10 9 8 7  6  5  4  3     2      1 0
`endif
wire [7:0] joyser; 

wire [21:0] ram_addr;
wire  [7:0] ram_dout;
wire        ram_rd;

wire [13:0] ram_a;
wire        ram_we;
wire  [7:0] ram_d;
wire  [7:0] ram_q;

wire [14:0] nvram_a;
wire        nvram_we;
wire  [7:0] nvram_d;
wire  [7:0] nvram_q;

// SYSMODE[0]: [0]=EncryptBase,[1]=EncryptBank,[2]=Paddle,[3]=Pedal,[4,5]=E0Type,[6]=E1,[7]=E2
// SYSMODE[1]: [0]=
reg [7:0] SYSMODE[1];
reg [7:0] DSW[3];


system #(63) system
(
	.clk_sys(clk_sys), .ce_cpu(ce_cpu), .ce_vdp(ce_vdp),
	.ce_pix(ce_pix), .ce_sp(ce_sp), .turbo(turbo),
	.gg(gg), .ggres(ggres), .systeme(systeme),
	.bios_en(/*~status[11] & ~systeme*/1'b0), .RESET_n(~reset),

	.GG_RESET(/*ioctl_download && ioctl_wr && !ioctl_addr*/), .GG_EN(status[24]), .GG_CODE(/*gg_code*/),
	.GG_AVAIL(/*gg_avail*/),

	.rom_rd(ram_rd), .rom_a(ram_addr), .rom_do(ram_dout),

	.j1_up(~joy1[4]), .j1_down(~joy1[5]), .j1_left(~joy1[6]),
	.j1_right(~joy1[7]), .j1_tl(~joy1[0]), .j1_tr(~joy1[8]),
	.j1_th(joya_th), .j1_start(swap ? ~joy1[3] : ~joy2[3]), .j1_coin(swap ? ~joy1[11] : ~joy1[11]),
	.j1_a3(swap ? ~joy1[10] : ~joy1[10]),

	.j2_up(~joy2[4]), .j2_down(~joy2[5]), .j2_left(~joy2[6]),
	.j2_right(~joy2[7]), .j2_tl(~joy2[0]), .j2_tr(~joy2[8]),
	.j2_th(joyb_th), .pause(joy1[6]&joy2[6]), .j2_start(swap ? ~joy1[11] : ~joy2[11]),
	.j2_coin(swap ? ~joy1[10] : ~joy2[10]), .j2_a3(swap ? ~joy1[8] : ~joy2[8]),

	.j1_tr_out(joya_tr_out), .j1_th_out(joya_th_out), .j2_tr_out(joyb_tr_out),
	.j2_th_out(joyb_th_out),

	.E0Type(SYSMODE[0][5:4]), .E1Use(SYSMODE[0][6]), .E2Use(SYSMODE[0][7]),
	.F2(DSW[0]), .F3(DSW[1]), .E0(DSW[2]),

	.has_pedal(SYSMODE[0][3]), .has_paddle(SYSMODE[0][2]), .paddle(),
	.paddle2(), .pedal(),

	.x(x), .y(y), .color(color),
	.palettemode(palettemode), .mask_column(mask_column), .black_column(status[28] && ~status[13]),
	.smode_M1(smode_M1), .smode_M2(smode_M2), .smode_M3(smode_M3),
	.ysj_quirk(/*ysj_quirk*/), .pal(pal), .region(status[10]),
	.mapper_lock(status[15] && ~systeme), .vdp_enables(2'b00), .psg_enables(2'b00),

	.fm_ena(~status[12] | gg), .audioL(audio_l), .audioR(audio_r),

	.dbr(/*dbr*/), .sp64(status[8]),

	.ram_a(ram_a), .ram_we(ram_we), .ram_d(ram_d),
	.ram_q(ram_q),

	.nvram_a(nvram_a), .nvram_we(nvram_we), .nvram_d(nvram_d),
	.nvram_q(nvram_q),

	.encrypt(SYSMODE[0][1:0]), .key_a(/*(key_a)*/), .key_d(/*(key_d)*/),

	.ROMCL(clk_sys), .ROMAD(/*ioctl_addr*/), .ROMDT(/*ioctl_dout*/),
	.ROMEN(/*ioctl_wr & ioctl_index==0*/)
);

wire HBlank, VBlank;
video video
(
	.clk(clk_sys),
	.ce_pix(ce_pix),
	.pal(pal),
	.ggres(ggres),
	.border(border),
	.mask_column(mask_column),
	.cut_mask(status[29]),
	.smode_M1(smode_M1),
	.smode_M3(smode_M3),
	.x(x),
	.y(y),
	.hsync(HS),
	.vsync(VS),
	.hblank(HBlank),
	.vblank(VBlank)
);


////////////////// Memories //////////////////

`ifndef VERILATOR
wire rom_loading;
wire rom_do_valid;
wire [7:0] rom_do;
`endif

reg [23:0] loading_addr_next, loading_addr;
reg loading_req;
reg [7:0] loading_data;

// reg ram_rd_req_r;
// wire ram_rd_req = ram_rd ^ ram_rd_req_r;        // turn ram_rd pulse into toggle request
// always @(posedge clk_sys) ram_rd_req_r <= ram_rd_req;

reg ram_rd_req;
reg [21:0] ram_addr_r;
reg ram_rd_r;
always @(posedge clk_sys) begin
	ram_rd_r <= ram_rd;
	if (ram_rd) begin
		ram_addr_r <= ram_addr;
		if (ram_addr_r != ram_addr || ram_rd && !ram_rd_r) begin
			ram_rd_req <= ~ram_rd_req;
		end
	end
end


sdram ram (
	.clk(clk_sys), .resetn(locked), .refresh_allowed(1'b1), .busy(),

    // channel 0 for downloading, only use lower 8 bit
    .req0(loading_req), .ack0(), .wr0(1'b1), .addr0(loading_addr), 
    .din0(loading_data), .dout0(), .be0(2'b11),

    // channel 1 for normal reading
    .req1(ram_rd_req), .ack1(), .wr1(1'b0), 
	.addr1(cart_sz512 ? (ram_addr + 10'd512) & cart_mask512 : ram_addr & cart_mask),
    .din1(), .dout1(ram_dout), .be1(2'b11),
	
    .req2(), .ack2(), .wr2(), .addr2(), .din2(), .dout2(), .be2(),

    .SDRAM_DQ(IO_sdram_dq), .SDRAM_A(O_sdram_addr), .SDRAM_BA(O_sdram_ba),      
    .SDRAM_nCS(O_sdram_cs_n), .SDRAM_nWE(O_sdram_wen_n),  .SDRAM_nRAS(O_sdram_ras_n), 
    .SDRAM_nCAS(O_sdram_cas_n), .SDRAM_CKE(O_sdram_cke), .SDRAM_DQM(O_sdram_dqm)
);

spram #(.widthad_a(14)) ram_inst
(
	.clock     (clk_sys),
	.address   (systeme ? ram_a : {1'b0,ram_a[12:0]}),
	.wren      (ram_we),
	.data      (ram_d),
	.q         (ram_q)
);

dpram #(.widthad_a(15)) nvram_inst
(
	.clock_a     (clk_sys),
	.address_a   (nvram_a),
	.wren_a      (nvram_we),
	.data_a      (nvram_d),
	.q_a         (nvram_q),
	.clock_b     (clk_sys),
	.address_b   (/*{sd_lba[5:0],sd_buff_addr}*/),
	.wren_b      (/*sd_buff_wr & sd_ack*/),
	.data_b      (/*sd_buff_dout*/),
	.q_b         (/*sd_buff_din*/)
);

////////////////// I/O //////////////////

`ifndef VERILATOR

wire overlay;
wire [7:0] overlay_x;
wire [7:0] overlay_y;
wire [14:0] overlay_color;

sms2hdmi sms2hdmi_inst (
	.clk(clk_sys), .resetn(1'b1),
	.clk_pixel(clk_pixel),.clk_5x_pixel(clk_5x_pixel),
    .ce_pix(ce_pix), .x(x), .y(y), .color(color), .audio_l(audio_l), .audio_r(audio_r),
    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y), .overlay_color(overlay_color),
	.tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p)
);

wire [11:0] joy1_btns, joy2_btns;
wire [11:0] joy1_usb, joy2_usb;
wire [11:0] joy1_mcu, joy2_mcu;
assign joy1 = joy1_btns | joy1_usb | joy1_mcu;
assign joy2 = joy2_btns | joy2_usb | joy2_mcu;

controller_ds2 #(.FREQ(53_700_000)) joy1_ds2 (
    .clk(clk_sys), .snes_buttons(joy1_btns),
    .ds_clk(ds_clk), .ds_miso(ds_miso), .ds_mosi(ds_mosi), .ds_cs(ds_cs) 
);
controller_ds2 #(.FREQ(53_700_000)) joy2_ds2 (
   .clk(clk_sys), .snes_buttons(joy2_btns),
   .ds_clk(ds_clk2), .ds_miso(ds_miso2), .ds_mosi(ds_mosi2), .ds_cs(ds_cs2) 
);

wire clk12;
wire pll_lock_12;
wire usb_conerr;
wire [1:0] usb_type;
pll_12 pll12(.clkin(clk_g), .clkout0(clk12), .lock(pll_lock_12));
usb_hid_host usb_hid_host (
    .usbclk(clk12), .usbrst_n(pll_lock_12),
    .usb_dm(usb1_dn), .usb_dp(usb1_dp),
    .game_snes(joy1_usb), .typ(usb_type), .conerr(usb_conerr)
);
usb_hid_host usb_hid_host2 (
    .usbclk(clk12), .usbrst_n(pll_lock_12),
    .usb_dm(usb2_dn), .usb_dp(usb2_dp),
    .game_snes(joy2_usb)
);

assign led = ~{joy1[4:0], usb_type, usb_conerr};

iosys_bl616 #(.COLOR_LOGO(15'b11111_00000_00000), .FREQ(53_700_000), .CORE_ID(5) )     // deep blue smstang logo
    sys_inst (
    .clk(clk_sys), .hclk(clk_pixel), .resetn(1'b1),

    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y), .overlay_color(overlay_color),
    .joy1(joy1_btns | joy1_usb), .joy2(joy2_btns | joy2_usb),
    .hid1(joy1_mcu), .hid2(joy2_mcu),
    .uart_tx(UART_TXD), .uart_rx(UART_RXD),

    .rom_loading(rom_loading), .rom_do(rom_do), .rom_do_valid(rom_do_valid)
);

`else

// rom loading is done by sim_main.cpp

// test_loader test_loader_inst(
//     .clk(clk_sys),
//     .resetn(locked),
//     .dout(rom_do),
//     .dout_valid(rom_do_valid),
//     .loading(rom_loading),
//     .fail()
// );
`endif

reg rom_loading_r;
always @(posedge clk_sys) begin
    rom_loading_r <= rom_loading;
	if(!rom_loading_r && rom_loading) begin     // download start, reset system
        loading_addr_next <= 0;
        reset <= 1;
    end
    if (rom_loading_r && !rom_loading) begin    // download complete, start system
        reset <= 0;
    end
    if (rom_loading && rom_do_valid) begin      // write a byte to SDRAM
        loading_addr_next <= loading_addr_next + 1'd1;
        loading_addr <= loading_addr_next;
        loading_req <= ~loading_req;
        loading_data <= rom_do;
	end
end

// the last loading address is our mask, e.g. 0xffff for 64KB carts
assign cart_mask = loading_addr;

endmodule
