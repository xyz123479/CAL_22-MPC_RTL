module DEDBX (
  input   wire  [255:0]   bpx_i,

  output  wire  [255:0]   diff_o
);

  wire  [0:31]  bitplaneXOR   [0:7];
  wire  [0:31]  bitplane      [0:7];
  wire  [0:7]   diff          [0:31];

  // input rename
  genvar k;
  generate
    for (k = 0; k < 8; k = k + 1) begin : input_rename
      assign bitplaneXOR[k] = bpx_i[32*(8-k)-1 : 32*(7-k)];
    end
  endgenerate

  // xor operation
  //// consecutive-xor base (first row)
  assign bitplane[0] = bitplaneXOR[0];
  //// root (first col)
  genvar i;
  generate
    for (i = 1; i < 8; i = i + 1) begin : move_root
      assign bitplane[i][0] = bitplaneXOR[i][0];
    end
  endgenerate

  genvar row_xor, col_xor;
  generate
    for (row_xor = 1; row_xor < 8; row_xor = row_xor + 1) begin : xor_row
      for (col_xor = 1; col_xor < 32; col_xor = col_xor + 1) begin : xor_col
        assign bitplane[row_xor][col_xor] = bitplaneXOR[row_xor][col_xor] ^ bitplane[row_xor - 1][col_xor];
      end
    end
  endgenerate

  // bitplane transpose
  genvar row_tr, col_tr;
  generate
    for (row_tr = 0; row_tr < 32; row_tr = row_tr + 1) begin : transpose_row
      for (col_tr = 0; col_tr < 8; col_tr = col_tr + 1) begin : transpose_col
        assign diff[row_tr][col_tr] = bitplane[col_tr][row_tr];
      end
    end
  endgenerate

  // output rename
  genvar j;
  generate
    for (j = 0; j < 32; j = j + 1) begin : output_rename
      assign diff_o[256-8*j-1:256-8*(j+1)] = diff[j];
    end
  endgenerate

endmodule
