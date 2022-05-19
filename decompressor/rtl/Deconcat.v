module DECONCAT #(
  parameter     NUM_PATTERNS  = 8
)(
  input   wire  [255:0]   data_i,
  input   wire            clk,
  input   wire            rst_n,
  input   wire            en_i,

  output  wire  [255:0]   scanned_o,
  output  wire            en_o
);
  // sysnopsys template

  // stage 1 ------------------------------------------------------------------------------------------------------------------
  // 6 decoders

  localparam NUM_FIRST_DECODERS = 6;
  
  wire  [255:0]                       data_first;
  wire  [  3:0]                       zrl_first;

  wire  [16*NUM_FIRST_DECODERS-1:0]   scanned_first;

  DECODER_GROUP   #(
    .NUM_DECODERS   (NUM_FIRST_DECODERS)
  ) DEC_STAGE1  (
    .data_i       (data_i),
    .zrl_carry_i  (4'd0),

    .scanned_o    (scanned_first),
    .data_o       (data_first),
    .zrl_carry_o  (zrl_first)
  );

  // --------------------------------------------------------------------------------------------------------------------------

  wire  [255:0]                     data_first_q;
  wire  [  3:0]                     zrl_first_q;
  wire  [16*NUM_FIRST_DECODERS-1:0] scanned_first_q;

  wire                              one_clk_delayed_en;

  D_FF #(
    .BITWIDTH     (256)
  )   DATA_FIRST_DFF  (
    .d_i          (data_first),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (data_first_q)
  );

  D_FF #(
    .BITWIDTH     (4)
  )   ZRL_FIRST_DFF   (
    .d_i          (zrl_first),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (zrl_first_q)
  );

  D_FF #(
    .BITWIDTH     (16*NUM_FIRST_DECODERS)
  )   SCAN_FIRST_DFF_1   (
    .d_i          (scanned_first),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (scanned_first_q)
  );

  D_FF #(
    .BITWIDTH     (1)
  )   EN1_DFF   (
    .d_i          (en_i),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (one_clk_delayed_en)
  );

  // stage 2 ------------------------------------------------------------------------------------------------------------------
  // 5 decoders

  localparam NUM_SECOND_DECODERS = 5;
  
  wire  [255:0]                       data_second;
  wire  [  3:0]                       zrl_second;

  wire  [16*NUM_SECOND_DECODERS-1:0]  scanned_second;

  DECODER_GROUP   #(
    .NUM_DECODERS   (NUM_SECOND_DECODERS)
  ) DEC_STAGE2  (
    .data_i       (data_first_q),
    .zrl_carry_i  (zrl_first_q),

    .scanned_o    (scanned_second),
    .data_o       (data_second),
    .zrl_carry_o  (zrl_second)
  );

  // --------------------------------------------------------------------------------------------------------------------------

  wire  [16*NUM_FIRST_DECODERS-1:0]   scanned_first_qq;

  D_FF #(
    .BITWIDTH     (16*NUM_FIRST_DECODERS)
  )   SCAN_FIRST_DFF_2   (
    .d_i          (scanned_first_q),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (scanned_first_qq)
  );

  wire  [255:0]                       data_second_q;
  wire  [  3:0]                       zrl_second_q;
  wire  [16*NUM_SECOND_DECODERS-1:0]  scanned_second_q;

  wire                                two_clk_delayed_en;

  D_FF #(
    .BITWIDTH     (256)
  )   DATA_SECOND_DFF  (
    .d_i          (data_second),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (data_second_q)
  );

  D_FF #(
    .BITWIDTH     (4)
  )   ZRL_SECOND_DFF   (
    .d_i          (zrl_second),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (zrl_second_q)
  );

  D_FF #(
    .BITWIDTH     (16*NUM_SECOND_DECODERS)
  )   SCAN_SECOND_DFF   (
    .d_i          (scanned_second),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (scanned_second_q)
  );

  D_FF #(
    .BITWIDTH     (1)
  )   EN2_DFF   (
    .d_i          (one_clk_delayed_en),
    .clk          (clk),
    .rst_n        (rst_n),

    .q_o          (two_clk_delayed_en)
  );

  // stage 3 ------------------------------------------------------------------------------------------------------------------
  // 5 decoders

  localparam NUM_THIRD_DECODERS = 5;
  
  wire  [255:0]                       data_third;
  wire  [  3:0]                       zrl_third;

  wire  [16*NUM_THIRD_DECODERS-1:0]   scanned_third;

  DECODER_GROUP   #(
    .NUM_DECODERS   (NUM_THIRD_DECODERS)
  ) DEC_STAGE3  (
    .data_i       (data_second_q),
    .zrl_carry_i  (zrl_second_q),

    .scanned_o    (scanned_third),
    .data_o       (),
    .zrl_carry_o  ()
  );

  // --------------------------------------------------------------------------------------------------------------------------

  D_FF #(
    .BITWIDTH       (256)
  )   SCANNED_DFF   (
    .d_i            ({scanned_first_qq, scanned_second_q, scanned_third}),
    .clk            (clk),
    .rst_n          (rst_n),

    .q_o            (scanned_o)
  );

  D_FF #(
    .BITWIDTH       (1)
  )   EN3_DFF   (
    .d_i            (two_clk_delayed_en),
    .clk            (clk),
    .rst_n          (rst_n),

    .q_o            (en_o)
  );

endmodule

