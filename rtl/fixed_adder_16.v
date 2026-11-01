

`timescale 1ns/1ps

module fixed_adder_16 (
      
      input wire signed [15:0] a,
      input wire signed [15:0] b,

      output wire signed [16:0] result
);


wire signed [16:0] a_ext;
wire signed [16:0] b_ext;

assign a_ext = {a[15], a};
assign b_ext = {b[15], b};


assign result = a_ext + b_ext;

endmodule
