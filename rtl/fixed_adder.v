

`timescale 1ns/1ps

module fixed_adder (
      input wire signed [7:0] a,
      input wire signed [7:0] b,

      output wire signed [8:0] result
);

wire signed [8:0] a_ext;
wire signed [8:0] b_ext;


assign a_ext = {a[7], a};
assign b_ext = {b[7], b};


assign result = a_ext + b_ext;

endmodule
