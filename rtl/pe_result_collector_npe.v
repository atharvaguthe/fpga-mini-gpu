

`timescale 1ns/1ps

module pe_result_collector_npe #(
  parameter NUM_PE = 4,
  parameter FIFO_DEPTH = 32
) (
  input wire clk,
  input wire rst,
  
  input wire [NUM_PE-1:0] result_valid,
  output wire [NUM_PE-1:0] result_ready,

  input wire [NUM_PE*16-1:0] result_x_bus,
  input wire [NUM_PE*16-1:0] result_y_bus,
  input wire [NUM_PE*16-1:0] result_iterations_bus,
  input wire [NUM_PE-1:0] result_escaped_bus,

  output wire out_valid,
  input wire out_ready,
  output wire [48:0] out_data,

  output wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count
  
);

reg [NUM_PE-1:0] hold_valid;
reg [NUM_PE*49-1:0] hold_data_bus;

wire [NUM_PE-1:0] fifo_write_ready;

integer i;

assign result_ready = ~hold_valid | fifo_write_ready;

wire [NUM_PE*49-1:0] fifo_write_data_bus;

assign fifo_write_data_bus = hold_data_bus;

result_fifo_npe #(
  .NUM_PE(NUM_PE),
  .DEPTH(FIFO_DEPTH)
) result_fifo (
  .clk(clk),
  .rst(rst),
  
  .write_valid(hold_valid),
  .write_ready(fifo_write_ready),
  .write_data_bus(fifo_write_data_bus),

  .out_valid(out_valid),
  .out_ready(out_ready),
  .out_data(out_data),

  .count(fifo_count)
);

always @(posedge clk) begin
  if (rst) begin
    hold_valid <= 0;
    hold_data_bus <= 0;
  end 

  else begin 
    for(i = 0;i < NUM_PE; i = i + 1) begin

      if (result_valid[i] && result_ready[i]) begin 

        hold_valid[i] <= 1'b1;

        hold_data_bus[i*49 +: 49] <= {result_x_bus[i*16 +: 16],result_y_bus[i*16 +: 16],result_iterations_bus[i*16 +: 16],result_escaped_bus[i]};

      end 
      else if (hold_valid[i] && fifo_write_ready[i]) begin
        hold_valid[i] <= 1'b0;
      end 
    end 
  end 
end 

endmodule 
        
