

`timescale 1ns/1ps

module mandelbrot_renderer_small_tb;

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

integer count;
integer cycles;
integer pixel_index;

reg [11:0] seen;

mandelbrot_renderer #(
      .IMAGE_WIDTH(4),
      .IMAGE_HEIGHT(3)
) dut (
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

initial begin
        
        $dumpfile("sim/single_pe_small.vcd");
        $dumpvars(0,mandelbrot_renderer_small_tb);

        clk = 0;
        rst = 1;
        start = 0;

        max_iter = 8;

        count = 0;
        cycles = 0;
        seen = 0;

        repeat (2) @(negedge clk);
        rst = 0;

        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        while ((count < 12 || !frame_done) && cycles < 10000) begin 

          @(posedge clk);
          #1;

          cycles = cycles + 1;

          if (result_valid) begin

            $display("result: pixel=(%0d, %0d), iterations=%0d, escaped=%b",result_x,result_y,result_iterations,result_escaped);

            if (result_x >= 4 || result_y >= 3)
              $fatal(1,"Invalid pixel coordinates");

            if(result_x !== count % 4 || result_y !== count /4)
              $fatal(1, "unexpected pixel order");

            pixel_index = result_y * 4 + result_x;

            if(seen[pixel_index])
              $fatal(1,"duplicate pixel");

            seen[pixel_index] = 1'b1;

            count = count + 1;

      end 

    end

    if (count != 12)
      $fatal(1, "single pe renderer timeout");

    if(!frame_done)
      $fatal(1, "frame genration didn't finish");

    if(seen != 12'hFFF)
      $fatal(1, "missing pixels");

    $display("==============================");
    $display("Pass");
    $display("Single pe clock cycle = %0d",cycles);
    $display("==============================");

    $finish;

  end

initial begin 
      #100000;
      $fatal(1,"timeout");

  end 

endmodule

