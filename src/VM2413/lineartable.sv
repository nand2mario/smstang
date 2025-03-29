//
// LinearTable.vhd
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

// ----------------------------------------------------------------------------
import vm2413::*;
module linear_table_mul(i0, i1, o);
   input [5:0]  i0;		//Unsigned 6bit (6bit decimal)
   input [9:0]  i1;		//Signed 10bit (integer part 10bit)
   output [9:0] o;		//Signed 10bit (integer part 10bit)
   
   wire [16:0]  w_mul;		//Signed 17bit (16bit integer part)
   
   assign w_mul = {1'b0, i0} * i1;
   assign o = w_mul[15:6];		//MSB cut, decimal part lower 6bit cut
   
endmodule

// ----------------------------------------------------------------------------

module LinearTable(clk, reset, addr, data);
   input           clk;
   input           reset;
   input [13:0]    addr;		//Integer part 8bit, decimal part 6bit
   output SIGNED_LI_TYPE data;
   
   parameter [8:0] log2lin_data[0:127] = 
      {9'b111111111, 9'b111101001, 9'b111010100, 9'b111000000, 
       9'b110101101, 9'b110011011, 9'b110001010, 9'b101111001, 
       9'b101101001, 9'b101011010, 9'b101001011, 9'b100111101, 
       9'b100110000, 9'b100100011, 9'b100010111, 9'b100001011, 
       9'b100000000, 9'b011110101, 9'b011101010, 9'b011100000, 
       9'b011010111, 9'b011001110, 9'b011000101, 9'b010111101, 
       9'b010110101, 9'b010101101, 9'b010100110, 9'b010011111, 
       9'b010011000, 9'b010010010, 9'b010001011, 9'b010000110, 
       9'b010000000, 9'b001111010, 9'b001110101, 9'b001110000, 
       9'b001101011, 9'b001100111, 9'b001100011, 9'b001011110, 
       9'b001011010, 9'b001010111, 9'b001010011, 9'b001001111, 
       9'b001001100, 9'b001001001, 9'b001000110, 9'b001000011, 
       9'b001000000, 9'b000111101, 9'b000111011, 9'b000111000, 
       9'b000110110, 9'b000110011, 9'b000110001, 9'b000101111, 
       9'b000101101, 9'b000101011, 9'b000101001, 9'b000101000, 
       9'b000100110, 9'b000100100, 9'b000100011, 9'b000100001, 
       9'b000100000, 9'b000011110, 9'b000011101, 9'b000011100, 
       9'b000011011, 9'b000011001, 9'b000011000, 9'b000010111, 
       9'b000010110, 9'b000010101, 9'b000010100, 9'b000010100, 
       9'b000010011, 9'b000010010, 9'b000010001, 9'b000010000, 
       9'b000010000, 9'b000001111, 9'b000001110, 9'b000001110, 
       9'b000001101, 9'b000001101, 9'b000001100, 9'b000001011, 
       9'b000001011, 9'b000001010, 9'b000001010, 9'b000001010, 
       9'b000001001, 9'b000001001, 9'b000001000, 9'b000001000, 
       9'b000001000, 9'b000000111, 9'b000000111, 9'b000000111, 
       9'b000000110, 9'b000000110, 9'b000000110, 9'b000000101, 
       9'b000000101, 9'b000000101, 9'b000000101, 9'b000000101, 
       9'b000000100, 9'b000000100, 9'b000000100, 9'b000000100, 
       9'b000000100, 9'b000000011, 9'b000000011, 9'b000000011, 
       9'b000000011, 9'b000000011, 9'b000000011, 9'b000000011, 
       9'b000000010, 9'b000000010, 9'b000000010, 9'b000000010, 
       9'b000000010, 9'b000000010, 9'b000000010, 9'b000000000};
   
   reg             ff_sign;
   reg [5:0]       ff_weight;
   reg [8:0]       ff_data0;
   reg [8:0]       ff_data1;
   
   wire [12:6]     w_addr1;
   wire [8:0]      w_data;
   wire [9:0]      w_sub;		//Signed
   wire [9:0]      w_mul;
   wire [9:0]      w_inter;

   assign w_addr1 = ((addr[12:6] != 7'b1111111)) ? (addr[12:6] + 1) : 
                    7'b1111111;
   
   always @(posedge clk)
       begin
         //The corresponding value appears on the next addressed cycle (1cycle delay)
         ff_data0 <= log2lin_data[(addr[12:6])];
         ff_data1 <= log2lin_data[w_addr1];
      end 
   
   
   always @(posedge clk)
       begin
         ff_sign <= addr[13];
         ff_weight <= addr[5:0];
      end 
   
   // Interpolation (*It will be 0 at places that span the code, so ff_sign is not a concern)
   // o = i0 * (1 - k) + i1 * w = i0 - w * i0 + w * i1 = i0 + w * (i1 - i0)
   assign w_sub = {1'b0, ff_data1} - {1'b0, ff_data0};
   
   linear_table_mul u_linear_table_mul(.i0(ff_weight), .i1(w_sub), .o(w_mul));
   
   assign w_inter = {1'b0, ff_data0} + w_mul;
   
   always @(posedge clk) begin
      data.sign <= ff_sign;
      data.value  <= w_inter[8:0];
   end
   
endmodule
