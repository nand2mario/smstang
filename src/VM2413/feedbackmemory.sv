//
// FeedbackMemory.vhd
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
// This module represents a store for feedback data of all OPLL channels. The feedback
// data is written by the OutputGenerator module. Then the value written is
// read from the Operator module.
//
import vm2413::*;
module FeedbackMemory(clk, reset, wr, waddr, wdata, raddr, rdata);
   input                clk;
   input                reset;
   input                wr;
   input      [3:0]     waddr;
   input SIGNED_LI_TYPE wdata;      // signed LI_TYPE
   input      [3:0]     raddr;
   output SIGNED_LI_TYPE rdata;
   
   SIGNED_LI_TYPE data_array[0:9-1];
   
   always @(posedge clk or posedge reset) begin
      
      reg [3:0] init_ch;
      
      if (reset)
         
         init_ch = 0;
      
      else  begin
         
         if (init_ch != 9) begin
            
            data_array[init_ch] <= 0;
            init_ch = init_ch + 1;
         
         end else if (wr)
            
            data_array[waddr] <= wdata;
         
         rdata <= data_array[raddr];
      end 
   end
   
endmodule
