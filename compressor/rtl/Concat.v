module CONCAT #(
  parameter     NUM_CLUSTERS = 8,
  parameter     NUM_ENCODED_LINES = 16
)(
  input   wire  [271:0]                               codewords_i,
  input   wire  [119:0]                               startidx_i,
  input   wire  [$clog2(NUM_CLUSTERS) - 1 : 0]        select_i,

  output  wire  [256 + $clog2(NUM_CLUSTERS) - 1 : 0]  concat_o
);
// synopsys template

  // rename input
  wire  [255:0]  codewords[0:NUM_ENCODED_LINES-1];
  wire  [  7:0]  startidx[1:NUM_ENCODED_LINES-1];
  genvar i;
  generate
    for (i = 0; i < NUM_ENCODED_LINES; i = i + 1) begin : input_rename
      assign codewords[i] = {codewords_i[(NUM_ENCODED_LINES - i) * 17 - 1 : (NUM_ENCODED_LINES - i - 1) * 17], 239'd0};
      if (i >= 1) begin : startidx_rename
        assign startidx[i] = startidx_i[(NUM_ENCODED_LINES - i) *  8 - 1 : (NUM_ENCODED_LINES - i - 1) *  8];
      end
    end
  endgenerate

  // shift
  wire  [255:0] shiftedWords[0:NUM_ENCODED_LINES-1];
  assign shiftedWords[0] = codewords[0];
  genvar j;
  generate
    for (j = 1; j < NUM_ENCODED_LINES; j = j + 1) begin : berrel_shift
      assign shiftedWords[j] = codewords[j] >> startidx[j];
    end
  endgenerate

  // bit-wise OR
  integer k;
  reg [255:0]  concat;
  always @(*) begin
    concat = 'd0;
    for (k = 0; k < NUM_ENCODED_LINES; k = k + 1) begin
      concat = concat | shiftedWords[k];
    end
  end
  assign concat_o = {select_i, concat};
endmodule
