module sprom #(
    parameter widthad_a = 15,
    parameter width_a = 8,
    parameter init_file = ""        // hex file for initialization
) (
    input [widthad_a-1:0] address,
    input clock,
    output reg [width_a-1:0] q
);

    reg [width_a-1:0] mem [0:2**widthad_a-1]; // memory array
    initial
        if (init_file != "") $readmemh(init_file, mem);

    always @(posedge clock)
        q <= mem[address];

endmodule
