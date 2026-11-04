
module mandelbrot_escape_wide (
      input wire signed [20:0] x,
      input wire signed [20:0] y,

      output wire escaped,
      output wire [30:0] magnitude_squared
);

wire signed [41:0] x_raw;
wire signed [41:0] y_raw;

wire signed [29:0] x_squared;
wire signed [29:0] y_squared;

wire [30:0] x_squared_ext;
wire [30:0] y_squared_ext;

assign x_raw = x * x;
assign y_raw = y * y;

assign x_squared = x_raw >>> 12;
assign y_squared = y_raw >>> 12;

assign x_squared_ext = {1'b0, x_squared};
assign y_squared_ext = {1'b0, y_squared};

assign magnitude_squared = x_squared_ext + y_squared_ext;

assign escaped = (magnitude_squared > 31'd16384);

endmodule
