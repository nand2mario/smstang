//
// VoiceMemory.vhd
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
module VoiceMemory(clk, reset, idata, wr, rwaddr, roaddr, odata, rodata);
   input        clk;
   input        reset;
   
   input VOICE_TYPE     idata;
   input                wr;
   input VOICE_ID_TYPE  rwaddr;		// read/write address
   input VOICE_ID_TYPE  roaddr;		// read only address
   output VOICE_TYPE    odata;
   output VOICE_TYPE    rodata;
   
   // The following array is mapped into a Single-Clock Synchronous RAM with two-read
   // addresses by Altera's QuartusII compiler.
   VOICE_TYPE     voices [0:37];
   
   VOICE_ID_TYPE  rom_addr;
   VOICE_TYPE     rom_data;
   logic [1:0]    rstate;
   
   VoiceRom ROM2413(clk, rom_addr, rom_data);
   
   always @(posedge clk or posedge reset) begin
      reg [5:0] init_id;
      
      if (reset) begin
         init_id = 0;
         rstate <= 0;
      
      end else  begin
         if (init_id != 37 + 1)
            case (rstate)
               0: begin
                  rom_addr <= init_id;
                  rstate <= 1;
               end
               1: rstate <= 2;
               2: begin
                  voices[init_id] <= rom_data;
                  rstate <= 0;
                  init_id = init_id + 1;
               end
            endcase
         
         else if (wr)
            voices[rwaddr] <= idata;
         
         odata <= voices[rwaddr];
         rodata <= voices[roaddr];
      end 
   end
   
endmodule
