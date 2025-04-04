// Cheat Code handling by Kitrinx
// Apr 21, 2019

// Code layout:
// {clock bit, 32'bcode flags, 32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

module CODES(
	input  clk,        // Best to not make it too high speed for timing reasons
	input  reset,      // This should only be triggered when a new rom is loaded or before new codes load, not warm reset
	input  enable,
	output reg available,
	input  [ADDR_WIDTH - 1:0] addr_in,
	input  [DATA_WIDTH - 1:0] data_in,
	input  [128:0] code,
	output reg genie_ovr,
	output reg [DATA_WIDTH - 1:0] genie_data
);

parameter ADDR_WIDTH   = 16; // Not more than 32
parameter DATA_WIDTH   = 8;  // Not more than 32
parameter MAX_CODES    = 32;

localparam INDEX_SIZE  = $clog2(MAX_CODES-1); // Number of bits for index, must accomodate MAX_CODES

localparam DATA_S      = DATA_WIDTH - 1;
localparam COMP_S      = DATA_S + DATA_WIDTH;
localparam ADDR_S      = COMP_S + ADDR_WIDTH;
localparam COMP_F_S    = ADDR_S + 1;
localparam ENA_F_S     = COMP_F_S + 1;

reg [ENA_F_S:0] codes[MAX_CODES];

wire [ADDR_WIDTH-1: 0] code_addr    = code[64+:ADDR_WIDTH];
wire [DATA_WIDTH-1: 0] code_compare = code[32+:DATA_WIDTH];
wire [DATA_WIDTH-1: 0] code_data    = code[0+:DATA_WIDTH];
wire code_comp_f = code[96];

wire [COMP_F_S:0] code_trimmed = {code_comp_f, code_addr, code_compare, code_data};

reg [INDEX_SIZE:0] index = '0;

assign available = |index;

reg code_change;
always_ff @(posedge clk) begin
	int x;
	if (reset) begin
		index <= 0;
		code_change <= 0;
		for (x = 0; x < MAX_CODES; x = x + 1) codes[x] <= '0;
	end else begin
		code_change <= code[128];
		if (code[128] && ~code_change && (index < MAX_CODES)) begin // detect posedge
			codes[index] <= {1'b1, code_trimmed};
			index <= index + 1'b1;
		end
	end
end

always_comb begin
	int x;
	genie_ovr = 0;
	genie_data = '0;

	if (enable) begin
		for (x = 0; x < MAX_CODES; x = x + 1) begin
			if (codes[x][ENA_F_S] && codes[x][ADDR_S-:ADDR_WIDTH] == addr_in) begin
				if (!codes[x][COMP_F_S] || (codes[x][COMP_S-:DATA_WIDTH] == data_in)) begin
					genie_ovr = 1;
					genie_data = codes[x][DATA_S-:DATA_WIDTH];
				end
			end
		end
	end
end

endmodule
