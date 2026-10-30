

`timescale 1ns/1ps

module signed_adder_tb;

reg signed [7:0] a;
reg signed [7:0] b;
reg sub;

wire signed [8:0] result;


signed_adder dut(
      .a(a),
      .b(b),
      .sub(sub),
      .result(result)
);

task test_operation;

        input signed [7:0] x;
        input signed [7:0] y;
        input operation;
        input signed [8:0] expected;

        begin

            a = x;
            b = y;
            sub = operation;

            #10;

            $display("A = %0d | B = %0d | sub = %0d | result = %0d | expected = %0d", a, b, sub, result, expected);

            if (result !== expected)
              $fatal(1, "test failed");

            $display("test passed");

        end 

endtask

initial begin

      $dumpfile("sim/signed_adder.vcd");
      $dumpvars(0, signed_adder_tb);

      // test 1: positive + positive
      test_operation(8'sd5, 8'sd3, 0, 9'sd8);

      // test 2: positive + negative
      test_operation(8'sd5, -8'sd3, 0, 9'sd2);

      // test 3: negative + negative
      test_operation(-8'sd5, -8'sd3, 0, -9'sd8);

      // test 4: positive - positive
      test_operation(8'sd7, 8'sd10, 1, -9'sd3);

      // test 5: negative - positive
      test_operation(-8'sd10, 8'sd5, 1, -9'sd15);

      // test 6: positive - negative
      test_operation(8'sd10, -8'sd5, 1, 9'sd15);

      // test 7: large positive result
      test_operation(8'sd100, 8'sd50, 0, 9'sd150);

      // test 8: Minimum signed value minus one
      test_operation(-8'sd128, 8'sd1, 1, -9'sd129);

      $display("all tests are passed");

      $finish;

end

endmodule
