

`timescale 1ns/1ps

module mandelbrot_registers_tb;

reg clk;
reg rst;
reg load;

reg signed [20:0] x_next;
reg signed [20:0] y_next;

wire signed [20:0] x_reg;
wire signed [20:0] y_reg;

mandelbrot_registers uut (
      .clk(clk),
      .rst(rst),
      .load(load),
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
      x_next = 0;
      y_next = 0;

      // test 1 : reset
      #10 
      rst = 0;
      #1;

      if(x_reg == 0 && y_reg == 0)
        $display("test 1 pass : reset");
      else 
        $display("test 1 fail : reset");

      // test 2 : load values

      x_next = 21'sd4096;
      y_next = -21'sd2048;
      load = 1;

      @(posedge clk);
      #1;

      if(x_reg == 4096 && y_reg == -2048)
        $display("test 2 pass : load");
      else 
        $display("test 2 fail : load");


      // test 3 : hold values when load is disabled

      load = 0;
      x_next = 21'sd1000;
      y_next = 21'sd2000;

      @(posedge clk);
      #1;

      if(x_reg == 4096 && y_reg == -2048)
        $display("test 3 pass : hold");
      else
        $display("test 3 fail : hold");


      // test 4 : load new values


      load = 1;
      x_next = -21'sd3072;
      y_next = 21'sd512;

      @(posedge clk);
      #1;

      if(x_reg == -3072 && y_reg == 512)
        $display("test 4 pass : update");
      else
        $display("test 4 fail : update");

      $display("register tests passed");

      $finish;

end

endmodule
