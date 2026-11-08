

`timescale 1ns/1ps

module mandelbrot_escape_detector_q16_tb;

reg signed [24:0] x;
reg signed [24:0] y;

wire escaped;

//instantiate escape detector 


mandelbrot_escape_detector_q16 dut (
      
      .x(x),
      .y(y),
      .escaped(escaped)
);


task check_escape;

      input signed [24:0] tx;
      input signed [24:0] ty;

      input expected;

      begin
      
          x = tx;
          y = ty;

          #10;

          if(escaped === expected)
            $display("Pass: x=%0d y=%0d escaped=%b",x,y,escaped);
          else 
            $fatal(1,"fail: x=%0d y=%0d expected=%b actual=%b",x, y, expected,escaped);

      end 

endtask

initial begin 

      $dumpfile("sim/mandelbrot_escape_detector_q16.vcd");
      $dumpvars(0, mandelbrot_escape_detector_q16_tb);

      // Test 1: Origin

      check_escape(25'sd0, 25'sd0, 1'b0);

      // Test 2: x = 1, y = 0

      check_escape(25'sd65536, 25'sd0, 1'b0);

      // Test 3: x = 2, y = 0
      // Boundary: condition is strictly greater than 4.

      check_escape(25'sd131072, 25'sd0, 1'b0);

      // Test 4: x = 2.25, y = 0

      check_escape(25'sd147456, 25'sd0, 1'b1);

      // Test 5: x = 1.5, y = 1.5
      // 1.5^2 + 1.5^2 = 4.5

      check_escape(25'sd98304, 25'sd98304, 1'b1);

      // Test 6: x = -2.25, y = 0

      check_escape(-25'sd147456, 25'sd0, 1'b1);

      // Test 7: x = 1.5, y = 1

      check_escape(25'sd98304, 25'sd65536, 1'b0);
      $display("all tests passed");

      $finish;
end

endmodule
