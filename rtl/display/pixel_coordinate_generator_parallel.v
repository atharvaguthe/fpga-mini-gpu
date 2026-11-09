
`timescale 1ns/1ps

module pixel_coordinate_generator_parallel #(
      parameter IMAGE_WIDTH = 320,
      parameter IMAGE_HEIGHT = 240
)(
      
      input wire clk,
      input wire rst,
      input wire start,
      input wire pixel_ready,

      output reg [8:0] pixel_x,
      output reg [7:0] pixel_y,

      output wire signed [15:0] a,
      output wire signed [15:0] b,

      output reg valid,
      output reg done
);

//Intermediate coordinate calculation
reg signed [31:0] a_calc;
reg signed [31:0] b_calc;

//Convert pixel coorinates into Q4.12

always @(*) begin
      
      a_calc = -32'sd8192 + (($signed({1'b0,pixel_x}) * 32'sd12288) / (IMAGE_WIDTH - 1));

      b_calc = -32'sd6144 + (($signed({1'b0,pixel_y}) * 32'sd12288) / (IMAGE_HEIGHT - 1));

end

assign a = a_calc[15:0];
assign b = b_calc[15:0];

always @(posedge clk) begin
      
      if (rst) begin

        pixel_x <= 0;
        pixel_y <= 0;

        valid <= 0;
        done <= 0;

      end

      else if (start && !valid && !done) begin

        pixel_x <= 0;
        pixel_y <= 0;

        valid <= 1;
        done <= 0;

      end

      else if (valid && pixel_ready) begin

        // Last pixel of the frame?

        if (pixel_x == IMAGE_WIDTH - 1) begin

          pixel_x <= 0;

          if (pixel_y == IMAGE_HEIGHT - 1) begin

            valid <= 0;
            done <= 1;

          end

          else begin

            pixel_y <= pixel_y + 1'b1;

          end

        end

        else begin

          pixel_x <= pixel_x + 1'b1;

        end

      end

end 

endmodule


