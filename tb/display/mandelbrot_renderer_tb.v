

`timescale 1ns/1ps

module mandelbrot_renderer_tb;

reg clk;
reg rst;
reg start;

reg [15:0] max_iter;

wire [8:0] result_x;
wire [7:0] result_y;
wire [15:0] result_iterations;
wire result_escaped;
wire result_valid;
wire frame_done;
integer expected_x;
integer expected_y;


mandelbrot_renderer uut(
        
        .clk(clk),
        .rst(rst),
        .start(start),

        .max_iter(max_iter),

        .result_x(result_x),
        .result_y(result_y),
        .result_iterations(result_iterations),
        .result_escaped(result_escaped),
        .result_valid(result_valid),

        .frame_done(frame_done)
);

always #5 clk = ~clk;

integer count;
integer cycles;

initial begin

      $dumpfile("sim/mandelbrot_renderer.vcd");
      $dumpvars(0,mandelbrot_renderer_tb);

      clk = 0;
       rst = 1;
       start = 0;
       max_iter = 16'd1;

       count = 0;
       cycles = 0;


       $display("mandelbrot rendrer test");

       repeat (2) @(posedge clk);

       @(negedge clk);
       rst = 0;

       start = 1;

       @(negedge clk);
       start = 0;

       while (count < 322 && cycles < 100000) begin

        @(posedge clk);
        #1;

        cycles = cycles + 1;

        if (result_valid) begin

          $display("Pixel %0d | x = %0d | y = %0d | iterations = %0d | escaped %0d", count, result_x, result_y, result_iterations, result_escaped);

          expected_x = count % 320;
          expected_y = count / 320;

          if (result_x == expected_x && result_y == expected_y && result_iterations == 1) begin
            $display("pass: pixel %0d", count);
          end 

          else begin
            $display("fail: pixe %0d", count);
          end

          count = count + 1;
        end

      end

      if (count == 322)
        $display("success: row transition varified");
      else
        $display("fail: timeout");

      $display("==================");

      $finish;

end

endmodule
