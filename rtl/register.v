

module register (
      input wire clk,
      input wire rst,
      input wire enable,

      input wire [7:0] data_in,
      output reg [7:0] data_out
);


always @(posedge clk) begin


        if (rst)
          data_out <= 8'd0;


        else if (enable)
          data_out <= data_in;

end

endmodule
