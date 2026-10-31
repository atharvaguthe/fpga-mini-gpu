

`timescale 1ns/1ps

module fixed_adder_tb;

reg signed [7:0] a;
reg signed [7:0] b;

wire signed [8:0] result;

fixed_adder dut (
      .a(a),
      .b(b),
      .result(result)
);


task test_add;

      input signed [7:0] x;
      input signed [7:0] y;
      input signed [8:0] expected;

      begin

      a = x;
      b = y;

      #10;

      $display("A raw = %0d | B raw = %0d | result raw = %0d", a, b, result);

      if(result !== expected)
        $fatal(1, "Fixed adder test failed");

      $display("test passed\n");

    end 

endtask

initial begin
      
      $dumpfile("sim/fixed_adder.vcd");
      $dumpvars(0, fixed_adder_tb);

      //1.5 + 0.75 = 2.25
      test_add(8'sd24, 8'sd12, 9'sd36);

      //-0.75 + 0.5 = -0.25
      test_add(-8'sd12, 8'sd8, -9'sd4);

      //-1.5 + -0.5 = -2.0
      test_add(-8'sd24, -8'sd8, -9'sd32);

      //2.0 + 3.0 = 5.0
      test_add(8'sd32, 8'sd48, 9'sd80);

      //7.0 + 1.0 = 8.0
      test_add(8'sd112, 8'sd16, 9'sd128);

      //-8.0 + -8.0 = -16.0 
      test_add(8'sd128, -8'sd128, 9'sd256);

      $display("all the fixed adder tests passed");

      $finish;

end

endmodule
