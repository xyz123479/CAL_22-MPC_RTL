//-------------------------------------
// Design Name  : D_FF
// File Name    : D_FF.v
// Function     : Synchronous D Flip-Flop
// Coder        : Hoyong Jin
//-------------------------------------

module D_FF #(
  parameter   BITWIDTH  = 4
) (
  input   wire  [BITWIDTH - 1:0]  d_i,
  input   wire                    clk,
  input   wire                    rst_n,

  output  reg   [BITWIDTH - 1:0]  q_o
);
// synopsys template

  always @(posedge clk) begin
    if (~rst_n) begin
      q_o   <= 'd0;
    end
    else begin
      q_o   <= d_i;
    end
  end
endmodule
