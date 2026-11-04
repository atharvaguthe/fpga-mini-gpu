
`timescale 1ns/1ps

module mandelbrot_pe (
      input wire clk,
      input wire rst,
      input wire start,

      input wire signed [15:0] a,
      input wire signed [15:0] b,
      input wire [15:0] max_iter,

      output wire [15:0] iterations,
      output wire escaped,
      output wire done

);

// input registers

reg signed [15:0] a_reg;
reg signed [15:0] b_reg;
reg [15:0] max_iter_reg;

always @(posedge clk) begin
      if (rst) begin
        a_reg <= 16'sd0;
        b_reg <= 16'sd0;
        max_iter_reg <= 16'sd0;
      end 
      else if (start) begin
        a_reg <= a;
        b_reg <= b;
        max_iter_reg <= max_iter;
      end
end


// control signals

wire initialize;
wire update;
wire count_enable;

wire escaped_wire;
wire max_reached;

assign max_reached = (iterations >= max_iter_reg);


//fsm

mandelbrot_fsm control_unit (
      .clk(clk),
      .rst(rst),
      .start(start),

      .escaped(escaped_wire),
      .max_reached(max_reached),

      .initialize(initialize),
      .update(update),
      .done(done),
      .count_enable(count_enable)
);

// x/y registers

wire signed [20:0] x_reg;
wire signed [20:0] y_reg;

wire signed [20:0] x_next;
wire signed [20:0] y_next;

mandelbrot_registers coordinate_registers (
      .clk(clk),
      .rst(rst),
      .initialize(initialize),
      .load(update),

      .x_next(x_next),
      .y_next(y_next),

      .x_reg(x_reg),
      .y_reg(y_reg)
);

// mandelbrot arithmatics

mandelbrot_step datapath (
      .x(x_reg),
      .y(y_reg),
      .a(a_reg),
      .b(b_reg),

      .x_next(x_next),
      .y_next(y_next)
);

// escape detection

wire [30:0] magnitude_squared;

mandelbrot_escape_wide escape_detector (
      .x(x_next),
      .y(y_next),

      .escaped(escaped_wire),
      .magnitude_squared(magnitude_squared)
);

// iteration counter 

iteration_counter counter (
      .clk(clk),
      .rst(rst),
      .clear(initialize),
      .enable(count_enable),

      .count(iterations)
);

// final escape result

assign escaped = escaped_wire;

endmodule
