

`timescale 1ns/1ps

module signed_multiplier_tb;

reg signed [7:0] a;
reg signed [7:0] b;

wire signed [15:0] product;


signed_multiplier dut (
      .a(a),
      .b(b),
      .product(product)
);


task test_multiply;

        input signed [7:0] x;
        input signed [7:0] y;
        input signed [15:0] expected;


        begin

        a = x;
        b = y;

        #10;

        $display("A = %0d | B = o%d | product = %0d | expected = %0d", a, b, product, expected);

        if (product !== expected)
          $fatal(1, "multiplication test failed");

        $display("test passed");

    end

endtask

initial begin
      

      $dumpfile("sim/signed_multiplier.vcd");
      $dumpvars(0, signed_multiplier_tb);

      // Test 1 : Positive * Positive
      test_multiply(8'sd5, 8'sd3, 16'sd15);
      
      // Test 2 : negative * Positive
      test_multiply(-8'sd5, 8'sd3, -16'sd15);

      // Test 3 : negative * negative
      test_multiply(-8'sd5, -8'sd3, 16'sd15);

      // Test 4 : multiplication by zero
      test_multiply(8'sd0, 8'sd100, 16'sd0);

      // Test 5 : Positive * negative
      test_multiply(8'sd1, -8'sd100, -16'sd100);
      
      // Test 6 : larger negative number 
      test_multiply(8'sd100, -8'sd100, -16'sd10000);

      // Test 7 : maximum Positive inputs
      test_multiply(8'sd127, 8'sd127, 16'sd16129);

      // Test 8 : minimum negative inputs
      test_multiply(-8'sd128, -8'sd128, 16'sd16384);

      // Test 9: Minimum * maximum
      test_multiply(-8'sd128, 8'sd127, -16'sd16256);

      // Test 10
      test_multiply(-8'sd7 , 8'sd6, -16'sd42);

      // Test 11
      test_multiply(-8'sd12, -8'sd12, 16'sd144);
      
      // Test 12
      test_multiply(8'sd25, -8'sd4, -16'sd100);

      // Test 13
      test_multiply(-8'sd128, 8'sd1, -16'sd128);
      
      // Test 14
      test_multiply(8'sd127, -8'sd127, -16'sd16129);

      $display("all signed multiplier passed");

      $finish;

end

endmodule
