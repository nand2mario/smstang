//
// EnvelopeMemory.vhd
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
module EnvelopeMemory(clk, reset, waddr, wr, wdata, raddr, rdata);
   input     clk;
   input     reset;
   
   input [4:0]            waddr;
   input                  wr;
   input EGDATA_TYPE      wdata;
   input [4:0]            raddr;
   output EGDATA_TYPE rdata;
   
   reg [24:0] egdata_set [0:18-1];
   
   always @(posedge clk or posedge reset) begin
      
      reg [4:0] init_slot;
      
      if (reset)
         
         init_slot = 0;
      
      else  begin
         
         if (init_slot != 18) begin
            egdata_set[init_slot] <= {25{1'b1}};
            init_slot = init_slot + 1;
         end else if (wr)
            egdata_set[waddr] <= 25'(wdata);
            
         rdata <= EGDATA_TYPE'(egdata_set[raddr]);
      end 
   end
   
endmodule
