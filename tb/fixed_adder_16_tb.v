

`timescale 1ns/1ps

module fixed_adder_16_tb;

reg signed [15:0] a;
reg signed [15:0] b;

wire signed [16:0] result;

fixed_adder_16 dut (
      .a(a),
      .b(b),
      .result(result)
);

task test_add;

        input signed [15:0] x;
        input signed [15:0] y;
        input signed [16:0] expected;

        begin

            a = x;
            b = y;

            #10;

            $display ("A raw = %0d | B raw = %0d | result raw = %0d | expected = %0d", a, b, result, expected);

            if(result !== expected) 
              $fatal(1, "!4.12 adder failed");

            $display("test passed");

      end

endtask


initial begin
        
        $dumpfile("sim/fixed_adder_16.vcd");
        $dumpvars(0, fixed_adder_16_tb);

        // 1.5 + 0.75 = 2.25
        test_add(16'sd6144, 16'sd3072, 17'sd9216);

        // -0.75 + 0.5 = -0.25
        test_add(-16'sd3072, 16'sd2048, -17'sd1024);

        // -1.5 + -0.5 = -2.0
        test_add(-16'sd6144, -16'sd2048, -17'sd8192);
        
        // 2.0 + 3.0 = 5.0
        test_add(16'sd8192 , 16'sd12288, 17'sd20480);

        // 7.0 + 1.0 = 8.0
        test_add(16'sd28672, 16'sd4096, 17'sd32768);

        // -8.0 + -8.0 = -16.0
        test_add(-16'sd32768, -16'sd32768, -17'sd65536);

        $display("all tests passed");

        $finish;

end 

endmodule

