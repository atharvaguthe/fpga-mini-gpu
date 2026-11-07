
`timescale 1ns/1ps

module mandelbrot_registers_q16(
    
    input wire clk,
    input wire rst,
    input wire load,
    input wire initialize,

    input wire signed [24:0] x_next,
    input wire signed [24:0] y_next,

    output reg signed [24:0] x_reg,
    output reg signed [24:0] y_reg
);

always @(posedge clk) begin 

      if (rst || initialize) begin

        x_reg <= 25'sd0;
        y_reg <= 25'sd0;

      end 

      else if (load) begin

        x_reg <= x_next;
        y_reg <= y_next;

      end
end

endmodule
