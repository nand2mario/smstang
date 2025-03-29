//
// OutputGenerator.vhd
//
// Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//      this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//      product or activity without specific prior written permission.
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
module OutputGenerator(clk, reset, clkena, slot, stage, rhythm, opout, faddr, fdata, maddr, mdata);
   input        clk;
   input        reset;
   input        clkena;
   input SLOT_TYPE slot;
   input STAGE_TYPE stage;
   
   input        rhythm;
   input [13:0] opout;
   
   input CH_TYPE faddr;
   output SIGNED_LI_TYPE fdata;
   
   input SLOT_TYPE maddr;
   output SIGNED_LI_TYPE mdata;
   
   function [8:0] AVERAGE;
      input SIGNED_LI_TYPE L;
      input SIGNED_LI_TYPE R;
      reg [8+2:0]  vL;
      reg [8+2:0]  vR;
   begin
      
      // Sign + Absolute Value -> Two's Complement
      if (L.sign == 1'b0)
         vL = {2'b00, L.value};
      else
         vL = ~{2'b00, L.value} + 1'b1;
      if (R.sign == 1'b0)
         vR = {2'b00, R.value};
      else
         vR = ~{2'b00, R.value} + 1'b1;
      
      vL = vL + vR;
      
      // Two's complement -> sign + absolute value, and then 1/2 times. One bit is gone here.
      if (vL[10] == 1'b0)		// positive
         AVERAGE = {1'b0, vL[10 - 1:1]};
      else begin              // negative
         vL = ~(vL - 1'b1);
         AVERAGE = {1'b1, vL[10 - 1:1]};
      end
   end
   endfunction
   
   reg            fb_wr;
   reg            mo_wr;
   CH_TYPE        fb_addr;
   SLOT_TYPE      mo_addr;
   SIGNED_LI_TYPE li_data;
   SIGNED_LI_TYPE fb_wdata;
   SIGNED_LI_TYPE mo_wdata;
   SIGNED_LI_TYPE mo_rdata;
   
   FeedbackMemory Fmem(
      .clk(clk), 
      .reset(reset), 
      .wr(fb_wr), 
      .waddr(fb_addr), 
      .wdata(fb_wdata), 
      .raddr(faddr), 
      .rdata(fdata));
   
   OutputMemory Mmem(
      .clk(clk), 
      .reset(reset), 
      .wr(mo_wr), 
      .addr(mo_addr), 
      .wdata(mo_wdata), 
      .rdata(mo_rdata), 
      .addr2(maddr), 
      .rdata2(mdata));
   
   
   LinearTable Ltbl(
      .clk(clk), 
      .reset(reset), 
      .addr(opout),        // 0 to 127 (opout is an output of FF so it's fine to put it directly)
      .data(li_data));		// 0-511
   
   always @(posedge reset or posedge clk)
      if (reset) begin
         mo_wr <= 1'b0;
         fb_wr <= 1'b0;
      end else  begin
         if (clkena) begin
            mo_addr <= slot;
            
            if (stage == 0) begin
               mo_wr <= 1'b0;
               fb_wr <= 1'b0;
            end else if (stage == 1)
               ;     // Stage where the desired value is entered in opout
            else if (stage == 2)
               ;     // Waiting
            else if (stage == 3) begin
               // Stage where the value corresponding to the address specified by opout appears from LinerTable
               if (slot[0] == 1'b0) begin
                  // Only written to feedback memory when using modulators
                  fb_addr <= slot/2;
                  fb_wdata <= AVERAGE(mo_rdata, li_data);
                  fb_wr <= 1'b1;
               end 
               // Store raw output
               mo_wdata <= li_data;
               mo_wr <= 1'b1;
            end 
         end 
      end 
   
endmodule
