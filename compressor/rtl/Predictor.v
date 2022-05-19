module PREDICTOR #(
  parameter[0:7]   ROOT_IDX = 8'd21,
  parameter[0:255] BASE_IDX = {
    8'd11, 8'd11, 8'd23, 8'd11, 8'd07, 8'd07, 8'd07, 8'd15,
    8'd11, 8'd11, 8'd07, 8'd19, 8'd15, 8'd15, 8'd23, 8'd23,
    8'd19, 8'd19, 8'd23, 8'd23, 8'd23, 8'd21, 8'd23, 8'd21,
    8'd27, 8'd27, 8'd23, 8'd19, 8'd31, 8'd11, 8'd23, 8'd23
  },
  parameter[0:255] SHIFT_VAL = {
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0
  }
)	(
  input [255:0] data_i,

  output [  7:0] root_o,
  output [247:0] data_o,
  output [247:0] pred_o
);
// synopsys template

  genvar i, j, k, l;

  wire[7:0] data_byte[0:31];
  wire[7:0] pred[0:31];

  // renaming input in byte size
  generate
    for (i = 0; i < 32; i = i + 1) begin : input_rename
      assign data_byte[i] = data_i[(32 - i) * 8 - 1 : (31 - i) * 8];
    end
  endgenerate

  // prediction
  generate
    for (j = 0; j < 32; j = j + 1) begin : prediction
      localparam        [0:7] base_idx = BASE_IDX[j * 8 : (j + 1) * 8 - 1];
      localparam signed [0:7] shift_val = SHIFT_VAL[j * 8 : (j + 1) * 8 - 1];

      if (shift_val > 0) begin : pred_rs
        assign pred[j] = (data_byte[base_idx] << shift_val);
      end
      else if (shift_val < 0) begin : pred_ls
        assign pred[j] = (data_byte[base_idx] >> -shift_val);
      end
      else begin : pred_ns
        assign pred[j] = (data_byte[base_idx]);
      end
    end
  endgenerate

  // renaming pred to contiguous pred_o
  generate
    for (k = 0; k < 31; k = k + 1) begin : pred_rename
      localparam[0:7] idx = (k >= ROOT_IDX) ? k + 1 : k;
      assign pred_o[(31 - k) * 8 - 1 : (30 - k) * 8] = pred[idx];
    end
  endgenerate

  // assign output
  assign root_o = data_byte[ROOT_IDX];
  generate
    for (l = 0; l < 31; l = l + 1) begin : output_rename
      localparam[0:7] idx = (l >= ROOT_IDX) ? l + 1 : l;
      assign data_o[(31 - l) * 8 - 1 : (30 - l) * 8] = data_byte[idx];
    end
  endgenerate

endmodule

