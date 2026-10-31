

`timescale 1ns/1ps

module fixed_multiplier (

      input wire signed [7:0] a,
      input wire signed [7:0] b,

      output wire signed [11:0] product
);

wire signed [15:0] raw_product;

assign raw_product = a * b;

assign product = raw_product >>> 4;

endmodule
