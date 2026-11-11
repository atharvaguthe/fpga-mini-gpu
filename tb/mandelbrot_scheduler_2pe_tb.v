
`timescale 1ns/1ps

module mandelbrot_scheduler_2pe_tb;

reg clk;
reg rst;

reg pixel_valid;
wire pixel_ready;

reg [8:0] pixel_x;
reg [7:0] pixel_y;

reg signed [15:0] a;
reg signed [15:0] b;

reg [15:0] max_iter;

reg pe_available0;
reg pe_available1;

wire result_valid0;
wire [8:0] result_x0;
wire [7:0] result_y0;
wire [15:0] iterations0;
wire escaped0;

wire result_valid1;
wire [8:0] result_x1;
wire [7:0] result_y1;
wire [15:0] iterations1;
wire escaped1;

integer result_count;

mandelbrot_scheduler_2pe dut (
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

  .result_valid0(result_valid0),
  .result_x0(result_x0),
  .result_y0(result_y0),
  .iterations0(iterations0),
  .escaped0(escaped0),

  .result_valid1(result_valid1),
  .result_x1(result_x1),
  .result_y1(result_y1),
  .iterations1(iterations1),
  .escaped1(escaped1)
);

always #5 clk = ~clk;

task send_pixel;

  input [8:0] x;
  input [7:0] y;
  input signed [15:0] real_part;
  input signed [15:0] imag_part;

  begin

    @(negedge clk);

    pixel_x = x;
    pixel_y = y;
    a = real_part;
    b = imag_part;
    pixel_valid = 1;

    while(pixel_ready !== 1'b1)
    @(negedge clk);

    @(posedge clk);
    @(negedge clk);

    pixel_valid = 0;
  end 
endtask

always @(posedge clk) begin
  if (!rst) begin

    if (result_valid0) begin
      $display("PE0 = pixel = (%0d,%0d), iterations=%0d, escaped=%b",result_x0, result_y0,iterations0, escaped0);

      if (result_x0 !== 0 || result_y0 !== 0)
        $fatal(1, "Pe0 returned incorrect pixel coordinates");

      if (escaped0 !== 1'b1)
        $fatal(1,"Pe0 should have detected escape");

      result_count = result_count + 1;

    end

    if (result_valid1) begin
      $display("PE1 = pixel = (%0d,%0d), iterations=%0d, escaped=%b",result_x1, result_y1,iterations1, escaped1);

      if (result_x1 !== 1 || result_y1 !== 0)
        $fatal(1, "Pe1 returned incorrect pixel coordinates");

      if (escaped1 !== 1'b0)
        $fatal(1,"Pe1 should have detected escape");

      result_count = result_count + 1;

    end

  end
end

initial begin

  $dumpfile("sim/scheduler.vcd");
  $dumpvars(0,mandelbrot_scheduler_2pe_tb);

  clk = 0;
  rst = 1;

  pixel_valid = 0;
  pixel_x = 0;
  pixel_y = 0;
  a = 0;
  b = 0;

  pe_available0 = 1;
  pe_available1 = 1;

  max_iter = 5;
  result_count = 0;

  repeat (2) @(negedge clk);
  rst = 0;

  // test : neither pe is pe_available 
  @(negedge clk);

  pixel_valid = 1;
  pe_available0 = 0;
  pe_available1 = 0;

  #1;

  if(pixel_ready !== 0)
    $fatal(1, "Scheduler should stall when both PEs are unavailable");

  if(dut.start0 !== 0 || dut.start1 !== 0)
    $fatal(1, "Scheduler dispatched a pixel despite backpressure");

  $display("Pass : Scheduler stall when both PEs are unavailabe");

  @(negedge clk);

  pixel_valid = 0;
  pe_available0 = 1;
  pe_available1 = 1;

  send_pixel(0,0,16'sd12288, 16'sd0);

  send_pixel(1,0,16'sd0, 16'sd0);

  wait (result_count == 2);

  $display("=============================");
  $display("Pass: both pe results verified");
  $display("=============================");

  $finish;
end

initial begin
  #1000;
  $fatal(1,"Timeout: scheduler test did not finish");
end

endmodule
