
`timescale 1ns/1ps

module mandelbrot_renderer_tb;

reg clk;
reg rst;
reg start;

reg [15:0] max_iter;

wire [8:0] result_x;
wire [7:0] result_y;
wire [15:0] result_iterations;
wire result_escaped;
wire result_valid;
wire frame_done;

integer expected_x;
integer expected_y;

integer count;
integer cycles;

reg [76799:0] seen;

mandelbrot_renderer uut (
    .clk(clk),
    .rst(rst),
    .start(start),

    .max_iter(max_iter),

    .result_x(result_x),
    .result_y(result_y),
    .result_iterations(result_iterations),
    .result_escaped(result_escaped),
    .result_valid(result_valid),

    .frame_done(frame_done)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;
    start = 0;
    max_iter = 16;

    count = 0;
    cycles = 0;
    seen = 0;

    $display("================================");
    $display("SINGLE PE RENDERER STARTED");
    $display("Resolution: 320 x 240");
    $display("Maximum iterations: %0d", max_iter);
    $display("================================");

    repeat (2) @(negedge clk);
    rst = 0;

    @(negedge clk);
    start = 1;

    @(negedge clk);
    start = 0;

    // Measure from the first clock after start
    // until all results and frame completion.
    while ((count < 76800 || !frame_done) &&
           cycles < 10000000) begin

        @(posedge clk);
        #1;

        cycles = cycles + 1;

        if (result_valid) begin

            if (result_x >= 320 || result_y >= 240)
                $fatal(1, "Invalid pixel coordinate");

            expected_x = count % 320;
            expected_y = count / 320;

            if (result_x !== expected_x ||
                result_y !== expected_y)
                $fatal(1,
                    "Pixel order error: expected (%0d,%0d), got (%0d,%0d)",
                    expected_x, expected_y, result_x, result_y);

            if (seen[result_y * 320 + result_x])
                $fatal(1, "Duplicate pixel");

            seen[result_y * 320 + result_x] = 1'b1;

            count = count + 1;

            if (count % 5000 == 0)
                $display(
                    "Progress: %0d / 76800 | %0.1f%%",
                    count, (count * 100.0) / 76800
                );

        end

    end

    if (count != 76800)
        $fatal(1, "Incorrect pixel count: %0d", count);

    if (!frame_done)
        $fatal(1, "Frame generation did not finish");

    if (seen !== {76800{1'b1}})
        $fatal(1, "Missing pixels detected");

    $display("================================");
    $display("PASS: Single PE full resolution");
    $display("Total pixels: %0d", count);
    $display("Clock cycles: %0d", cycles);
    $display("Throughput: %f pixels/cycle",
             76800.0 / cycles);
    $display("================================");

    $finish;

end

initial begin
    #1000000000;
    $fatal(1, "TIMEOUT");
end

endmodule
