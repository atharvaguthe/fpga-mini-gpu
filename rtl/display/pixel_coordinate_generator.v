

`timescale 1ns/1ps

module pixel_coordinate_generator (
      input wire clk,
      input wire rst,
      input wire start,
      input wire pixel_done,

      output reg [8:0] pixel_x,
      output reg [7:0] pixel_y,

      output wire signed [15:0] a,
      output wire signed [15:0] b,

      output reg valid,
      output reg done

);

//Image dimensions
localparam WIDTH = 320;
localparam HEIGHT = 240;

//Intermediate calculation values
reg signed [31:0] a_calc;
reg signed [31:0] b_calc;

//convert pixel coordinates into Q4.12
always @(*) begin
      
      a_calc = -32'sd8192 + (($signed({1'b0, pixel_x}) * 32'sd12288) / 32'sd319);

      b_calc = -32'sd6144 + (($signed({1'b0, pixel_y}) * 32'sd12288) / 32'sd239);
      
end

assign a = a_calc[15:0];
assign b = b_calc[15:0];

// Pixel scanning logic
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
      end

      else if (valid && pixel_done) begin

        if (pixel_x == WIDTH - 1) begin

          pixel_x <= 0;

          if (pixel_y == HEIGHT - 1) begin

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

