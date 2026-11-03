

`timescale 1ns/1ps

module mandelbrot_escape_tb;

reg signed [15:0] x;
reg signed [15:0] y;

wire escaped;
wire signed [20:0] magnitude_squared;

//instantiate escape detector 


mandelbrot_escape dut (
      
      .x(x),
      .y(y),
      .escaped(escaped),
      .magnitude_squared(magnitude_squared)
);


task test_escape;

      input signed [15:0] tx;
      input signed [15:0] ty;

      input expected_escaped;
      input signed [20:0] expected_magnitude;

      begin
      
          x = tx;
          y = ty;

          #10;

          $display("x = %0d | y = %0d | mangnitude = %0d | escaped = %0d", x, y, magnitude_squared, escaped);

          if((escaped !== expected_escaped) || (magnitude_squared !== expected_magnitude))
            $fatal(1, "escape detector test failed");

          $display("test passed");

      end 

endtask

initial begin 

      $dumpfile("sim/mandelbrot_escape.vcd");
      $dumpvars(0, mandelbrot_escape_tb);

      // test 1 : origin
      // 0^2 + 0^2 = 0
      test_escape(16'sd0, 16'sd0, 1'b0, 21'sd0);

      // test 2 : 1 + 0i
      // magnitude_squared = 1
      test_escape(16'sd4096, 16'sd0, 1'b0, 21'sd4096);

      // test 3 : 1 + 1i
      // magnitude_squared = 2
      test_escape(16'sd4096, 16'sd4096, 1'b0, 21'sd8192);

      // test 4 : 2 + 0i
      // magnitude_squared = 4
      test_escape(16'sd8192, 16'sd0, 1'b0, 21'sd16384);
        
      // test 5 : 3 + 0i
      // magnitude_squared = 9
      test_escape(16'sd12288, 16'sd0, 1'b1, 21'sd36864);

      // test 6 : 2 + 2i
      // magnitude_squared = 8
      test_escape(16'sd8192, 16'sd8192, 1'b1, 21'sd32768);

      // test 7 : -3 + 0i
      // magnitude_squared = 9
      test_escape(-16'sd12288, 16'sd0, 1'b1, 21'sd36864);

      // test 8 : -1 + 1i
      // magnitude_squared = 2
      test_escape(-16'sd4096, 16'sd4096, 1'b0, 21'sd8192);

      $display("all tests passed");

      $finish;
end

endmodule
