

`timescale 1ns/1ps

module signed_multiplier (

      input wire signed [7:0] a,
      input wire signed [7:0] b,

      output wire signed [15:0] product
);


//signed multiplication
assign product = a * b;

endmodule
