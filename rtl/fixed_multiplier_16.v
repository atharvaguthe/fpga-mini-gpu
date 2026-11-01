

`timescale 1ns/1ps

module fixed_multiplier_16 (

        input wire signed [15:0] a,
        input wire signed [15:0] b,

        output wire signed [19:0] product
);

wire signed [31:0] raw_product;

assign raw_product = a * b;

assign product = raw_product >>> 12;

endmodule
