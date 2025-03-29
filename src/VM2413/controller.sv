//
// Controller.vhd
// The core controller module of VM2413
//
// Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//    product or activity without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
// [Description]
//
// The Controller is the beginning module of the OPLL slot calculation.
// It manages register accesses from I/O and sends proper voice parameters
// to the succeding PhaseGenerator and EnvelopeGenerator modules.
// The one cycle of the Controller consists of 4 stages as follows.
//
// 1st stage:
//   * Prepare to read the register value for the current slot from RegisterMemory.
//   * Prepare to read the voice parameter for the current slot from VoiceMemory.
//   * Prepare to read the user-voice data from VoiceMemory.
//
// 2nd stage:
//   * Wait for RegisterMemory and VoiceMemory
//
// 3rd clock stage:
//   * Update register value if wr='1' and addr points the current OPLL channel.
//   * Update voice parameter if wr='1' and addr points the voice parameter area.
//   * Write register value to RegisterMemory.
//   * Write voice parameter to VoiceMemory.
//
// 4th stage:
//   * Send voice and register parameters to PhaseGenerator and EnvelopeGenerator.
//   * Increment the number of the current slot.
//
// Each stage is completed in one clock. Thus the Controller traverses all 18 opll
// slots in 72 clocks.
//

//
//  modified by t.hara
//

import vm2413::*;

