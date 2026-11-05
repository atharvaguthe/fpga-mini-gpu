

`timescale 1ns/1ps

module mandelbrot_frame_tb;

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
integer errors;

integer expected_x;
integer expected_y;

initial begin

  $dumpfile("sim/mandelbrot_frame.vcd");
  $dumpvars(0,mandelbrot_frame_tb);

  clk = 0;
  rst = 1;
  start = 0;
  max_iter = 16'd1;

  count = 0;
  cycles = 0;
  errors = 0;


  $display("mandelbrot frame test");

  repeat (2) @(posedge clk);

  @(negedge clk);
  rst = 0;

  start = 1;

  @(negedge clk);
  start = 0;

  while (count < 76800 && cycles < 2000000) begin

    @(posedge clk);
    #1;

    cycles = cycles + 1;

    if (result_valid) begin

      expected_x = count % 320;
      expected_y = count / 320;

      if (result_x == expected_x && result_y == expected_y && result_iterations == 1) begin

        if (count % 10000 == 0) 
          $display("progress : %0d / 76800 pixels",count);

      end

      else begin

        errors = errors + 1;

        $display("error: pixel %0d", count);

        $display("expected x = %0d, y = %0d",expected_x, expected_y);

        $display("received x = %0d, y = %0d",result_x, result_y);
      end

      count = count + 1;
    end
  end


  repeat (10) @(posedge clk);
  #1;

  $display("total pixels received: %0d",count);
  $display("total errors : %0d",errors);
  $display("clock cycles : %0d",cycles);

  if (count == 76800 && errors == 0 && frame_done == 1) begin
    $display("success: full  frame rendered");

  end
  else begin
    $display("fail: frame render fail");

    $display("frame done: %0d", frame_done);

  end

  $display("==================");

  $finish;

end
endmodule
