

`timescale 1ns/1ps

module mandelbrot_scheduler_2pe (

  input wire clk,
  input wire rst,

  input wire pixel_valid,
  output wire pixel_ready,

  input wire [8:0] pixel_x,
  input wire [7:0] pixel_y,
  input wire signed [15:0] a,
  input wire signed [15:0] b,

  input wire [15:0] max_iter,

  output wire result_valid0,
  output wire [8:0] result_x0,
  output wire [7:0] result_y0,
  output wire [15:0] iterations0,
  output wire escaped0,

  output wire result_valid1,
  output wire [8:0] result_x1,
  output wire [7:0] result_y1,
  output wire [15:0] iterations1,
  output wire escaped1

);

reg busy0;
reg busy1;

reg next_pe;

reg [8:0] stored_x0;
reg [7:0] stored_y0;

reg [8:0] stored_x1;
reg [7:0] stored_y1;

reg start0;
reg start1;

wire done0;
wire done1;

wire [15:0] pe_iterations0;
wire [15:0] pe_iterations1;

wire pe_escaped0;
wire pe_escaped1;

always @(*) begin
  start0 = 0;
  start1 = 0;


  if (pixel_valid) begin

    if(next_pe == 0) begin

      if(!busy0)

        start0 = 1;

      else if (!busy1)

        start1 = 1;

    end 

    else begin

      if(!busy1)

        start1 = 1;

      else if(!busy0)
        start1 = 1;

    end

  end
end

assign pixel_ready = !busy0 || !busy1;

mandelbrot_pe_pair pe_pair(

  .clk(clk),
  .rst(rst),

  .start0(start0),
  .start1(start1),

  .a0(a),
  .b0(b),
  .a1(a),
  .b1(b),

  .max_iter(max_iter),

  .iterations0(pe_iterations0),
  .escaped0(pe_escaped0),
  .done0(done0),

  .iterations1(pe_iterations1),
  .escaped1(pe_escaped1),
  .done1(done1)
);

always @(posedge clk) begin

  if(rst) begin
    busy0 <= 0;
    busy1 <= 0;

    next_pe <= 0;

    stored_x0 <= 0;
    stored_y0 <= 0;
    stored_x1 <= 0;
    stored_y1 <= 0;

  end

  else begin
    if(start0) begin

      busy0 <= 1;
      stored_x0 <= pixel_x;
      stored_y0 <= pixel_y;
      next_pe <= 1;
    end

    if(start1) begin
      busy1 <= 1;
      stored_x1 <= pixel_x;
      stored_y1 <= pixel_y;
      next_pe <= 0;
    end

    if (done0)
      busy0 <= 0;

    if (done1)
      busy1 <= 0;
  end
end


assign result_valid0 = done0;
assign result_valid1 = done1;

assign result_x0 = stored_x0;
assign result_y0 = stored_y0;

assign result_x1 = stored_x1;
assign result_y1 = stored_y1;

assign iterations0 = pe_iterations0;
assign iterations1 = pe_iterations1;

assign escaped0 = pe_escaped0;
assign escaped1 = pe_escaped1;

endmodule
