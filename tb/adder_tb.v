
`timescale 1ns/1ps

module adder_tb;

reg [3:0] a;
reg [3:0] b;
wire [4:0] sum;

adder dut(
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin

    $dumpfile("sim/adder.vcd");
    $dumpvars(0, adder_tb);


    a = 4'd3;
    b = 4'd5;
    #10;


    if(sum !== 5'd8)
      $fatal(1, "Test 1 failed");

      $display("Test 1 PASS");

      a = 4'd15;
      b = 4'd1;
      #10;

      if(sum !== 5'd16)
        $fatal(1,"Test 2 failed");

      $display("Test 2 PASS");

      a = 4'd7;
      b = 4'd9;
      #10;

      if(sum !== 5'd16)
        $fatal(1,"Test 3 failed");

      $display("Test 3 PASS");

      a = 4'd15;
      b = 4'd15;
      #10;

      if(sum !== 5'd30)
        $fatal(1,"Test 4 failed");

      $display("Test 4 PASS");

      $finish;

end

endmodule
