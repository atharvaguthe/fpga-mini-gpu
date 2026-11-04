
`timescale 1ns/1ps

module mandelbrot_pe_tb;

reg clk;
reg rst;
reg start;

reg signed [15:0] a;
reg signed [15:0] b;
reg [15:0] max_iter;

wire [15:0] iterations;
wire escaped;
wire done;

mandelbrot_pe uut (

      .clk(clk),
      .rst(rst),
      .start(start),
      .a(a),
      .b(b),
      .max_iter(max_iter),
      .iterations(iterations),
      .escaped(escaped),
      .done(done)

);

always #5 clk = ~clk;

task run_test;

      input signed [15:0] test_a;
      input signed [15:0] test_b;
      input [15:0] test_max;
      input expected_escape;
      input [15:0] expected_iterations;

      integer cycles;
      reg finished;

      begin

          @(negedge clk);
          rst = 1;
          start = 0;

          repeat (2) @(negedge clk);

          rst = 0;

          a = test_a;
          b = test_b;
          max_iter = test_max;

          start = 1;

          @(negedge clk);
          start = 0;

          finished = 0;

          for (cycles = 0; cycles < 1000; cycles = cycles + 1) begin

              @(negedge clk);

              if (done) begin
                finished = 1;
                cycles = 1000;
              end 

          end

          #1;
          
          if (!finished) begin
            $display("Fail : timeout");
          end
          else if (escaped == expected_escape && iterations == expected_iterations) begin
            $display("pass : a = %0d | b = %0d | iterations = %0d | escaped = %0d", test_a, test_b, iterations, escaped);

          end

          else begin
            $display("fail : a = %0d | b = %0d | iterations = %0d | escaped = %0d", test_a, test_b, iterations, escaped);

            $display("Expected : iterations = %0d | escaped = %0d", expected_iterations, expected_escape);

          end

      end

endtask

initial begin 

        clk = 0;
        rst = 0;
        start = 0;

        a = 0;
        b = 0;
        max_iter = 0;

        $display("Mandelbrot pe testing");

        run_test(16'sd12288, 16'sd0, 16'sd100, 1'b1, 16'd1);

        run_test(16'sd0, 16'sd0, 16'sd5, 1'b0, 16'd5);

        run_test(-16'sd2048, 16'sd0, 16'sd20, 1'b0, 16'd20);

        $display("all pe tests completed");

        $finish;

end

endmodule
