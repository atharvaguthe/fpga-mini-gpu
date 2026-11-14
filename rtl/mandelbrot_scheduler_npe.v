
`timescale 1ns/1ps

module mandelbrot_scheduler_npe #(
    parameter NUM_PE = 4
) (
    input wire clk,
    input wire rst,
    
    //incoming pixel
    input wire pixel_valid,
    output reg pixel_ready,
    input wire [15:0] pixel_x,
    input wire [15:0] pixel_y,
    input wire signed [15:0] pixel_a,
    input wire signed [15:0] pixel_b,
    input wire [15:0] max_iter,

    // PE control and input buses
    output reg [NUM_PE-1:0] start,
    output reg [NUM_PE*16-1:0] a_bus,
    output reg [NUM_PE*16-1:0] b_bus,

    // PE completion inputs
    input wire [NUM_PE-1:0] pe_done,
    input wire [NUM_PE*16-1:0] iterations_bus,
    input wire [NUM_PE-1:0] escaped_bus,

    //REsults, one channel per pe
    output reg [NUM_PE-1:0] result_valid,
    output reg [NUM_PE*16-1:0] result_x_bus,
    output reg [NUM_PE*16-1:0] result_y_bus,
    output reg [NUM_PE*16-1:0] result_iterations_bus,
    output reg [NUM_PE-1:0] result_escaped_bus

);

reg [NUM_PE-1:0] busy;

reg [15:0] stored_x [0:NUM_PE-1];
reg [15:0] stored_y [0:NUM_PE-1];

integer rr_ptr;
integer i;
integer offset;
integer candidate;
integer selected_pe;
reg found;

always @(*) begin 
  found = 0;
  selected_pe = 0;
  pixel_ready = 0;
  candidate = 0;

  for (offset = 0; offset < NUM_PE; offset = offset + 1) begin
    candidate = rr_ptr + offset;

    if (candidate >= NUM_PE)
      candidate = candidate - NUM_PE;

    if (!found && !busy[candidate]) begin
      found = 1;
      selected_pe = candidate;
    end

  end 

  pixel_ready = found;

end 

always @(posedge clk) begin

  if (rst) begin

    busy<= 0;
    rr_ptr <= 0;
    
    start <= 0;
    a_bus <= 0;
    b_bus <= 0;

    result_valid <= 0;
    result_x_bus <= 0;
    result_y_bus <= 0;
    result_iterations_bus <= 0;
    result_escaped_bus <= 0;
  
  end
  else begin

    start <= 0;
    result_valid <= pe_done;

    for (i = 0; i < NUM_PE; i = i + 1) begin
      if(pe_done[i]) begin

        busy[i] <= 0;

        result_x_bus[i*16 +: 16] <= stored_x[i];
        result_y_bus[i*16 +: 16] <= stored_y[i];

        result_iterations_bus[i*16 +: 16] <= iterations_bus[i*16 +: 16];

        result_escaped_bus[i] <= escaped_bus[i];

      end 
    end 

    if (pixel_valid && pixel_ready) begin
      
      busy[selected_pe] <= 1;

      start[selected_pe] <= 1;

      a_bus[selected_pe*16 +: 16] <= pixel_a;
      b_bus[selected_pe*16 +: 16] <= pixel_b;

      stored_x[selected_pe] <= pixel_x;
      stored_y[selected_pe] <= pixel_y;

      if (selected_pe == NUM_PE-1)
        rr_ptr <= 0;
      else
        rr_ptr <= selected_pe + 1;
    
    end
  end 
end 

endmodule
 
