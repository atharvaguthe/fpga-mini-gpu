

`timescale 1ns/1ps

module pixel_coordinate_generator_tb;

reg clk;
reg rst;
reg start;
reg pixel_done;

wire [8:0] pixel_x;
wire [7:0] pixel_y;

wire signed [15:0] a;
wire signed [15:0] b;

wire valid;
wire done;

pixel_coordinate_generator uut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .pixel_done(pixel_done),

      .pixel_x(pixel_x),
      .pixel_y(pixel_y),

      .a(a),
      .b(b),

      .valid(valid),
      .done(done)
);

always #5 clk = ~clk;

integer i;

initial begin

      clk = 0;
      rst = 1;
      start = 0;
      pixel_done = 0;

      //reset 
      repeat (2) @(posedge clk);

      @(negedge clk);
      rst = 0;

      //start scanning
      start = 1;

      @(posedge clk);
      #1;

      if (pixel_x == 0 && pixel_y == 0 && a == -8192 && b == -6144 && valid)
        $display("test 1 pass : first pixel");

      else 
        $display("test 1 fail");

      @(negedge clk);
      start = 0;
      pixel_done = 1;

      @(posedge clk);
      #1;

      if (pixel_x == 1 && pixel_y == 0 && a == -8154 && b == -6144)
        $display("test 2 pass : second pixel");

      else 
        $display("test 2 fail : x = %0d | y = %0d | a = %0d | b = %0d", pixel_x, pixel_y, a, b);
      

      for (i = 0; i < 318; i = i + 1)
        @(posedge clk);

      #1;

      if(pixel_x == 319 && pixel_y == 0 && a == 4096)
        $display("test 3 pass : end of the first row");
      else 
        $display("test 3 fail");

      @(posedge clk);
      #1;

      if(pixel_x == 0 && pixel_y == 1)
        $display("test 4 pass : beginnning of the 2nd row");
      else
        $display("test 4 fail");


      for(i = 0; i < (238 * 320 + 319); i = i + 1)
        @(posedge clk);

      #1;

      if(pixel_x == 319 && pixel_y == 239 && a == 4096 && b == 6144)
        $display("test 5 pass : final pixel");

      else 
        $display("test 2 fail : x = %0d | y = %0d | a = %0d | b = %0d", pixel_x, pixel_y, a, b);


      @(posedge clk);
      #1;

      if(done && !valid)
        $display("test 6 pass : image scanning complete");

      else
        $display("test 6 fail");

      $display("coordinate generator tests passed");

      $finish;

end

endmodule


