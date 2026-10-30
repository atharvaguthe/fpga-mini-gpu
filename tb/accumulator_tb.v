

`timescale 1ns/1ps


module accumulator_tb;

reg clk = 0;
reg rst = 1;
reg enable = 0;

reg [7:0] data_in;
wire [7:0] result;

accumulator dut(
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .data_in(data_in),
      .result(result)
);


always #5 clk = ~clk;

task add_value;


      input [7:0] value;
      input [7:0] expected;


      begin

          @(negedge clk);

          data_in = value;
          enable = 1;

          @(posedge clk);
          #1;

          $display("Input = %0d | accumulator = %od | expected = %0d", data_in, result, expected);

          if (result !== expected)
            $fatal(1, "accumulator test failed");

      end 

endtask


initial begin

      $dumpfile("sim/accumulator.vcd");
      $dumpvars(0, accumulator_tb);


      @(posedge clk);
      #1;

      if (result !== 8'd0)
        $fatal(1, "Reset failed");

      $display("test 1 pass: reset");

      @(negedge clk);
      rst = 0;

      // Test 2

      add_value(8'd5, 8'd5);
      add_value(8'd3, 8'd8);
      add_value(8'd7, 8'd15);
      add_value(8'd2, 8'd17);

      $display("Test 2 pass: accumulation");

      // test 3 
      
      @(negedge clk);

      enable = 0;
      data_in = 8'd100;

      @(posedge clk);
      #1;

      if (result !== 8'd17)
        $fatal(1, "hold test failed");

      $display("test 3 pass: hold");

      // test 4

      @(negedge clk);
      rst = 1;

      @(posedge clk);
      #1;

      if (result !== 8'd0)
        $fatal(1, "Second rst failed");

      @(negedge clk);
      rst = 0;

      $display("test 4 pass: second reset");

      //test 5

      add_value(8'd200, 8'd200);
      add_value(8'd100, 8'd44);

      $display("test 5 pass: overflow behaviour");

      $display("all accumulator tests pass");

      $finish;

end

endmodule



