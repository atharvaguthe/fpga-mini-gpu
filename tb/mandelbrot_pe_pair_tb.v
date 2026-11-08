
`timescale 1ns/1ps

module mandelbrot_pe_pair_tb;

reg clk;
reg rst;
reg start0;
reg start1;

reg signed [15:0] a0, b0;
reg signed [15:0] a1, b1;

reg [15:0] max_iter;

wire [15:0] iterations0;
wire escaped0, done0;

wire [15:0] iterations1;
wire escaped1, done1;

reg finished0, finished1;

integer cycles;

reg pe0_finished;
reg pe1_finished;

mandelbrot_pe_pair uut(

      .clk(clk),
      .rst(rst),
      .start0(start0),
      .start1(start1),

      .a0(a0),
      .b0(b0),
      .a1(a1),
      .b1(b1),

      .max_iter(max_iter),

      .iterations0(iterations0),
      .escaped0(escaped0),
      .done0(done0),

      .iterations1(iterations1),
      .escaped1(escaped1),
      .done1(done1)

);

always #5 clk = ~clk;

always @(posedge clk) begin 
      if (rst) begin
        pe0_finished <= 0;
        pe1_finished <= 0;
      end 

      else begin

        if (done0)
          pe0_finished <= 1;

        if (done1)
          pe1_finished <= 1;

      end 
end

initial begin 
      
      $dumpfile("sim/mandelbrot_pe_pair.vcd");
      $dumpvars(0,mandelbrot_pe_pair_tb);

      clk = 0;
      rst = 1;
      start0 = 0;
      start1 = 0;

      pe0_finished = 0;
      pe1_finished = 0;

      a0 = 0;
      b0 = 0;
      a1 = 0;
      b1 = 0;

      max_iter = 16'd5;

      //reset
      repeat (2) @(negedge clk);

      rst = 0;

      //pe 0 

      a0 = 16'sd12288;
      b0 = 16'sd0;

      //pe 1
      a1 = 16'sd0;
      b1 = 16'sd0;

      // pe0 start

      @(negedge clk);
      start0 = 1;

      @(negedge clk);
      start0 = 0;

      cycles = 0;

      while (!pe0_finished && cycles < 1000) begin

        @(negedge clk);
        cycles = cycles + 1;

      end 

      #1;

      if(!pe0_finished)
        $fatal(1,"Fail : timeout");

      //check pe0
      if (iterations0 != 1 && escaped0 != 1)
        $fatal(1, "fail: pe 0 failed");

      $display("pe 0 pass : iterations=%0d escaped0=%0d",iterations0, escaped0);
      $display("pe0 finished before pe 1 started");

      // pe1 start

      @(negedge clk);
      start1 = 1;

      @(negedge clk);
      start1 = 0;

      cycles = 0;

      while (!pe1_finished && cycles < 1000) begin

        @(negedge clk);
        cycles = cycles + 1;

      end 

      #1;

      if(!pe1_finished)
        $fatal(1,"Fail : timeout");

      //check pe0
      if (iterations1 != 5 && escaped1 != 0)
        $fatal(1, "fail: pe 1 failed");

      $display("pe 1 pass : iterations=%0d escaped0=%0d",iterations0, escaped0);

      $display("\nBoth elements completed");

      $finish;

end 

endmodule
