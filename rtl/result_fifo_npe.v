

`timescale 1ns/1ps

module result_fifo_npe #(
  parameter NUM_PE = 4,
  parameter DEPTH = 32
) (
  input wire clk,
  input wire rst,

  input wire [NUM_PE-1:0] write_valid,
  output reg [NUM_PE-1:0] write_ready,
  input wire [NUM_PE*49-1:0] write_data_bus,

  output wire out_valid,
  input wire out_ready,
  output wire [48:0] out_data,

  output reg [$clog2(DEPTH+1)-1:0] count
);

localparam PTR_W = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

reg [48:0] memory [0:DEPTH-1];

reg [PTR_W-1:0] write_ptr;
reg [PTR_W-1:0] read_ptr;

integer comb_i;
integer slots;
integer comb_accepted;

integer seq_i;
integer seq_accepted;
integer seq_write_index;


assign out_valid = (count != 0);
assign out_data = memory[read_ptr];

always @(*) begin 
  write_ready = 0;
  slots = DEPTH - count;

  if (out_valid && out_ready)
    slots = slots + 1;

  comb_accepted = 0;

  for (comb_i = 0; comb_i < NUM_PE; comb_i = comb_i + 1) begin
    if (write_valid[comb_i] && comb_accepted < slots) begin
      write_ready[comb_i] = 1;
      comb_accepted = comb_accepted + 1;
    end 
  end 
end 

always @(posedge clk) begin
  if (rst) begin
    write_ptr <= 0;
    read_ptr <= 0;
    count <= 0;
  end 
  else begin

    seq_accepted = 0;

    for (seq_i = 0; seq_i < NUM_PE; seq_i = seq_i + 1) begin
      if (write_valid[seq_i] && write_ready[seq_i]) begin

        seq_write_index = write_ptr + seq_accepted;
        if (seq_write_index >= DEPTH)
          seq_write_index = seq_write_index - DEPTH;

        memory[seq_write_index] <= write_data_bus[seq_i*49 +: 49];

        seq_accepted = seq_accepted + 1;
      end 
    end 

    seq_write_index = write_ptr + seq_accepted;

    if(seq_write_index >= DEPTH)
      seq_write_index = seq_write_index - DEPTH;

    write_ptr <= seq_write_index;

    if (out_valid && out_ready) begin
      if (read_ptr == DEPTH-1)
        read_ptr <= 0;
      else 
        read_ptr <= read_ptr + 1'b1;
    end 

    count <= count + seq_accepted - ((out_valid && out_ready) ? 1 : 0);

  end 
end 
endmodule

