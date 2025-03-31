//
// Opll.vhd
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
module opll(xin, xout, xena, d, a, cs_n, we_n, ic_n, mixout);
   input         xin;
   output        xout;
   input         xena;
   input [7:0]   d;
   input         cs_n;     // {cs_n,we_n,a0} is command: 000=reg addr, 001=reg data, 011=hi-z
   input         we_n;
   input         a;
   input         ic_n;
   output [13:0] mixout;
   
   wire          reset;
   
   reg [7:0]     opllptr;
   reg [7:0]     oplldat;
   reg           opllwr;
   
   AM_TYPE       am;
   PM_TYPE       pm;
   WF_TYPE       wf;
   DB_TYPE       tl;
   FB_TYPE       fb;
   AR_TYPE       ar;
   DR_TYPE       dr;
   SL_TYPE       sl;
   RR_TYPE       rr;
   ML_TYPE       ml;
   FNUM_TYPE     fnum;
   BLK_TYPE      blk;
   RKS_TYPE      rks;
   wire          key;
   
   wire          rhythm;
   
   wire           noise;
   wire [17:0]    pgout;
   wire [12:0]    egout;
   wire [13:0]    opout;
   
   CH_TYPE        faddr;
   SLOT_TYPE      maddr;
   SIGNED_LI_TYPE fdata;
   SIGNED_LI_TYPE mdata;
   
   wire [6:0]    state2;
   wire [6:0]    state5;
   wire [6:0]    state8;
   SLOT_TYPE     slot;
   SLOT_TYPE     slot2;
   SLOT_TYPE     slot5;
   SLOT_TYPE     slot8;
   STAGE_TYPE    stage;
   STAGE_TYPE    stage2;
   STAGE_TYPE    stage5;
   STAGE_TYPE    stage8;
   
   assign xout = xin;
   assign reset = ~ic_n;
   
   always @(posedge xin or posedge reset)
      if (reset) begin
         opllwr <= 1'b0;
         opllptr <= {8{1'b0}};
      end else begin
         if (xena) begin
            if (cs_n == 1'b0 & we_n == 1'b0 & a == 1'b0) begin
               opllptr <= d;
               opllwr <= 1'b0;
            end else if (cs_n == 1'b0 & we_n == 1'b0 & a) begin
               oplldat <= d;
               opllwr <= 1'b1;
            end 
         end 
      end 
   
   SlotCounter #(0) s0(
      .clk(xin),
      .reset(reset), 
      .clkena(xena), 
      .slot(slot), 
      .stage(stage));
   
   SlotCounter #(2) s2(
      .clk(xin), 
      .reset(reset), 
      .clkena(xena), 
      .slot(slot2), 
      .stage(stage2));
   
   SlotCounter #(5) s5(
      .clk(xin), 
      .reset(reset), 
      .clkena(xena), 
      .slot(slot5), 
      .stage(stage5));
   
   SlotCounter #(8) s8(
      .clk(xin), 
      .reset(reset), 
      .clkena(xena), 
      .slot(slot8), 
      .stage(stage8));
   
   // no delay
   controller controller(
      .clk(xin), .reset(reset), .clkena(xena), 
      .slot(slot), .stage(stage), .wr(opllwr), .addr(opllptr), 
      .data(oplldat), .am(am), .pm(pm), .wf(wf), .ml(ml), .tl(tl), 
      .fb(fb), .ar(ar), .dr(dr), .sl(sl), .rr(rr), .blk(blk), 
      .fnum(fnum), .rks(rks), .key(key), .rhythm(rhythm));
   
   // 2 stages delay
   EnvelopeGenerator envelopegen(.clk(xin), .reset(reset), .clkena(xena), 
      .slot(slot2), .stage(stage2), .rhythm(rhythm), 
      .am(am), .tl(tl), .ar(ar), .dr(dr), .sl(sl), .rr(rr), 
      .rks(rks), .key(key), .egout(egout));
   
   PhaseGenerator phasegen(
      .clk(xin), .reset(reset), .clkena(xena), 
      .slot(slot2), .stage(stage2), .rhythm(rhythm), 
      .pm(pm), .ml(ml), .blk(blk), .fnum(fnum), .key(key), 
      .noise(noise), .pgout(pgout));
   
   // 5 stages delay
   Operator operator(
      .clk(xin), .reset(reset), .clkena(xena), 
      .slot(slot5), .stage(stage5), .rhythm(rhythm), 
      .wf(wf), .fb(fb), .noise(noise), .pgout(pgout), .egout(egout), 
      .faddr(faddr), .fdata(fdata), .opout(opout));
   
   // 8 stages delay
   OutputGenerator outputgen(
      .clk(xin), .reset(reset), .clkena(xena), 
      .slot(slot8), .stage(stage8), .rhythm(rhythm), 
      .opout(opout), .faddr(faddr), .fdata(fdata), 
      .maddr(maddr), .mdata(mdata));
   
   // independent from delay
   TemporalMixer temporalmixer(
      .clk(xin), .reset(reset), .clkena(xena), 
      .slot(slot), .stage(stage), .rhythm(rhythm), 
      .maddr(maddr), .mdata(mdata), .mixout(mixout));
   
endmodule
