// Dual-port RAM of any size
module dpram
 #(  parameter widthad_a = 8, // address width (therefore total size is 2**widthad_a)
     parameter width_a = 8,   // data width
     parameter init_file = "" // initialization hex file, optional
  )( 
     input      [widthad_a-1:0] address_a , // address      for port A
     input      [widthad_a-1:0] address_b , // address      for port B
     input                 clock_a,
     input                 clock_b,
     input      [width_a-1:0] data_a, // write data   for port A
     input      [width_a-1:0] data_b, // write data   for port B
     input                 wren_a , // write enable for port A
     input                 wren_b , // write enable for port B
     output reg [width_a-1:0] q_a, // read  data   for port A
     output reg [width_a-1:0] q_b  // read  data   for port B
  );

    reg [width_a-1:0] mem [0:2**widthad_a-1]; // memory array
    initial
        if (init_file != "") $readmemh(init_file, mem);

    // PORT A
    always @(posedge clock_a) 
        if (wren_a)
            mem[address_a] <= data_a;

    always @(posedge clock_a) 
        if (!wren_a)
            q_a <= mem[address_a]; 

    // PORT B
    always @(posedge clock_b) 
        if (wren_b) 
            mem[address_b] <= data_b;

    always @(posedge clock_b)
        if (!wren_b)
            q_b <= mem[address_b];

endmodule