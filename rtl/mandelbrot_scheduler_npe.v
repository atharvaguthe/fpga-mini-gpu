
`timescale 1ns/1ps

module mandelbrot_scheduler_npe #(
    parameter NUM_PE = 4
)(
    input wire clk,
    input wire rst,

    // Incoming pixel
    input wire pixel_valid,
    output reg pixel_ready,
    input wire [15:0] pixel_x,
    input wire [15:0] pixel_y,
    input wire signed [15:0] pixel_a,
    input wire signed [15:0] pixel_b,

    // PE control and input buses
    output reg [NUM_PE-1:0] start,
    output reg [NUM_PE*16-1:0] a_bus,
    output reg [NUM_PE*16-1:0] b_bus,

    // PE completion inputs
    input wire [NUM_PE-1:0] pe_done,
    input wire [NUM_PE*16-1:0] iterations_bus,
    input wire [NUM_PE-1:0] escaped_bus,

    // Result interface with backpressure
    output wire [NUM_PE-1:0] result_valid,
    input wire [NUM_PE-1:0] result_ready,

    output wire [NUM_PE*16-1:0] result_x_bus,
    output wire [NUM_PE*16-1:0] result_y_bus,
    output wire [NUM_PE*16-1:0] result_iterations_bus,
    output wire [NUM_PE-1:0] result_escaped_bus
);

    // A PE remains busy until its result is accepted.
    reg [NUM_PE-1:0] busy;

    // Indicates a completed result waiting for acceptance.
    reg [NUM_PE-1:0] pending;

    reg [15:0] stored_x [0:NUM_PE-1];
    reg [15:0] stored_y [0:NUM_PE-1];

    reg [15:0] stored_iterations [0:NUM_PE-1];
    reg stored_escaped [0:NUM_PE-1];

    integer rr_ptr;
    integer i;
    integer offset;
    integer candidate;
    integer selected_pe;
    reg found;

    // Result interface remains valid while pending.
    assign result_valid = pending;

    // Hold result data stable until accepted.
    genvar g;
    generate
        for (g = 0; g < NUM_PE; g = g + 1) begin : RESULT_OUTPUTS

            assign result_x_bus[g*16 +: 16] =
                stored_x[g];

            assign result_y_bus[g*16 +: 16] =
                stored_y[g];

            assign result_iterations_bus[g*16 +: 16] =
                stored_iterations[g];

            assign result_escaped_bus[g] =
                stored_escaped[g];

        end
    endgenerate

    // Round-robin search for an available PE.
    always @(*) begin
        found = 0;
        selected_pe = 0;
        pixel_ready = 0;
        candidate = 0;

        for (offset = 0; offset < NUM_PE; offset = offset + 1) begin

            candidate = rr_ptr + offset;

            if (candidate >= NUM_PE)
                candidate = candidate - NUM_PE;

            if (!found && !busy[candidate]) begin
                found = 1;
                selected_pe = candidate;
            end
        end

        pixel_ready = found;
    end

    // Scheduler state and result capture.
    always @(posedge clk) begin

        if (rst) begin

            busy <= 0;
            pending <= 0;

            rr_ptr <= 0;

            start <= 0;
            a_bus <= 0;
            b_bus <= 0;

            for (i = 0; i < NUM_PE; i = i + 1) begin
                stored_x[i] <= 0;
                stored_y[i] <= 0;
                stored_iterations[i] <= 0;
                stored_escaped[i] <= 0;
            end

        end
        else begin

            // Start is a one-cycle pulse.
            start <= 0;

            // Capture completed PE results.
            for (i = 0; i < NUM_PE; i = i + 1) begin

                if (pe_done[i]) begin

                    stored_iterations[i] <=
                        iterations_bus[i*16 +: 16];

                    stored_escaped[i] <= escaped_bus[i];

                    pending[i] <= 1;

                end

                // Release PE only after collector accepts result.
                if (pending[i] && result_ready[i]) begin

                    pending[i] <= 0;
                    busy[i] <= 0;

                end

            end

            // Allocate a new pixel to an available PE.
            if (pixel_valid && pixel_ready) begin

                busy[selected_pe] <= 1;

                start[selected_pe] <= 1;

                a_bus[selected_pe*16 +: 16] <= pixel_a;
                b_bus[selected_pe*16 +: 16] <= pixel_b;

                stored_x[selected_pe] <= pixel_x;
                stored_y[selected_pe] <= pixel_y;

                if (selected_pe == NUM_PE-1)
                    rr_ptr <= 0;
                else
                    rr_ptr <= selected_pe + 1;

            end

        end
    end

endmodule
