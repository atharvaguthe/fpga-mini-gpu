`timescale 1ns/1ps

module mandelbrot_escape_detector_q16 (
      
      input wire signed [24:0] x,
      input wire signed [24:0] y,

      output wire escaped

);

// step 1 = extend inputs for multiplication


wire signed [49:0] x_ext;
wire signed [49:0] y_ext;

assign x_ext = {{25{x[24]}}, x};
assign y_ext = {{25{y[24]}}, y};


// step 2 = calculate x*x and y*y 


wire signed [99:0] xx_raw;
wire signed [99:0] yy_raw;

assign xx_raw = x_ext * x_ext;
assign yy_raw = y_ext * y_ext;


//step 3 = restore Q8.12 scaling

wire signed [49:0] xx;
wire signed [49:0] yy;

assign xx = xx_raw[49:0];
assign yy = yy_raw[49:0];




// step 5 = calculate magnitude_squared
wire [50:0] magnitude_squared;

assign magnitude_squared = {1'b0,xx} + {1'b0,yy};

localparam [50:0] ESCAPE_THRESHOLD = 51'd17179869184;

//step 6 = Escape detection
// threshold = 4.0 in Q8.12 = 16384


assign escaped = (magnitude_squared > ESCAPE_THRESHOLD);

endmodule
