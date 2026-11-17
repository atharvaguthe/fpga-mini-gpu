

`timescale 1ns/1ps

module pe_result_collector_npe_tb;

localparam NUM_PE = 4;
localparam FIFO_DEPTH = 8;

reg clk;
reg rst;

reg [NUM_PE-1:0] result_valid;
wire [NUM_PE-1:0] result_ready;

reg [NUM_PE*16-1:0] result_x_bus;
reg [NUM_PE*16-1:0] result_y_bus;
reg [NUM_PE*16-1:0] result_iterations_bus;
reg [NUM_PE-1:0] result_escaped_bus;

wire out_valid;
reg out_ready;
wire [48:0] out_data;

wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;
integer i;

pe_result_collector_npe #(
  .NUM_PE(NUM_PE),
  .FIFO_DEPTH(FIFO_DEPTH)
) dut (
  .clk(clk),
  .rst(rst),

  .result_valid(result_valid),
  .result_ready(result_ready),

  .result_x_bus(result_x_bus),
  .result_y_bus(result_y_bus),
  .result_iterations_bus(result_iterations_bus),
  .result_escaped_bus(result_escaped_bus),

  .out_valid(out_valid),
  .out_ready(out_ready),
  .out_data(out_data),

  .fifo_count(fifo_count)
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

task send_four;
  input [15:0] base;
  begin
    @(negedge clk);

    for(integer j = 0; j < NUM_PE; j = j + 1) begin
      result_x_bus[j*16 +: 16] = base + j;
      result_y_bus[j*16 +: 16] = j;
      result_iterations_bus[j*16 +: 16] = base + j + 1;
      result_escaped_bus[j] = j % 2;
    end 

    result_valid = 4'b1111;

    while (result_ready != 4'b1111) 
      @(negedge clk);

    @(posedge clk);
    #1;

    @(negedge clk);
    result_valid = 0;
  end 
endtask 

task read_and_check;
  input [15:0] expected_x;
  input [15:0] expected_y;
  input [15:0] expected_iterations;
  input expected_escaped;
  begin 
    @(negedge clk);
    out_ready = 1;

    #1;

    if(!out_valid)
      $fatal(1, "collector output unexpectedly empty");

    if(out_data !== {expected_x, expected_y, expected_iterations,expected_escaped})
      $fatal(1,"incorrect result for pixel %0d", expected_x);
    
    @(posedge clk);
    #1;

    @(negedge clk);
    out_ready = 0;
  end 
endtask

initial begin 
  clk = 0; rst = 1;

  result_valid = 0;
  result_x_bus = 0;
  result_y_bus = 0;
  result_iterations_bus = 0;
  result_escaped_bus = 0;
  out_ready = 0;

  repeat (3) @ (negedge clk);
  rst = 0;

  $display("Test 1: 4 simultanuous PE results");

  send_four(10);

  repeat (2) @(negedge clk);

  if(fifo_count != 4) 
    $fatal(1,"expected fifo count 4, got %0d",fifo_count);

  $display("Test 2 :output backpressure");

  if(!out_valid)
    $fatal(1, "expected valid output");

  if(out_data[48:33] != 10)
    $fatal(1, "first result incorrect");

  repeat (3) @(negedge clk);

  if(out_data[48:33] != 10 || fifo_count != 4)
    $fatal(1, "result changed during backpressure");

  $display("test 3: fifo ordering");

  for (i = 0; i < 4; i = i + 1) 
    read_and_check(10 + i,i,11+i, i%2);
  
  if(fifo_count != 0 || out_valid)
    $fatal(1, "fifo should be empty");

  $display("test 4: holding registers under backpressure");

  out_ready = 0;
  send_four(20);
  repeat (2) @(negedge clk);

  send_four(30);
  repeat(2) @(negedge clk);

  if (fifo_count != FIFO_DEPTH)
    $fatal(1, "expected full fifo, got %0d", fifo_count);

  send_four(40);
  repeat (2) @(negedge clk);

  if (fifo_count != FIFO_DEPTH)
    $fatal(1, "fifo count changed while output blocked");

  if(dut.hold_valid != 4'b1111)
    $fatal(1, "holding registers did not retain all results");

  $display("test 5: Drain and release held results");

  out_ready = 1;

  for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
    @(posedge clk);
    #1;
    @(negedge clk);
  end 

  out_ready = 0;
  repeat (3) @(negedge clk);

  if(fifo_count != 4)
    $fatal(1, "expected four released results, got %0d", fifo_count);

  if(dut.hold_valid != 0)
    $fatal(1, "holding registers should be empty");

  for(i = 0; i < 4; i = i + 1) 
    read_and_check(40+i, i, 41+i, i%2);
    
  if (fifo_count != 0)
    $fatal(1,"fifo should be empty at end");

  $display("==============================");
  $display("pass: all test complete");
  $display("==============================");

  $finish;

end 

initial begin 
#200000;
$fatal(1, "timout");
end 

endmodule



