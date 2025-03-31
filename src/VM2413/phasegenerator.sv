//
// PhaseGenerator.vhd
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
module PhaseGenerator(clk, reset, clkena, slot, stage, rhythm, pm, ml, blk, fnum, key, noise, pgout);
   input            clk;
   input            reset;
   input            clkena;
   
   input SLOT_TYPE  slot;
   input STAGE_TYPE stage;
   
   input            rhythm;
   input PM_TYPE    pm;
   input ML_TYPE    ml;
   input BLK_TYPE   blk;
   input FNUM_TYPE  fnum;
   input            key;
   
   output reg       noise;
   output reg [17:0]    pgout;
   
   localparam [4:0]  mltbl[0:15] = 
      {5'b00001, 5'b00010, 5'b00100, 5'b00110, 5'b01000, 5'b01010, 5'b01100, 5'b01110, 
       5'b10000, 5'b10010, 5'b10100, 5'b10100, 5'b11000, 5'b11000, 5'b11110, 5'b11110};
   
   localparam [63:0] noise14_tbl = 
      64'b1000100010001000100010001000100100010001000100010001000100010000;
   localparam [7:0]  noise17_tbl = 8'b00001010;
   
   // Signals connected to the phase memory.
   logic          memwr;
   PHASE_TYPE     memout, memin;
   
   // Counter for pitch modulation;
   logic [12:0]   pmcount;
   
   
   always @(posedge clk or posedge reset) begin
      reg [18-1:0]     lastkey;
      PHASE_TYPE       dphase;
      reg              noise14;
      reg              noise17;
      reg [17:0]       pgout_buf;		// integer part 9bit, decimal part 9bit
      
      if (reset) begin
         
         pmcount <= {13{1'b0}};
         memwr <= 1'b0;
         lastkey = {18{1'b0}};
         dphase = {18{1'b0}};
         noise14 = 1'b0;
         noise17 = 1'b0;
      
      end else begin
         if (clkena) begin
            
            noise <= noise14 ^ noise17;
            
            if (stage == 0)
               memwr <= 1'b0;
            
            else if (stage == 1)
               ;   // Wait for memory
            
            else if (stage == 2) begin
               // Update pitch LFO counter when slot = 0 and stage = 0 (i.e. increment per 72 clocks)
               if (slot == 0)
                  pmcount <= pmcount + 1'b1;
               
               // Delta phase
               dphase = ({8'b00000000, fnum * mltbl[ml]} << blk) >> 2;
               // dphase := (SHL("00000000"&(fnum*mltbl(CONV_INTEGER(ml))),blk)(19 downto 2));

               if (pm)
                  case (pmcount[12:11])
                     2'b01 :
                        dphase = dphase + (dphase >> 3'b111);
                     2'b11 :
                        dphase = dphase - (dphase >> 3'b111);
                     default : ;
                  endcase
               
               // Update Phase
               if (lastkey[slot] == 1'b0 & key & (rhythm == 1'b0 | (slot != 5'b01110 & slot != 5'b10001)))
                  memin <= {18{1'b0}};
               else
                  memin <= memout + dphase;
               lastkey[slot] = key;
               
               // Update noise
               if (slot == 5'b01110)
                  noise14 = noise14_tbl[memout[15:10]];
               else if (slot == 5'b10001)
                  noise17 = noise17_tbl[memout[13:11]];
               
               pgout_buf = memout;
               pgout <= pgout_buf;
               memwr <= 1'b1;
            
            end else if (stage == 3)
               memwr <= 1'b0;
         end 
      end 
   end
   
   PhaseMemory MEM(
      .clk(clk),
      .reset(reset),
      .slot(slot),
      .memwr(memwr),
      .memout(memout),
      .memin(memin)
   );
   
endmodule
