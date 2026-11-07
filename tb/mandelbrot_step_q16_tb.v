
`timescale 1ns/1ps

module mandelbrot_step_q16_tb;

reg signed [24:0] x, y;
reg signed [24:0] a, b;

wire signed [24:0] x_next, y_next;

mandelbrot_step_q16 dut (
      .x(x),
      .y(y),
      .a(a),
      .b(b),
      .x_next(x_next),
      .y_next(y_next)
);

task test_step;

      input signed [24:0] tx, ty;
      input signed [24:0] ta, tb;

      input signed [24:0] expected_x, expected_y;

      begin
          
          x = tx;
          y = ty;
          a = ta;
          b = tb;

          #10;

          $display("Actual: x %0d y=%0d",x_next,y_next);
          $display("Expected: x=%0d y=%0d",expected_x, expected_y);

          if (x_next !== expected_x || y_next !== expected_y)
            $fatal(1, "Q9.16 test failed");

          $display("test passed");
      end 
endtask

initial begin
      
      $dumpfile("sim/mandelbrot_step_q16.vcd");
      $dumpvars(0,mandelbrot_step_q16_tb);

      test_step(25'sd0, 25'sd0, -25'sd49152, 25'sd8192, -25'sd49152, 25'sd8192);

      test_step(-25'sd49152, 25'sd8192, -25'sd49152, 25'sd8192, -25'sd13312, -25'sd4096);

      test_step(25'sd0, 25'sd0, -25'sd32768, 25'sd32768, -25'sd32768, 25'sd32768);

      test_step(-25'sd32768, 25'sd32768, -25'sd32768, 25'sd32768, -25'sd32768, 25'sd0);

      $display("All tests passed");

      $finish;

end 

endmodule


