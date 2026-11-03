

module iteration_counter (
      input wire clk,
      input wire rst,
      input wire clear,
      input wire enable,

      output reg [15:0] count
);

always @(posedge clk) begin
      if (rst)
        count <= 16'd0;
      else if (clear)
        count <= 16'd0;
      else if(enable)
        count <= count + 1'b1;

end

endmodule
