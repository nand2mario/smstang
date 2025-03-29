// this is basically hello.img but takes up less space

module test_loader (
    input clk,
    input resetn,
    output reg [7:0] dout,
    output reg dout_valid,
    output loading,
    output fail
);

// 64KB ROMS
// localparam SIZE = 65536;
// localparam string FILE = "roms/zexall.hex";

// 256KB ROMS
localparam SIZE= 262144;
localparam string FILE = "roms/outrun.hex";

reg [7:0] rom [0:SIZE-1];
initial begin
   $readmemh(FILE, rom);
   $display("Loaded %d bytes from %s", SIZE, FILE);
   $display("First 4 values: %d, %d, %d, %d", rom[0], rom[1], rom[2], rom[3]);
end

reg [$clog2(SIZE+1)-1:0] addr = 0;
assign fail = 1'b0;
assign loading = addr != SIZE;
reg [3:0] cnt;

always @(posedge clk) begin
    if (~resetn) begin
        addr <= 0;
    end else begin
        cnt <= cnt + 1;
        case (cnt)
        0: begin
            dout_valid <= 1;
            dout <= rom[addr];
            // $display("addr = %d, dout = %d", addr, rom[addr]);
        end
        1: begin
            dout_valid <= 0;
            addr <= addr + 1;
        end
        15: 
            if (addr == SIZE)
                cnt <= 15;       // done
        endcase
    end
end

endmodule