module controller(clk, reset, clkena, slot, stage, wr, addr, data, am, pm, wf, ml, tl, fb, ar, dr, sl, rr, blk, fnum, rks, key, rhythm);
   
   input           clk;
   input           reset;
   input           clkena;
   
   input [4:0]     slot;
   input [1:0]     stage;
   
   input           wr;
   input [7:0]     addr;
   input [7:0]     data;
   
   // output parameters for phasegenerator and envelopegenerator
   output reg          am;
   output reg          pm;
   output reg          wf;
   output reg [3:0]    ml;
   output reg [6:0]    tl;
   output reg [2:0]    fb;
   output reg [3:0]    ar;
   output reg [3:0]    dr;
   output reg [3:0]    sl;
   output reg [3:0]    rr;
   
   output reg [2:0]    blk;
   output reg [8:0]    fnum;
   output reg [3:0]    rks;
   
   output reg          key;
   output reg          rhythm;
   
   // // slot_out : out slot_id
   
   // the array which caches instrument number of each channel.
   reg [3:0]       inst_cache[0:9-1];
   
   parameter [5:0] kl_table[0:15] = 
      {6'b000000, 6'b011000, 6'b100000, 6'b100101, 
       6'b101000, 6'b101011, 6'b101101, 6'b101111, 
       6'b110000, 6'b110010, 6'b110011, 6'b110100, 
       6'b110101, 6'b110110, 6'b110111, 6'b111000};      // 0.75db/step, 6db/oct
   
   // signals for the read-only access ports of voicememory module.
   reg [5:0]       slot_voice_addr;
   VOICE_TYPE      slot_voice_data;
   
   // signals for the read-write access ports of voicememory module.
   reg             user_voice_wr;
   reg [5:0]       user_voice_addr;
   VOICE_TYPE      user_voice_rdata;
   VOICE_TYPE      user_voice_wdata;
   
   // signals for the registermemory module.
   reg             regs_wr;
   reg [3:0]       regs_addr;
   wire [23:0]     regs_rdata;
   reg [23:0]      regs_wdata;
   
   reg [7:0]       rflag;
   wire [3:0]      w_channel;
   //  signal w_is_carrier         : std_logic;
   
   RegisterMemory u_register_memory(
      .clk(clk), .reset(reset), .addr(regs_addr), .wr(regs_wr), 
      .idata(regs_wdata), .odata(regs_rdata));

   VoiceMemory vmem(
      .clk(clk), .reset(reset), .idata(user_voice_wdata), .wr(user_voice_wr), 
      .rwaddr(user_voice_addr), .roaddr(slot_voice_addr), .odata(user_voice_rdata), .rodata(slot_voice_data));

   // Memory to hold register settings
   // Register Address Latch (1st Stage)
   always @(posedge reset or posedge clk)
      if (reset)
         regs_addr <= {4{1'b0}};
      else begin
         if (clkena) begin
            if (stage == 2'b00)
               regs_addr <= slot[4:1];
            else begin
               //  hold
            end
         end 
      end 
   
   //Address latch to read tone data for current slot (1st stage)
   always @(posedge reset or posedge clk)
      if (reset)
         slot_voice_addr <= 0;
      else  begin
         if (clkena) begin
            if (stage == 2'b00) begin
               if (rflag[5] & w_channel >= 4'b0110)
                  //In rhythm mode, ch6 and later
                  slot_voice_addr <= slot - 12 + 32;
               else
                  slot_voice_addr <= inst_cache[slot/2] * 2 + slot % 2;
            end 
         end 
      end 
   //  hold
   
   assign w_channel = slot[4:1];
   //  w_is_carrier    <= slot( 0 );
   
   always @(posedge clk or posedge reset) begin
      
      reg             kflag;
      reg [6+1:0]     tll;
      reg [6+1:0]     kll;
      
      reg [23:0]      regs_tmp;
      VOICE_TYPE      user_voice_tmp;
      
      reg [2:0]       fb_buf;
      reg             wf_buf;
      
      reg             extra_mode;
      reg [5:0]       vindex;
      
      // process
      
      if (reset) begin
         
         key <= 1'b0;
         rhythm <= 1'b0;
         tll = {8{1'b0}};
         kll = {8{1'b0}};
         kflag = 1'b0;
         rflag <= {8{1'b0}};
         user_voice_wr <= 1'b0;
         user_voice_addr <= 0;
         regs_wr <= 1'b0;
         ar <= {4{1'b0}};
         dr <= {4{1'b0}};
         sl <= {4{1'b0}};
         rr <= {4{1'b0}};
         tl <= {7{1'b0}};
         fb <= {3{1'b0}};
         wf <= 1'b0;
         ml <= {4{1'b0}};
         fnum <= {9{1'b0}};
         blk <= {3{1'b0}};
         key <= 1'b0;
         rks <= {4{1'b0}};
         rhythm <= 1'b0;
         extra_mode = 1'b0;
         vindex = 0;
      
      end else  begin
         if (clkena)
            
            case (stage)
               //------------------------------------------------------------------------
               // 1st stage (setting up a read request for register and voice memories.)
               //------------------------------------------------------------------------
               2'b00 :
                  begin
                     
                     //              if extra_mode = '0' then
                     // alternately read modulator or carrior.
                     vindex = slot % 2;
                     //              else
                     //                  if vindex = voice_id_type'high then
                     //                      vindex$ 0;
                     //                  else
                     //                      vindex$ vindex + 1;
                     //                  end if;
                     //              end if;
                     
                     user_voice_addr <= vindex;
                     regs_wr <= 1'b0;
                     user_voice_wr <= 1'b0;
                  end
               
               //------------------------------------------------------------------------
               // 2nd stage (just a wait for register and voice memories.)
               //------------------------------------------------------------------------
               2'b01 :
                  ;
               
               //------------------------------------------------------------------------
               // 3rd stage (updating a register and voice parameters.)
               //------------------------------------------------------------------------
               2'b10 :
                  
                  if (wr) begin
                     
                     //                  if ( extra_mode = '0' and conv_integer(addr) < 8 ) or
                     //                       ( extra_mode = '1' and ( conv_integer(addr) - 64 ) / 8 = vindex / 2 ) then
                     if (extra_mode == 1'b0 & addr < 8) begin
                        
                        // update user voice parameter.
                        user_voice_tmp = user_voice_rdata;
                        
                        case (addr[2:1])
                           2'b00 :
                              if ((addr[0:0]) == (vindex % 2)) begin
                                 user_voice_tmp.am = data[7];
                                 user_voice_tmp.pm = data[6];
                                 user_voice_tmp.eg = data[5];
                                 user_voice_tmp.kr = data[4];
                                 user_voice_tmp.ml = data[3:0];
                                 user_voice_wr <= 1'b1;
                              end 
                           
                           2'b01 :
                              if (addr[0] == 1'b0 & (vindex % 2 == 0)) begin
                                 user_voice_tmp.kl = data[7:6];
                                 user_voice_tmp.tl = data[5:0];
                                 user_voice_wr <= 1'b1;
                              end else if (addr[0] & (vindex % 2 == 0)) begin
                                 user_voice_tmp.wf = data[3];
                                 user_voice_tmp.fb = data[2:0];
                                 user_voice_wr <= 1'b1;
                              end else if (addr[0] & (vindex % 2 == 1)) begin
                                 user_voice_tmp.kl = data[7:6];
                                 user_voice_tmp.wf = data[4];
                                 user_voice_wr <= 1'b1;
                              end 
                           
                           2'b10 :
                              if ((addr[0:0]) == (vindex % 2)) begin
                                 user_voice_tmp.ar = data[7:4];
                                 user_voice_tmp.dr = data[3:0];
                                 user_voice_wr <= 1'b1;
                              end 
                           
                           2'b11 :
                              if ((addr[0:0]) == (vindex % 2)) begin
                                 user_voice_tmp.sl = data[7:4];
                                 user_voice_tmp.rr = data[3:0];
                                 user_voice_wr <= 1'b1;
                              end 
                        endcase
                        
                        user_voice_wdata <= user_voice_tmp;
                     
                     end else if (addr == 14)
                        
                        rflag <= data;
                     
                     else if (addr < 16)
                        
                        ;
                     
                     else if (addr <= 63) begin
                        
                        if ((addr[3:0]) == slot/2) begin
                           regs_tmp = regs_rdata;
                           case (addr[5:4])
                              2'b01 :		//For 10h to 18h (lower F-Number)
                                 begin
                                    regs_tmp[7:0] = data;		//  F-Number
                                    regs_wr <= 1'b1;
                                 end
                              2'b10 :		//For 20h to 28h (Sus, Key, Block, F-Number MSB)
                                 begin
                                    regs_tmp[13] = data[5];		//  Sus
                                    regs_tmp[12] = data[4];		//  Key
                                    regs_tmp[11:9] = data[3:1];		//  Block
                                    regs_tmp[8] = data[0];		//  F-Number
                                    regs_wr <= 1'b1;
                                 end
                              2'b11 :		//For 30h to 38h (Inst, Vol)
                                 begin
                                    regs_tmp[23:20] = data[7:4];		//  Inst
                                    regs_tmp[19:16] = data[3:0];		//  Vol
                                    regs_wr <= 1'b1;
                                 end
                              default :
                                 ;
                           endcase
                           regs_wdata <= regs_tmp;
                        end 
                     
                     end else if (addr == 240) begin
                        
                        if (data[7:0] == 8'b10000000)
                           extra_mode = 1'b1;
                        else
                           extra_mode = 1'b0;
                     end 
                  end 
               
               //------------------------------------------------------------------------
               // 4th stage (updating a register and voice parameters.)
               //------------------------------------------------------------------------
               2'b11 :
                  begin
                     
                     // output slot number (for explicit synchonization with other units).
                     // slot_out <= slot;
                     
                     // updating insturument cache
                     inst_cache[slot/2] <= (regs_rdata[23:20]);
                     
                     rhythm <= rflag[5];
                     
                     // updating rhythm status and key flag
                     if (rflag[5] & 12 <= slot)
                        case (slot)
                           5'b01100, 5'b01101 :	// bd
                              kflag = rflag[4];
                           5'b01110 :		      // hh
                              kflag = rflag[0];
                           5'b01111 :		      // sd
                              kflag = rflag[3];
                           5'b10000 :		      // tom
                              kflag = rflag[2];
                           5'b10001 :		      // cym
                              kflag = rflag[1];
                           default :
                              ;
                        endcase
                     else
                        kflag = 1'b0;
                     
                     kflag = kflag | regs_rdata[12];
                     
                     // calculate key-scale attenuation amount.
                     kll = {{1'b0, kl_table[regs_rdata[8:5]]} - 
                            {1'b0, 3'b111 - regs_rdata[11:9], 3'b000}, 1'b0};
                     
                     if (kll[7] | slot_voice_data.kl == 2'b00)
                        kll = {8{1'b0}};
                     else
                        kll = kll >> (2'b11 - slot_voice_data.kl);
                     
                     // calculate base total level from volume register value.
                     if (rflag[5] & (slot == 5'b01110 | slot == 5'b10000))		// hh and cym
                        tll = {1'b0, regs_rdata[23:20], 3'b000};
                     else if (slot[0] == 1'b0)
                        tll = {1'b0, slot_voice_data.tl, 1'b0};		// mod
                     else
                        tll = {1'b0, regs_rdata[19:16], 3'b000};		// car
                     
                     tll = tll + kll;
                     
                     if (tll[7])
                        tl <= {7{1'b1}};
                     else
                        tl <= tll[6:0];
                     
                     // output rks, f-number, block and key-status.
                     fnum <= regs_rdata[8:0];
                     blk <= regs_rdata[11:9];
                     key <= kflag;
                     
                     if (rflag[5] & 14 <= slot) begin
                        if (slot_voice_data.kr)
                           rks <= 4'b0101;
                        else
                           rks <= {2'b00, regs_rdata[11:10]};
                     end else
                        if (slot_voice_data.kr)
                           rks <= {regs_rdata[11:9], regs_rdata[8]};
                        else
                           rks <= {2'b00, regs_rdata[11:10]};
                     
                     // output voice parameters
                     // note that wf and fb output must keep its value
                     // at least 3 clocks since the operator module will fetch
                     // the wf and fb 2 clocks later of this stage.
                     am <= slot_voice_data.am;
                     pm <= slot_voice_data.pm;
                     ml <= slot_voice_data.ml;
                     wf_buf = slot_voice_data.wf;
                     fb_buf = slot_voice_data.fb;
                     wf <= wf_buf;
                     fb <= fb_buf;
                     ar <= slot_voice_data.ar;
                     dr <= slot_voice_data.dr;
                     sl <= slot_voice_data.sl;
                     
                     // output release rate (depends on the sustine and envelope type).
                     if (kflag) begin		// key on
                        if (slot_voice_data.eg)
                           rr <= 4'b0000;
                        else
                           rr <= slot_voice_data.rr;
                     end else             // key off
                        if ((slot[0] == 1'b0) & ~(rflag[5] & (7 <= slot/2)))
                           rr <= 4'b0000;
                        else if (regs_rdata[13])
                           rr <= 4'b0101;
                        else if (slot_voice_data.eg == 1'b0)
                           rr <= 4'b0111;
                        else
                           rr <= slot_voice_data.rr;
                  end
            endcase
      end 
   end
   
endmodule
