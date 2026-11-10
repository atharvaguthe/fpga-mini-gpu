

`timescale 1ns/1ps

module pe_result_collector_2pe_tb;

reg clk;
reg rst;

reg pe_valid0, pe_valid1;
reg [8:0] pe_x0, pe_x1;
reg [7:0] pe_y0, pe_y1;

reg [15:0] pe_iterations0, pe_iterations1;

reg pe_escaped0, pe_escaped1;

wire result_valid;
reg result_ready;

wire [8:0] result_x;
wire [7:0] result_y;

wire [15:0] result_iterations;
wire result_escaped;

wire [2:0] fifo_count;

pe_result_collector_2pe #(
      .FIFO_DEPTH(4)
) dut (
      .clk(clk),
      .rst(rst),

      .pe_valid0(pe_valid0),
      .pe_x0(pe_x0),
      .pe_y0(pe_y0),
      .pe_iterations0(pe_iterations0),
      .pe_escaped0(pe_escaped0),

      .pe_valid1(pe_valid1),
      .pe_x1(pe_x1),
      .pe_y1(pe_y1),
      .pe_iterations1(pe_iterations1),
      .pe_escaped1(pe_escaped1),

      .result_valid(result_valid),
      .result_ready(result_ready),
      .result_x(result_x),
      .result_y(result_y),
      .result_iterations(result_iterations),
      .result_escaped(result_escaped),
      
      .fifo_count(fifo_count)
);

always #5 clk = ~clk;

task capture_pair;


        input [8:0] x0;
        input [8:0] x1;

        begin
        @(negedge clk);
          
            pe_valid0 = 1;
            pe_valid1 = 1;

            pe_x0 = x0;
            pe_y0 = 0;
            pe_iterations0 = x0;
            pe_escaped0 = 1;

            pe_x1 = x1;
            pe_y1 = 0;
            pe_iterations1 = x1;
            pe_escaped1 = 0;

            @(negedge clk);
            pe_valid0 = 0;
            pe_valid1 = 0;

            @(negedge clk);
        end 
endtask

task read_and_check;
      
      input [8:0] expected_x;
      input exptected_escaped;

      begin
      @(negedge clk);

      if (!result_valid)
        $fatal(1,"collector fifo unexpectedly empty");

      if (result_x !== expected_x || result_y !== 0 || result_iterations !== expected_x || result_escaped !== exptected_escaped) begin

        $display("Expected : x=%0d escaped=%0d",expected_x, exptected_escaped);

        $display("Actual: x=%0d y=%0d iterations=%0d escaped=%b",result_x, result_y,result_iterations,result_escaped);

        $fatal(1, "Colletor result mismatch");
      end

      $display("Pass: x=%0d iterations=%0d escaped=%b", result_x, result_iterations, result_escaped);

      result_ready = 1;

      @(negedge clk);
      result_ready = 0;

    end 

endtask

initial begin

        $dumpfile("sim/pe_result_collector_2pe.vcd");
        $dumpvars(0,pe_result_collector_2pe_tb);

        clk = 0;
        rst = 1;

        pe_valid0 = 0;
        pe_valid1 = 0;

        pe_x0 = 0;
        pe_x1 = 0;

        pe_y0 = 0;
        pe_y1 = 0;

        pe_iterations0 = 0;
        pe_iterations1 = 0;

        pe_escaped0 = 0;
        pe_escaped1 = 0;

        result_ready = 0;

        repeat (2) @(negedge clk);
        rst = 0;

        // test 1 : fill fifo with four results 
        capture_pair(0,1);
        capture_pair(2,3);

        if (fifo_count != 4)
          $fatal(1,"Expected fifo count 4, got %0d",fifo_count);

        $display("pass: collector fifo filled");

        //test 2: Capture two more results while fifo is full.

        capture_pair(4,5);

        if (fifo_count != 4)
          $fatal(1, "fifo count should remain 4");

        if(!dut.hold_valid0 || !dut.hold_valid1)
          $fatal(1, "holding registers failed to preserve results");

        if(dut.hold_x0 !== 4 || dut.hold_x1 !== 5)
          $fatal(1, "holding register data incorrect");

        $display("pass: both pe result held during fifo backpressure");

        //test 3 : drain all six results in order
        read_and_check(0,1);
        read_and_check(1,0);
        read_and_check(2,1);
        read_and_check(3,0);
        read_and_check(4,1);
        read_and_check(5,0);

        if(fifo_count != 0)
          $fatal(1,"collector fifo should be empty");

        if (dut.hold_valid0 || dut.hold_valid1)
          $fatal(1, "holding registers should be empty");

        $display("================================");
        $display("Pass: Complete result collector test");
        $display("================================");

        $finish;

    end


initial begin
      #2000;
      $fatal(1,"Timeout");
    end

endmodule



