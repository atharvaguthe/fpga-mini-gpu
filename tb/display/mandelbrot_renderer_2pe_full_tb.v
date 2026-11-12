

`timescale 1ns/1ps

module mandelbrot_renderer_2pe_full_tb;

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
wire [4:0] fifo_count;

integer received;
integer cycles;
integer pixel_index;
integer i;

reg [76799:0] seen;
reg measuring;

mandelbrot_renderer_2pe #(
    .IMAGE_WIDTH(320),
    .IMAGE_HEIGHT(240),
    .FIFO_DEPTH(16)
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
    .fifo_count(fifo_count)
);

always #5 clk = ~clk;

always @(posedge clk) begin
  if (rst) 
    cycles = 0;
  else if (measuring)
    cycles = cycles + 1;
end 

always @(posedge clk) begin
  if (!rst && result_valid && result_ready) begin


    if(result_x >= 320 || result_y >= 240)
      $fatal(1, "invalid pixel coordinate");

    pixel_index = result_y * 320 + result_x;

    if(seen[pixel_index])
      $fatal(1, "duplicate pixel at (%0d,%0d)",result_x, result_y);

    seen[pixel_index] = 1'b1;
    received =received + 1;

    if (received % 5000 == 0) begin
      $display("Progress: %0d/ 76800 | %0.1f%% complete",received,(received * 100.0) /76800);
    end 
  end 

end

initial begin
  //$dumpfile("sim/renderer_2pe_full.vcd");
  //$dumpvars(0,mandelbrot_renderer_2pe_full_tb);

  clk = 0;
  rst = 1;
  start = 0;

  max_iter = 16;
  result_ready = 1;

  received = 0;
  cycles = 0;
  measuring = 0;
  pixel_index = 0;
  seen = 0;

  repeat (2) @(negedge clk);
  rst = 0;

  @(negedge clk);
  measuring = 1;
  start = 1;

  @(negedge clk);
  start = 0;

  $display("=================================");
  $display("renderer started");
  $display("max iterations: %od",max_iter);
  $display("=================================");

  wait(received == 76800 && generation_done && fifo_count == 0);

  @(negedge clk);
  measuring = 0;

  if(received != 76800)
    $fatal(1, "incorrect pixel count");

  for(i = 0; i < 76800; i = i + 1) begin
    if(!seen[i])
      $fatal(1,"missing pixel %0d",i);
  end

  $display("=================================");
  $display("pass");
  $display("total clock cycles: %0d",cycles);
  $display("througput: %f pixels/cycles",76800.0/cycles);
  $display("=================================");

  $finish;

end

initial begin
  #1000000000000;
  $fatal(1,"timout");
end
initial begin
    forever begin
        #1000000;

        $display(
            "HEARTBEAT: received=%0d | cycles=%0d | generation_done=%b | fifo_count=%0d",
            received,
            cycles,
            generation_done,
            fifo_count
        );

        $display(
            "COORDINATOR: x=%0d y=%0d valid=%b",
            dut.coordinate_generator.pixel_x,
            dut.coordinate_generator.pixel_y,
            dut.coordinate_generator.valid
        );

        $display(
            "PE STATUS: busy0=%b busy1=%b",
            dut.scheduler.busy0,
            dut.scheduler.busy1
        );
    end
end
endmodule 
