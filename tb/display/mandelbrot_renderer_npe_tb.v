

`timescale 1ns/1ps

module mandelbrot_renderer_npe_tb;

localparam IMAGE_WIDTH = 32;
localparam IMAGE_HEIGHT = 24;
localparam NUM_PE = 4;
localparam FIFO_DEPTH = 32;
localparam MAX_ITER = 64;
localparam TOTAL_PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;
localparam FIFO_COUNT_W = $clog2(FIFO_DEPTH + 1);

reg clk;
reg rst;
reg start;
reg [15:0] max_iter;

wire result_valid;
reg result_ready;

wire [8:0] result_x;
wire [7:0] result_y;
wire [15:0] result_iterations;
wire result_escaped;

wire generation_done;
wire frame_done;

wire [FIFO_COUNT_W-1:0] fifo_count;
reg [TOTAL_PIXELS-1:0] seen;

integer result_count;
integer cycle_count;
integer result_index;
integer i;

mandelbrot_renderer_npe #(
  .IMAGE_WIDTH(IMAGE_WIDTH),
  .IMAGE_HEIGHT(IMAGE_HEIGHT),
  .NUM_PE(NUM_PE),
  .FIFO_DEPTH(FIFO_DEPTH)
) dut (
  .clk(clk),
  .rst(rst),
  .start(start),
  .max_iter(max_iter),

  .result_valid(result_valid),
  .result_ready(result_ready),

  .result_x(result_x),
  .result_y(result_y),
  .result_iterations(result_iterations),
  .result_escaped(result_escaped),

  .generation_done(generation_done),
  .frame_done(frame_done),

  .fifo_count(fifo_count)
);

always #5 clk = ~clk;

always @(negedge clk) begin 
  if (rst)
    result_ready = 0;

  else 
    result_ready = ((cycle_count % 7) != 0) && ((cycle_count % 11) != 0);

end 

always @(posedge clk) begin 
  if (rst) begin
    result_count = 0;
    cycle_count = 0;
    seen = 0;
  end
  else begin 
    cycle_count = cycle_count + 1;
    if (result_valid && result_ready) begin

      if (result_x >= IMAGE_WIDTH || result_y >= IMAGE_HEIGHT)
        $fatal(1, "invalid coordinate: (%0d,%0d)",result_x, result_y);

      result_index = result_y * IMAGE_WIDTH + result_x;

      if(seen[result_index])
        $fatal(1,"Duplicate pixel: (%0d,%0d)",result_x, result_y);

      seen[result_index] = 1'b1;
      result_count = result_count + 1;

      if (result_iterations > MAX_ITER)
        $fatal(1, "invalid iterations count at (%0d,%0d): %0d",result_x, result_y,result_iterations);

      $display("pixel %0d/%0d: (%0d,%0d), iterations=%0d,escaped=%0d, fifo=%0d",result_count,TOTAL_PIXELS,result_x,result_y,result_iterations,result_escaped,fifo_count);

    end 
  end 
end

initial begin 
  clk = 0;
  rst = 1;
  start = 0;

  max_iter = MAX_ITER;
  result_ready = 0;

  seen = 0;
  result_count = 0;
  cycle_count = 0;
  result_index = 0;

  $display("===================================");
  $display("N-pe mandelbrot renderer test");
  $display("Resolution: %0d, %0d",IMAGE_WIDTH, IMAGE_HEIGHT);
  $display("Processing elements: %0d",NUM_PE);
  $display("Max iterations: %0d", MAX_ITER);
  $display("fifo depth:%0d",FIFO_DEPTH);
  $display("===================================");

  repeat (4) @(negedge clk);

  rst = 0;

  @(negedge clk);
  start = 1;

  @(negedge clk);
  start = 0;

  $display("\nFrame started");

  fork 

    begin 
      wait(frame_done === 1'b1);
    end 

    begin 
      #1000000;
      $fatal(1,"timeout: results=%0d, generation_done=%0d, fifo=%0d",result_count,generation_done,fifo_count);
    end 

  join_any 

  disable fork;

  #1;
  if(result_count != TOTAL_PIXELS)
    $fatal(1,"Expected %0d pixels, received %0d",TOTAL_PIXELS,result_count);

  for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
    if (seen[i] !== 1'b1)
      $fatal(1,"Missing pixel at linear index %0d",i);

  end 
  if (fifo_count != 0)
    $fatal(1, "fifo not empty at frame completion");

  $display("===================================");
  $display("PASS: N-PE MANDELBROT FRAME RENDERED");
  $display("Resolution: %0d x %0d",
    IMAGE_WIDTH, IMAGE_HEIGHT);
  $display("PE count: %0d", NUM_PE);
  $display("Expected pixels: %0d", TOTAL_PIXELS);
  $display("Received pixels: %0d", result_count);
  $display("Missing pixels: 0");
  $display("Duplicate pixels: 0");
  $display("Coordinate bounds: PASS");
  $display("Iteration bounds: PASS");
  $display("Output backpressure: PASS");
  $display("Frame completion: PASS");
  $display("========================================");

  $finish;

end

// Global simulation timeout

initial begin

  #1000000;

  $fatal(1, "Simulation timeout");

end

endmodule
