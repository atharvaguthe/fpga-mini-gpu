

`timescale 1ns/1ps

module mandelbrot_renderer_npe #(
  parameter IMAGE_WIDTH = 320,
  parameter IMAGE_HEIGHT = 240,
  parameter NUM_PE = 4,
  parameter FIFO_DEPTH = 32
) (
  input wire clk,
  input wire rst,
  input wire start,

  input wire [15:0] max_iter,

  output wire result_valid,
  input wire result_ready,

  output wire [8:0] result_x,
  output wire [7:0] result_y,
  output wire [15:0] result_iterations,
  output wire result_escaped,

  output wire generation_done,
  output wire frame_done,

  output wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count
);

// =======================================
// 1. Pixel coordinate generator
// =======================================

wire [8:0] pixel_x;
wire [7:0] pixel_y;

wire signed [15:0] a;
wire signed [15:0] b;

wire pixel_valid;
wire pixel_ready;

pixel_coordinate_generator_parallel #(
  .IMAGE_WIDTH(IMAGE_WIDTH),
  .IMAGE_HEIGHT(IMAGE_HEIGHT)
) coordinate_generator (
  .clk(clk),
  .rst(rst),
  .start(start),

  .pixel_ready(pixel_ready),

  .pixel_x(pixel_x),
  .pixel_y(pixel_y),

  .a(a),
  .b(b),

  .valid(pixel_valid),
  .done(generation_done)
);

//=======================================
// 2. N PE scheduler
//=======================================

wire [NUM_PE-1:0] pe_start;

wire [NUM_PE*16-1:0] pe_a_bus;
wire [NUM_PE*16-1:0] pe_b_bus;
wire [NUM_PE*16-1:0] pe_iterations_bus;
wire [NUM_PE-1:0] pe_escaped_bus;
wire [NUM_PE-1:0] pe_done_bus;

wire [NUM_PE-1:0] scheduler_result_valid;
wire [NUM_PE-1:0] scheduler_result_ready;

wire [NUM_PE*16-1:0] scheduler_result_x;
wire [NUM_PE*16-1:0] scheduler_result_y;
wire [NUM_PE*16-1:0] scheduler_result_iterations;
wire [NUM_PE-1:0] scheduler_result_escaped;

mandelbrot_scheduler_npe #(
  .NUM_PE(NUM_PE)
) scheduler (
  .clk(clk),
  .rst(rst),

  .pixel_valid(pixel_valid),
  .pixel_ready(pixel_ready),

  .pixel_x({7'b0, pixel_x}),
  .pixel_y({8'b0, pixel_y}),

  .pixel_a(a),
  .pixel_b(b),

  .start(pe_start),
  .a_bus(pe_a_bus),
  .b_bus(pe_b_bus),

  .pe_done(pe_done_bus),
  .iterations_bus(pe_iterations_bus),
  .escaped_bus(pe_escaped_bus),

  .result_valid(scheduler_result_valid),
  .result_ready(scheduler_result_ready),

  .result_x_bus(scheduler_result_x),
  .result_y_bus(scheduler_result_y),
  .result_iterations_bus(scheduler_result_iterations),
  .result_escaped_bus(scheduler_result_escaped)
);

//=============================================
// 3. Parallel mandelbrot processing element
//=============================================

mandelbrot_pe_array #(
  .NUM_PE(NUM_PE)
) pe_array (
  .clk(clk),
  .rst(rst),

  .start(pe_start),

  .a_bus(pe_a_bus),
  .b_bus(pe_b_bus),

  .max_iter(max_iter),

  .iterations_bus(pe_iterations_bus),
  .escaped_bus(pe_escaped_bus),
  .done_bus(pe_done_bus)
);

//=============================================
// 4. N PE result collector 
//=============================================

wire fifo_valid;
wire [48:0] fifo_data;

pe_result_collector_npe #(
  .NUM_PE(NUM_PE),
  .FIFO_DEPTH(FIFO_DEPTH)
) result_collector (
  .clk(clk),
  .rst(rst),

  .result_valid(scheduler_result_valid),
  .result_ready(scheduler_result_ready),

  .result_x_bus(scheduler_result_x),
  .result_y_bus(scheduler_result_y),
  .result_iterations_bus(scheduler_result_iterations),
  .result_escaped_bus(scheduler_result_escaped),

  .out_valid(fifo_valid),
  .out_ready(result_ready),
  .out_data(fifo_data),

  .fifo_count(fifo_count)
);


//=============================================
// 5. Renderer output 
//=============================================
 
assign result_valid = fifo_valid;

assign result_x = fifo_data[41:33];
assign result_y = fifo_data[24:17];

assign result_iterations = fifo_data[16:1];
assign result_escaped = fifo_data[0];

//=============================================
// 6. Renderer output 
//=============================================

wire pixel_accepted;
wire result_consumed;

reg [31:0] outstanding_count;

assign pixel_accepted = pixel_valid && pixel_ready;
assign result_consumed = result_valid && result_ready;

always @(posedge clk) begin 
  if (rst) begin 
    outstanding_count <= 0;
  end 
  else begin 
    case({pixel_accepted, result_consumed})

      2'b10:
        outstanding_count <= outstanding_count + 1'b1;

      2'b01:
        outstanding_count <= outstanding_count - 1'b1;

      default:
        outstanding_count <= outstanding_count;
    endcase
  end 
end 

assign frame_done = generation_done && (outstanding_count == 0);

endmodule
