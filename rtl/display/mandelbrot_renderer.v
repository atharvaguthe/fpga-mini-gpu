
`timescale 1ns/1ps

module mandelbrot_renderer (
      input wire clk,
      input wire rst,
      input wire start,

      input wire [15:0] max_iter,

      output reg [8:0] result_x,
      output reg [7:0] result_y,
      output reg [15:0] result_iterations,
      output reg result_escaped,
      output reg result_valid,

      output wire frame_done
);

// controller states 

localparam IDLE = 3'd0;
localparam WAIT_PIXEL = 3'd1;
localparam LAUNCH_PE = 3'd2;
localparam WAIT_PE = 3'd3;
localparam CAPTURE = 3'd4;

reg [2:0] state;

// coordinate generator
reg generator_start;
reg pixel_done;

wire [8:0] pixel_x;
wire [7:0] pixel_y;

wire signed [15:0] a;
wire signed [15:0] b;

wire pixel_valid;
wire generator_done;

pixel_coordinate_generator coordinate_generator (
        .clk(clk),
        .rst(rst),
        .start(generator_start),
        .pixel_done(pixel_done),

        .pixel_x(pixel_x),
        .pixel_y(pixel_y),

        .a(a),
        .b(b),

        .valid(pixel_valid),
        .done(generator_done)
);

// mandelbrot processing element 

reg pe_start;

wire [15:0] iterations;
wire escaped;
wire pe_done;

mandelbrot_pe processing_element (
        .clk(clk),
        .rst(rst),
        .start(pe_start),

        .a(a),
        .b(b),
        .max_iter(max_iter),

        .iterations(iterations),
        .escaped(escaped),
        .done(pe_done)
);

// frame completion
assign frame_done = generator_done;
// handshake

// renderer completion

always @ (posedge clk) begin
    
      if (rst) begin
          state <= IDLE;

          generator_start <= 0;
          pe_start <= 0;
          pixel_done <= 0;

          result_x <= 0;
          result_y <= 0;
          result_iterations <= 0;
          result_escaped <= 0;
          result_valid <= 0;

      end 

      else begin

          generator_start <= 0;
          pe_start <= 0;
          pixel_done <= 0;
          result_valid <= 0;

          case (state)

            IDLE: begin
              if (start) begin

                generator_start <= 1;
                state <= WAIT_PIXEL;

              end
            end 

            WAIT_PIXEL: begin

              if (pixel_valid)
                state <= LAUNCH_PE;
              else if (generator_done)
                state <= IDLE;

            end

            LAUNCH_PE: begin

              pe_start <= 1;
              state <= WAIT_PE;

            end

            WAIT_PE: begin

              if (pe_done)
                state <= CAPTURE;

            end

            CAPTURE: begin

              result_x <= pixel_x;
              result_y <= pixel_y;

              result_iterations <= iterations;
              result_escaped <= escaped;

              result_valid <= 1;
              pixel_done <= 1;

              state <= WAIT_PIXEL;

            end

            default:
              state <= IDLE;

          endcase

      end


end

endmodule
