

`timescale 1ns/1ps

module multiplier_tb;


reg [3:0] a;
reg [3:0] b;
wire [7:0] product;


reg [7:0] expected;

integer i;
integer j;

multiplier dut(
      .a(a),
      .b(b),
      .product(product)
);

initial begin

      $dumpfile("sim/multiplier.vcd");
      $dumpvars(0, multiplier_tb);


      for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin

          a = i;
          b = j;

          expected = i * j;


          #10;

          if (product !== expected) begin

            $display(
            "FAIL: A=%0d B=%0d Expected=%0d Actual=%0d", a, b, expected, product
            );
            $fatal;
          end 

        end

      end

      $display("ALL 256 Multiplications test passed");

      $finish;

end

endmodule
