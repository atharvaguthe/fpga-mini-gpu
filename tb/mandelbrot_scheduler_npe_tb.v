

`timescale 1ns/1ps

module mandelbrot_scheduler_npe_tb;

localparam NUM_PE = 4;
localparam NUM_PIXELS = 8;

reg clk;
reg rst;

reg pixel_valid;
wire pixel_ready;

reg [15:0] pixel_x;
reg [15:0] pixel_y;

reg signed [15:0] pixel_a;
reg signed [15:0] pixel_b;

wire [NUM_PE-1:0] start;
wire [NUM_PE*16-1:0] a_bus;
wire [NUM_PE*16-1:0] b_bus;
reg [15:0] max_iter;

wire [NUM_PE*16-1:0] iterations_bus;
wire [NUM_PE-1:0] escaped_bus;
wire [NUM_PE-1:0] done_bus;

wire [NUM_PE-1:0] result_valid;
wire [NUM_PE*16-1:0] result_x_bus;
wire [NUM_PE*16-1:0] result_y_bus;
wire [NUM_PE*16-1:0] result_iterations_bus;
wire [NUM_PE-1:0] result_escaped_bus;
reg [NUM_PE-1:0] result_ready;

integer result_count;
integer i;

reg [NUM_PIXELS-1:0] seen;

reg [NUM_PE-1:0] held_valid;
reg [NUM_PE*16-1:0] held_x;
reg [NUM_PE*16-1:0] held_y;
reg [NUM_PE*16-1:0] held_iterations;
reg [NUM_PE-1:0] held_escaped;

mandelbrot_pe_array #(
    .NUM_PE(NUM_PE)
) pe_array (
    .clk(clk),
    .rst(rst),
    .start(start),
    .a_bus(a_bus),
    .b_bus(b_bus),
    .max_iter(max_iter),
    .iterations_bus(iterations_bus),
    .escaped_bus(escaped_bus),
    .done_bus(done_bus)
);

mandelbrot_scheduler_npe #(
  .NUM_PE(NUM_PE)
) scheduler (
  .clk(clk),
  .rst(rst),

  .pixel_valid(pixel_valid),
  .pixel_ready(pixel_ready),
  .pixel_x(pixel_x),
  .pixel_y(pixel_y),
  .pixel_a(pixel_a),
  .pixel_b(pixel_b),

  .start(start),
  .a_bus(a_bus),
  .b_bus(b_bus),

  .pe_done(done_bus),
  .iterations_bus(iterations_bus),
  .escaped_bus(escaped_bus),
  .result_ready(result_ready),

  .result_valid(result_valid),
  .result_x_bus(result_x_bus),
  .result_y_bus(result_y_bus),
  .result_iterations_bus(result_iterations_bus),
  .result_escaped_bus(result_escaped_bus)
);

always #5 clk = ~clk;

always @(posedge clk) begin 
  if (rst) begin
    result_count = 0;
    seen = 0;
  end
  else begin
    for(i = 0; i < NUM_PE; i = i + 1) begin

      if (result_valid[i] && result_ready[i]) begin

        if (result_x_bus[i*16 +: 16] >= NUM_PIXELS)
          $fatal(1,"invalid pixel coordinate");

        if(seen[result_x_bus[i*16 +: 16]])
          $fatal(1, "duplicate result for pixel x=%0d",result_x_bus[i*16 +: 16]);

        seen[result_x_bus[i*16 +: 16]] = 1'b1;
       result_count = result_count + 1;
      
        $display("PE%0d: pixel=(%0d,%0d), iterations=%0d, escaped=%b",i,result_x_bus[i*16 +: 16],result_y_bus[i*16 +: 16],result_iterations_bus[i*16 +: 16],result_escaped_bus[i]);
        if (result_x_bus[i*16 +: 16] % 2 == 0) begin
            // Even x: expected to escape immediately
            if (result_iterations_bus[i*16 +: 16] != 1 ||
                result_escaped_bus[i] != 1)
                $fatal(1, "Incorrect result for pixel x=%0d",
                    result_x_bus[i*16 +: 16]);
        end
        else begin
            // Odd x: expected not to escape within max_iter
            if (result_iterations_bus[i*16 +: 16] != max_iter ||
                result_escaped_bus[i] != 0)
                $fatal(1, "Incorrect result for pixel x=%0d",
                    result_x_bus[i*16 +: 16]);
        end
      end
    end 
  end 
end 

task send_pixel;
  input [15:0] x;
  input [15:0] y;
  input signed [15:0] a;
  input signed [15:0] b;

  begin
    @(negedge clk);

    while (!pixel_ready)
      @(negedge clk);

    pixel_x = x;
    pixel_y = y;
    pixel_a = a;
    pixel_b = b;
    pixel_valid = 1;

    @(posedge clk);
    @(negedge clk);

    pixel_valid = 0;
  end 
endtask

initial begin 
  clk = 0;
  rst = 1;

  pixel_valid = 0;
  pixel_x = 0;
  pixel_y = 0;
  pixel_a = 0;
  pixel_b = 0;
  max_iter = 16'd64;
  result_ready = 0;
  seen = 0;

  repeat (3) @(negedge clk);
  rst = 0;

  $display("Starting 4- PE scheduler test ");

// TEST 1: Fill all PEs
$display("\nTEST 1: Filling all PEs");

for (integer p = 0; p < NUM_PE; p = p + 1) begin

    if (p % 2 == 0)
        send_pixel(p, 0, 16'sd12288, 16'sd0);
    else
        send_pixel(p, 0, 16'sd0, 16'sd0);

end

// Wait until every PE has a pending result
wait (result_valid == {NUM_PE{1'b1}});

$display("All PEs completed");

// TEST 2: Backpressure
$display("\nTEST 2: Testing backpressure");

// Save current results
held_valid = result_valid;
held_x = result_x_bus;
held_y = result_y_bus;
held_iterations = result_iterations_bus;
held_escaped = result_escaped_bus;

// Verify results remain stable
repeat (5) begin
    @(negedge clk);

    if (result_valid !== held_valid ||
        result_x_bus !== held_x ||
        result_y_bus !== held_y ||
        result_iterations_bus !== held_iterations ||
        result_escaped_bus !== held_escaped)
        $fatal(1, "Result changed during backpressure");
end

$display("PASS: Results remained stable");

// Release backpressure
result_ready = {NUM_PE{1'b1}};

// TEST 3: Submit remaining pixels
$display("\nTEST 3: Processing remaining pixels");

for (integer p = NUM_PE; p < NUM_PIXELS; p = p + 1) begin

    if (p % 2 == 0)
        send_pixel(p, 0, 16'sd12288, 16'sd0);
    else
        send_pixel(p, 0, 16'sd0, 16'sd0);

end

wait (result_count == NUM_PIXELS);

if (seen !== {NUM_PIXELS{1'b1}})
    $fatal(1, "Missing pixel results");
  #10;

  $display("==============================");
  $display("PASS: N-PE scheduler verification");
  $display("Backpressure: PASS");
  $display("Result stability: PASS");
  $display("Duplicate detection: PASS");
  $display("Missing result detection: PASS");
  $display("total pixels processed: %0d", result_count);
  $display("==============================");

  $finish;

end 

initial begin

  #1000000;
  $fatal(1,"timout");
end 

endmodule

