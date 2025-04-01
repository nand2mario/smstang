//
// EnvelopeGenerator.vhd
// The envelope generator module of VM2413
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

//
//  modified by t.hara
//
import vm2413::*;
module EnvelopeGenerator(clk, reset, clkena, slot, stage, rhythm, am, tl, ar, dr, sl, rr, rks, key, egout);
   input         clk;
   input         reset;
   input         clkena;
   
   input [4:0]   slot;
   input [1:0]   stage;
   input         rhythm;
   
   input         am;
   input [6:0]   tl;
   input [3:0]   ar;
   input [3:0]   dr;
   input [3:0]   sl;
   input [3:0]   rr;
   input [3:0]   rks;
   input         key;
   
   output reg [12:0] egout;		//Decimal part 6bit
   
   SLOT_TYPE     rslot;
   EGDATA_TYPE   memin;
   EGDATA_TYPE   memout;
   logic         memwr;
   
   reg [21:0]    aridx;
   wire [12:0]   ardata;		//Decimal part 6bit
   
   //  Attack table
   AttackTable u_attack_table(
      .clk(clk), 
      .clkena(clkena),
      .addr(aridx),    //Decimal part 15bit
      .data(ardata));
   
   
   EnvelopeMemory u_envelope_memory(
      .clk(clk), .reset(reset), .waddr(slot), .wr(memwr), 
      .wdata(memin), .raddr(rslot), .rdata(memout));
   
   // Prefetching EnvelopeMemory
   always @(posedge reset or posedge clk)
      if (reset)
         rslot <= 1'b0;
      else  begin
         if (clkena) begin
            if (stage == 2'b10) begin
               if (slot == 5'b10001)
                  rslot <= 5'b0;
               else
                  rslot <= slot + 1;
            end 
         end 
      end 
   
   
   always @(posedge reset or posedge clk) begin
      reg [18-1:0]  lastkey;
      reg [4:0]     rm;
      reg [6+8:0]   egtmp;		//Decimal part 6bit
      reg [19:0]    amphase;
      EGPHASE_TYPE  egphase;
      EGSTATE_TYPE  egstate;
      EGPHASE_TYPE  dphase;
      reg [17:0]    ntable;

      if (reset) begin
         rm = {5{1'b0}};
         lastkey = {18{1'b0}};
         memwr <= 1'b0;
         egstate = Finish;
         egphase = 1'b0;
         ntable = {18{1'b1}};
         amphase[19:19 - 4] = 5'b00001;
         amphase[19 - 5:0] = {20{1'b0}};
      
      end else  begin
         
         aridx <= egphase[22 - 1:0];
         
         if (clkena) begin
            
            ntable[17:1] = ntable[16:0];
            ntable[0] = ntable[17] ^ ntable[14];
            
            // Amplitude oscillator ( -4.8dB to 0dB , 3.7Hz )
            amphase = amphase + 1'b1;
            if (amphase[19:19 - 4] == 5'b11111)
               amphase[19:19 - 4] = 5'b00001;
            
            if (stage == 0) begin
               egstate = memout.state;
               egphase = memout.phase;
            
            end else if (stage == 1)   // Wait for AttackTable
               ;
            
            else if (stage == 2) begin
               case (egstate)
                  Attack :
                     begin
                        rm = {1'b0, ar};
                        egtmp = {2'b00, tl, 6'b000000} + {2'b00, ardata};		//Draw a curve and rise
                     end
                  Decay :
                     begin
                        rm = {1'b0, dr};
                        egtmp = {2'b00, tl, 6'b000000} + {2'b00, egphase[22 - 1:22 - 7 - 6]};
                     end
                  Release :
                     begin
                        rm = {1'b0, rr};
                        egtmp = {2'b00, tl, 6'b000000} + {2'b00, egphase[22 - 1:22 - 7 - 6]};
                     end
                  Finish :
                     begin
                        egtmp = {2'b00, {13{1'b1}}};         // 15 bits
                     end
               endcase
               
               // SD and HH
               if (ntable[0] & slot/2 == 7 & rhythm)
                  egtmp = egtmp + 15'b010000000000000;
               
               // Amplitude LFO
               if (am) begin
                  if (amphase[19] == 1'b0)
                     //In the case of an uphill
                     egtmp = egtmp + {5'b00000, (amphase[19 - 1:19 - 4 - 6] - 10'b0001000000)};
                  else
                     //For downhill
                     egtmp = egtmp + {5'b00000, (10'b1111000000 - amphase[19 - 1:19 - 4 - 6])};
               end 
               
               // Generate output
               if (egtmp[8:8 - 1] == 2'b00)		//Limiter
                  egout <= egtmp[12:0];
               else
                  egout <= {13{1'b1}};
               
               if (rm != 5'b00000) begin
                  
                  rm = rm + rks[3:2];
                  if (rm[4])
                     rm[3:0] = 4'b1111;
                  
                  case (egstate)
                     Attack :
                        begin
                           dphase[22:5] = 0;
                           dphase[5:0] = 3'b110 * {1'b1, rks[1:0]};
                           dphase = dphase << rm[3:0];
                           egphase = egphase - dphase[22:0];
                        end
                     Decay, Release :
                        begin
                           dphase[22:3] = 0;
                           dphase[2:0] = {1'b1, rks[1:0]};
                           dphase = dphase << (rm[3:0] - 1'b1);
                           egphase = egphase + dphase;
                        end
                     Finish :
                        ;
                  endcase
               end 
               
               case (egstate)
                  Attack :
                     if (egphase[22]) begin
                        egphase = 0;
                        egstate = Decay;
                     end 
                  Decay :
                     if (egphase[22:18] >= {1'b0, sl})
                        egstate = Release;
                  Release :
                     if (egphase[22:18] >= 5'b01111)
                        egstate = Finish;
                  Finish :
                     egphase = {23{1'b1}};
               endcase
               
               if (lastkey[slot] == 1'b0 & key) begin
                  egphase[22] = 1'b0;
                  egphase[21:0] = {22{1'b1}};
                  egstate = Attack;
               end else if (lastkey[slot] & key == 1'b0 & egstate != Finish)
                  egstate = Release;
               lastkey[slot] = key;
               
               // update phase and state memory
               memin.state <= egstate;
               memin.phase <= egphase;
               memwr <= 1'b1;
            end else if (stage == 3)
               // wait for phase memory
               memwr <= 1'b0;
         end 
      end 
   end
   
endmodule
