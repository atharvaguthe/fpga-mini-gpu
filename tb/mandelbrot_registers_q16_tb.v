

`timescale 1ns/1ps

module mandelbrot_registers_tb;

reg clk;
reg rst;
reg load;
reg initialize;

reg signed [24:0] x_next;
reg signed [24:0] y_next;

wire signed [24:0] x_reg;
wire signed [24:0] y_reg;

mandelbrot_registers_q16 uut (
      .clk(clk),
      .rst(rst),
      .load(load),
      .initialize(initialize),
      .x_next(x_next),
      .y_next(y_next),
      .x_reg(x_reg),
      .y_reg(y_reg)
);

always #5 clk = ~clk;

initial begin 
      clk = 0;
      rst = 1;
      load = 0;
      initialize = 0;
      x_next = 0;
      y_next = 0;

      // test 1 : reset
      @(posedge clk);
      #1;

      if(x_reg == 0 && y_reg == 0)
        $display("test 1 pass : reset");
      else 
        $display("test 1 fail : reset");

      // test 2 : load values
      //
      @(negedge clk);

      rst = 0;
      load = 1;

      x_next = 21'sd49152;
      y_next = -21'sd32768;

      @(posedge clk);
      #1;

      if(x_reg == 49152 && y_reg == -32768)
        $display("test 2 pass : load");
      else 
        $display("test 2 fail : load");


      // test 3 : hold values when load is disabled

      @(negedge clk);
      load = 0;
      x_next = 21'sd1000;
      y_next = 21'sd2000;

      @(posedge clk);
      #1;

      if(x_reg == 49152 && y_reg == -32768)
        $display("test 3 pass : hold");
      else
        $display("test 3 fail : hold");

      //test 4 : initialize

      @(negedge clk);
      initialize = 1;
      @(posedge clk);
      #1;

      if (x_reg == 0 && y_reg == 0)
        $display("test 4 pass");
      else
        $fatal(1, "test 4 fail");

      // test 5 : load new values

      @(negedge clk);

      load = 1;
      initialize = 0;
      x_next = -21'sd13312;
      y_next = 21'sd8192;

      @(posedge clk);
      #1;

      if(x_reg == -13312 && y_reg == 8192)
        $display("test 4 pass : update");
      else
        $display("test 4 fail : update");

      $display("register tests passed");

      $finish;

end

endmodule
