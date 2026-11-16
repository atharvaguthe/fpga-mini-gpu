

`timescale 1ns/1ps

module result_fifo_npe_tb;

localparam NUM_PE = 4;
localparam DEPTH = 8;

reg clk;
reg rst;

reg [NUM_PE-1:0] write_valid;
wire [NUM_PE-1:0] write_ready;
reg [NUM_PE*49-1:0] write_data_bus;

wire out_valid;
reg out_ready;
wire [48:0] out_data;

wire [$clog2(DEPTH+1)-1:0] count;

integer i;

result_fifo_npe #(
  .NUM_PE(NUM_PE),
  .DEPTH(DEPTH)
) dut (
  .clk(clk),
  .rst(rst),
  .write_valid(write_valid),
  .write_ready(write_ready),
  .write_data_bus(write_data_bus),
  .out_valid(out_valid),
  .out_ready(out_ready),
  .out_data(out_data),
  .count(count)
);

always #5 clk = ~clk;

function [48:0] make_result;

  input [15:0] x;
  input [15:0] y;
  input [15:0] iterations;
  input escaped;
  begin
    make_result = {x,y,iterations,escaped};
  end 
endfunction 

task write_four;
  input [15:0] base;
  begin 
    @(negedge clk);

    for (integer j = 0; j < NUM_PE; j = j + 1) begin 
      write_data_bus[j*49 +: 49] = make_result(base+j, 0, base+j+1, 0);
    end 

    write_valid = 4'b1111;

    #1;

    if(write_ready != 4'b1111)
      $fatal(1, "Expected all four write channels ready");

    @(posedge clk);
    #1;

    @(negedge clk);
    write_valid = 0;
  end 
endtask 

task read_and_check;
  input [15:0] expected_x;
  begin 
    out_ready = 1;

    #1;
    if (!out_valid)
      $fatal(1, "fifo unexectedly empty");

    if (out_data[48:33] !== expected_x)
      $fatal(1, "ordering error: expected x=%0d, got x=%0d",expected_x, out_data[48:33]);

    @(posedge clk);
    #1;

    @(negedge clk);
    out_ready = 0;
  end 
endtask

initial begin

  clk = 0;
  rst = 1;

  write_valid = 0;
  write_data_bus = 0;
  out_ready = 0;

  repeat (2) @(negedge clk);
  rst = 0;

  // Test 1 : four simultanuous writes 
  $display("Test 1 : simultanuous writes");

  write_four(10);

  if (count != 4) 
    $fatal(1, "Expected count = 4, got %0d",count);

  //Test 2 : fifo ordering 
  $display("TEST 2 : fifo ordering");

  for (i = 0; i < 4;i = i + 1)
    read_and_check(10+i);

  if (count != 0 || out_valid)
    $fatal(1,"fifo should be empty");

  //TEst 3 : simultanuous read and write 
  $display("Test 3 : simultanuous read/write");

  write_four(20);

  @(negedge clk);
  out_ready = 1;
  write_valid = 4'b0001;
  write_data_bus[0 +: 49] = make_result(99,0,5,0);

  #1;

  if(out_data[48:33] !== 20)
    $fatal(1, "incorrect fifo output");

  @(posedge clk);
  #1;

  if(count != 4)
    $fatal(1,"count incorrect after simultanuous read/write");

  @(negedge clk);
  out_ready = 0;
  write_valid = 0;

  read_and_check(21);
  read_and_check(22);
  read_and_check(23);
  read_and_check(99);

  if (count != 0)
    $fatal(1, "fifo should be empty after draining");

  // test 4 : full condition 
  $display("test 4 : full conditon");

  write_four(30);
  write_four(40);

  if(count != DEPTH)
    $fatal(1,"fifo did not reach full capacity");

  @(negedge clk);
  write_valid = 4'b0001;
  write_data_bus[0 +: 49] = make_result(100, 0, 1, 0);

  #1;

  if(write_ready != 0)
    $fatal(1,"fifo accepted a write while full");
  
  @(negedge clk);
  write_valid = 0;

  out_ready = 1;
  write_valid = 4'b0001;
  write_data_bus[0 +: 49] = make_result(100,0,1,0);

  #1;

  if(write_ready != 4'b0001)
    $fatal(1,"fifo did not accept write alongside read");

  @(posedge clk);
  #1;

  if(count != DEPTH)
    $fatal(1, "fifo count incorrect after full read/write");

  @(negedge clk);
  out_ready = 0;
  write_valid = 0;

  for (i = 0; i < DEPTH; i = i + 1) begin 
    out_ready = 1;
    @(posedge clk);
    #1;
    @(negedge clk);
  end 

  out_ready = 0;

  if(count != 0 || out_valid)
    $fatal(1, "fifo failed to return to empty");

  $display("=============================");
  $display("Pass: N input fifo, all fifo test passed");
  $display("=============================");

  $finish;

end 

initial begin 
#100000;
$fatal(1, "timout");
end 

endmodule

