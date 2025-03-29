module io(clk, WR_n, RD_n, A, D_in, D_out, HL_out, vdp1_bank, vdp2_bank, vdp_cpu_bank, rom_bank, J1_tr_out, J1_th_out, J2_tr_out, J2_th_out, J1_up, J1_down, J1_left, J1_right, J1_tl, J1_tr, J1_th, J1_start, J1_coin, J1_a3, J2_up, J2_down, J2_left, J2_right, J2_tl, J2_tr, J2_th, J2_start, J2_coin, J2_a3, Pause, E0Type, E1Use, E2Use, E0, F2, F3, has_paddle, has_pedal, paddle, paddle2, pedal, pal, gg, systeme, region, RESET_n);
   input                clk;
   input                WR_n;
   input                RD_n;
   input [7:0]          A;
   input [7:0]          D_in;
   output reg [7:0]     D_out;
   output reg           HL_out;
   output reg           vdp1_bank;
   output reg           vdp2_bank;
   output reg           vdp_cpu_bank;
   output reg [3:0]     rom_bank;
   output reg           J1_tr_out;
   output reg           J1_th_out;
   output reg           J2_tr_out;
   output reg           J2_th_out;
   input                J1_up;
   input                J1_down;
   input                J1_left;
   input                J1_right;
   input                J1_tl;
   input                J1_tr;
   input                J1_th;
   input                J1_start;
   input                J1_coin;
   input                J1_a3;
   input                J2_up;
   input                J2_down;
   input                J2_left;
   input                J2_right;
   input                J2_tl;
   input                J2_tr;
   input                J2_th;
   input                J2_start;
   input                J2_coin;
   input                J2_a3;
   input                Pause;
   input [1:0]          E0Type;
   input                E1Use;
   input                E2Use;
   input [7:0]          E0;
   input [7:0]          F2;
   input [7:0]          F3;
   input                has_paddle;
   input                has_pedal;
   input [7:0]          paddle;
   input [7:0]          paddle2;
   input [7:0]          pedal;
   input                pal;
   input                gg;
   input                systeme;
   input                region;
   input                RESET_n;
   
   reg [7:0]    ctrl;
   reg [7:0]    gg_ddr;
   reg [7:0]    gg_txd;
   reg [7:0]    gg_rxd;
   reg [7:0]    gg_pdr;
   reg          j1_th_dir;
   reg          j2_th_dir;
   reg          analog_select;
   reg          analog_player;
   reg          analog_upper;
   // signal gg_sctrl:	std_logic_vector(7 downto 3) $ "00111";
   
   always @(posedge clk or negedge RESET_n)
      if (RESET_n == 1'b0) begin
         ctrl <= 8'hFF;
         gg_ddr <= 8'hFF;
         gg_txd <= 8'h00;
         gg_rxd <= 8'hFF;
         gg_pdr <= 8'h00;
         analog_select <= 1'b0;
         analog_player <= 1'b0;
      // gg_sctrl <= "00111" ;
      end else begin
         if (gg & A[7:3] == 5'b00000) begin
            if (WR_n == 1'b0)
               case (A[2:0])
                  3'b001 : gg_pdr <= D_in;
                  3'b010 : gg_ddr <= D_in;
                  3'b011 : gg_txd <= D_in;
                  // 3'b100 : gg_rxd <= D_in;
                  // 3'b101 : gg_sctrl <= D_in[7:3];
                  default : ;
               endcase
         end else if (systeme & A == 8'hF7) begin
            if (WR_n == 1'b0) begin
               vdp1_bank <= D_in[7];
               vdp2_bank <= D_in[6];
               vdp_cpu_bank <= D_in[5];
               rom_bank <= D_in[3:0];
            end 
         end else if (systeme & A == 8'hFA) begin
            if (WR_n == 1'b0) begin
               analog_player <= D_in[3];		// paddle select ridleofp
               analog_upper <= D_in[2];		// upperbits ridleofp
               analog_select <= D_in[0];		// analog select(paddle, pedal) hangonjr
            end 
         end else if (A[0]) begin
            //				if WR_n='0' and ((A(7 downto 4)/="0000") or (A(3 downto 0)="0000")) then
            if (WR_n == 1'b0)
               ctrl <= D_in;
         end 
      end 
   
   //	J1_tr <= ctrl(4) when ctrl(0)='0' else 'Z';
   //	J2_tr <= ctrl(6) when ctrl(2)='0' else 'Z';
   // $00-$06 : GG specific registers. Initial state is 'C0 7F FF 00 FF 00 FF'
   always @(posedge clk) begin
      if (RD_n == 1'b0) begin
         if (A[7] == 1'b0)		// implies gg='1'
            case (A[2:0])
               3'b000 :
                  begin
                     D_out[7] <= Pause;
                     if (region == 1'b0) begin
                        D_out[6] <= 1'b1;		// 1=Export (USA/Europe)/0=Japan
                        D_out[5] <= (~pal);
                        D_out[4:0] <= 5'b11111;
                     end else
                        D_out[6:0] <= 7'b0000000;
                  end
               // when "001" => D_out <= gg_pdr(7)&(gg_ddr(6 downto 0) or gg_pdr(6 downto 0)) ;
               3'b001 : D_out <= {gg_pdr[7], ((~gg_ddr[6:0]) | gg_pdr[6:0])};
               3'b010 : D_out <= gg_ddr;        // bit7 controls NMI ?
               3'b011 : D_out <= gg_txd;
               3'b100 : D_out <= gg_rxd;
               3'b101 : D_out <= 8'b00111000;   // gg_sctrl & "000"
               3'b110 : D_out <= {8{1'b1}};
               default : ;
            endcase
         else if (systeme & A[7:0] == 8'he0) begin
            D_out[7] <= ~J2_start | E0Type[1] | E0Type[0];
            D_out[6] <= ~J1_start | E0Type[1];
            D_out[5] <= 1'b1;		// not used?
            D_out[4] <= ~J1_start | ~E0Type[0];
            D_out[3] <= E0[3];		// service
            D_out[2] <= E0[2];		// service no toggle (usually)
            D_out[1] <= ~J2_coin;
            D_out[0] <= ~J1_coin;
         end else if (systeme & A[7:0] == 8'he1) begin
            if (E1Use) begin
               D_out[7] <= 1'b1;
               D_out[6] <= 1'b1;
               D_out[5] <= J1_tr;
               D_out[4] <= J1_tl;
               D_out[3] <= J1_right;
               D_out[2] <= J1_left;
               D_out[1] <= J1_down;
               D_out[0] <= J1_up;
            end else
               D_out <= 8'hFF;
         end else if (systeme & A[7:0] == 8'he2) begin
            if (E2Use) begin
               D_out[7] <= 1'b1;
               D_out[6] <= 1'b1;
               D_out[5] <= J2_tr;
               D_out[4] <= J2_tl;
               D_out[3] <= J2_right;
               D_out[2] <= J2_left;
               D_out[1] <= J2_down;
               D_out[0] <= J2_up;
            end else
               D_out <= 8'hFF;
         end else if (systeme & A[7:0] == 8'hf2)
            D_out <= F2;		// free play or 1coin/credit
         else if (systeme & A[7:0] == 8'hf3)
            D_out <= F3;		// dip switch options
         else if (systeme & A[7:0] == 8'hf8) begin		// analog (paddle, pedal)
            if (has_pedal == 1'b0 & has_paddle == 1'b0)
               D_out <= 8'hFF;
            else if (has_pedal) begin
               if (analog_select == 1'b0)
                  D_out <= paddle;
               else
                  D_out <= pedal;
            end else if (analog_upper) begin
               if (analog_player == 1'b0) begin
                  D_out[7] <= J1_tl | J1_tr | J1_a3;
                  D_out[6] <= J1_tl;
                  D_out[5] <= J1_tr;
                  D_out[4] <= J1_a3;		//j1_middle;
                  D_out[3:0] <= paddle[7:4];
               end else begin
                  D_out[7] <= J1_tl | J1_tr | J1_a3;
                  D_out[6] <= J2_tl;
                  D_out[5] <= J2_tr;
                  D_out[4] <= J2_a3;		//j1_middle;
                  D_out[3:0] <= paddle2[7:4];
               end
            end else
               if (analog_player == 1'b0) begin
                  D_out[3:0] <= paddle[7:4];
                  D_out[7:4] <= paddle[3:0];
               end else begin
                  D_out[3:0] <= paddle2[7:4];
                  D_out[7:4] <= paddle2[3:0];
               end
         end else if (systeme & A[7:0] == 8'hf9)
            D_out <= 8'hFF;		// analog (paddle, pedal, dial)
         else if (systeme & A[7:0] == 8'hfa)
            D_out <= 8'h00;		// analog (paddle, pedal, dial)
         else if (systeme & A[7:0] == 8'hfb)
            D_out <= 8'hFF;		// analog (paddle, pedal, dial)
         else if (A[0] == 1'b0) begin
            D_out[7] <= J2_down;
            D_out[6] <= J2_up;
            // 5=j1_tr
            if (ctrl[0] == 1'b0 & region == 1'b0 & gg == 1'b0)
               D_out[5] <= ctrl[4];
            else
               D_out[5] <= J1_tr;
            D_out[4] <= J1_tl;
            D_out[3] <= J1_right;
            D_out[2] <= J1_left;
            D_out[1] <= J1_down;
            D_out[0] <= J1_up;
         end 
         else begin
            // 7=j2_th
            if (ctrl[3] == 1'b0 & region == 1'b0 & gg == 1'b0)
               D_out[7] <= ctrl[7];
            else
               D_out[7] <= J2_th;
            // 6=j1_th
            if (ctrl[1] == 1'b0 & region == 1'b0 & gg == 1'b0)
               D_out[6] <= ctrl[5];
            else
               D_out[6] <= J1_th;
            D_out[5] <= 1'b1;
            D_out[4] <= 1'b1;
            // 4=j2_tr
            if (ctrl[2] == 1'b0 & gg == 1'b0)
               D_out[3] <= ctrl[6];
            else
               D_out[3] <= J2_tr;
            D_out[2] <= J2_tl;
            D_out[1] <= J2_right;
            D_out[0] <= J2_left;
         end
      end 
      
      J1_tr_out <= ctrl[0] | ctrl[4] | region;
      J1_th_out <= ctrl[1] | ctrl[5] | region;
      J2_tr_out <= ctrl[2] | ctrl[6] | region;
      J2_th_out <= ctrl[3] | ctrl[7] | region;
      HL_out <= ((~j1_th_dir) & ctrl[1]) | (ctrl[1] & (~J1_th)) | ((~j2_th_dir) & ctrl[3]) | (ctrl[3] & (~J2_th));
      j1_th_dir <= ctrl[1];
      j2_th_dir <= ctrl[3];
   end 
   
endmodule


