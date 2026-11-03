

`timescale 1ns/1ps

module mandelbrot_fsm_tb;

reg clk;
reg rst;
reg start;
reg escaped;
reg max_reached;

wire initialize;
wire update;
wire done;

mandelbrot_fsm uut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .escaped(escaped),
      .max_reached(max_reached),
      .initialize(initialize),
      .update(update),
      .done(done)
);

always #5 clk = ~clk;

initial begin
      clk = 0;
      rst = 1;
      start = 0;
      escaped = 0;
      max_reached = 0;

      //reset
      @(posedge clk);
      #1;
      rst = 0;

      // test 1 : start and initialize
      @(negedge clk);
      start = 1;

      @(posedge clk);
      #1
      if(initialize)
        $display("test 1 pass : fst entered int");
      else
        $display("test 1 fail : init");

      @(negedge clk);
      start = 0;

      // test 2 : init -> calc -> check
      @(posedge clk);
      #1;

      if(!initialize && !update && !done)
        $display("test 2 pass : fsm entered calc");
      else
        $display("test 2 fail : calc");

      //test 3

      @(posedge clk);
      #1;

      if(!initialize && !update && !done)
        $display("test 3 pass : fsm enterend check");
      else 
        $display("test 3 fail : check");

      // test 4 : no excape and limit not reached -> update

      @(posedge clk);
      #1;

      if(update)
        $display("test 4 passed: fsm entered update");
      else
        $display("test 4 failed : update");

      //test 5 : update -> calc
      @(posedge clk);
      #1;

      if(!update && !done)
        $display("test 5 pass : fsm returned to calc");
      else
        $display("test 5 fail : calc after update");

      //test 6 : escape detected -> done
      @(posedge clk);
      #1;

      escaped = 1;

      @(posedge clk);
      #1;

      if (done)
        $display("test 6 passed : escaped leads to done");
      else
        $display("test 6 fail : escape detection");


      // return to idle 
      @(posedge clk);
      #1;
      escaped = 0;

      // test 7 : max iteration reached -> done
      @(negedge clk);
      start = 1;

      @(posedge clk);
      #1;

      @(negedge clk);
      start = 0;

      @(posedge clk);
      #1;

      @(posedge clk);
      #1;

      @(posedge clk);
      #1;

      max_reached = 1;

      @(posedge clk);
      #1;

      if (done)
        $display("test 7 pass : max iteration lead to done");
      else
        $display("test 7 fail : max iteration detection");


      $display("fsm test completed");

      $finish;

end 

endmodule
