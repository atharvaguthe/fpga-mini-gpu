

`timescale 1ns/1ps

module pixel_coordinate_generator_parallel_tb;

reg clk;
reg rst;
reg start;
reg pixel_ready;

wire [8:0] pixel_x;
wire [7:0] pixel_y;

wire signed [15:0] a;
wire signed [15:0] b;

wire valid;
wire done;

integer count;

pixel_coordinate_generator_parallel #(
      .IMAGE_WIDTH(4),
      .IMAGE_HEIGHT(3)
) dut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .pixel_ready(pixel_ready),

      .pixel_x(pixel_x),
      .pixel_y(pixel_y),

      .a(a),
      .b(b),

      .valid(valid),
      .done(done)
);

always #5 clk = ~clk;

task check_pixel;
      
      input [8:0] expected_x;
      input [7:0] expected_y;

      input signed [15:0] expected_a;
      input signed [15:0] expected_b;

      begin

        while (valid !== 1'b1)
          @(negedge clk);

          if (pixel_x !== expected_x || pixel_y !== expected_y || a !== expected_a || b !== expected_b) begin
            $fatal(1,"fail: pixel(%0d,%0d), a=%0d, b=%0d",pixel_x,pixel_y,a,b);

          end

          $display("Pass: pixel = (%0d,%0d), a=%0d, b=%0d", pixel_x, pixel_y,a,b);

          pixel_ready = 1;

          @(negedge clk);

          pixel_ready = 0;
          count = count + 1;

        end 

endtask
          

initial begin

      $dumpfile("sim/pixel_coordinate_generator_parallel.vcd");
      $dumpvars(0,pixel_coordinate_generator_parallel_tb);

      clk = 0;
      rst = 1;
      start = 0;
      pixel_ready = 0;
      count = 0;

      //reset 
      repeat (2) @(negedge clk);
      rst = 0;

      @(negedge clk);
      start = 1;

      @(negedge clk);
      start = 0;
      // Row 0: b = -6144

      check_pixel(0, 0, -8192, -6144);
      check_pixel(1, 0, -4096, -6144);
      check_pixel(2, 0, 0, -6144);
      check_pixel(3, 0, 4096, -6144);

      // Row 1: b = 0

      check_pixel(0, 1, -8192, 0);
      check_pixel(1, 1, -4096, 0);
      check_pixel(2, 1, 0, 0);
      check_pixel(3, 1, 4096, 0);

      // Row 2: b = 6144

      check_pixel(0, 2, -8192, 6144);
      check_pixel(1, 2, -4096, 6144);
      check_pixel(2, 2, 0, 6144);
      check_pixel(3, 2, 4096, 6144);

      // Verify frame completion.

      if (valid !== 0 || done !== 1)
        $fatal(1, "FAIL: Frame completion");

      if (count != 12)
        $fatal(1, "FAIL: Incorrect pixel count");

      $display("All pixels verified, frame completed");

      $finish;

end

endmodule


