//
// SineTable.vhd
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

module interpolate_mul(i0, i1, o);
   input [8:0]   i0;		//Unsigned 9bit (0bit integer, 9bit decimal)
   input [11:0]  i1;		//Signed 12bit (8bit integer part, 4bit decimal part)
   output [13:0] o;		//Signed 7bit (8bit integer part, 6bit decimal part)
   
   wire [21:0]   w_mul;		//Signed 22bit (integer part 9bit, decimal part 13bit)
   
   assign w_mul = {1'b0, i0} * i1;
   assign o = w_mul[20:7];		//21bit with MSB cut, 7bit cut with decimal part lower
   
endmodule

// ----------------------------------------------------------------------------
//  conv_integer()

module SineTable(clk, clkena, wf, addr, data);
   input            clk;
   input            clkena;
   input            wf;
   input [17:0]     addr;		//integer part 9bit, decimal part 9bit
   output [13:0]    data;		//Integer part 8bit, decimal part 6bit
   
   
   //integer part 7bit, decimal part 4bit
   parameter [10:0] sin_data[0:127] = 
      {11'b11111111111, 11'b11001010000, 11'b10101010001, 11'b10010111100, 
       11'b10001010011, 11'b10000000001, 11'b01110111110, 11'b01110000101, 
       11'b01101010101, 11'b01100101001, 11'b01100000011, 11'b01011100000, 
       11'b01011000000, 11'b01010100011, 11'b01010001000, 11'b01001101111,
       11'b01001011000, 11'b01001000010, 11'b01000101101, 11'b01000011010, 
       11'b01000000111, 11'b00111110110, 11'b00111100101, 11'b00111010101, 
       11'b00111000110, 11'b00110110111, 11'b00110101001, 11'b00110011100, 
       11'b00110001111, 11'b00110000011, 11'b00101110111, 11'b00101101011, 
       11'b00101100000, 11'b00101010110, 11'b00101001011, 11'b00101000001, 
       11'b00100111000, 11'b00100101110, 11'b00100100101, 11'b00100011100, 
       11'b00100010100, 11'b00100001011, 11'b00100000011, 11'b00011111011, 
       11'b00011110100, 11'b00011101100, 11'b00011100101, 11'b00011011110, 
       11'b00011010111, 11'b00011010001, 11'b00011001010, 11'b00011000100, 
       11'b00010111110, 11'b00010111000, 11'b00010110010, 11'b00010101100, 
       11'b00010100111, 11'b00010100001, 11'b00010011100, 11'b00010010111, 
       11'b00010010010, 11'b00010001101, 11'b00010001000, 11'b00010000011, 
       11'b00001111111, 11'b00001111010, 11'b00001110110, 11'b00001110010, 
       11'b00001101110, 11'b00001101010, 11'b00001100110, 11'b00001100010, 
       11'b00001011110, 11'b00001011010, 11'b00001010111, 11'b00001010011, 
       11'b00001010000, 11'b00001001101, 11'b00001001001, 11'b00001000110, 
       11'b00001000011, 11'b00001000000, 11'b00000111101, 11'b00000111011, 
       11'b00000111000, 11'b00000110101, 11'b00000110011, 11'b00000110000, 
       11'b00000101110, 11'b00000101011, 11'b00000101001, 11'b00000100111, 
       11'b00000100101, 11'b00000100010, 11'b00000100000, 11'b00000011110, 
       11'b00000011101, 11'b00000011011, 11'b00000011001, 11'b00000010111, 
       11'b00000010110, 11'b00000010100, 11'b00000010011, 11'b00000010001, 
       11'b00000010000, 11'b00000001110, 11'b00000001101, 11'b00000001100, 
       11'b00000001011, 11'b00000001010, 11'b00000001001, 11'b00000001000,
       11'b00000000111, 11'b00000000110, 11'b00000000101, 11'b00000000100, 
       11'b00000000011, 11'b00000000011, 11'b00000000010, 11'b00000000010, 
       11'b00000000001, 11'b00000000001, 11'b00000000000, 11'b00000000000, 
       11'b00000000000, 11'b00000000000, 11'b00000000000, 11'b00000000000};
   
   reg [10:0]       ff_data0;		// 7bit, 4bit, 4bit, 100%
   reg [10:0]       ff_data1;		// 7bit, 4bit, 4bit, 100%
   wire [13:0]      w_wf;
   wire [6:0]       w_xor;
   wire [6:0]       w_addr0;
   wire [6:0]       w_addr1;
   wire [6:0]       w_xaddr;
   reg              ff_sign;
   reg              ff_wf;
   reg [8:0]        ff_weight;
   wire [11:0]      w_sub;		   // Signed integer part 8bit, decimal part 4bit
   wire [13:0]      w_mul;		   // Signed integer part 8bit, decimal part 6bit
   wire [13:0]      w_inter;
   reg [13:0]       ff_data;
   
   assign w_xor = {7{addr[16]}};
   assign w_xaddr = addr[15:9] ^ w_xor;
   assign w_addr0 = w_xaddr;
   assign w_addr1 = addr[15:9] == 7'b1111111 ? 7'b1111111 ^ w_xor : 		//Handling the parts where the waveform is circulating
                   (addr[15:9] + 1) ^ w_xor;
   
   //Waveform memory
   always @(posedge clk)
       begin
         if (clkena) begin
            ff_data0 <= sin_data[w_addr0];
            ff_data1 <= sin_data[w_addr1];
         end 
      end 
   
   //Delay in modifier information (matches the read delay of the waveform memory)
   
   always @(posedge clk)
       begin
         if (clkena) begin
            ff_sign <= addr[17];
            ff_wf <= wf & addr[17];
            ff_weight <= addr[8:0];
         end 
      end 
   
   // Interpolation (*It will be 0 at places that span the code, so ff_sign is not a concern)
   // o = i0 * (1 - k) + i1 * w = i0 - w * i0 + w * i1 = i0 + w * (i1 - i0)
   assign w_sub = ({1'b0, ff_data1}) - ({1'b0, ff_data0});
   
   interpolate_mul u_interpolate_mul(
      .i0(ff_weight),   //Unsigned 9bit (0bit integer, 9bit decimal)
      .i1(w_sub),       //Signed 8bit (Integer part 8bit)
      .o(w_mul));        //Unsigned 7bit (Integer part 8bit)
   
   // Leave the lower 6 bits (decimal part) to maintain computational accuracy
   assign w_inter = {ff_data0, 2'b00} + w_mul;		//"00" matches the digits
   assign w_wf = {14{ff_wf}};
   
   always @(posedge clk)
       begin
         if (clkena)
            // The result of the interpolation operation is added to FF to absorb the operation delay.
            ff_data <= {ff_sign, w_inter[12:0]} | w_wf;
      end 
   
   assign data = ff_data;
   
endmodule

//------------------------------------------------------------------------
//  addr        X addr input  X
//  w_addr0     X fixed      X
//  w_addr1     X fixed      X
//  ff_data0                X fixed      X
//  ff_data1                X fixed      X
//  ff_sign                 X fixed      X
//  ff_wf                   X fixed      X
//  ff_weight               X fixed      X
//  w_sub                   X fixed      X
//  w_mul                   X fixed      X
//  w_inter                 X fixed      X
//  w_wf                    X fixed      X
//  ff_data                             X fixed      X
//  data                                X fixed      X
//  Operator
//    stage     X 01        X 10        X 11        X 00        X
//
//Operator obtains an output based on the input value input when stage = 01
//Must be received with stage = 11.
//
//2cycle delay from addressing until a corresponding value is obtained
//