

`timescale 1ns/1ps

module pe_result_collector_2pe #(
      parameter FIFO_DEPTH = 16
) (
      input wire clk,
      input wire rst,

      input wire pe_valid0,
      input wire [8:0] pe_x0,
      input wire [7:0] pe_y0,
      input wire [15:0] pe_iterations0,
      input wire pe_escaped0,

      input wire pe_valid1,
      input wire [8:0] pe_x1,
      input wire [7:0] pe_y1,
      input wire [15:0] pe_iterations1,
      input wire pe_escaped1,

      output wire result_valid,
      input wire result_ready,

      output wire [8:0] result_x,
      output wire [7:0] result_y,
      output wire [15:0] result_iterations,
      output wire result_escaped,

      output wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count
);

wire hold_valid0;
wire hold_valid1;

wire [8:0] hold_x0;
wire [7:0] hold_y0;
wire [15:0] hold_iterations0;
wire hold_escaped0;

wire [8:0] hold_x1;
wire [7:0] hold_y1;
wire [15:0] hold_iterations1;
wire hold_escaped1;

wire fifo_ready0;
wire fifo_ready1;

pe_result_hold hold0 (
      .clk(clk),
      .rst(rst),

      .capture_valid(pe_valid0),
      .capture_x(pe_x0),
      .capture_y(pe_y0),
      .capture_iterations(pe_iterations0),
      .capture_escaped(pe_escaped0),

      .out_valid(hold_valid0),
      .out_ready(fifo_ready0),

      .out_x(hold_x0),
      .out_y(hold_y0),
      .out_iterations(hold_iterations0),
      .out_escaped(hold_escaped0)
);

pe_result_hold hold1 (
      .clk(clk),
      .rst(rst),

      .capture_valid(pe_valid1),
      .capture_x(pe_x1),
      .capture_y(pe_y1),
      .capture_iterations(pe_iterations1),
      .capture_escaped(pe_escaped1),

      .out_valid(hold_valid1),
      .out_ready(fifo_ready1),

      .out_x(hold_x1),
      .out_y(hold_y1),
      .out_iterations(hold_iterations1),
      .out_escaped(hold_escaped1)
);

result_fifo_2pe #(
      .DEPTH(FIFO_DEPTH)
) result_fifo (
      .clk(clk),
      .rst(rst),

      .in_valid0(hold_valid0),
      .in_ready0(fifo_ready0),
      .in_x0(hold_x0),
      .in_y0(hold_y0),
      .in_iterations0(hold_iterations0),
      .in_escaped0(hold_escaped0),

      .in_valid1(hold_valid1),
      .in_ready1(fifo_ready1),
      .in_x1(hold_x1),
      .in_y1(hold_y1),
      .in_iterations1(hold_iterations1),
      .in_escaped1(hold_escaped1),

      .out_valid(result_valid),
      .out_ready(result_ready),
      .out_x(result_x),
      .out_y(result_y),
      .out_iterations(result_iterations),
      .out_escaped(result_escaped),

      .count(fifo_count)
);

endmodule
