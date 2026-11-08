
`timescale 1ns/1ps

module mandelbrot_pe_pair (
      
      input wire clk,
      input wire rst,
      input wire start0,
      input wire start1,

      input wire signed [15:0] a0,
      input wire signed [15:0] b0,

      input wire signed [15:0] a1,
      input wire signed [15:0] b1,

      input wire [15:0] max_iter,

      output wire [15:0] iterations0,
      output wire escaped0,
      output wire done0,

      output wire [15:0] iterations1,
      output wire escaped1,
      output wire done1
);

mandelbrot_pe pe0 (
      .clk(clk),
      .rst(rst),
      .start(start0),

      .a(a0),
      .b(b0),
      .max_iter(max_iter),

      .iterations(iterations0),
      .escaped(escaped0),
      .done(done0)
);

mandelbrot_pe pe1 (
      .clk(clk),
      .rst(rst),
      .start(start1),

      .a(a1),
      .b(b1),
      .max_iter(max_iter),

      .iterations(iterations1),
      .escaped(escaped1),
      .done(done1)
);

endmodule
