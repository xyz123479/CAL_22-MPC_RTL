module ENCODER #(
  parameter   NUM_PATTERNS  = 8,
  parameter   NUM_MODULES   = NUM_PATTERNS-1,

  parameter   LEN_ENCODE    = $clog2(NUM_PATTERNS)
)(
  input  [255:0] scanned_i,

  output [  8:0] size_o,
  output [119:0] startidx_o,
  output [271:0] codewords_o
);
  // synopsys template

  // rename input
  wire[15:0] scanned[0:15];
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : input_rename
      assign scanned[i] = scanned_i[(16 - i) * 16 - 1 : (15 - i) * 16];
    end
  endgenerate

  // instantiate BPEncoders
  wire[0:15] isZeros;
  wire[4:0] BP_sizelist[0:15];
  wire[16:0] BP_codewords[0:15];

  genvar j;
  generate
    for (j = 0; j < 16; j = j + 1) begin : BPEncoder
      BPEncoder BP_ENCODER (
        .scanned_i (scanned[j]),
        .isZero_o  (isZeros[j]),
        .size_o    (BP_sizelist[j]),
        .codeword_o(BP_codewords[j])
      );
    end
  endgenerate

  // instantiate ZRLE
  wire[79:0] ZRL_sizelist_contiguous;
  wire[4:0] ZRL_sizelist[0:15];
  wire[271:0] ZRL_codewords_contiguous;
  wire[16:0] ZRL_codewords[0:15];

  ZRLEncoder ZRL_ENCODER (
    .isZeros_i  (isZeros),
    .sizelist_o (ZRL_sizelist_contiguous),
    .codewords_o(ZRL_codewords_contiguous)
  );

  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin : ZRL_rename
      assign ZRL_sizelist[k] = ZRL_sizelist_contiguous[(16 - k) * 5 - 1 : (15 - k) * 5];
      assign ZRL_codewords[k] = ZRL_codewords_contiguous[(16 - k) * 17 - 1 : (15 - k) * 17];
    end
  endgenerate

  // integrate sizelists
  wire[4:0] sizelist[0:15];

  genvar integ_i, integ_j;
  generate 
    for (integ_i = 0; integ_i <= 15; integ_i = integ_i + 1) begin : integrate_sizelist_loop1
      for (integ_j = 0; integ_j <= 4; integ_j = integ_j + 1) begin : integrate_sizelist_loop2
        assign sizelist[integ_i][integ_j] = BP_sizelist[integ_i][integ_j] & ZRL_sizelist[integ_i][integ_j];
      end
    end
  endgenerate

  // integrate codewords
  wire[16:0] codewords[0:15];

  genvar integ_k, integ_l;
  generate
    for (integ_k = 0; integ_k <= 15; integ_k = integ_k + 1) begin : integrate_codewords_loop1
      for (integ_l = 0; integ_l <= 16; integ_l = integ_l + 1) begin : integrate_codewords_loop2
        assign codewords[integ_k][integ_l] = BP_codewords[integ_k][integ_l] & ZRL_codewords[integ_k][integ_l];
      end
    end
  endgenerate

  // output rename
  wire [79:0] sizelist_contiguous;
  genvar l;
  generate
    for (l = 0; l < 16; l = l + 1) begin : output_rename
      assign sizelist_contiguous[(16 - l) * 5 - 1 : (15 - l) * 5] = sizelist[l];
      assign codewords_o[(16 - l) * 17 - 1 : (15 - l) * 17] = codewords[l];
    end
  endgenerate

  // compressed size adder
  Adder   #(
    .NUM_PATTERNS   (NUM_PATTERNS)
  ) SIZE_ADDER (
    .sizelist_i(sizelist_contiguous),
    .size_o(size_o),
    .startidx_o(startidx_o)
  );

endmodule

