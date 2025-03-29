// A simple audio mixer which avoids attenuation by clipping extremities
//
// Copyright 2020 by Alastair M. Robinson

module AudioMix(clk, reset_n, audio_in_l1, audio_in_l2, audio_in_r1, audio_in_r2, audio_l, audio_r);
   input         clk;
   input         reset_n;
   input signed [15:0]  audio_in_l1;
   input signed [15:0]  audio_in_l2;
   input signed [15:0]  audio_in_r1;
   input signed [15:0]  audio_in_r2;
   output reg signed [15:0] audio_l;
   output reg signed [15:0] audio_r;
   
   wire signed [15:0]   in1;
   wire signed [15:0]   in2;
   wire signed [16:0]   sum;
   wire                 overflow;
   wire signed [16:0]   clipped;
   reg                  toggle;
   
   assign in1 = (toggle == 1'b0) ? audio_in_l1 : audio_in_r1;
   assign in2 = (toggle == 1'b0) ? audio_in_l2 : audio_in_r2;
   
   assign sum = {in1[15], in1} + {in2[15], in2};
   assign overflow = sum[15] ^ sum[16];
   
   assign clipped = (overflow == 1'b0) ? sum : {17{sum[16]}};
      
   always @(posedge clk) begin
      if (toggle == 1'b0)
         audio_l <= clipped[15:0];
      else
         audio_r <= clipped[15:0];
      toggle <= ~toggle;
   end 
   
endmodule
