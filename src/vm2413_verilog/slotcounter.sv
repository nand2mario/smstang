//
// SlotCounter.vhd
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
module SlotCounter(clk, reset, clkena, slot, stage);
   parameter    delay = 0;
   input        clk;
   input        reset;
   input        clkena;
   
   output [4:0] slot;
   output [1:0] stage;
   
   reg [6:0]    ff_count;
   
   
   always @(posedge reset or posedge clk)
      if (reset == 1'b1)
         ff_count <= 7'b1000111 - delay;
      else  begin
         if (clkena) begin
            if (ff_count == 7'b1000111)		// 71
               ff_count <= '0;
            else
               ff_count <= ff_count + 1;
         end 
      end 
   
   assign stage = ff_count[1:0];		//0-3 cycle
   assign slot  = ff_count[6:2];		//0-17 cycle
   
endmodule
