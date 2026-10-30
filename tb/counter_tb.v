

`timescale 1ns/1ps

module counter_tb;

reg clk = 0;
reg rst = 1;
wire [3:0] count;


counter dut(
    .clk(clk),
    .rst(rst),
    .count(count)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("sim/counter.vcd");
    $dumpvars(0, counter_tb);


    repeat (2) @(posedge clk);

    @(negedge clk);
    rst = 0;

    @(posedge clk);
    #1;
    if (count !== 4'd1)
      $fatal(1, "Expected 1, got %0d", count);


      @(posedge clk);
      #1;
      if(count !== 4'd2)
        $fatal(1, "Expected 2, got %0d", count);


      $display("Initial checks passed");

      repeat (6) begin
        @(posedge clk);
        #1;
        $display("Time = %0t ns | Count = %od", $time, count);

      end

      $display("Simulation completed successfully");

      $finish;

    end 

  endmodule
