module SCAN_MUX #(
  parameter   NUM_PATTERNS = 8,
  parameter   NUM_FIRST_TRANSFORMER = 2,
  parameter   NUM_LAST_TRANSFORMER = 6
)(
  input   wire                                                            isAllZero_i, 
  input   wire                                                            isAllWordSame_i,
  input   wire  [256*(NUM_LAST_TRANSFORMER-NUM_FIRST_TRANSFORMER+1)-1:0]  scanned_i,

  output  wire  [255:0]                                                   sel_scanned_o,
  output  wire  [$clog2(NUM_PATTERNS)-1:0]                                select_o
);
  // synopsys template
  localparam  NUM_TRANSFORMER = NUM_LAST_TRANSFORMER-NUM_FIRST_TRANSFORMER+1;
  localparam  LEN_ENCODE      = $clog2(NUM_PATTERNS);

  // rename input
  wire  [255:0]   scanned   [NUM_FIRST_TRANSFORMER:NUM_LAST_TRANSFORMER];
  genvar i;
  generate
    for (i = NUM_FIRST_TRANSFORMER; i <= NUM_LAST_TRANSFORMER; i = i + 1) begin : input_rename
      assign scanned[i]   = scanned_i[256*NUM_TRANSFORMER-256*(i-NUM_FIRST_TRANSFORMER)-1 : 256*NUM_TRANSFORMER-256*(i-NUM_FIRST_TRANSFORMER+1)];
    end
  endgenerate
  
  wire  [3:0]                     zeroRunLen          [NUM_FIRST_TRANSFORMER:NUM_LAST_TRANSFORMER];
  wire  [4*NUM_TRANSFORMER-1:0]   zeroRunLen_concat;
  genvar j;
  generate
    for (j = NUM_FIRST_TRANSFORMER; j <= NUM_LAST_TRANSFORMER; j = j + 1) begin : zero_run_length
      LEN_ZERORUN   ZRL (
        .scanned_i        (scanned[j]),

        .zeroRunLen_o     (zeroRunLen[j])
      );
    end
  endgenerate
  genvar k;
  generate
    for (k = NUM_FIRST_TRANSFORMER; k <= NUM_LAST_TRANSFORMER; k = k + 1) begin : zrl_concat
      assign zeroRunLen_concat[4*(NUM_TRANSFORMER-(k-NUM_FIRST_TRANSFORMER))-1:4*(NUM_TRANSFORMER-(k-NUM_FIRST_TRANSFORMER+1))] = zeroRunLen[k];
    end
  endgenerate

  wire  [LEN_ENCODE-1:0]   select;
  MAXZRLSELECTOR  #(
    .NUM_PATTERNS(NUM_PATTERNS),
    .NUM_FIRST_TRANSFORMER(NUM_FIRST_TRANSFORMER),
    .NUM_LAST_TRANSFORMER(NUM_LAST_TRANSFORMER)
  )   MAXZRLSEL   (
    .isAllZero_i          (isAllZero_i),
    .isAllWordSame_i      (isAllWordSame_i),
    .zeroRunLen_i         (zeroRunLen_concat),

    .select_o             (select)
  );

  // select max zrl scanned
  reg   [255:0]   sel_scanned;
  always @(*) begin
    if (select == 'd0)
      sel_scanned = 'd0;      // All-Zero
    else if (select == 'd1)
      sel_scanned = 'd0;      // All-WordSame
    else if (select == NUM_PATTERNS - 1)
      sel_scanned = 'd0;      // Uncompressible
    else
      sel_scanned = scanned[select];
  end

  // output assignment
  assign sel_scanned_o  = sel_scanned;
  assign select_o       = select;
endmodule

module LEN_ZERORUN  (
  input   wire  [255:0]   scanned_i,

  output  wire  [  3:0]   zeroRunLen_o
);
  wire  [15:0]  scanned   [0:15];
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : input_rename
      assign scanned[i]   = scanned_i[256-16*i-1:256-16*(i+1)];
    end
  endgenerate

  wire  [0:15]  isRowZeros;
  genvar j;
  generate
    for (j = 0; j < 16; j = j + 1) begin : row_zeros
      assign isRowZeros[j] = (scanned[j] == 'd0) ? 1 : 0;
    end
  endgenerate

  reg   [3:0]   zeroRunLen;
  always @(*) begin
    casez (isRowZeros)
      16'b0???_????_????_???? : zeroRunLen = 'd0;
      16'b10??_????_????_???? : zeroRunLen = 'd1;
      16'b110?_????_????_???? : zeroRunLen = 'd2;
      16'b1110_????_????_???? : zeroRunLen = 'd3;
      16'b1111_0???_????_???? : zeroRunLen = 'd4;
      16'b1111_10??_????_???? : zeroRunLen = 'd5;
      16'b1111_110?_????_???? : zeroRunLen = 'd6;
      16'b1111_1110_????_???? : zeroRunLen = 'd7;
      16'b1111_1111_0???_???? : zeroRunLen = 'd8;
      16'b1111_1111_10??_???? : zeroRunLen = 'd9;
      16'b1111_1111_110?_???? : zeroRunLen = 'd10;
      16'b1111_1111_1110_???? : zeroRunLen = 'd11;
      16'b1111_1111_1111_0??? : zeroRunLen = 'd12;
      16'b1111_1111_1111_10?? : zeroRunLen = 'd13;
      16'b1111_1111_1111_110? : zeroRunLen = 'd14;
      16'b1111_1111_1111_1110 : zeroRunLen = 'd15;
      default                 : zeroRunLen = 'd0;
    endcase
  end
  assign zeroRunLen_o = zeroRunLen;
endmodule
