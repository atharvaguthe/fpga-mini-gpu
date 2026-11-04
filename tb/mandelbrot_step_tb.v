

`timescale 1ns/1ps

module mandelbrot_step_tb;

reg signed [20:0] x;
reg signed [20:0] y;

reg signed [15:0] a;
reg signed [15:0] b;

wire signed [20:0] x_next;
wire signed [20:0] y_next;


// mandelbrot calc unit

mandelbrot_step dut (
        .x(x),
        .y(y),
        .a(a),
        .b(b),
        .x_next(x_next),
        .y_next(y_next)
);


task test_step;

        input signed [15:0] tx;
        input signed [15:0] ty;
        input signed [15:0] ta;
        input signed [15:0] tb;

        input signed [20:0] expected_x;
        input signed [20:0] expected_y;

        begin 
            
            x = tx;
            y = ty;
            a = ta;
            b = tb;

            #10;

            $display("x_next = %0d | y_next = %0d",x_next, y_next);

            $display("expected x = %0d | expected y = %0d",expected_x, expected_y);

            if ((x_next !== expected_x) || (y_next !== expected_y))
              $fatal(1, "mandelbrot test failed");

            $display("test passed");

        end 

endtask

initial begin
        
        $dumpfile("sim/mandelbrot_step.vcd");
        $dumpvars(0, mandelbrot_step_tb);

        // c = -0.75 + 0.1251
        //
        // first iteration : z0 = 0
        // z1 = -0.75 + 0.1251

        test_step(16'sd0, 16'sd0,
                  -16'sd3072, 16'sd512,
                  -21'sd3072, 21'sd512);


        // second iteration 
        // z2 = -0.203125 - 0.0625i

        test_step(-16'sd3072, 16'sd512,
                  -16'sd3072, 16'sd512,
                  -21'sd832, -21'sd256);

        // first iteration 

        test_step(16'sd0, 16'sd0,
                  -16'sd2048, 16'sd2048,
                  -21'sd2048, 21'sd2048);

        // second iteration 

        test_step(-16'sd2048, 16'sd2048,
                  -16'sd2048, 16'sd2048,
                  -21'sd2048, 21'sd0);



        $display("all steps passed");

        $finish;

end 

endmodule


