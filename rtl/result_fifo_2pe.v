
`timescale 1ns/1ps

module result_fifo_2pe #(
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst,

    // PE0 input
    input wire in_valid0,
    output wire in_ready0,
    input wire [8:0] in_x0,
    input wire [7:0] in_y0,
    input wire [15:0] in_iterations0,
    input wire in_escaped0,

    // PE1 input
    input wire in_valid1,
    output wire in_ready1,
    input wire [8:0] in_x1,
    input wire [7:0] in_y1,
    input wire [15:0] in_iterations1,
    input wire in_escaped1,

    // FIFO output
    output wire out_valid,
    input wire out_ready,
    output wire [8:0] out_x,
    output wire [7:0] out_y,
    output wire [15:0] out_iterations,
    output wire out_escaped,

    output wire [$clog2(DEPTH+1)-1:0] count
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [33:0] memory [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] write_ptr;
    reg [PTR_WIDTH-1:0] read_ptr;

    reg [$clog2(DEPTH+1)-1:0] count_reg;

    wire pop;
    wire accept0;
    wire accept1;

    wire [PTR_WIDTH-1:0] second_write_addr;

    integer available;

    // FIFO status
    assign out_valid = (count_reg != 0);
    assign pop = out_valid && out_ready;

    // Available space, including space freed by a simultaneous read.
    always @(*) begin
        available = DEPTH - count_reg + pop;
    end

    // PE0 gets priority when only one slot is available.
    assign in_ready0 = (available >= 1);
    assign accept0 = in_valid0 && in_ready0;

    assign in_ready1 =
        (available >= 2) ||
        (!in_valid0 && available >= 1);

    assign accept1 = in_valid1 && in_ready1;

    // Calculate the next write address with wraparound.
    assign second_write_addr =
        (write_ptr == DEPTH-1) ? 0 : write_ptr + 1'b1;

    // FIFO output
    assign {
        out_x,
        out_y,
        out_iterations,
        out_escaped
    } = memory[read_ptr];

    assign count = count_reg;

    always @(posedge clk) begin

        if (rst) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count_reg <= 0;
        end

        else begin

            // Write PE0 at the current write address.
            if (accept0) begin
                memory[write_ptr] <= {
                    in_x0,
                    in_y0,
                    in_iterations0,
                    in_escaped0
                };
            end

            // Write PE1 at the next address if PE0 also writes.
            // Otherwise PE1 uses the current write address.
            if (accept1) begin
                if (accept0) begin
                    memory[second_write_addr] <= {
                        in_x1,
                        in_y1,
                        in_iterations1,
                        in_escaped1
                    };
                end
                else begin
                    memory[write_ptr] <= {
                        in_x1,
                        in_y1,
                        in_iterations1,
                        in_escaped1
                    };
                end
            end

            // Update write pointer exactly once.
            case ({accept0, accept1})

                2'b00: write_ptr <= write_ptr;

                2'b01,
                2'b10: begin
                    if (write_ptr == DEPTH-1)
                        write_ptr <= 0;
                    else
                        write_ptr <= write_ptr + 1'b1;
                end

                2'b11: begin
                    if (write_ptr >= DEPTH-2)
                        write_ptr <= write_ptr - (DEPTH-2);
                    else
                        write_ptr <= write_ptr + 2;
                end

            endcase

            // Update read pointer.
            if (pop) begin
                if (read_ptr == DEPTH-1)
                    read_ptr <= 0;
                else
                    read_ptr <= read_ptr + 1'b1;
            end

            // Update occupancy.
            count_reg <= count_reg
                       + accept0
                       + accept1
                       - pop;

        end
    end

endmodule
