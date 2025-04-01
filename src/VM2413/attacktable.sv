//
//AttackTable.vhd
//Envelope attack shaping table for VM2413
//
//Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
//All rights reserved.
//
//Redistribution and use of this source code or any derivative works, are
//permitted provided that the following conditions are met:
//
//1. Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//3. Redistributions may not be sold, nor may they be used in a commercial
//   product or activity without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
//TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//

//
// modified by t.hara
//

//-----------------------------------------------------------------------------

import vm2413::*;

// nand2mario: the original code uses ieee.std_logic_signed. so the multiplication is signed.
module attack_table_mul(i0, i1, o);
   input         [7:0]   i0;		// Unsigned 8bit (0bit integer part, 8bit decimal part)
   input  signed [7:0]   i1;		// Signed 8bit (Integer part 8bit)
   output signed [13:0]  o;		// Signed 14bit (8bit integer part, 6bit decimal part)
   
   wire signed [16:0] w_mul;
   
   assign w_mul = signed'({1'b0, i0}) * i1;
   assign o = w_mul[15:2];		//bit16 is the same as bit15 so cut it. Truncate bits 1 to 0 (decimal part).
endmodule

//-----------------------------------------------------------------------------
module AttackTable(clk, clkena, addr, data);
   input             clk;
   input             clkena;
   input [21:0]      addr;		//Decimal part 15bit
   output reg [12:0] data;		//Decimal part 6bit
   
   parameter [6:0] ar_adjust[0:127] = 
     {7'b0000000, 7'b0000000, 7'b0000000, 7'b0000000, 7'b0000000, 7'b0000001, 7'b0000001, 7'b0000001, 
      7'b0000001, 7'b0000001, 7'b0000010, 7'b0000010, 7'b0000010, 7'b0000010, 7'b0000011, 7'b0000011, 
      7'b0000011, 7'b0000011, 7'b0000100, 7'b0000100, 7'b0000100, 7'b0000100, 7'b0000100, 7'b0000101, 
      7'b0000101, 7'b0000101, 7'b0000110, 7'b0000110, 7'b0000110, 7'b0000110, 7'b0000111, 7'b0000111, 
      7'b0000111, 7'b0000111, 7'b0001000, 7'b0001000, 7'b0001000, 7'b0001001, 7'b0001001, 7'b0001001, 
      7'b0001001, 7'b0001010, 7'b0001010, 7'b0001010, 7'b0001011, 7'b0001011, 7'b0001011, 7'b0001100, 
      7'b0001100, 7'b0001100, 7'b0001101, 7'b0001101, 7'b0001101, 7'b0001110, 7'b0001110, 7'b0001110, 
      7'b0001111, 7'b0001111, 7'b0001111, 7'b0010000, 7'b0010000, 7'b0010001, 7'b0010001, 7'b0010001, 
      7'b0010010, 7'b0010010, 7'b0010011, 7'b0010011, 7'b0010100, 7'b0010100, 7'b0010101, 7'b0010101, 
      7'b0010101, 7'b0010110, 7'b0010110, 7'b0010111, 7'b0010111, 7'b0011000, 7'b0011000, 7'b0011001, 
      7'b0011010, 7'b0011010, 7'b0011011, 7'b0011011, 7'b0011100, 7'b0011101, 7'b0011101, 7'b0011110, 
      7'b0011110, 7'b0011111, 7'b0100000, 7'b0100001, 7'b0100001, 7'b0100010, 7'b0100011, 7'b0100100, 
      7'b0100100, 7'b0100101, 7'b0100110, 7'b0100111, 7'b0101000, 7'b0101001, 7'b0101010, 7'b0101011, 
      7'b0101100, 7'b0101101, 7'b0101111, 7'b0110000, 7'b0110001, 7'b0110011, 7'b0110100, 7'b0110110, 
      7'b0111000, 7'b0111001, 7'b0111011, 7'b0111101, 7'b1000000, 7'b1000010, 7'b1000101, 7'b1001000, 
      7'b1001011, 7'b1010000, 7'b1010100, 7'b1011010, 7'b1100010, 7'b1101100, 7'b1110101, 7'b1111111};
   
   reg [7:0]       ff_w;
   reg [6:0]       ff_d1;
   reg [6:0]       ff_d2;
   
   wire [6:0]      w_addr1;
   wire [6:0]      w_addr2;
   wire [7:0]      w_sub;		//Signed
   wire [13:0]     w_mul;		//Signed
   wire [13:0]     w_inter;
   
   assign w_addr1 = addr[21:15];
   assign w_addr2 = addr[21:15] == 7'b1111111 ? {7{1'b1}} : w_addr1 + 1;
   
   always @(posedge clk)
      begin
         if (clkena) begin
            ff_d1 <= ar_adjust[w_addr1];
            ff_d2 <= ar_adjust[w_addr2];
         end 
      end 
   
   
   always @(posedge clk)
      begin
         if (clkena)
            ff_w <= addr[14:7];		// Since the number of bits in the data itself is 7bit, 8bit is sufficient
      end 
   
   // Interpolation (*It will be 0 at places that span the code, so ff_sign is not a concern)
   // o = i1 *(1 -k) + i2 *w = i1 -w *i1 + w *i2 = i1 + w *(i2 -i1)
   assign w_sub = {1'b0, ff_d2} - {1'b0, ff_d1};

   attack_table_mul u_attack_table_mul(
      .i0(ff_w), 
      .i1(w_sub), 
      .o(w_mul));

   assign w_inter = {1'b0, ff_d1, 6'b0} + w_mul;
   
   always @(posedge clk)
      begin
         if (clkena)
            data <= w_inter[12:0];		//MSB is always 0
      end 
   
endmodule
