

`timescale 1ns/1ps

module result_fifo_2pe_tb;

reg clk;
reg rst;

reg in_valid0, in_valid1;
wire in_ready0, in_ready1;

reg [8:0] in_x0, in_x1;
reg [7:0] in_y0, in_y1;
reg [15:0] in_iterations0, in_iterations1;
reg in_escaped0, in_escaped1;

wire out_valid;
reg out_ready;

wire [8:0] out_x;
wire [7:0] out_y;
wire [15:0] out_iterations;
wire out_escaped;

wire [2:0] count;

result_fifo_2pe #(
  .DEPTH(4)
) dut (
  .clk(clk),
  .rst(rst),

  .in_valid0(in_valid0),
  .in_ready0(in_ready0),
  .in_x0(in_x0),
  .in_y0(in_y0),
  .in_iterations0(in_iterations0),
  .in_escaped0(in_escaped0),

  .in_valid1(in_valid1),
  .in_ready1(in_ready1),
  .in_x1(in_x1),
  .in_y1(in_y1),
  .in_iterations1(in_iterations1),
  .in_escaped1(in_escaped1),

  .out_valid(out_valid),
  .out_ready(out_ready),
  .out_x(out_x),
  .out_y(out_y),
  .out_iterations(out_iterations),
  .out_escaped(out_escaped),

  .count(count)
);

always #5 clk = ~clk;

task read_and_check;

    input [8:0] expected_x;
    input [7:0] expected_y;
    input [15:0] expected_iterations;
    input expected_escaped;

    begin

        @(negedge clk);

        if (!out_valid)
            $fatal(1, "FIFO unexpectedly empty");

        if (out_x !== expected_x ||
            out_y !== expected_y ||
            out_iterations !== expected_iterations ||
            out_escaped !== expected_escaped) begin

            $display("EXPECTED: x=%0d y=%0d iterations=%0d escaped=%b",
                     expected_x, expected_y,
                     expected_iterations, expected_escaped);

            $display("ACTUAL:   x=%0d y=%0d iterations=%0d escaped=%b",
                     out_x, out_y, out_iterations, out_escaped);

            $display("FIFO count=%0d", count);

            $fatal(1, "FIFO data mismatch");

        end

        $display("PASS: (%0d,%0d), iterations=%0d, escaped=%b",
                 out_x, out_y, out_iterations, out_escaped);

        out_ready = 1;

        @(negedge clk);
        out_ready = 0;

    end

endtask

initial begin 

  $dumpfile("sim/result_fifo.vcd");
  $dumpvars(0,result_fifo_2pe_tb);

  clk = 0;
  rst = 1;

  in_valid0 = 0;
  in_valid1 = 0;
  out_ready = 0;

  in_x0 = 0;
  in_y0 = 0;
  in_iterations0 = 0;
  in_escaped0 = 0;

  in_x1 = 0;
  in_y1 = 0;
  in_iterations1 = 0;
  in_escaped1 = 0;

  repeat (2) @(negedge clk);
  rst = 0;

  @(negedge clk);

  in_valid0 = 1;
  in_x0 = 0;
  in_y0 = 0;
  in_iterations0 = 1;
  in_escaped0 = 1;

  in_valid1 = 1;
  in_x1 = 1;
  in_y1 = 0;
  in_iterations1 = 5;
  in_escaped1 = 0;

  @(negedge clk);

  in_valid0 = 0;
  in_valid1 = 0;

  if (count != 2)
    $fatal(1, "Expected 2 fifo enteries, got %0d", count);

  read_and_check(0,0,1,1);
  read_and_check(1,0,5,0);

  if(count != 0)
    $fatal(1,"fifo should be empty");

  $display("===========================");
  $display("Pass");
  $display("===========================");

  $finish;
end

initial begin
  #1000;
  $fatal(1,"timeout");
end

endmodule

