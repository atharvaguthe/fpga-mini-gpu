

module mandelbrot_fsm (
    input wire clk,
    input wire rst,
    input wire start,

    input wire escaped,
    input wire max_reached,

    output reg initialize,
    output reg update,
    output reg done,
    output reg count_enable
);

localparam IDLE = 3'd0;
localparam INIT = 3'd1;
localparam CALC = 3'd2;
localparam CHECK = 3'd3;
localparam UPDATE = 3'd4;
localparam DONE = 3'd5;

reg [2:0] state;
reg [2:0] next_state;

always @(posedge clk) begin 
    if (rst) 
      state <= IDLE;
    else 
      state <= next_state;

end


always @(*) begin
    next_state = state;

    case (state)

        IDLE: begin
            if (start)
              next_state = INIT;
        end

        INIT:
            next_state = CALC;

        CALC:
            next_state = CHECK;

        CHECK: begin
            if (escaped || max_reached)
              next_state = DONE;
            else
              next_state = UPDATE;
        end

        UPDATE:
            next_state = CALC;

        DONE:
            next_state = IDLE;

        default:
            next_state = IDLE;


      endcase
end

always @(*) begin
      initialize = 0;
      update = 0;
      done = 0;
      count_enable = 0;

      case (state)

          INIT:
              initialize = 1;

          CALC:
              count_enable = 1;

          UPDATE:
              update = 1;

          DONE: 
              done = 1;

          default: begin
              initialize = 0;
              update = 0;
              done = 0;
              count_enable = 0;
          
          end
      endcase

end

endmodule
