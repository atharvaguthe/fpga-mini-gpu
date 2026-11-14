

`timescale 1ns/1ps

module mandelbrot_scheduler_npe_tb;

localparam NUM_PE = 4;
localparam NUM_PIXELS = 8;

reg clk;
reg rst;

reg pixel_valid;
wire pixel_ready;

reg [15:0] pixel_x;
reg [15:0] pixel_y;

reg signed [15:0] pixel_a;
reg signed [15:0] pixel_b;

reg [15:0] max_iter;

wire [NUM_PE-1:0] start;
wire [NUM_PE*16-1:0] a_bus;
wire [NUM_PE*16-1:0] b_bus;

wire [NUM_PE*16-1:0] iterations_bus;
wire [NUM_PE-1:0] escaped_bus;
wire [NUM_PE-1:0] done_bus;

wire [NUM_PE-1:0] result_valid;
wire [NUM_PE*16-1:0] result_x_bus;
wire [NUM_PE*16-1:0] result_y_bus;
wire [NUM_PE*16-1:0] result_iterations_bus;
wire [NUM_PE-1:0] result_escaped_bus;

integer result_count;
integer i;

mandelbrot_pe_array #(
    .NUM_PE(NUM_PE)
) pe_array (
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

mandelbrot_scheduler_npe #(
  .NUM_PE(NUM_PE)
) scheduler (
  .clk(clk),
  .rst(rst),

  .pixel_valid(pixel_valid),
  .pixel_ready(pixel_ready),
  .pixel_x(pixel_x),
  .pixel_y(pixel_y),
  .pixel_a(pixel_a),
  .pixel_b(pixel_b),

  .start(start),
  .a_bus(a_bus),
  .b_bus(b_bus),

  .pe_done(done_bus),
  .iterations_bus(iterations_bus),
  .escaped_bus(escaped_bus),

  .result_valid(result_valid),
  .result_x_bus(result_x_bus),
  .result_y_bus(result_y_bus),
  .result_iterations_bus(result_iterations_bus),
  .result_escaped_bus(result_escaped_bus)
);

always #5 clk = ~clk;

always @(posedge clk) begin 
  if (rst) begin
    result_count = 0;
  end
  else begin
    for(i = 0; i < NUM_PE; i = i + 1) begin

      if (result_valid[i]) begin
       result_count = result_count + 1;
      
        $display("PE%0d: pixel=(%0d,%0d), iterations=%0d, escaped=%b",i,result_x_bus[i*16 +: 16],result_y_bus[i*16 +: 16],result_iterations_bus[i*16 +: 16],result_escaped_bus[i]);

        if (result_x_bus[i*16 +: 16] % 2 == 0) begin
          if(result_iterations_bus[i*16 +: 16] != 1 || result_escaped_bus[i] != 1)
            $fatal(1,"Incorrect result from PE%0d",i);
        
        end
        else begin
          if (result_iterations_bus[i*16 +: 16] != 8 || result_escaped_bus[i] != 0)
            $fatal(1,"Incorrect result form pe%0d",i);
        end
      end
    end 
  end 
end 

task send_pixel;
  input [15:0] x;
  input [15:0] y;
  input signed [15:0] a;
  input signed [15:0] b;

  begin
    @(negedge clk);

    while (!pixel_ready)
      @(negedge clk);

    pixel_x = x;
    pixel_y = y;
    pixel_a = a;
    pixel_b = b;
    pixel_valid = 1;

    @(posedge clk);
    @(negedge clk);

    pixel_valid = 0;
  end 
endtask

initial begin 
  clk = 0;
  rst = 1;

  pixel_valid = 0;
  pixel_x = 0;
  pixel_y = 0;
  pixel_a = 0;
  pixel_b = 0;

  max_iter = 8;

  repeat (3) @(negedge clk);
  rst = 0;

  $display("Starting 4- PE scheduler test ");

  for (integer p = 0; p < NUM_PIXELS; p = p + 1) begin

    if (p % 2 == 0)
      send_pixel(p,0,16'sd12288, 16'sd0);
    else 
      send_pixel(p,0,16'sd0, 16'sd0);

  end 

  wait (result_count == NUM_PIXELS);

  #10;

  $display("==============================");
  $display("pass");
  $display("total pixels processed: %0d", result_count);
  $display("==============================");

  $finish;

end 

initial begin

  #1000000;
  $fatal(1,"timout");
end 

endmodule

