module SEL_DETRANSFORMER #(
  parameter   NUM_PATTERNS          = 8,
  parameter   NUM_FIRST_TRANSFORMER = 2,
  parameter   NUM_LAST_TRANSFORMER  = 6,
  parameter   NUM_TRANSFORMER       = NUM_LAST_TRANSFORMER-NUM_FIRST_TRANSFORMER+1,
  parameter   NUM_MODULES           = NUM_PATTERNS-1,

  parameter   LEN_ENCODE            = $clog2(NUM_PATTERNS)
)(
  input   wire  [LEN_ENCODE-1:0]              select_i,
  input   wire  [256*NUM_TRANSFORMER-1:0]     detransformed_i,
  input   wire  [255:0]                       data_i,

  output  wire  [255:0]                       data_o 
);
  // synopsys template

  wire  [255:0]   detransformed   [NUM_FIRST_TRANSFORMER:NUM_LAST_TRANSFORMER];
  genvar i;
  generate
    for (i = NUM_FIRST_TRANSFORMER; i < NUM_LAST_TRANSFORMER; i = i + 1) begin : input_rename
      assign detransformed[i]   = detransformed_i[(256*NUM_TRANSFORMER)-256*(i-NUM_FIRST_TRANSFORMER)-1:(256*NUM_TRANSFORMER)-256*(i-NUM_FIRST_TRANSFORMER+1)];
    end
  endgenerate

  reg   [255:0]   data;
  reg   [ 31:0]   word;
  always @(*) begin
    // all-zero
    if (select_i == 'd0) begin
      data = 'd0;
    end

    // all-wordsame
    else if (select_i == 'd1) begin
      word = data_i[255:224];
      data = { 32{word} };
    end

    // uncompressed
    else if (select_i == NUM_PATTERNS-1) begin
      data = data_i;
    end
    // transformer
    else begin
      data = detransformed[select_i];
    end
  end
  assign data_o = data;
endmodule
