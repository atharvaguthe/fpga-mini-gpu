

`timescale 1ns/1ps

module mandelbrot_step_q16 (
    input wire signed [24:0] x,
    input wire signed [24:0] y,

    input wire signed [24:0] a,
    input wire signed [24:0] b,

    output wire signed [24:0] x_next,
    output wire signed [24:0] y_next

);

wire signed [49:0] xx_raw;
wire signed [49:0] yy_raw;
wire signed [49:0] xy_raw;

assign xx_raw = x * x;
assign yy_raw = y * y;
assign xy_raw = x * y;

//Restore Q9.16 scaling

wire signed [33:0] xx;
wire signed [33:0] yy;
wire signed [33:0] xy;

assign xx = xx_raw >>> 16;
assign yy = yy_raw >>> 16;
assign xy = xy_raw >>> 16;

//extend coordinates to 34 bits 

wire signed [33:0] a_ext;
wire signed [33:0] b_ext;

assign a_ext = {{9{a[24]}}, a};
assign b_ext = {{9{b[24]}}, b};


wire signed [33:0] x_result;
wire signed [33:0] y_result;

assign x_result = xx - yy + a_ext;
assign y_result = (xy <<< 1) + b_ext;

// return the lower 25 bits

assign x_next = x_result[24:0];
assign y_next = y_result[24:0];

endmodule
