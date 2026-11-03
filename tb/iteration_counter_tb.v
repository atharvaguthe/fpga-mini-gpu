
`timescale 1ns/1ps

module iteration_counter_tb;

reg clk;
reg rst;
reg clear;
reg enable;

wire [15:0] count;

iteration_counter uut (
      .clk(clk),
      .rst(rst),
      .clear(clear),
      .enable(enable),
      .count(count)
);

always #5 clk = ~clk;

initial begin
    
      clk = 0;
      rst = 1;
      clear = 0;
      enable = 0;

      //test 1 : reset
      @(posedge clk);
      #1;
      rst = 0;

      if(count == 0)
        $display("test 1 pass : reset");
      else 
        $display("test 1 fail : rest");

      // test 2 : increment
      @(negedge clk);
      enable = 1;

      repeat (5) @(posedge clk);
      #1;
      
      if (count == 5)
        $display("test 2 pass : increment");
      else
        $display("test 2 fail : increment, count = %0d", count);

      // test 3 : hold
      @(negedge clk);
      enable = 0;

      repeat (2) @(posedge clk);
      #1;

      if(count == 5)
        $display("test 3 pass : hold");
      else
        $display("test 3 failed : hold");

      // test 4 : clear
      @(negedge clk);
      clear = 1;

      @(posedge clk);
      #1;

      if (count == 0)
        $display("test 4 pass : clear");
      else 
        $display("test 4 failed : clear");

      clear =  0;

      //test 5 : increment again
      @(negedge clk);
      enable = 1;

      repeat (3) @(posedge clk);
      #1;

      if (count == 3)
        $display("test 5 pass : increment after clear");
      else 
        $display("test 5 failed : increment after clear");

      $display("counter tests passed");

      $finish;

end

endmodule
