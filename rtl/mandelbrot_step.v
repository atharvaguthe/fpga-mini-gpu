`timescale 1ns/1ps

module mandelbrot_step (

    input wire signed [20:0] x,
    input wire signed [20:0] y,

    input wire signed [15:0] a,
    input wire signed [15:0] b,

    output wire signed [20:0] x_next,
    output wire signed [20:0] y_next
);

// 21-bit x/y multiplied together produce 42-bit results.

wire signed [41:0] xx_raw;
wire signed [41:0] yy_raw;
wire signed [41:0] xy_raw;

assign xx_raw = x * x;
assign yy_raw = y * y;
assign xy_raw = x * y;

// Restore Q9.12 scaling.

wire signed [29:0] xx;
wire signed [29:0] yy;
wire signed [29:0] xy;

assign xx = xx_raw >>> 12;
assign yy = yy_raw >>> 12;
assign xy = xy_raw >>> 12;

// Extend a and b to 30 bits.

wire signed [29:0] a_ext;
wire signed [29:0] b_ext;

assign a_ext = {{14{a[15]}}, a};
assign b_ext = {{14{b[15]}}, b};

// Calculate next coordinates using 30-bit intermediates.

wire signed [29:0] x_result;
wire signed [29:0] y_result;

assign x_result = xx - yy + a_ext;
assign y_result = (xy <<< 1) + b_ext;

// Output the 21-bit results.

assign x_next = x_result[20:0];
assign y_next = y_result[20:0];

endmodule
