//
// Operator.vhd
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
module Operator(clk, reset, clkena, slot, stage, rhythm, wf, fb, noise, pgout, egout, faddr, fdata, opout);
   input            clk;
   input            reset;
   input            clkena;
   
   input SLOT_TYPE  slot;
   input STAGE_TYPE stage;
   input            rhythm;
   
   input WF_TYPE    wf;
   input FB_TYPE    fb;
   
   input            noise;
   input [17:0]     pgout;		//integer part 9bit, decimal part 9bit
   input [12:0]     egout;
   
   output CH_TYPE faddr;
   input SIGNED_LI_TYPE fdata;
   
   output reg [13:0]  opout;		//Integer part 8bit, decimal part 6bit
   
   reg  [17:0]    addr;
   wire [13:0]    data;
   wire           w_is_carrier;
   wire [8+2+9:0] w_modula_m;
   wire [8+2+9:0] w_modula_c;
   wire [8+2+9:0] w_modula;
   reg  [12:0]    ff_egout;
   
   //  Sine wave (logarithmic representation) -----------------------------------------------------------
   //  addr data appears in the specified cycles one after the other
   //
   //  stage   X 00    X 01    X 10    X 11    X 00
   //  addr            X Fixed
   //  data                            X Fixed
   //  opout                                   X Fixed
   //
   SineTable u_sine_table(
      .clk(clk), 
      .clkena(clkena), 
      .wf(wf), 
      .addr(addr),     //integer part 9bit, decimal part 9bit
      .data(data));    //Integer part 8bit, decimal part 6bit
   
   assign w_is_carrier = slot[0];
   assign w_modula_m = (fb == 3'b000) ? {12{1'b0}} : 
                       {1'b0, fdata.value, 1'b0, 9'b000000000} >> (3'b111 ^ fb);
   assign w_modula_c = {fdata.value, 2'b00, 9'b000000000};
   assign w_modula = ((w_is_carrier)) ? w_modula_c : w_modula_m;
   
   always @(posedge reset or posedge clk) begin
      reg [13:0]     opout_buf;		//Integer part 8bit, decimal part 6bit

      if (reset) begin
         opout <= {14{1'b0}};
         ff_egout <= {13{1'b0}};
      end else  begin
         if (clkena) begin
            if (stage == 2'b00) begin
               // Stage that determines the reference address (phase) of the sine wave
               if (rhythm & (slot == 14 | slot == 17))		// HH or CYM
                  addr <= {~noise, 8'b01111111, 9'b000000000};
               else if (rhythm & slot == 15)		// SD
                  addr <= {~pgout[17], 8'b01111111, 9'b000000000};
               else if (rhythm & slot == 16)		// TOM
                  addr <= pgout;
               else
                  if (fdata.sign == 1'b0)		//modula is a value that shifts the absolute value of fdata, so we handle the sign here.
                     addr <= pgout + w_modula[17:0];
                  else
                     addr <= pgout - w_modula[17:0];
            
            end else if (stage == 2'b01)
               ;    // Stage where the determined reference address is fed to u_sine_table
            else if (stage == 2'b10) begin
               ff_egout <= egout;
               
               // Stage to determine the address of the feedback memory
               if (slot[0]) begin
                  if (slot/2 == 8)
                     faddr <= 0;
                  else
                     faddr <= slot/2 + 1;		//Because it is the address of the next modulator, +1
               end 
            end else if (stage == 2'b11) begin
               // Stages where data comes out from SineTable
               if ({1'b0, ff_egout} + {1'b0, data[12:0]} < 14'b10000000000000)
                  opout_buf = {data[13], ff_egout + data[12:0]};
               else
                  opout_buf = {data[13], 13'b1111111111111};
               opout <= opout_buf;
            end 
         end 
      end 
   end
   
endmodule
