module SELECTOR   #(
  parameter   NUM_PATTERNS  = 8,
  parameter   NUM_MODULES   = NUM_PATTERNS-1,

  parameter   LEN_ENCODE    = $clog2(NUM_PATTERNS)
)(
  input   wire  [255:0]           original_i,
  input   wire                    isAllZero_i,
  input   wire                    isAllWordSame_i,

  input   wire  [LEN_ENCODE-1:0]  select_i,
  input   wire  [  8:0]           size_i,
  input   wire  [119:0]           startidx_i,
  input   wire  [271:0]           codewords_i,

  output  wire  [271:0]           codewords_o,
  output  wire  [119:0]           startidx_o,
  output  wire  [LEN_ENCODE-1:0]  select_o,
  output  wire  [  8:0]           size_o
);
  // synopsys template
  
  reg   [271:0]           codewords;
  reg   [119:0]           startidx;
  reg   [LEN_ENCODE-1:0]  select;
  reg   [8:0]             size;

  always @(*) begin
    // all-zero
    if (isAllZero_i) begin
      codewords = 272'd0;
      startidx = 120'd0;
      select = 'd0;
      size = LEN_ENCODE;
    end
    // all-wordsame
    else if (isAllWordSame_i) begin
      codewords = {original_i[255:224], 240'b0};
      startidx[119:112] = 'd17;
      startidx[111:104] = 'd34;
      startidx[103: 96] = 'd51;
      startidx[ 95: 88] = 'd68;
      startidx[ 87: 80] = 'd85;
      startidx[ 79: 72] = 'd102;
      startidx[ 71: 64] = 'd119;
      startidx[ 63: 56] = 'd136;
      startidx[ 55: 48] = 'd153;
      startidx[ 47: 40] = 'd170;
      startidx[ 39: 32] = 'd187;
      startidx[ 31: 24] = 'd204;
      startidx[ 23: 16] = 'd221;
      startidx[ 15:  8] = 'd238;
      startidx[  7:  0] = 'd255;
      select = 'd1;
      size = LEN_ENCODE + 'd32;
    end
    // uncompressible
    else if (size_i >= 'd256 + LEN_ENCODE) begin
      codewords = {original_i, 16'b0};
      startidx[119:112] = 'd17;
      startidx[111:104] = 'd34;
      startidx[103: 96] = 'd51;
      startidx[ 95: 88] = 'd68;
      startidx[ 87: 80] = 'd85;
      startidx[ 79: 72] = 'd102;
      startidx[ 71: 64] = 'd119;
      startidx[ 63: 56] = 'd136;
      startidx[ 55: 48] = 'd153;
      startidx[ 47: 40] = 'd170;
      startidx[ 39: 32] = 'd187;
      startidx[ 31: 24] = 'd204;
      startidx[ 23: 16] = 'd221;
      startidx[ 15:  8] = 'd238;
      startidx[  7:  0] = 'd255;
      select = NUM_PATTERNS - 1;
      size = LEN_ENCODE + 256;
    end
    // compressible
    else begin
      codewords = codewords_i;
      startidx = startidx_i;
      select = select_i;
      size = size_i;
    end
  end

  // output assignment
  assign codewords_o = codewords;
  assign startidx_o = startidx;
  assign select_o = select;
  assign size_o = size;
endmodule
