

`timescale 1ns/1ps

module mandelbrot_pe_array_tb;

localparam NUM_PE = 4;

reg clk;
reg rst;

reg [NUM_PE-1:0] start;

reg [NUM_PE*16-1:0] a_bus;
reg [NUM_PE*16-1:0] b_bus;

reg [15:0] max_iter;

wire [NUM_PE*16-1:0] iterations_bus;
wire [NUM_PE-1:0] escaped_bus;
wire [NUM_PE-1:0] done_bus;

reg [NUM_PE-1:0] completed;

integer i;

mandelbrot_pe_array #(
    .NUM_PE(NUM_PE)
) dut (
    .clk(clk),
    .rst(rst),
    .start(start),

    .a_bus(a_bus),
    .b_bus(b_bus),
    .max_iter(max_iter),

    .iterations_bus(iterations_bus),
    .escaped_bus(escaped_bus),
    .done_bus(done_bus)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst)
        completed <= 0;
    else
        completed <= completed | done_bus;
end

initial begin
    
    clk = 0;
    rst = 1;
    start = 0;

    a_bus = 0;
    b_bus = 0;

    max_iter = 8;

    repeat (2) @(negedge clk);
    rst = 0;

    // PE0 : c = 3 + 0i
    a_bus[0*16+:16] = 16'sd12288;

    // PE1 : c = 0 + 0i
    a_bus[1*16+:16] = 16'sd0;

    // PE2 : c = 0 + 0i
    a_bus[2*16+:16] = 16'sd0;
    
    // PE3 : c = 3 + 0i
    a_bus[3*16+:16] = 16'sd12288;

    @(negedge clk);
    start = 4'b1111;

    @(negedge clk);
    start = 0;

    wait(&completed);

    #1;

    for (i = 0; i < NUM_PE; i = i + 1) begin

      $display("PE%0d: iterations=%0d, escaped=%b",i,iterations_bus[i*16+:16], escaped_bus[i]);

    end 

    if(iterations_bus[0*16+:16] != 1 || escaped_bus[0] != 1)
      $fatal(1,"PE0 failed");

    if(iterations_bus[1*16+:16] != 8 || escaped_bus[1] != 0)
      $fatal(1,"PE1 failed");
      
    if(iterations_bus[2*16+:16] != 8 || escaped_bus[2] != 0)
      $fatal(1,"PE2 failed");
      
    if(iterations_bus[3*16+:16] != 1 || escaped_bus[3] != 1)
      $fatal(1,"PE3 failed");

    $display("===========================");
    $display("Pass :four pe array");
    $display("============================");

    $finish;

    end

initial begin
  #10000;
  $fatal(1,"timeout");
end 

endmodule
