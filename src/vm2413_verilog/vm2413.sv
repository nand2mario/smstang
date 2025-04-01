//
// VM2413.vhd
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

// nand2mario: 
// - this is mostly hand-converted from VHDL
// - we do not need the CONV_* functions as SystemVerilog supports direct casting 
//   between structs and packed arrays
package vm2413;

typedef logic [3:0] CH_TYPE;
typedef logic [4:0] SLOT_TYPE;
typedef logic [1:0] STAGE_TYPE;

typedef logic [23:0] REGS_VECTOR_TYPE;

typedef struct packed {
   logic [3:0] inst;
   logic [3:0] vol;
   logic       sus;
   logic       key;
   logic [2:0] blk;
   logic [8:0] fnum;
} REGS_TYPE;

typedef logic [5:0] VOICE_ID_TYPE;     // range 0-37
typedef logic [35:0] VOICE_VECTOR_TYPE;

// 36 bits
typedef struct packed {
   logic am;         // AM switch - '0':off  '1':3.70Hz
   logic pm;         // PM switch - '0':stop '1':6.06Hz
   logic eg;         // Envelope type - '0':release '1':sustine
   logic kr;         // Keyscale Rate
   logic [3:0] ml;   // Multiple
   logic [1:0] kl;   // WaveForm - '0':sine '1':half-sine
   logic [5:0] tl;
   logic wf;         // WaveForm - '0':sine '1':half-sine
   logic [2:0] fb;   // Feedback
   logic [3:0] ar;   // Attack Rate
   logic [3:0] dr;   // Decay Rate
   logic [3:0] sl;   // Sustine Level
   logic [3:0] rr;   // Release Rate
} VOICE_TYPE;

typedef logic AM_TYPE;
typedef logic PM_TYPE;
typedef logic EG_TYPE;
typedef logic KR_TYPE;
typedef logic [3:0] ML_TYPE;
typedef logic [1:0] KL_TYPE;
typedef logic WF_TYPE;
typedef logic [2:0] FB_TYPE;
typedef logic [3:0] AR_TYPE;
typedef logic [3:0] DR_TYPE;
typedef logic [3:0] SL_TYPE;
typedef logic [3:0] RR_TYPE;

typedef logic [2:0] BLK_TYPE;      // Block
typedef logic [8:0] FNUM_TYPE;     // F-Number
typedef logic [3:0] RKS_TYPE;      // Rate-KeyScale

typedef logic [17:0] PHASE_TYPE;   // 18 bits phase counter
typedef logic [8:0] PGOUT_TYPE;    // Phage generator's output
typedef logic [8:0] LI_TYPE;       // Final linear output of opll
typedef logic [6:0] DB_TYPE;       // Wave in Linear

typedef logic [9:0] SIGNED_LI_VECTOR_TYPE;
typedef struct packed {
   logic sign;
   LI_TYPE value;
} SIGNED_LI_TYPE;

typedef logic [7:0] SIGNED_DB_VECTOR_TYPE;
typedef struct packed {
   logic sign;
   DB_TYPE value;
} SIGNED_DB_TYPE;

// Envelope generator states
typedef logic [1:0] EGSTATE_TYPE;

parameter [1:0]  Attack = 2'b01;
parameter [1:0]  Decay = 2'b10;
parameter [1:0]  Release = 2'b11;
parameter [1:0]  Finish = 2'b00;

typedef logic [22:0] EGPHASE_TYPE;

typedef struct packed {
   EGSTATE_TYPE state;
   EGPHASE_TYPE phase;
} EGDATA_TYPE;

typedef logic [1+22+1:0] EGDATA_VECTOR_TYPE;

// component Opll port(
//   XIN     : in std_logic;
//   XOUT    : out std_logic;
//   XENA    : in std_logic;
//   D       : in std_logic_vector(7 downto 0);
//   A       : in std_logic;
//   CS_n    : in std_logic;
//   WE_n    : in std_logic;

endpackage





