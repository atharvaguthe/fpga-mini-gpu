

`timescale 1ns/1ps

module register_tb;

reg clk = 0;
reg rst = 1;
reg enable = 0;


reg [7:0] data_in;
wire [7:0] data_out;


register dut(
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .data_in(data_in),
      .data_out(data_out)
);

always #5 clk = ~clk;

initial begin 


      $dumpfile("sim/register.vcd");
      $dumpvars(0, register_tb);

      @(posedge clk);
      #1;

      if(data_out !== 8'd0)
        $fatal(1, "Reset failed");

      $display("Test 1 Pass: Reset");


      @(negedge clk);
      rst = 0;
      enable = 1;
      data_in = 8'd25;

      @(posedge clk);
      #1;

      if (data_out !== 8'd25)
        $fatal(1, "Load Failed");

      $display("Test 2 passed: data loaded");

      @(negedge clk);
      enable = 0;
      data_in = 8'd100;

      @(posedge clk);
      #1;

      if(data_out !== 8'd25)
        $fatal(1, "Hold failed");

      $display("Test 3 passed: previous value retained");

      @(negedge clk);
      enable = 1;
      data_in = 8'd50;


      @(posedge clk);
      #1;

      if(data_out !== 8'd50)
        $fatal(1, "update failed");

      $display("Test 4 passed: new data loaded");

      $display("All register tests passed");

      $finish;

end 

endmodule
