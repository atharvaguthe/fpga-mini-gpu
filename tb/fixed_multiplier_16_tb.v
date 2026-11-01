
`timescale 1ns/1ps

module fixed_multiplier_16_tb;

reg signed [15:0] a;
reg signed [15:0] b;

wire signed [19:0] product;


fixed_multiplier_16 dut(

        .a(a),
        .b(b),
        .product(product)
);


task test_multiply;

        input signed [15:0] x;
        input signed [15:0] y;
        input signed [19:0] expected;


        begin 

              a = x;
              b = y;

              #10;

              $display("A raw = %0d | B raw = %0d | product raw = %0d | expected = %0d", a, b, product, expected);

              if(product !== expected)
                $fatal(1, "Q4.12 failed");

              $display("test passed");

        end 

endtask


initial begin 

        $dumpfile("sim/fixed_multiplier_16.vcd");
        $dumpvars(0,fixed_multiplier_16_tb);

        // 1.5 * 0.5 = 0.75
        test_multiply(16'sd6144, 16'sd2048, 20'sd3072);

        // -1.5 * 0.5 = -0.75
        test_multiply(-16'sd6144, 16'sd2048, -20'sd3072);

        // -0.75 * -0.75 = 0.5625
        test_multiply(-16'sd3072, -16'sd3072, 20'sd2304);

        // 2.25 * 2.0 = 4.5
        test_multiply(16'sd9216, 16'sd8192, 20'sd18432);

        // -2.0 * 1.5 = -3.0
        test_multiply(-16'sd8192, 16'sd6144, -20'sd12288);

        // 0.5 * 0.5 = 0.25
        test_multiply(16'sd2048, 16'sd2048, 20'sd1024);

        // 1.0 * 1.0 = 1.0
        test_multiply(16'sd4096, 16'sd4096, 20'sd4096);

        // 7.0 * 7.0 = 49.0
        test_multiply(16'sd28672, 16'sd28672, 20'sd200704);

        // -8.0 * -8.0 = 64.0
        test_multiply(-16'sd32768, -16'sd32768, 20'sd262144);

        // 0.125 * 0.125 = 0.015625
        test_multiply(16'sd512, 16'sd512, 20'sd64);

        $display("all tests passed");

        $finish;

end

endmodule




