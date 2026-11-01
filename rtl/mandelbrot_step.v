
`timescale 1ns/1ps

module mandelbrot_step (

          input wire signed [15:0] x,
          input wire signed [15:0] y,

          input wire signed [15:0] a,
          input wire signed [15:0] b,
          
          output wire signed [20:0] x_next,
          output wire signed [20:0] y_next
);

//
// Step 1 = extend inputs to 32 bits for multiplication
//


wire signed [31:0] x_ext;
wire signed [31:0] y_ext;

assign x_ext = {{16{x[15]}}, x};
assign y_ext = {{16{y[15]}}, y};


//
// Step 2 = perform multiplication
//

wire signed [31:0] xx_raw;
wire signed [31:0] yy_raw;
wire signed [31:0] xy_raw;

assign xx_raw = x_ext * x_ext;
assign yy_raw = y_ext * y_ext;
assign xy_raw = x_ext * y_ext;


//
//step 3 = Restore Q4.12 scaling
//results are now Q8.12
//

wire signed [19:0] xx;
wire signed [19:0] yy;
wire signed [19:0] xy;

assign xx = xx_raw >>> 12;
assign yy = yy_raw >>> 12;
assign xy = xy_raw >>> 12;


//
//step 4 = extend intermediate values to 21 bits
//


wire signed [20:0] xx_ext;
wire signed [20:0] yy_ext;
wire signed [20:0] xy_ext;

wire signed [20:0] a_ext;
wire signed [20:0] b_ext;

assign xx_ext = {xx[19], xx};
assign yy_ext = {yy[19], yy};
assign xy_ext = {xy[19], xy};

assign a_ext = {{5{a[15]}}, a};
assign b_ext = {{5{b[15]}}, b};

//
//step 5 = calculate next real and imaginary values
//

assign x_next = xx_ext - yy_ext + a_ext;

assign y_next = (xy_ext <<< 1) + b_ext;

endmodule