/*** submodules ***/
module ZRLEncoder	(
  input  [0:15] isZeros_i,

  output [ 79:0] sizelist_o,
  output [271:0] codewords_o
);

  // localparams
  localparam[ 3:0] encodingBitsZero = 4'b0011;
  localparam[12:0] zeroDummyBits = 13'b0000000000000;
  localparam[ 4:0] zeroSize = 5'd4;

  localparam[ 2:0] encodingBitsZRL  = 3'b010;
  localparam[ 9:0] zrlDummyBits = 10'b0000000000;
  localparam[ 4:0] zrlSize = 5'd7;

  // rename outputs
  reg[4:0] sizelist[0:15];
  reg[16:0] codewords[0:15];

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : output_rename
      assign sizelist_o[(16 - i) * 5 - 1 : (15 - i) * 5] = sizelist[i];
      assign codewords_o[(16 - i) * 17 - 1 : (15 - i) * 17] = codewords[i];
    end
  endgenerate

  // Module #0
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b10??_????_????_???? : begin
        sizelist[0] = zeroSize;
        codewords[0] = {encodingBitsZero, zeroDummyBits};
      end

      16'b110?_????_????_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b1110_????_????_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b1111_0???_????_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b1111_10??_????_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b1111_110?_????_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b1111_1110_????_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b1111_1111_0???_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b1111_1111_10??_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b1111_1111_110?_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      16'b1111_1111_1110_???? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1010, zrlDummyBits};
      end

      16'b1111_1111_1111_0??? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1011, zrlDummyBits};
      end

      16'b1111_1111_1111_10?? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1100, zrlDummyBits};
      end

      16'b1111_1111_1111_110? :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1101, zrlDummyBits};
      end

      16'b1111_1111_1111_1110 :	begin
        sizelist[0] = zrlSize;
        codewords[0] = {encodingBitsZRL, 4'b1110, zrlDummyBits};
      end

      // 16'b1111_1111_1111_1111
      // All Zero,  No need to be implemented

      default :	begin
        sizelist[0] = 5'b11111;
        codewords[0] = 17'h1ffff;
      end
    endcase
  end

  // Module #1
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b11??_????_????_???? :	begin
        sizelist[1] = 5'd0;
        codewords[1] = 17'h00000;
      end

      16'b010?_????_????_???? :	begin
        sizelist[1] = zeroSize;
        codewords[1] = {encodingBitsZero, zeroDummyBits};
      end

      16'b0110_????_????_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b0111_0???_????_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b0111_10??_????_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b0111_110?_????_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b0111_1110_????_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b0111_1111_0???_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b0111_1111_10??_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b0111_1111_110?_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b0111_1111_1110_???? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      16'b0111_1111_1111_0??? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1010, zrlDummyBits};
      end

      16'b0111_1111_1111_10?? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1011, zrlDummyBits};
      end

      16'b0111_1111_1111_110? :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1100, zrlDummyBits};
      end

      16'b0111_1111_1111_1110 :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1101, zrlDummyBits};
      end

      16'b0111_1111_1111_1111 :	begin
        sizelist[1] = zrlSize;
        codewords[1] = {encodingBitsZRL, 4'b1110, zrlDummyBits};
      end

      default :	begin
        sizelist[1] = 5'b11111;
        codewords[1] = 17'h1ffff;
      end
    endcase
  end

  // Module #2
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b?11?_????_????_???? :	begin
        sizelist[2] = 5'd0;
        codewords[2] = 17'h00000;
      end

      16'b?010_????_????_???? :	begin
        sizelist[2] = zeroSize;
        codewords[2] = {encodingBitsZero, zeroDummyBits};
      end

      16'b?011_0???_????_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b?011_10??_????_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b?011_110?_????_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b?011_1110_????_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b?011_1111_0???_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b?011_1111_10??_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b?011_1111_110?_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b?011_1111_1110_???? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b?011_1111_1111_0??? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      16'b?011_1111_1111_10?? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b1010, zrlDummyBits};
      end

      16'b?011_1111_1111_110? :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b1011, zrlDummyBits};
      end

      16'b?011_1111_1111_1110 :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b1100, zrlDummyBits};
      end

      16'b?011_1111_1111_1111 :	begin
        sizelist[2] = zrlSize;
        codewords[2] = {encodingBitsZRL, 4'b1101, zrlDummyBits};
      end

      default :	begin
        sizelist[2] = 5'b11111;
        codewords[2] = 17'h1ffff;
      end
    endcase
  end

  // Module #3
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b??11_????_????_???? :	begin
        sizelist[3] = 5'd0;
        codewords[3] = 17'h00000;
      end

      16'b??01_0???_????_???? :	begin
        sizelist[3] = zeroSize;
        codewords[3] = {encodingBitsZero, zeroDummyBits};
      end

      16'b??01_10??_????_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b??01_110?_????_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b??01_1110_????_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b??01_1111_0???_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b??01_1111_10??_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b??01_1111_110?_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b??01_1111_1110_???? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b??01_1111_1111_0??? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b??01_1111_1111_10?? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      16'b??01_1111_1111_110? :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b1010, zrlDummyBits};
      end

      16'b??01_1111_1111_1110 :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b1011, zrlDummyBits};
      end

      16'b??01_1111_1111_1111 :	begin
        sizelist[3] = zrlSize;
        codewords[3] = {encodingBitsZRL, 4'b1100, zrlDummyBits};
      end

      default :	begin
        sizelist[3] = 5'b11111;
        codewords[3] = 17'h1ffff;
      end
    endcase
  end

  // Module #4
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b???1_1???_????_???? :	begin
        sizelist[4] = 5'd0;
        codewords[4] = 17'h00000;
      end

      16'b???0_10??_????_???? :	begin
        sizelist[4] = zeroSize;
        codewords[4] = {encodingBitsZero, zeroDummyBits};
      end

      16'b???0_110?_????_???? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b???0_1110_????_???? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b???0_1111_0???_???? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b???0_1111_10??_???? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b???0_1111_110?_???? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b???0_1111_1110_???? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b???0_1111_1111_0??? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b???0_1111_1111_10?? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b???0_1111_1111_110? :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      16'b???0_1111_1111_1110 :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b1010, zrlDummyBits};
      end

      16'b???0_1111_1111_1111 :	begin
        sizelist[4] = zrlSize;
        codewords[4] = {encodingBitsZRL, 4'b1011, zrlDummyBits};
      end

      default :	begin
        sizelist[4] = 5'b11111;
        codewords[4] = 17'h1ffff;
      end
    endcase
  end

  // Module #5
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_11??_????_???? :	begin
        sizelist[5] = 5'd0;
        codewords[5] = 17'h00000;
      end

      16'b????_010?_????_???? :	begin
        sizelist[5] = zeroSize;
        codewords[5] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_0110_????_???? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_0111_0???_???? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_0111_10??_???? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_0111_110?_???? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b????_0111_1110_???? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b????_0111_1111_0??? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b????_0111_1111_10?? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b????_0111_1111_110? :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b????_0111_1111_1110 :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      16'b????_0111_1111_1111 :	begin
        sizelist[5] = zrlSize;
        codewords[5] = {encodingBitsZRL, 4'b1010, zrlDummyBits};
      end

      default :	begin
        sizelist[5] = 5'b11111;
        codewords[5] = 17'h1ffff;
      end
    endcase
  end

  // Module #6
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_?11?_????_???? :	begin
        sizelist[6] = 5'd0;
        codewords[6] = 17'h00000;
      end

      16'b????_?010_????_???? :	begin
        sizelist[6] = zeroSize;
        codewords[6] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_?011_0???_???? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_?011_10??_???? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_?011_110?_???? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_?011_1110_???? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b????_?011_1111_0??? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b????_?011_1111_10?? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b????_?011_1111_110? :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b????_?011_1111_1110 :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      16'b????_?011_1111_1111 :	begin
        sizelist[6] = zrlSize;
        codewords[6] = {encodingBitsZRL, 4'b1001, zrlDummyBits};
      end

      default :	begin
        sizelist[6] = 5'b11111;
        codewords[6] = 17'h1ffff;
      end
    endcase
  end

  // Module #7
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_??11_????_???? :	begin
        sizelist[7] = 5'd0;
        codewords[7] = 17'h00000;
      end

      16'b????_??01_0???_???? :	begin
        sizelist[7] = zeroSize;
        codewords[7] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_??01_10??_???? :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_??01_110?_???? :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_??01_1110_???? :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_??01_1111_0??? :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b????_??01_1111_10?? :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b????_??01_1111_110? :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b????_??01_1111_1110 :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      16'b????_??01_1111_1111 :	begin
        sizelist[7] = zrlSize;
        codewords[7] = {encodingBitsZRL, 4'b1000, zrlDummyBits};
      end

      default :	begin
        sizelist[7] = 5'b11111;
        codewords[7] = 17'h1ffff;
      end
    endcase
  end

  // Module #8
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_???1_1???_???? :	begin
        sizelist[8] = 5'd0;
        codewords[8] = 17'h00000;
      end

      16'b????_???0_10??_???? :	begin
        sizelist[8] = zeroSize;
        codewords[8] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_???0_110?_???? :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_???0_1110_???? :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_???0_1111_0??? :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_???0_1111_10?? :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b????_???0_1111_110? :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b????_???0_1111_1110 :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      16'b????_???0_1111_1111 :	begin
        sizelist[8] = zrlSize;
        codewords[8] = {encodingBitsZRL, 4'b0111, zrlDummyBits};
      end

      default :	begin
        sizelist[8] = 5'b11111;
        codewords[8] = 17'h1ffff;
      end
    endcase
  end

  // Module #9
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_11??_???? :	begin
        sizelist[9] = 5'd0;
        codewords[9] = 17'h00000;
      end

      16'b????_????_010?_???? :	begin
        sizelist[9] = zeroSize;
        codewords[9] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_????_0110_???? :	begin
        sizelist[9] = zrlSize;
        codewords[9] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_????_0111_0??? :	begin
        sizelist[9] = zrlSize;
        codewords[9] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_????_0111_10?? :	begin
        sizelist[9] = zrlSize;
        codewords[9] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_????_0111_110? :	begin
        sizelist[9] = zrlSize;
        codewords[9] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b????_????_0111_1110 :	begin
        sizelist[9] = zrlSize;
        codewords[9] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      16'b????_????_0111_1111 :	begin
        sizelist[9] = zrlSize;
        codewords[9] = {encodingBitsZRL, 4'b0110, zrlDummyBits};
      end

      default :	begin
        sizelist[9] = 5'b11111;
        codewords[9] = 17'h1ffff;
      end
    endcase
  end

  // Module #10
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_?11?_???? :	begin
        sizelist[10] = 5'd0;
        codewords[10] = 17'h0000;
      end

      16'b????_????_?010_???? :	begin
        sizelist[10] = zeroSize;
        codewords[10] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_????_?011_0??? :	begin
        sizelist[10] = zrlSize;
        codewords[10] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_????_?011_10?? :	begin
        sizelist[10] = zrlSize;
        codewords[10] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_????_?011_110? :	begin
        sizelist[10] = zrlSize;
        codewords[10] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_????_?011_1110 :	begin
        sizelist[10] = zrlSize;
        codewords[10] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      16'b????_????_?011_1111 :	begin
        sizelist[10] = zrlSize;
        codewords[10] = {encodingBitsZRL, 4'b0101, zrlDummyBits};
      end

      default :	begin
        sizelist[10] = 5'b11111;
        codewords[10] = 17'h1ffff;
      end
    endcase
  end

  // Module #11
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_??11_???? :	begin
        sizelist[11] = 5'd0;
        codewords[11] = 17'h00000;
      end

      16'b????_????_??01_0??? :	begin
        sizelist[11] = zeroSize;
        codewords[11] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_????_??01_10?? :	begin
        sizelist[11] = zrlSize;
        codewords[11] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_????_??01_110? :	begin
        sizelist[11] = zrlSize;
        codewords[11] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_????_??01_1110 :	begin
        sizelist[11] = zrlSize;
        codewords[11] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      16'b????_????_??01_1111 :	begin
        sizelist[11] = zrlSize;
        codewords[11] = {encodingBitsZRL, 4'b0100, zrlDummyBits};
      end

      default :	begin
        sizelist[11] = 5'b11111;
        codewords[11] = 17'h1ffff;
      end
    endcase
  end

  // Module #12
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_???1_1??? :	begin
        sizelist[12] = 5'd0;
        codewords[12] = 17'h00000;
      end

      16'b????_????_???0_10?? :	begin
        sizelist[12] = zeroSize;
        codewords[12] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_????_???0_110? :	begin
        sizelist[12] = zrlSize;
        codewords[12] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_????_???0_1110 :	begin
        sizelist[12] = zrlSize;
        codewords[12] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      16'b????_????_???0_1111 :	begin
        sizelist[12] = zrlSize;
        codewords[12] = {encodingBitsZRL, 4'b0011, zrlDummyBits};
      end

      default :	begin
        sizelist[12] = 5'b11111;
        codewords[12] = 17'h1ffff;
      end
    endcase
  end

  // Module #13
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_????_11?? :	begin
        sizelist[13] = 5'd0;
        codewords[13] = 17'h00000;
      end

      16'b????_????_????_010? :	begin
        sizelist[13] = zeroSize;
        codewords[13] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_????_????_0110 :	begin
        sizelist[13] = zrlSize;
        codewords[13] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      16'b????_????_????_0111 :	begin
        sizelist[13] = zrlSize;
        codewords[13] = {encodingBitsZRL, 4'b0010, zrlDummyBits};
      end

      default :	begin
        sizelist[13] = 5'b11111;
        codewords[13] = 17'h1ffff;
      end
    endcase
  end

  // Module #14
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_????_?11? :	begin
        sizelist[14] = 5'd0;
        codewords[14] = 17'h00000;
      end

      16'b????_????_????_?010 :	begin
        sizelist[14] = zeroSize;
        codewords[14] = {encodingBitsZero, zeroDummyBits};
      end

      16'b????_????_????_?011 :	begin
        sizelist[14] = zrlSize;
        codewords[14] = {encodingBitsZRL, 4'b0001, zrlDummyBits};
      end

      default :	begin
        sizelist[14] = 5'b11111;
        codewords[14] = 17'h1ffff;
      end
    endcase
  end

  // Module #15
  always @(isZeros_i) begin
    casez (isZeros_i)
      16'b????_????_????_??11 :	begin
        sizelist[15] = 5'd0;
        codewords[15] = 17'h00000;
      end

      16'b????_????_????_??01 :	begin
        sizelist[15] = zeroSize;
        codewords[15] = {encodingBitsZero, zeroDummyBits};
      end

      default :	begin
        sizelist[15] = 5'b11111;
        codewords[15] = 17'h1ffff;
      end
    endcase
  end

endmodule

module Adder #(
  parameter   NUM_PATTERNS  = 8,

  parameter   LEN_ENCODE    = $clog2(NUM_PATTERNS)
)(
  input [79:0] sizelist_i,

  output [8:0] size_o,
  output [119:0] startidx_o
);
  // synopsys template
  wire [4:0] sizelist [0:15];
  reg [8:0] size;
  reg [7:0] startidx [1:15];

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : input_rename
      assign sizelist[i] = sizelist_i[(16-i)*5 - 1:(15-i)*5];
    end
  endgenerate

  integer j;
  always @(*) begin
    startidx[1] = sizelist[0];
    for (j = 2; j < 16; j = j + 1) begin
      startidx[j] = startidx[j - 1] + sizelist[j - 1];
    end
    size = startidx[15] + sizelist[15] + LEN_ENCODE;
  end

  genvar k;
  generate
    for (k = 1; k < 16; k = k + 1) begin : output_rename
      assign startidx_o[(16-k)*8 - 1:(15-k)*8] = startidx[k];
    end
  endgenerate
  assign size_o = size;
endmodule

module BPEncoder (
  input  [15:0] scanned_i,

  output        isZero_o,
  output [ 4:0] size_o,
  output [16:0] codeword_o
);

  wire is_zero;
  wire is_singleOne;
  wire is_doubleConsecOnes;
  wire is_frontHalfZeros;
  wire is_backHalfZeros;

  wire[16:0] zeroCodeword;
  wire[16:0] singleOneCodeword;
  wire[16:0] doubleConsecOnesCodeword;
  wire[16:0] frontHalfZerosCodeword;
  wire[16:0] backHalfZerosCodeword;

  // pattern check modules
  ZerosModule ZEROS (
    .data_i    (scanned_i),
    .flag_o    (is_zero),
    .codeword_o(zeroCodeword)
  );

  SingleOneModule SINGLE (
    .data_i    (scanned_i),
    .flag_o    (is_singleOne),
    .codeword_o(singleOneCodeword)
  );

  DoubleConsecOnesModule DOUBLE (
    .data_i    (scanned_i),
    .flag_o    (is_doubleConsecOnes),
    .codeword_o(doubleConsecOnesCodeword)
  );

  FrontHalfZerosModule FRONT_ZEROS (
    .data_i    (scanned_i),
    .flag_o    (is_frontHalfZeros),
    .codeword_o(frontHalfZerosCodeword)
  );

  BackHalfZerosModule BACK_ZEROS (
    .data_i    (scanned_i),
    .flag_o    (is_backHalfZeros),
    .codeword_o(backHalfZerosCodeword)
  );

  assign isZero_o = is_zero;

  // priority encoder
  wire[2:0] selectBits;
  PriorityEncoder PRIO_ENC (
    .is_zero_i            (is_zero),
    .is_singleOne_i       (is_singleOne),
    .is_doubleConsecOnes_i(is_doubleConsecOnes),
    .is_frontHalfZeros_i  (is_frontHalfZeros),
    .is_backHalfZeros_i   (is_backHalfZeros),
    .selectBits_o         (selectBits)
  );

  // codeword MUX
  CodewordMUX CODEWORD_MUX (
    .scanned_i                 (scanned_i),
    .selectBits_i              (selectBits),
    .zeroCodeword_i            (zeroCodeword),
    .singleOneCodeword_i       (singleOneCodeword),
    .doubleConsecOnesCodeword_i(doubleConsecOnesCodeword),
    .frontHalfZerosCodeword_i  (frontHalfZerosCodeword),
    .backHalfZerosCodeword_i   (backHalfZerosCodeword),
    .codeword_o                (codeword_o)
  );

  // size MUX
  SizeMUX SIZE_MUX (
    .selectBits_i(selectBits),
    .size_o      (size_o)
  );

endmodule

/*** submodules of BPEncoder ***/
module PriorityEncoder (
  input is_zero_i,
  input is_singleOne_i,
  input is_doubleConsecOnes_i,
  input is_frontHalfZeros_i,
  input is_backHalfZeros_i,

  output reg [2:0] selectBits_o
);

  wire[4:0] flags = {
    is_zero_i,
    is_singleOne_i,
    is_doubleConsecOnes_i,
    is_frontHalfZeros_i,
    is_backHalfZeros_i
  };

  always @(*) begin
    casez (flags)
      5'b1???? : selectBits_o = 3'b000;	// zeros
      5'b01??? : selectBits_o = 3'b001;	// single one
      5'b001?? : selectBits_o = 3'b010; // double consecutive ones
      5'b0001? : selectBits_o = 3'b011; // front half zeros
      5'b00001 : selectBits_o = 3'b100; // back half zeros
      5'b00000 : selectBits_o = 3'b101; // default
    endcase
  end

endmodule

module CodewordMUX (
  input [15:0] scanned_i,
  input [ 2:0] selectBits_i,

  input [16:0] zeroCodeword_i,
  input [16:0] singleOneCodeword_i,
  input [16:0] doubleConsecOnesCodeword_i,
  input [16:0] frontHalfZerosCodeword_i,
  input [16:0] backHalfZerosCodeword_i,

  output reg [16:0] codeword_o
);

  always @(*) begin
    case (selectBits_i)
      3'b000  : codeword_o = zeroCodeword_i;
      3'b001  : codeword_o = singleOneCodeword_i;
      3'b010  : codeword_o = doubleConsecOnesCodeword_i;
      3'b011  : codeword_o = frontHalfZerosCodeword_i;
      3'b100  : codeword_o = backHalfZerosCodeword_i;
      3'b101  : codeword_o = {1'b1, scanned_i};
      default : codeword_o = 17'd0;
    endcase
  end

endmodule

module SizeMUX (
  input [2:0]  selectBits_i,

  output reg [4:0] size_o
);

  always @(*) begin
    case (selectBits_i)
      3'b000  : size_o = 5'b11111;	// for convenient AND-operation
      3'b001  : size_o = 5'd7;
      3'b010  : size_o = 5'd8;
      3'b011  : size_o = 5'd12;
      3'b100  : size_o = 5'd12;
      3'b101  : size_o = 5'd17;
      default : size_o = 5'd0;
    endcase
  end

endmodule

module ZerosModule (
  input [15:0] data_i,

  output        flag_o,
  output [16:0] codeword_o
);

  assign codeword_o = (data_i == 16'h0000) ? 17'h1ffff : {1'b0, data_i};	// for conveninent AND-operation
  assign flag_o = (data_i == 16'h0000) ? 1'b1 : 1'b0;

endmodule

module SingleOneModule (
  input [15:0] data_i,

  output reg        flag_o,
  output reg [16:0] codeword_o
);

  localparam[2:0] encoding_bits = 3'b011;
  localparam[9:0] dummy_bits = 10'b0000000000;

  always @(*) begin
    case (data_i)
      16'b1000_0000_0000_0000 : begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0000, dummy_bits};
      end

      16'b0100_0000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0001, dummy_bits};
      end

      16'b0010_0000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0010, dummy_bits};
      end

      16'b0001_0000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0011, dummy_bits};
      end

      16'b0000_1000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0100, dummy_bits};
      end

      16'b0000_0100_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0101, dummy_bits};
      end

      16'b0000_0010_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0110, dummy_bits};
      end

      16'b0000_0001_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0111, dummy_bits};
      end

      16'b0000_0000_1000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1000, dummy_bits};
      end

      16'b0000_0000_0100_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1001, dummy_bits};
      end

      16'b0000_0000_0010_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1010, dummy_bits};
      end

      16'b0000_0000_0001_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1011, dummy_bits};
      end

      16'b0000_0000_0000_1000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1100, dummy_bits};
      end

      16'b0000_0000_0000_0100 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1101, dummy_bits};
      end

      16'b0000_0000_0000_0010 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1110, dummy_bits};
      end

      16'b0000_0000_0000_0001 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1111, dummy_bits};
      end

      default :	begin
        flag_o = 1'b0;
        codeword_o = {1'b0, data_i};
      end
    endcase
  end

endmodule

module DoubleConsecOnesModule (
  input [15:0] data_i,

  output reg        flag_o,
  output reg [16:0] codeword_o
);

  localparam[3:0] encoding_bits = 4'b0000;
  localparam[8:0] dummy_bits = 9'b000000000;

  always @(*) begin
    case (data_i)
      16'b1100_0000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0000, dummy_bits};
      end

      16'b0110_0000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0001, dummy_bits};
      end

      16'b0011_0000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0010, dummy_bits};
      end

      16'b0001_1000_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0011, dummy_bits};
      end

      16'b0000_1100_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0100, dummy_bits};
      end

      16'b0000_0110_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0101, dummy_bits};
      end

      16'b0000_0011_0000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0110, dummy_bits};
      end

      16'b0000_0001_1000_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b0111, dummy_bits};
      end

      16'b0000_0000_1100_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1000, dummy_bits};
      end

      16'b0000_0000_0110_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1001, dummy_bits};
      end

      16'b0000_0000_0011_0000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1010, dummy_bits};
      end

      16'b0000_0000_0001_1000 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1011, dummy_bits};
      end

      16'b0000_0000_0000_1100 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1100, dummy_bits};
      end

      16'b0000_0000_0000_0110 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1101, dummy_bits};
      end

      16'b0000_0000_0000_0011 :	begin
        flag_o = 1'b1;
        codeword_o = {encoding_bits, 4'b1110, dummy_bits};
      end

      default: begin
        flag_o = 1'b0;
        codeword_o = {1'b0, data_i};
      end
    endcase
  end

endmodule

module FrontHalfZerosModule (
  input [15:0] data_i,

  output        flag_o,
  output [16:0] codeword_o
);

  localparam[3:0] encoding_bits = 4'b0001;
  localparam[4:0] dummy_bits = 5'b00000;

  assign flag_o = (data_i[15:8] == 8'h00) ? 1'b1 : 1'b0;
  assign codeword_o = (data_i[15:8] == 8'h00) ? {encoding_bits, data_i[7:0], dummy_bits} : {1'b0, data_i};

endmodule

module BackHalfZerosModule (
  input [15:0] data_i,

  output        flag_o,
  output [16:0] codeword_o
);

  localparam[3:0] encoding_bits = 4'b0010;
  localparam[4:0] dummy_bits = 5'b00000;

  assign flag_o = (data_i[7:0] == 8'h00) ? 1'b1 : 1'b0;
  assign codeword_o = (data_i[7:0] == 8'h00) ? {encoding_bits, data_i[15:8], dummy_bits} : {1'b0, data_i};

endmodule

