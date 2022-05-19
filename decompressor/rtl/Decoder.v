module DECODER_GROUP #(
  parameter   NUM_DECODERS    = 8
)(
  input   wire  [255:0]                 data_i,
  input   wire  [  3:0]                 zrl_carry_i,

  output  wire  [16*NUM_DECODERS-1:0]   scanned_o,
  output  wire  [255:0]                 data_o,
  output  wire  [  3:0]                 zrl_carry_o
);
  // synopsys template

  wire  [255:0]   data      [0:NUM_DECODERS];
  wire  [  3:0]   zrl       [0:NUM_DECODERS];
  wire  [  4:0]   size      [0:NUM_DECODERS-1];
  wire  [ 15:0]   scanned   [0:NUM_DECODERS-1];

  // input assignment
  assign zrl[0]   = zrl_carry_i;
  assign data[0]  = data_i;

  genvar i;
  generate
    for (i = 0; i < NUM_DECODERS; i = i + 1) begin : decoders
      DECODER   DEC   (
        .data_i     (data[i]),
        .zrl_i      (zrl[i]),

        .size_o     (size[i]),
        .zrl_o      (zrl[i+1]),
        .scanned_o  (scanned[i])
      );
    end
  endgenerate

  genvar j;
  generate
    for (j = 1; j < NUM_DECODERS+1; j = j + 1) begin : sized_shift
      assign data[j] = data[j-1] << size[j-1];
    end
  endgenerate

  // output assignment
  genvar k;
  generate
    for (k = 0; k < NUM_DECODERS; k = k + 1) begin : output_rename
      assign scanned_o[16*(NUM_DECODERS-k)-1:16*(NUM_DECODERS-(k+1))] = scanned[k];
    end
  endgenerate
  assign data_o       = data[NUM_DECODERS];
  assign zrl_carry_o  = zrl[NUM_DECODERS];
endmodule


module DECODER (
  input   wire  [255:0]     data_i,
  input   wire  [  3:0]     zrl_i,

  output  reg   [  4:0]     size_o,
  output  reg   [  3:0]     zrl_o,
  output  reg   [ 15:0]     scanned_o
);

  always @(*) begin
    if (zrl_i == 0) begin
      scanned_o = 16'h0;
      zrl_o = 4'd0;
      casez (data_i[255:252])
        4'b0011 : begin   // zero
          size_o = 5'd4;
        end
        4'b010? : begin   // zrl
          size_o = 5'd7;
          zrl_o = data_i[252:249];
        end
        4'b011? : begin   // single one
          size_o = 5'd7;
          scanned_o[15-(data_i[252:249])] = 1'b1;
        end
        4'b0000 : begin   // consec two ones
          size_o = 5'd8;
          scanned_o[15-(data_i[251:248])] = 1'b1;
          scanned_o[15-(data_i[251:248]+1)] = 1'b1;
        end
        4'b0001 : begin   // front half zeros
          size_o = 5'd12;
          scanned_o[7:0] = data_i[251:244];
        end
        4'b0010 : begin
          size_o = 5'd12;
          scanned_o[15:8] = data_i[251:244];
        end
        default : begin
          size_o = 5'd17;
          scanned_o = data_i[254:239];
        end
      endcase
    end
    else begin
      size_o = 5'd0;
      zrl_o = zrl_i - 1;
      scanned_o = 16'h0;
    end
  end
endmodule

