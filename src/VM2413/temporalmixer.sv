//
// TemporalMixer.vhd
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
import vm2413::*;
module TemporalMixer(clk, reset, clkena, slot, stage, rhythm, maddr, mdata, mixout);
   input         clk;
   input         reset;
   input         clkena;
   
   input SLOT_TYPE   slot;
   input STAGE_TYPE  stage;
   
   input         rhythm;
   
   output SLOT_TYPE  maddr;
   input SIGNED_LI_TYPE  mdata;
   
   output reg [13:0] mixout;
   
   reg           mute;
   reg [13:0]    mix;
   
   always @(posedge clk or posedge reset)
      
      if (reset) begin
         maddr <= {5{1'b0}};
         mute <= 1'b1;
         mix <= {14{1'b0}};
         mixout <= {14{1'b0}};
      
      end else begin
         if (clkena == 1'b1) begin
            if (stage == 0) begin
               if (rhythm == 1'b0)
                  case (slot)
                     5'b00000 : begin maddr <= 5'b00001; mute <= 1'b0; end		// CH0
                     5'b00001 : begin maddr <= 5'b00011; mute <= 1'b0; end		// CH1
                     5'b00010 : begin maddr <= 5'b00101; mute <= 1'b0; end		// CH2
                     5'b00011 : begin mute <= 1'b1; end
                     5'b00100 : begin mute <= 1'b1; end
                     5'b00101 : begin mute <= 1'b1; end
                     5'b00110 : begin maddr <= 5'b00111; mute <= 1'b0; end		// CH3
                     5'b00111 : begin maddr <= 5'b01001; mute <= 1'b0; end		// CH4
                     5'b01000 : begin maddr <= 5'b01011; mute <= 1'b0; end		// CH5
                     5'b01001 : begin mute <= 1'b1; end
                     5'b01010 : begin mute <= 1'b1; end
                     5'b01011 : begin mute <= 1'b1; end
                     5'b01100 : begin maddr <= 5'b01101; mute <= 1'b0; end		// CH6
                     5'b01101 : begin maddr <= 5'b01111; mute <= 1'b0; end		// CH7
                     5'b01110 : begin maddr <= 5'b10001; mute <= 1'b0; end		// CH8
                     5'b01111 : begin mute <= 1'b1; end
                     5'b10000 : begin mute <= 1'b1; end
                     5'b10001 : begin mute <= 1'b1; end
                     default  : begin mute <= 1'b1; end
                  endcase
               else
                  case (slot)
                     5'b00000 : begin maddr <= 5'b00001; mute <= 1'b0; end		// CH0
                     5'b00001 : begin maddr <= 5'b00011; mute <= 1'b0; end		// CH1
                     5'b00010 : begin maddr <= 5'b00101; mute <= 1'b0; end		// CH2
                     5'b00011 : begin maddr <= 5'b01111; mute <= 1'b0; end		// SD
                     5'b00100 : begin maddr <= 5'b10001; mute <= 1'b0; end		// CYM
                     5'b00101 : begin mute <= 1'b1; end
                     5'b00110 : begin maddr <= 5'b00111; mute <= 1'b0; end		// CH3
                     5'b00111 : begin maddr <= 5'b01001; mute <= 1'b0; end		// CH4
                     5'b01000 : begin maddr <= 5'b01011; mute <= 1'b0; end		// CH5
                     5'b01001 : begin maddr <= 5'b01110; mute <= 1'b0; end		// HH
                     5'b01010 : begin maddr <= 5'b10000; mute <= 1'b0; end		// TOM
                     5'b01011 : begin maddr <= 5'b01101; mute <= 1'b0; end		// BD
                     5'b01100 : begin maddr <= 5'b01111; mute <= 1'b0; end		// SD
                     5'b01101 : begin maddr <= 5'b10001; mute <= 1'b0; end		// CYM
                     5'b01110 : begin maddr <= 5'b01110; mute <= 1'b0; end		// HH
                     5'b01111 : begin maddr <= 5'b10000; mute <= 1'b0; end		// TOM
                     5'b10000 : begin maddr <= 5'b01101; mute <= 1'b0; end		// BD
                     5'b10001 : begin mute <= 1'b1; end
                     default  : begin mute <= 1'b1; end
                  endcase
            end else
  
            if (stage == 2) begin
               if (slot == 5'b10001) begin
                  mixout <= mix;
                  mix <= {14{1'b0}};
               end else
                  if (mute == 1'b0) begin
                     // if (mdata.value)
                     //    $display("mdata.value: %d", mdata.value);
                     if (mdata.sign == 1'b0)
                        mix <= mix + mdata.value;
                     else
                        mix <= mix - mdata.value;
                  end 
            end 
         end 
      end 
   
endmodule
