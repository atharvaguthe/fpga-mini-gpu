`timescale 1ns/1ps

module mandelbrot_escape (
      
      input wire signed [15:0] x,
      input wire signed [15:0] y,

      output wire escaped,

      output wire signed [20:0] magnitude_squared
);

// step 1 = extend inputs for multiplication


wire signed [31:0] x_ext;
wire signed [31:0] y_ext;

assign x_ext = {{16{x[15]}}, x};
assign y_ext = {{16{y[15]}}, y};


// step 2 = calculate x*x and y*y 


wire signed [31:0] xx_raw;
wire signed [31:0] yy_raw;

assign xx_raw = x_ext * x_ext;
assign yy_raw = y_ext * y_ext;


//step 3 = restore Q8.12 scaling

wire signed [19:0] xx;
wire signed [19:0] yy;

assign xx = xx_raw >>> 12;
assign yy = yy_raw >>> 12;


// step 4 = extend both squares to 21 bits 

wire signed [20:0] xx_ext;
wire signed [20:0] yy_ext;

assign xx_ext = {xx[19], xx};
assign yy_ext = {yy[19], yy};


// step 5 = calculate magnitude_squared

assign magnitude_squared = xx_ext + yy_ext;

//step 6 = Escape detection
// threshold = 4.0 in Q8.12 = 16384


assign escaped = (magnitude_squared > 21'sd16384);

endmodule
