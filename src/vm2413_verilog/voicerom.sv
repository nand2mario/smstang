//
// VoiceRom.vhd
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
// 36'bAS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
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
// based on bumbed voices:  https://siliconpr0n.org/archive/doku.php?id=vendor:yamaha:opl2

import vm2413::*;
module VoiceRom(clk, addr, data);
   parameter        VRC7 = 1'b0;
   input            clk;
   input VOICE_ID_TYPE addr;
   output VOICE_TYPE data;
   
   localparam VOICE_TYPE base_voices[0:37] = '{
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000000000000000000000000000000000,      // @0(M)
      36'b000000000000000000000000000000000000,      // @0(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b011100010001111001111101000000000000,      // @1(M)
      36'b011000010000000010000111100000010111,      // @1(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000100110001101011011101100000100011,      // @2(M)
      36'b010000010000000000001111011100010011,      // @2(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000100111001100100001111001000010001,      // @3(M)
      36'b000000010000000000001100010000100011,      // @3(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001100010000111001111010100001110000,      // @4(M)
      36'b011000010000000000000110010000100111,      // @4(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001100100001111001101110000000000000,      // @5(M)
      36'b001000010000000000000111011000101000,      // @5(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001100010001011001011110000000000000,      // @6(M)
      36'b001000100000000000000111000100011000,      // @6(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001000010001110101111000001000010000,      // @7(M)
      36'b011000010000000000001000000100000111,      // @7(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001000110010110101001010001000000000,      // @8(M)
      36'b001000010000000010000111001000000111,      // @8(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b011000010001101101100110010000010000,      // @9(M)
      36'b011000010000000000000110010100010111,      // @9(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b010000010000101110001000010101110001,      // @10(M)
      36'b011000010000000010001111011100000111,      // @10(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000100111000001100011111101000010000,      // @11(M)
      36'b000000010000000010001110010000000100,      // @11(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000101110010010001111111100000100010,      // @12(M)
      36'b110000010000000000001111100000010010,      // @12(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b011000010000110001011100001000100000,      // @13(M)
      36'b010100000000000000001111010101000010,      // @13(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000010101010100111100100100000011,      // @14(M)
      36'b000000010000000000001001010100000010,      // @14(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b011000011000100100111111000101000000,      // @15(M)
      36'b010000010000000000001110010000010011,      // @15(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000010001100011111101111101101010,      // BD(M)
      36'b000000010000000000001111100001101101,      // BD(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000010000000000001100100010100111,      // HH
      36'b000000010000000000001101100001001000,      // SD
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000001010000000000001111100001011001,      // TOM
      36'b000000010000000000001010101001010101       // CYM
   };

   //Register  Bitfield   Description
   //$00       TVSK MMMM  Modulator tremolo (T), vibrato (V), sustain (S), key rate scaling (K), multiplier (M)
   //$01       TVSK MMMM  Carrier tremolo (T), vibrato (V), sustain (S), key rate scaling (K), multiplier (M)
   //$02       KKOO OOOO  Modulator key level scaling (K), output level (O)
   //$03       KK-Q WFFF  Carrier key level scaling (K), unused (-), carrier waveform (Q), modulator waveform (W), feedback (F)
   //$04       AAAA DDDD  Modulator attack (A), decay (D)
   //$05       AAAA DDDD  Carrier attack (A), decay (D)
   //$06       SSSS RRRR  Modulator sustain (S), release (R)
   //$07       SSSS RRRR  Carrier sustain (S), release (R)
   
   parameter VOICE_TYPE vrc7_voices[0:37] = {
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000000000000000000000000000000000, // @0(M)
      36'b000000000000000000000000000000000000, // @0(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000110000010101101110100001000010, // @1(M)
      36'b001000010000000000001000000100100111, // @1(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000100110001010011011101100000100011, // @2(M)
      36'b010000010000000000001111011000010010, // @2(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000100010000100010001111101000100000, // @3(M)
      36'b000100010000000000001011001000010010, // @3(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001100010000110001111010100001100001, // @4(M)
      36'b011000010000000000000110010000100111, // @4(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001100100001111001101110000100000001, // @5(M)
      36'b001000010000000000000111011000101000, // @5(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000100000011000001010001111110100, // @6(M)
      36'b000000010000000000001110001011110100, // @6(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001000010001110101111000001000010001, // @7(M)
      36'b011000010000000000001000000100000111, // @7(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001000110010001001111010001000000001, // @8(M)
      36'b001000010000000010000111001000010111, // @8(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001101010010010100000100000001110010, // @9(M)
      36'b000100010000000000000111001100000001, // @9(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b101101010000111111111010100001010001, // @10(M)
      36'b000000010000000000001010010100000010, // @10(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000101110010010001111111100000100010, // @11(M)
      36'b110000010000000000001111100000010010, // @11(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b011100010001000101100110010100011000, // @12(M)
      36'b001000110000000000000111010000010110, // @12(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000011101001101011100100100000011, // @13(M)
      36'b000000100000000000001001010100000010, // @13(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b011000010000110000001001010000110011, // @14(M)
      36'b011000110000000000001100000011110110, // @14(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b001000010000110100001100000101010110, // @15(M)
      36'b011100100000000000001101010100000110, // @15(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000010001100011111101111101101010, // BD(M)
      36'b000000010000000000001111100001101101, // BD(C)
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000000010000000000001100100010100111, // HH
      36'b000000010000000000001101100001001000, // SD
      //  APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
      36'b000001010000000000001111100001011001, // TOM
      36'b000000010000000000001010101001010101  // CYM      
   };
   
   always @(posedge clk) begin
      if (VRC7 == 1'b0)
         data <= base_voices[addr];
      else
         data <= vrc7_voices[addr];
   end
   
endmodule
