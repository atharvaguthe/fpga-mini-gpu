

`timescale 1ns/1ps

module pe_result_hold_tb;

reg clk;
reg rst;

reg capture_valid;
reg [8:0] capture_x;
reg [7:0] capture_y;
reg [15:0] capture_iterations;
reg capture_escaped;

wire out_valid;
reg out_ready;

wire [8:0] out_x;
wire [7:0] out_y;
wire [15:0] out_iterations;
wire out_escaped;

pe_result_hold dut (
      .clk(clk),
      .rst(rst),

      .capture_valid(capture_valid),
      .capture_x(capture_x),
      .capture_y(capture_y),
      .capture_iterations(capture_iterations),
      .capture_escaped(capture_escaped),

      .out_valid(out_valid),
      .out_ready(out_ready),

      .out_x(out_x),
      .out_y(out_y),
      .out_iterations(out_iterations),
      .out_escaped(out_escaped)
);

always #5 clk = ~clk;

initial begin
        
        $dumpfile("sim/pe_result_hold.vcd");
        $dumpvars(0,pe_result_hold_tb);

        clk = 0;
        rst = 1;

        capture_valid = 0;
        capture_x = 0;
        capture_y = 0;
        capture_iterations = 0;
        capture_escaped = 0;

        out_ready = 0;

        repeat (2) @(negedge clk);
        rst = 0;

        // test 1 : check the pe result
        
        capture_valid = 1;
        capture_x = 25;
        capture_y = 10;
        capture_iterations = 17;
        capture_escaped = 1;

        @(negedge clk);
        capture_valid = 0;

        if(out_valid !== 1)
          $fatal(1,"result was not captured");

        if (out_x !== 25 || out_y !== 10 || out_iterations !== 17 || out_escaped !== 1)
          $fatal(1, "captured result is incorrect");

        $display("Pass : PE result captured");


        // test 2 : fifo is not ready 

        repeat (3) @(negedge clk);

        if(out_valid !== 1 || out_x !== 25 || out_y !== 10)
          $fatal(1, "result was not help while fifo was busy");
        
        $display("pass: result held during backpressure");


        // test 3 : fifo becomes ready

        @(negedge clk);
        out_ready = 1;

        @(negedge clk);
        out_ready = 0;

        if(out_valid !== 0)
          $fatal(1,"result did not clear after acceptance");

        $display("Pass : result cleared after fifo acceptance");

        //test 4: capture and consume on the same clock

        @(negedge clk);

        capture_valid = 1;
        capture_x = 30;
        capture_y = 20;
        capture_iterations = 12;
        capture_escaped = 0;
        out_ready = 1;

        @(negedge clk);

        capture_valid = 0;
        out_ready = 0;

        if (out_valid !== 1 || out_x !== 30 || out_y !== 20 || out_iterations !== 12 || out_escaped !== 0)
          $fatal(1, "New result not preserved");

        $display("Pass : simultanuous consume and capture");

        $display("========================================");
        $display("Pass : PE result holding test complete");
        $display("========================================");

        $finish;

end 

initial begin

        #1000;
        $fatal(1,"timeout");
end

endmodule


