

`timescale 1ns/1ps

module mandelbrot_renderer_2pe_tb;

reg clk;
reg rst;
reg start;

reg [15:0] max_iter;

wire result_valid;
reg result_ready;

wire [8:0] result_x;
wire [7:0] result_y;

wire [15:0] result_iterations;
wire result_escaped;

wire generation_done;
wire [4:0] fifo_count;

integer received;
integer cycles;
integer i;
integer pixel_index;

reg [11:0] seen;

reg measuring;

mandelbrot_renderer_2pe #(
      .IMAGE_WIDTH(4),
      .IMAGE_HEIGHT(3),
      .FIFO_DEPTH(16)
) dut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .max_iter(max_iter),

      .result_valid(result_valid),
      .result_ready(result_ready),

      .result_x(result_x),
      .result_y(result_y),
      .result_iterations(result_iterations),
      .result_escaped(result_escaped),

      .generation_done(generation_done),
      .fifo_count(fifo_count)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst)
        cycles = 0;
    else if (measuring)
        cycles = cycles + 1;
end

always @(posedge clk) begin

      if (rst) begin
        cycles = 0;
      end 
      else begin

        cycles = cycles + 1;

        if (result_valid && result_ready) begin

          $display("Result: pixel=(%0d,%0d), iterations=%0d, escaped=%b",result_x, result_y,result_iterations, result_escaped);

          // check coordinate range.
          if (result_x >= 4 || result_y >= 3)
            $fatal(1,"Invalid pixel coordinates");

          //Conver (x,y) into a unique array index
          pixel_index = result_y * 4 + result_x;

          // Check for duplicate pixels

          if(seen[pixel_index])
            $fatal(1,"Duplicate pixel result");

          seen[pixel_index] = 1'b1;

          received = received + 1;

        end

      end 

  end

initial begin

      $dumpfile("sim/renderer_2pe.vcd");
      $dumpvars(0,mandelbrot_renderer_2pe_tb);

      clk = 0;
      rst = 1;
      start = 0;

      max_iter = 8;
      result_ready = 1;

      received = 0;
      measuring = 0;
      cycles = 0;
      seen = 0;
      pixel_index = 0;

      repeat (2) @(negedge clk);
      rst = 0;

      @(negedge clk);
      measuring = 1;
      start = 1;

      @(negedge clk);
      start = 0;

      wait (received == 12 && generation_done && fifo_count == 0);

      @(negedge clk);
      measuring = 0;
      if (!generation_done)
        $fatal(1,"Coordinate generation did not finish");

      if (fifo_count != 0)
        $fatal(1, "Fifo should be empty");

      if(received != 12)
        $fatal(1,"Incorrect result count");

      for (i = 0; i < 12; i = i + 1) begin
        if(!seen[i])
          $fatal(1, "missing pixel index %0d", i);
      end

      $display("====================================");
      $display("Pass : all 12 pixels received, NO duplicate pixels, NO missing pixels, FIFO empty");
      $display("Clock cycles: %0d",cycles);
      $display("====================================");

      $finish;

  end 
initial begin
      #100000;
      $fatal(1,"timeout");
    end

endmodule





