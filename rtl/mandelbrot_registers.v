
module mandelbrot_registers (
        input wire clk,
        input wire rst,
        input wire load,
        input wire initialize,

        input wire signed [20:0] x_next,
        input wire signed [20:0] y_next,

        output reg signed [20:0] x_reg,
        output reg signed [20:0] y_reg

);

always @(posedge clk) begin 
        if (rst || initialize) begin
            x_reg <= 21'sd0;   
            y_reg <= 21'sd0;   
        end
        else if (load) begin
            x_reg <= x_next;
            y_reg <= y_next;
        end

    end

endmodule
