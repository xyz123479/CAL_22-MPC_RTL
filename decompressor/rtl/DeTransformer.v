module DETRANSFORMER #(
  parameter   [0:7]     ROOT_IDX  = 8'd16,
  parameter   [0:7]     LEVEL     = 8'd7,
  parameter   [0:255]   LEN_LEVEL     = {
    8'd03, 8'd03, 8'd04, 8'd09, 8'd08, 8'd02, 8'd02, 8'd00,
    8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00,
    8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00,
    8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00
  },
  parameter   [0:255]   LEVEL_START   = {
    8'd00, 8'd03, 8'd06, 8'd10, 8'd19, 8'd27, 8'd29, 8'd31,
    8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00,
    8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00,
    8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00
  },
  parameter   [0:255]   TARGET_IDX    = {
    8'd00, 8'd14, 8'd18, 8'd12, 8'd17, 8'd20, 8'd01, 8'd10,
    8'd19, 8'd22, 8'd03, 8'd08, 8'd21, 8'd23, 8'd24, 8'd25,
    8'd27, 8'd29, 8'd31, 8'd05, 8'd06, 8'd07, 8'd09, 8'd11,
    8'd13, 8'd15, 8'd26, 8'd04, 8'd28, 8'd02, 8'd30, 8'd00
  },
  parameter   [0:255]   BASE_IDX      = {
    8'd16, 8'd17, 8'd04, 8'd01, 8'd06, 8'd03, 8'd08, 8'd03,
    8'd10, 8'd03, 8'd12, 8'd03, 8'd14, 8'd03, 8'd16, 8'd03,
    8'd16, 8'd00, 8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd19,
    8'd22, 8'd19, 8'd24, 8'd19, 8'd26, 8'd19, 8'd28, 8'd19
  },
  parameter   [0:255]   SHIFT_VAL     = {
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
    8'd0, -8'd6,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
    8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0
  }
)(
  input   wire  [255:0]   diff_i,

  output  wire  [255:0]   detransformed_o
);
  // synopsys template

  wire  [7:0]   detransformed   [0:31];
  

  // root permuted input re-navigate
  wire  [7:0]   diff  [0:31];
  genvar j;
  generate
    assign diff[ROOT_IDX] = diff_i[255:248];
    for (j = 0; j < 32; j = j + 1) begin : input_rename
      if (j == ROOT_IDX) begin : root_rename
        assign diff[j]  = diff_i[255:248];
      end
      else if (j < ROOT_IDX) begin : under_the_root
        localparam  [0:7]   idx   = j + 1;
        assign diff[j]  = diff_i[256-8*idx-1:256-8*(idx+1)];
      end
      else begin : over_the_root
        localparam  [0:7]   idx   = j;
        assign diff[j]  = diff_i[256-8*idx-1:256-8*(idx+1)];
      end
    end
  endgenerate
  assign detransformed[ROOT_IDX] = diff[ROOT_IDX];

  // detransform
  wire  [7:0]   pred  [0:31];
  genvar level;
  genvar i;
  generate
    for (level = 0; level < LEVEL; level = level + 1) begin : level_traverse
      localparam  [0:7]   start_idx   = LEVEL_START[8*level : 8*(level+1)-1];
      for (i = 0; i < LEN_LEVEL[8*level:8*(level+1)-1]; i = i + 1) begin : idx_traverse
        localparam          target_idx  = TARGET_IDX[8*(start_idx+i) : 8*(start_idx+i+1)-1];
        localparam          base_idx    = BASE_IDX[8*target_idx : 8*(target_idx+1)-1];
        localparam signed   shift_val   = SHIFT_VAL[8*target_idx : 8*(target_idx+1)-1];

        if (shift_val > 0) begin : pred_rs
          assign pred[target_idx] = detransformed[base_idx] << shift_val;
        end
        else if (shift_val < 0) begin : pred_ls
          assign pred[target_idx] = detransformed[base_idx] >> -shift_val;
        end
        else begin : pred_ns
          assign pred[target_idx] = detransformed[base_idx];
        end

        assign detransformed[target_idx] = diff[target_idx] + pred[target_idx];
      end
    end
  endgenerate

  genvar k;
  generate
    for (k = 0; k < 32; k = k + 1) begin : output_rename
      assign detransformed_o[256-8*k-1:256-8*(k+1)] = detransformed[k];
    end
  endgenerate
endmodule

