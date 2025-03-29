
// CRAM: CPU writes and VDP reads
module vdp_cram(cpu_clk, cpu_we, cpu_a, cpu_d, vdp_clk, vdp_a, vdp_d);
   input         cpu_clk;
   input         cpu_we;
   input [4:0]   cpu_a;
   input [11:0]  cpu_d;

   input         vdp_clk;
   input [4:0]   vdp_a;
   output reg [11:0] vdp_d;
   
   reg [11:0]    ram[0:31];

   initial begin
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
         ram[i] = 12'b111111111111;
      end
   end

   always @(posedge cpu_clk)
      if (cpu_we) 
         ram[cpu_a] <= cpu_d;
   
   always @(posedge vdp_clk)
      vdp_d <= ram[vdp_a];
   
endmodule

