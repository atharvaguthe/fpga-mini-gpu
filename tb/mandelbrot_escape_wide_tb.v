

`timescale 1ns/1ps

module mandelbrot_escape_wide_tb;

reg signed [20:0] x;
reg signed [20:0] y;

wire escaped;
wire [30:0] magnitude_squared;

mandelbrot_escape_wide uut(
      .x(x),
      .y(y),
      .escaped(escaped),
      .magnitude_squared(magnitude_squared)
);

task check;
      
      input signed [20:1] test_x;
      input signed [20:1] test_y;
      input expected_escape;
      input [30:0] expected_magnitude;

      begin
          
          x = test_x;
          y = test_y;
          #10;

          if(escaped == expected_escape && magnitude_squared == expected_magnitude)
            $display("pass : x = %0d | y = %0d | magnitude = %0d | escaped = %0d", x, y, magnitude_squared, escaped);

          else 
            $display("fail : x = %0d | y = %0d | magnitude = %0d | escaped = %0d", x, y, magnitude_squared, escaped);


        end 

endtask

initial begin 
        
        check(0, 0, 0, 0);

        check(21'sd4096, 0, 0, 31'sd4096);

        check(21'sd4096, 21'sd4096, 0, 31'sd8192);

        check(21'sd8192, 0, 0, 31'sd16384);

        check(21'sd12288, 0, 1, 31'sd36864);

        check(-21'sd12288, 0, 1, 31'sd36864);

        check(21'sd8192, 21'sd8192, 1, 31'sd32768);

        check(0, 21'sd12288, 1, 31'sd36864);

        $display("Wide escape detector test complete");

        $finish;

end

endmodule
