

`timescale 1ns/1ps

module mandelbrot_pe_array #(
    parameter NUM_PE = 4
) (
    input wire clk,
    input wire rst,

    input wire [NUM_PE-1:0] start,

    input wire [NUM_PE*16-1:0] a_bus,
    input wire [NUM_PE*16-1:0] b_bus,

    input wire [15:0] max_iter,

    output wire [NUM_PE*16-1:0] iterations_bus,
    output wire [NUM_PE-1:0] escaped_bus,
    output wire [NUM_PE-1:0] done_bus
);

genvar i;

generate

  for (i = 0; i < NUM_PE; i = i + 1) begin : PE_ARRAY 

    mandelbrot_pe processing_element (
        .clk(clk),
        .rst(rst),
        .start(start[i]),

        .a(a_bus[i*16 +: 16]),
        .b(b_bus[i*16 +: 16]),

        .max_iter(max_iter),

        .iterations(iterations_bus[i*16 +: 16]),
        .escaped(escaped_bus[i]),
        .done(done_bus[i])
    );

  end 

endgenerate 

endmodule 
