module spram #(
    parameter widthad_a = 15,
    parameter width_a = 8
) (
    input [widthad_a-1:0] address,
    input clock,
    input [width_a-1:0] data,
    input wren,
    output reg [width_a-1:0] q
);

reg [width_a-1:0] mem [0:2**widthad_a-1];

always @(posedge clock) begin
    if (wren)
        mem[address] <= data;
end

always @(posedge clock) begin
    if (!wren)
        q <= mem[address];
end

endmodule