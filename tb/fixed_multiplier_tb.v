

`timescale 1ns/1ps

module fixed_multiplier_tb;

reg signed [7:0] a;
reg signed [7:0] b;

wire signed [11:0] product;

fixed_multiplier dut(
      .a(a),
      .b(b),
      .product(product)
);

task test_multiply;

        input signed [7:0] x;
        input signed [7:0] y;
        input signed [11:0] expected;

        begin

        a = x;
        b = y;

        #10;

        $display("A raw = %0d | B raw = %0d | product raw = %0d | expected = %0d", a, b, product, expected);

        if(product !== expected)
          $fatal(1, "Fixed multiplier test failed");

        $display("Test passed");

    end 

endtask


initial begin
      
      $dumpfile("sim/fixed_multiplier.vcd");
      $dumpvars(0, fixed_multiplier_tb);

      test_multiply(8'sd24, 8'sd8, 12'sd12);

      test_multiply(-8'sd24, 8'sd8, -12'sd12);

      test_multiply(-8'sd12, -8'sd12, 12'sd9);
      
      test_multiply(8'sd36, 8'sd32, 12'sd72);

      test_multiply(-8'sd32, 8'sd24, -12'sd48);

      test_multiply(8'sd8, 8'sd8, 12'sd4);

      test_multiply(8'sd16, 8'sd16, 12'sd16);

      test_multiply(8'sd112, 8'sd112, 12'sd784);


      $display("all tests passed");

      $finish;

end

endmodule
