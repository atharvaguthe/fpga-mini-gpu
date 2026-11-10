

`timescale 1ns/1ps

module pe_result_hold (
      
      input wire clk,
      input wire rst,

      input wire capture_valid,
      input wire [8:0] capture_x,
      input wire [7:0] capture_y,
      input wire [15:0] capture_iterations,
      input wire capture_escaped,

      output wire out_valid,
      input wire out_ready,

      output wire [8:0] out_x,
      output wire [7:0] out_y,
      output wire [15:0] out_iterations,
      output wire out_escaped
);

reg valid_reg;

reg [8:0] x_reg;
reg [7:0] y_reg;
reg [15:0] iterations_reg;
reg escaped_reg;

assign out_valid = valid_reg;

assign out_x = x_reg;
assign out_y = y_reg;
assign out_iterations = iterations_reg;
assign out_escaped = escaped_reg;

always @(posedge clk) begin
      if(rst) begin
        valid_reg <= 0;

        x_reg <= 0;
        y_reg <= 0;
        iterations_reg <= 0;
        escaped_reg <= 0;
      end 

      else begin

        if(capture_valid) begin

          if (valid_reg && !out_ready)
            $error("PE result holding register overflow");

          x_reg <= capture_x;
          y_reg <= capture_y;
          iterations_reg <= capture_iterations;
          escaped_reg <= capture_escaped;

          valid_reg <= 1;

        end

        else if (valid_reg && out_ready) begin
          valid_reg <= 0;
        end

      end 

    end 

endmodule
