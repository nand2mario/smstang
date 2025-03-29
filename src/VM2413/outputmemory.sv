//
// OutputMemory.vhd
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
module OutputMemory(clk, reset, wr, addr, wdata, rdata, addr2, rdata2);
   input                   clk;
   input                   reset;
   input                   wr;
   input SLOT_TYPE         addr;
   input SIGNED_LI_TYPE    wdata;
   output SIGNED_LI_TYPE   rdata;
   input SLOT_TYPE         addr2;
   output SIGNED_LI_TYPE   rdata2;
   
   SIGNED_LI_TYPE data_array[0:18];
   reg [4:0] init_ch;
   
   always @(posedge clk or posedge reset) begin
      
      if (reset)
         init_ch <= 0;
      
      else begin
         
         if (init_ch != 18) begin
            data_array[init_ch].sign <= 0;
            data_array[init_ch].value <= 0;
            init_ch <= init_ch + 1;
         
         end else if (wr)
            data_array[addr] <= wdata;
         
         rdata <= data_array[addr];
         rdata2 <= data_array[addr2];
      end 
   end
   
endmodule
