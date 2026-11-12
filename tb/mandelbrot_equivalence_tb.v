

`timescale 1ns/1ps

module mandelbrot_equivalence_tb;

reg clk;
reg rst;
reg start;

reg [15:0] max_iter;

// single pe
wire [8:0] single_x;
wire [7:0] single_y;
wire [15:0] single_iterations;
wire single_escaped;
wire single_valid;
wire single_done;

// 2 pe
wire parallel_valid;
wire [8:0] parallel_x;
wire [7:0] parallel_y;
wire [15:0] parallel_iterations;
wire parallel_escaped;
wire parallel_done;
wire [4:0] fifo_count;

integer single_count;
integer parallel_count;

integer single_index;
integer parallel_index;
integer i;

reg [15:0] single_results [0:11];
reg [15:0] parallel_results [0:11];

reg single_escape_results [0:11];
reg parallel_escape_results [0:11];

reg [11:0] single_seen;
reg [11:0] parallel_seen;

mandelbrot_renderer #(
    .IMAGE_WIDTH(4),
    .IMAGE_HEIGHT(3)
) single_renderer (
    .clk(clk),
    .rst(rst),
    .start(start),
    .max_iter(max_iter),

    .result_x(single_x),
    .result_y(single_y),
    .result_iterations(single_iterations),
    .result_escaped(single_escaped),
    .result_valid(single_valid),

    .frame_done(single_done)
);

mandelbrot_renderer_2pe #(
    .IMAGE_WIDTH(4),
    .IMAGE_HEIGHT(3),
    .FIFO_DEPTH(16)
) parallel_renderer (
    .clk(clk),
    .rst(rst),
    .start(start),
    .max_iter(max_iter),

    .result_x(parallel_x),
    .result_y(parallel_y),
    .result_iterations(parallel_iterations),
    .result_escaped(parallel_escaped),
    .result_valid(parallel_valid),
    .result_ready(1'b1),

    .generation_done(parallel_done),
    .fifo_count(fifo_count)
);

always #5 clk = ~clk;

//capture single pe results 
always @(posedge clk) begin 
  #1;

  if(!rst && single_valid) begin

    single_index = single_y * 4 + single_x;

    if(single_index < 0 || single_index >= 12)
      $fatal(1, "single pe: invalid coordinate");

    if(single_seen[single_index])
      $fatal(1, "single pe: duplicate pixel");

    single_results[single_index] = single_iterations;
    single_escape_results[single_index] = single_escaped;

    single_seen[single_index] = 1'b1;
    single_count = single_count + 1;

  end 
end 

//capture two pe results 
always @(posedge clk) begin 
  #1;

  if(!rst && parallel_valid) begin

    parallel_index = parallel_y * 4 + parallel_x;

    if(parallel_index < 0 || parallel_index >= 12)
      $fatal(1, "two pe: invalid coordinate");

    if(parallel_seen[parallel_index])
      $fatal(1, "two pe: duplicate pixel");

    parallel_results[parallel_index] = parallel_iterations;
    parallel_escape_results[parallel_index] = parallel_escaped;

    parallel_seen[parallel_index] = 1'b1;
    parallel_count = parallel_count + 1;

  end 
end 

initial begin
  $dumpfile("sim/mandelbrot_equivalence.vcd");
  $dumpvars(0, mandelbrot_equivalence_tb);

  clk = 0;
  rst = 1;
  start = 0;
  max_iter = 8;

  single_count = 0;
  parallel_count = 0;

  single_seen = 0;
  parallel_seen = 0;

  single_index = 0;
  parallel_index = 0;

  for (i = 0; i < 12; i = i + 1) begin
    single_results[i] = 0;
    parallel_results[i] = 0;

    single_escape_results[i] = 0;
    parallel_escape_results[i] = 0;
  end

  repeat (2) @(negedge clk);
  rst = 0;

  @(negedge clk);
  start = 1;

  @(negedge clk);
  start = 0;

  wait (single_count == 12 && parallel_count == 12 && single_done && parallel_done && fifo_count == 0);

  @(negedge clk);

  for (i = 0; i < 12; i = i + 1) begin

    if (!single_seen[i] || !parallel_seen[i])
      $fatal(1, "missing pixel at %0d", i);

    if (single_results[i] !== parallel_results[i]) begin

      $display("iteration mismatch at index %0d: single = %0d, parallel = %0d", i, single_results[i], parallel_results[i]);

      $fatal(1,"numerical equivalence failed");

    end

    if (single_escape_results[i] !== parallel_escape_results[i]) begin

      $display("escape mismatch at index %0d: single = %0d, parallel = %0d", i, single_escape_results[i], parallel_escape_results[i]);

      $fatal(1,"escape equivalence failed");

    end

    $display("Pass: pixel=(%0d,%0d), iterations=%0d, escape=%b",i%4, i/4, single_results[i], single_escape_results[i]);

  end

  $display("===========================================");
  $display("pass: numerical equivalence");
  $display("single pe results %0d",single_count);
  $display("two pe results %0d",parallel_count);
  $display("===========================================");

  $finish;

end

initial begin
  #100000;
  $fatal(1,"timeout");
end

endmodule


