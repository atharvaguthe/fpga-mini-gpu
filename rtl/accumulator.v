
`timescale 1ns/1ps

module accumulator (
      input wire clk,
      input wire rst,
      input wire enable,

      input wire [7:0] data_in,
      output reg [7:0] result
);

always @(posedge clk) begin

      if (rst)
        result <= 8'd0;

      else if (enable)
        result <= result + data_in;

end

endmodule
