

`timescale 1ns/1ps

module mandelbrot_image_tb;

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
integer fd;

initial begin

  fd = $fopen("sim/mandelbrot_pixels.csv", "w");

  if (fd == 0) begin

    $display("error : cannot open CSV file");
    $finish;
  
  end

  $fdisplay(fd, "x,y,iterations,escaped");

  clk = 0;
  rst = 1;
  start = 0;
  max_iter = 16'd64;

  count = 0;
  cycles = 0;
  errors = 0;

  //$dumpfile("sim/mandelbrot_image.vcd");
  //$dumpvars(0,mandelbrot_image_tb);

  $display("mandelbrot image generation");
  $display("Resolution: 320 * 240");
  $display("Max iterations : %0d", max_iter);

  repeat (2) @(posedge clk);

  @(negedge clk);
  rst = 0;

  start = 1;

  @(negedge clk);
  start = 0;

  while (count < 76800 && cycles < 6000000) begin

    @(posedge clk);
    #1;

    cycles = cycles + 1;

    if (result_valid) begin

      expected_x = count % 320;
      expected_y = count / 320;

      if (result_x != expected_x || result_y != expected_y) begin

        errors = errors + 1;

        $display("coodinates error at pixel : %0d",count);
      
      end

      $fdisplay(fd, "%0d,%0d,%0d,%0d",result_x, result_y, result_iterations, result_escaped);

      count = count + 1;

      if (count % 10000 == 0)
        $display("progress : %0d / 76800", count);

    end
  end


  repeat (10) @(posedge clk);
  #1;

  $fclose(fd);

  $display("total pixels received: %0d",count);
  $display("total errors : %0d",errors);
  $display("clock cycles : %0d",cycles);
  $display("frame_done : %0d", frame_done);

  if (count == 76800 && errors == 0) begin
    $display("success: image data generated");

  end
  else begin

    $display("fail: image genration failed");

  end

  $display("csv: sim/mandelbrot_pixels.csv");

  $display("==================");

  $finish;

end
endmodule
