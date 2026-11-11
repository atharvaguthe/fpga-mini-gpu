

`timescale 1ns/1ps

module mandelbrot_renderer_2pe #(
      parameter IMAGE_WIDTH = 320,
      parameter IMAGE_HEIGHT = 240,
      parameter FIFO_DEPTH = 16
)(
      input wire clk,
      input wire rst,
      input wire start,
      input wire [15:0] max_iter,

      output wire result_valid,
      input wire result_ready,

      output wire [8:0] result_x,
      output wire [7:0] result_y,
      output wire [15:0] result_iterations,
      output wire result_escaped,

      output wire generation_done,
      output wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count
);

wire [8:0] pixel_x;
wire [7:0] pixel_y;

wire signed [15:0] a;
wire signed [15:0] b;

wire pixel_valid;
wire pixel_ready;

wire pe_available0;
wire pe_available1;

wire pe_result_valid0;
wire pe_result_valid1;

wire [8:0] pe_result_x0;
wire [8:0] pe_result_x1;

wire [7:0] pe_result_y0;
wire [7:0] pe_result_y1;

wire [15:0] pe_iterations0;
wire [15:0] pe_iterations1;

wire pe_escaped0;
wire pe_escaped1;

// Pixel coordinate generator 

pixel_coordinate_generator_parallel #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT)
) coordinate_generator (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixel_ready(pixel_ready),

        .pixel_x(pixel_x),
        .pixel_y(pixel_y),

        .a(a),
        .b(b),

        .valid(pixel_valid),
        .done(generation_done)
);

// 2 : Two PE scheduler 

mandelbrot_scheduler_2pe scheduler (
        .clk(clk),
        .rst(rst),

        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),

        .pixel_x(pixel_x),
        .pixel_y(pixel_y),

        .a(a),
        .b(b),

        .max_iter(max_iter),

        .pe_available0(pe_available0),
        .pe_available1(pe_available1),

        .result_valid0(pe_result_valid0),
        .result_x0(pe_result_x0),
        .result_y0(pe_result_y0),
        .iterations0(pe_iterations0),
        .escaped0(pe_escaped0),

        .result_valid1(pe_result_valid1),
        .result_x1(pe_result_x1),
        .result_y1(pe_result_y1),
        .iterations1(pe_iterations1),
        .escaped1(pe_escaped1)
);

// 3: result collector 

pe_result_collector_2pe #(
        .FIFO_DEPTH(FIFO_DEPTH)
) result_collector (
        .clk(clk),
        .rst(rst),

        .pe_valid0(pe_result_valid0),
        .pe_x0(pe_result_x0),
        .pe_y0(pe_result_y0),
        .pe_iterations0(pe_iterations0),
        .pe_escaped0(pe_escaped0),

        .pe_valid1(pe_result_valid1),
        .pe_x1(pe_result_x1),
        .pe_y1(pe_result_y1),
        .pe_iterations1(pe_iterations1),
        .pe_escaped1(pe_escaped1),

        .pe_available0(pe_available0),
        .pe_available1(pe_available1),

        .result_valid(result_valid),
        .result_ready(result_ready),

        .result_x(result_x),
        .result_y(result_y),
        .result_iterations(result_iterations),
        .result_escaped(result_escaped),

        .fifo_count(fifo_count)

);

endmodule
