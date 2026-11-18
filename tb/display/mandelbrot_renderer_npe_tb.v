

`timescale 1ns/1ps

module mandelbrot_renderer_npe_tb;

parameter IMAGE_WIDTH = 320;
parameter IMAGE_HEIGHT = 240;
parameter NUM_PE = 8;
parameter FIFO_DEPTH = 4;
parameter MAX_ITER = 256;
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
reg [31:0] lfsr;

integer result_count;
integer cycle_count;
integer result_index;
integer i;
integer csv_fd;
string csv_filename;
integer frame_start_cycle;
integer frame_end_cycle;
integer frame_cycles;

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
  if (rst) begin
    result_ready = 0;
    lfsr <= 32'hACE1_1234;
  end 
  else begin
    lfsr <= {lfsr[30:0],lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
    if (cycle_count < 150)
      result_ready <= 0;
    else 
      result_ready <= lfsr[0] | lfsr[3] | lfsr[5];
  end 
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
      if ((result_escaped !== 1'b0) &&
        (result_escaped !== 1'b1)) begin
        $fatal(1, "Unknown escape flag at (%0d,%0d)",
          result_x, result_y);
      end

      if ((^result_iterations) === 1'bx) begin
        $fatal(1, "Unknown iteration count at (%0d,%0d)",
          result_x, result_y);
      end
      $fdisplay(csv_fd, "%0d,%0d,%0d,%0d", result_x,result_y,result_iterations,result_escaped);
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
  frame_start_cycle = 0;
  frame_end_cycle = 0;
  frame_cycles = 0;

  csv_filename = $sformatf("sim/rtl_results_%0dpe.csv",NUM_PE);
  csv_fd = $fopen(csv_filename, "w");

  if (csv_fd == 0)
    $fatal(1,"Could not open RTL results CSV");

  $fdisplay(csv_fd,"x,y,iterations,escaped");

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

  frame_start_cycle = cycle_count;
  $display("\nFrame started", frame_start_cycle);

  fork 

    begin 
      wait(frame_done === 1'b1);
      @(negedge clk);
      frame_end_cycle = cycle_count;
    end 

    begin 
      #(128'd50000000000000);
      $fatal(1,"timeout: results=%0d, generation_done=%0d, fifo=%0d",result_count,generation_done,fifo_count);
    end 

  join_any 

  disable fork;

  frame_cycles = frame_end_cycle - frame_start_cycle;

  $display("");
  $display("========== PERFORMANCE ==========");
  $display("PE count          : %0d", NUM_PE);
  $display("Total clock cycles: %0d", frame_cycles);
  $display("Clock period      : 10 ns");
  $display("Frame time        : %0.3f us",
    frame_cycles * 0.01);
  $display("Cycles per pixel  : %0.3f",
    frame_cycles * 1.0 / TOTAL_PIXELS);
  $display("=================================");

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

  $fclose(csv_fd);

  $finish;

end

endmodule
