module COMPRESSOR #(
  parameter   NUM_PATTERNS  = 8,
  parameter   NUM_FIRST_TRANSFORMER = 2,
  parameter   NUM_LAST_TRANSFORMER = 6,

  parameter   LEN_ENCODE    = $clog2(NUM_PATTERNS)
)(
  input   wire  [255:0]               data_i,
  input   wire                        en_i,
  input   wire                        clk,
  input   wire                        rst_n,
  
  output  wire  [255 + LEN_ENCODE:0]  data_o,
  output  wire  [8:0]                 size_o,
  output  wire                        en_o
);

  localparam  NUM_TRANSFORMER = NUM_LAST_TRANSFORMER-NUM_FIRST_TRANSFORMER+1;
  localparam  NUM_MODULES     = NUM_PATTERNS-1;


  wire  [255:0]           original;
  wire                    isAllZero;
  wire                    isAllWordSame;
  wire  [255:0]           scanned;
  wire  [LEN_ENCODE-1:0]  select_1;
  wire                    en_1;
  STAGE1  #(
    .NUM_PATTERNS           (NUM_PATTERNS),
    .NUM_FIRST_TRANSFORMER  (NUM_FIRST_TRANSFORMER),
    .NUM_LAST_TRANSFORMER   (NUM_LAST_TRANSFORMER),

    .LEN_ENCODE             (LEN_ENCODE)
  ) PIPELINE_STAGE1 (
    .data_i           (data_i),
    .en_i             (en_i),
    .clk              (clk),
    .rst_n            (rst_n),

    .data_o           (original),
    .isAllZero_o      (isAllZero),
    .isAllWordSame_o  (isAllWordSame),
    .scanned_o        (scanned),
    .select_o         (select_1),
    .en_o             (en_1)
  );

  wire  [271:0]                     sel_codeword;
  wire  [119:0]                     sel_startidx;
  wire  [8:0]                       sel_size;
  wire  [LEN_ENCODE-1:0]            select_2;
  wire                              en_2;
  STAGE2  #(
    .NUM_PATTERNS           (NUM_PATTERNS),

    .LEN_ENCODE             (LEN_ENCODE)
  ) PIPELINE_STAGE2 (
    .data_i           (original),
    .isAllZero_i      (isAllZero),
    .isAllWordSame_i  (isAllWordSame),
    .scanned_i        (scanned),
    .select_i         (select_1),
    .en_i             (en_1),
    .clk              (clk),
    .rst_n            (rst_n),

    .sel_codeword_o   (sel_codeword),
    .sel_startidx_o   (sel_startidx),
    .sel_size_o       (sel_size),
    .select_o         (select_2),
    .en_o             (en_2)
  );

  STAGE3  #(
    .NUM_PATTERNS           (NUM_PATTERNS),

    .LEN_ENCODE             (LEN_ENCODE)
  ) PIPELINE_STAGE3 (
    .sel_codeword_i   (sel_codeword),
    .sel_startidx_i   (sel_startidx),
    .sel_size_i       (sel_size),
    .select_i         (select_2),
    .en_i             (en_2),
    .clk              (clk),
    .rst_n            (rst_n),

    .data_o           (data_o),
    .size_o           (size_o),
    .en_o             (en_o)
  );

endmodule

module STAGE1 #(
  parameter   NUM_PATTERNS  = 8,
  parameter   NUM_FIRST_TRANSFORMER = 2,
  parameter   NUM_LAST_TRANSFORMER = 6,

  parameter   LEN_ENCODE    = 3
) (
  input   wire  [255:0]                     data_i,
  input   wire                              en_i,
  input   wire                              clk,
  input   wire                              rst_n ,

  output  wire  [255:0]                     data_o,
  output  wire                              isAllZero_o,
  output  wire                              isAllWordSame_o,
  output  wire  [255:0]                     scanned_o,
  output  wire  [LEN_ENCODE-1:0]            select_o,
  output  wire                              en_o
);
  // synopsys template
  localparam   NUM_TRANSFORMER  = 5;
  localparam   NUM_MODULES      = 7;

  wire            isAllZero;
  wire            isAllWordSame;
  wire  [255:0]   scanned         [NUM_FIRST_TRANSFORMER:NUM_LAST_TRANSFORMER];

  // pattern modules
  ALLZERO         PATTERN0    (
    .data_in              (data_i),

    .isAllZero_out        (isAllZero)
  );
  ALLWORDSAME     PATTERN1    (
    .data_i               (data_i),

    .isAllWordSame_o      (isAllWordSame)
  );
  TRANSFORMER #(
    .ROOT_IDX               (8'd8),
    .BASE_IDX               ({
               8'd28, 8'd00, 8'd16, 8'd04, 8'd08, 8'd04, 8'd16, 8'd08,
               8'd08, 8'd08, 8'd16, 8'd12, 8'd16, 8'd12, 8'd16, 8'd16,
               8'd08, 8'd16, 8'd04, 8'd20, 8'd08, 8'd20, 8'd16, 8'd24,
               8'd16, 8'd24, 8'd16, 8'd00, 8'd08, 8'd28, 8'd16, 8'd04
    }),
    .SHIFT_VAL              ({
                8'd0,  8'd0,  8'd3,  8'd0,  8'd0,  8'd0,  8'd3,  8'd0,
                8'd0,  8'd0,  8'd3,  8'd0,  8'd0,  8'd0,  8'd3,  8'd0,
                8'd0,  8'd0,  8'd3,  8'd0,  8'd0,  8'd0,  8'd3,  8'd0,
                8'd0,  8'd0,  8'd3,  8'd0,  8'd0,  8'd0,  8'd3,  8'd0
    }),
    .SCAN_ROW               ({
               8'd0, 8'd1, 8'd4, 8'd2, 8'd2, 8'd1, 8'd2, 8'd1,
               8'd2, 8'd1, 8'd2, 8'd2, 8'd1, 8'd2, 8'd2, 8'd1,
               8'd1, 8'd2, 8'd2, 8'd1, 8'd2, 8'd1, 8'd1, 8'd2,
               8'd1, 8'd2, 8'd1, 8'd2, 8'd1, 8'd1, 8'd2, 8'd1,
               8'd1, 8'd2, 8'd2, 8'd1, 8'd2, 8'd1, 8'd1, 8'd2,
               8'd2, 8'd1, 8'd1, 8'd2, 8'd2, 8'd1, 8'd1, 8'd2,
               8'd2, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5,
               8'd3, 8'd4, 8'd3, 8'd4, 8'd3, 8'd4, 8'd3, 8'd4,
               8'd3, 8'd4, 8'd6, 8'd3, 8'd4, 8'd3, 8'd4, 8'd6,
               8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd1, 8'd3, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd5, 8'd5,
               8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd0, 8'd7, 8'd7,
               8'd3, 8'd5, 8'd0, 8'd3, 8'd0, 8'd0, 8'd7, 8'd3,
               8'd3, 8'd7, 8'd7, 8'd3, 8'd3, 8'd0, 8'd7, 8'd7,
               8'd0, 8'd3, 8'd0, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd4, 8'd4,
               8'd4, 8'd4, 8'd4, 8'd4, 8'd7, 8'd4, 8'd7, 8'd7,
               8'd4, 8'd4, 8'd5, 8'd0, 8'd7, 8'd4, 8'd0, 8'd7,
               8'd4, 8'd4, 8'd0, 8'd7, 8'd7, 8'd7, 8'd4, 8'd0,
               8'd5, 8'd7, 8'd7, 8'd4, 8'd0, 8'd5, 8'd7, 8'd5,
               8'd5, 8'd5, 8'd5, 8'd1, 8'd5, 8'd6, 8'd4, 8'd4,
               8'd6, 8'd5, 8'd1, 8'd4, 8'd4, 8'd4, 8'd2, 8'd2,
               8'd6, 8'd4, 8'd6, 8'd2, 8'd6, 8'd6, 8'd2, 8'd2,
               8'd2, 8'd1, 8'd1, 8'd2, 8'd2, 8'd1, 8'd4, 8'd1,
               8'd1, 8'd6, 8'd1, 8'd6, 8'd4, 8'd0, 8'd7, 8'd7,
               8'd6, 8'd7, 8'd6, 8'd7, 8'd7, 8'd7, 8'd6, 8'd6,
               8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd5, 8'd5, 8'd5,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd5, 8'd0, 8'd0,
               8'd5, 8'd5, 8'd5, 8'd7, 8'd0, 8'd5, 8'd7, 8'd7,
               8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd0, 8'd0, 8'd0,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd3,
               8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6
    }),
    .SCAN_COL               ({
               8'd00, 8'd27, 8'd00, 8'd31, 8'd27, 8'd31, 8'd00, 8'd08,
               8'd08, 8'd28, 8'd01, 8'd02, 8'd29, 8'd29, 8'd04, 8'd05,
               8'd09, 8'd09, 8'd21, 8'd21, 8'd19, 8'd20, 8'd19, 8'd20,
               8'd16, 8'd15, 8'd15, 8'd17, 8'd17, 8'd12, 8'd11, 8'd11,
               8'd13, 8'd13, 8'd23, 8'd25, 8'd25, 8'd23, 8'd24, 8'd24,
               8'd06, 8'd06, 8'd04, 8'd05, 8'd28, 8'd01, 8'd02, 8'd16,
               8'd12, 8'd12, 8'd16, 8'd28, 8'd01, 8'd20, 8'd05, 8'd24,
               8'd01, 8'd01, 8'd28, 8'd28, 8'd16, 8'd16, 8'd12, 8'd12,
               8'd24, 8'd24, 8'd24, 8'd05, 8'd05, 8'd20, 8'd20, 8'd20,
               8'd05, 8'd16, 8'd28, 8'd01, 8'd12, 8'd00, 8'd03, 8'd07,
               8'd30, 8'd22, 8'd10, 8'd14, 8'd26, 8'd18, 8'd17, 8'd06,
               8'd09, 8'd02, 8'd21, 8'd29, 8'd13, 8'd16, 8'd24, 8'd12,
               8'd13, 8'd25, 8'd05, 8'd09, 8'd20, 8'd28, 8'd01, 8'd02,
               8'd21, 8'd20, 8'd05, 8'd06, 8'd29, 8'd01, 8'd28, 8'd16,
               8'd24, 8'd17, 8'd12, 8'd25, 8'd19, 8'd11, 8'd23, 8'd15,
               8'd31, 8'd27, 8'd04, 8'd08, 8'd08, 8'd07, 8'd26, 8'd30,
               8'd22, 8'd14, 8'd10, 8'd03, 8'd15, 8'd18, 8'd04, 8'd31,
               8'd13, 8'd09, 8'd00, 8'd09, 8'd09, 8'd25, 8'd25, 8'd25,
               8'd21, 8'd02, 8'd02, 8'd02, 8'd17, 8'd06, 8'd06, 8'd06,
               8'd23, 8'd13, 8'd29, 8'd29, 8'd29, 8'd04, 8'd21, 8'd15,
               8'd27, 8'd19, 8'd08, 8'd07, 8'd31, 8'd10, 8'd23, 8'd04,
               8'd14, 8'd11, 8'd22, 8'd15, 8'd31, 8'd11, 8'd30, 8'd26,
               8'd07, 8'd19, 8'd26, 8'd03, 8'd30, 8'd18, 8'd10, 8'd22,
               8'd07, 8'd03, 8'd26, 8'd18, 8'd14, 8'd30, 8'd27, 8'd14,
               8'd18, 8'd22, 8'd10, 8'd03, 8'd17, 8'd17, 8'd27, 8'd19,
               8'd21, 8'd23, 8'd00, 8'd08, 8'd00, 8'd11, 8'd13, 8'd17,
               8'd29, 8'd02, 8'd06, 8'd09, 8'd25, 8'd07, 8'd30, 8'd26,
               8'd22, 8'd14, 8'd10, 8'd03, 8'd30, 8'd14, 8'd26, 8'd07,
               8'd22, 8'd03, 8'd10, 8'd14, 8'd18, 8'd18, 8'd07, 8'd03,
               8'd22, 8'd26, 8'd10, 8'd30, 8'd18, 8'd13, 8'd21, 8'd19,
               8'd23, 8'd15, 8'd11, 8'd08, 8'd04, 8'd31, 8'd27, 8'd00,
               8'd23, 8'd27, 8'd31, 8'd04, 8'd19, 8'd15, 8'd11, 8'd08
    })
  )               PATTERN2_T  (
    .data_i               (data_i),

    .data_o               (scanned[2])
  );
  TRANSFORMER #(
    .ROOT_IDX               (8'd16),
    .BASE_IDX               ({
               8'd16, 8'd17, 8'd04, 8'd15, 8'd06, 8'd03, 8'd08, 8'd03,
               8'd10, 8'd03, 8'd12, 8'd03, 8'd14, 8'd03, 8'd16, 8'd14,
               8'd16, 8'd03, 8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd19,
               8'd22, 8'd19, 8'd24, 8'd19, 8'd26, 8'd19, 8'd28, 8'd19
    }),
    .SHIFT_VAL              ({
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0
    }),
    .SCAN_ROW               ({
               8'd7, 8'd5, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd2, 8'd2, 8'd2,
               8'd2, 8'd4, 8'd4, 8'd4, 8'd4, 8'd5, 8'd5, 8'd5,
               8'd5, 8'd5, 8'd5, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
               8'd4, 8'd4, 8'd4, 8'd2, 8'd2, 8'd2, 8'd0, 8'd1,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd1, 8'd0,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd1, 8'd1, 8'd2,
               8'd1, 8'd2, 8'd2, 8'd2, 8'd2, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd5,
               8'd3, 8'd7, 8'd7, 8'd7, 8'd6, 8'd6, 8'd7, 8'd5,
               8'd6, 8'd6, 8'd6, 8'd7, 8'd6, 8'd5, 8'd6, 8'd6,
               8'd5, 8'd6, 8'd7, 8'd6, 8'd5, 8'd7, 8'd7, 8'd7,
               8'd7, 8'd7, 8'd6, 8'd6, 8'd2, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd3, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2,
               8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd4, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd5, 8'd3, 8'd2, 8'd4, 8'd4,
               8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
               8'd4, 8'd4, 8'd6, 8'd3, 8'd2, 8'd5, 8'd5, 8'd5,
               8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5,
               8'd5, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6,
               8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd0, 8'd7, 8'd5,
               8'd4, 8'd6, 8'd2, 8'd1, 8'd3, 8'd4, 8'd7, 8'd5,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd7, 8'd7, 8'd7, 8'd7,
               8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7,
               8'd1, 8'd5, 8'd4, 8'd2, 8'd3, 8'd3, 8'd1, 8'd2,
               8'd4, 8'd5, 8'd4, 8'd6, 8'd1, 8'd0, 8'd0, 8'd7,
               8'd4, 8'd5, 8'd6, 8'd7, 8'd3, 8'd2, 8'd0, 8'd7,
               8'd6, 8'd7, 8'd6, 8'd0, 8'd5, 8'd6, 8'd0, 8'd7,
               8'd0, 8'd1, 8'd6, 8'd7, 8'd4, 8'd5, 8'd3, 8'd2
    }),
    .SCAN_COL               ({
               8'd31, 8'd23, 8'd29, 8'd27, 8'd25, 8'd23, 8'd21, 8'd14,
               8'd12, 8'd10, 8'd08, 8'd06, 8'd04, 8'd31, 8'd29, 8'd27,
               8'd25, 8'd04, 8'd06, 8'd08, 8'd31, 8'd14, 8'd12, 8'd10,
               8'd08, 8'd06, 8'd04, 8'd29, 8'd10, 8'd27, 8'd25, 8'd23,
               8'd21, 8'd14, 8'd12, 8'd23, 8'd21, 8'd14, 8'd21, 8'd02,
               8'd31, 8'd29, 8'd27, 8'd25, 8'd23, 8'd17, 8'd06, 8'd14,
               8'd12, 8'd10, 8'd08, 8'd06, 8'd04, 8'd04, 8'd08, 8'd12,
               8'd27, 8'd10, 8'd08, 8'd06, 8'd04, 8'd31, 8'd29, 8'd25,
               8'd10, 8'd23, 8'd21, 8'd19, 8'd17, 8'd14, 8'd12, 8'd21,
               8'd31, 8'd21, 8'd06, 8'd14, 8'd27, 8'd04, 8'd04, 8'd31,
               8'd08, 8'd06, 8'd12, 8'd12, 8'd14, 8'd29, 8'd31, 8'd29,
               8'd27, 8'd21, 8'd10, 8'd23, 8'd25, 8'd23, 8'd25, 8'd27,
               8'd29, 8'd08, 8'd25, 8'd10, 8'd02, 8'd11, 8'd20, 8'd24,
               8'd09, 8'd13, 8'd03, 8'd22, 8'd26, 8'd28, 8'd07, 8'd05,
               8'd30, 8'd02, 8'd28, 8'd11, 8'd22, 8'd20, 8'd03, 8'd05,
               8'd07, 8'd09, 8'd24, 8'd26, 8'd13, 8'd30, 8'd02, 8'd11,
               8'd09, 8'd07, 8'd13, 8'd20, 8'd22, 8'd24, 8'd26, 8'd28,
               8'd30, 8'd03, 8'd05, 8'd02, 8'd19, 8'd19, 8'd26, 8'd28,
               8'd30, 8'd24, 8'd22, 8'd20, 8'd11, 8'd09, 8'd07, 8'd05,
               8'd03, 8'd13, 8'd02, 8'd17, 8'd17, 8'd24, 8'd22, 8'd20,
               8'd26, 8'd28, 8'd30, 8'd11, 8'd09, 8'd07, 8'd05, 8'd03,
               8'd13, 8'd13, 8'd11, 8'd09, 8'd07, 8'd05, 8'd03, 8'd20,
               8'd22, 8'd24, 8'd26, 8'd28, 8'd30, 8'd02, 8'd02, 8'd19,
               8'd19, 8'd19, 8'd18, 8'd18, 8'd18, 8'd18, 8'd19, 8'd18,
               8'd13, 8'd11, 8'd09, 8'd07, 8'd05, 8'd03, 8'd22, 8'd20,
               8'd24, 8'd26, 8'd28, 8'd30, 8'd20, 8'd22, 8'd24, 8'd26,
               8'd28, 8'd30, 8'd11, 8'd09, 8'd07, 8'd05, 8'd03, 8'd13,
               8'd01, 8'd17, 8'd17, 8'd01, 8'd01, 8'd15, 8'd15, 8'd15,
               8'd15, 8'd15, 8'd01, 8'd18, 8'd16, 8'd19, 8'd18, 8'd18,
               8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd15,
               8'd15, 8'd17, 8'd17, 8'd15, 8'd01, 8'd01, 8'd01, 8'd01,
               8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00
    })
  )               PATTERN3_T  (
    .data_i               (data_i),

    .data_o               (scanned[3])
  );
  TRANSFORMER #(
    .ROOT_IDX               (8'd19),
    .BASE_IDX               ({
               8'd04, 8'd09, 8'd10, 8'd07, 8'd08, 8'd13, 8'd14, 8'd11,
               8'd16, 8'd17, 8'd14, 8'd15, 8'd16, 8'd21, 8'd15, 8'd19,
               8'd19, 8'd19, 8'd10, 8'd19, 8'd16, 8'd25, 8'd14, 8'd19,
               8'd20, 8'd17, 8'd18, 8'd23, 8'd24, 8'd21, 8'd22, 8'd27
    }),
    .SHIFT_VAL              ({
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
                8'd7,  8'd7,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0
    }),
    .SCAN_ROW               ({
               8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd3, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd4,
               8'd4, 8'd4, 8'd4, 8'd4, 8'd1, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd1, 8'd1, 8'd0, 8'd3, 8'd1, 8'd2, 8'd5,
               8'd6, 8'd3, 8'd1, 8'd2, 8'd5, 8'd6, 8'd3, 8'd1,
               8'd2, 8'd5, 8'd6, 8'd3, 8'd1, 8'd2, 8'd5, 8'd6,
               8'd3, 8'd1, 8'd2, 8'd5, 8'd6, 8'd3, 8'd1, 8'd2,
               8'd5, 8'd6, 8'd2, 8'd5, 8'd6, 8'd2, 8'd1, 8'd1,
               8'd2, 8'd3, 8'd7, 8'd0, 8'd7, 8'd0, 8'd0, 8'd7,
               8'd0, 8'd7, 8'd0, 8'd0, 8'd7, 8'd0, 8'd7, 8'd7,
               8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd5, 8'd5,
               8'd5, 8'd5, 8'd5, 8'd5, 8'd4, 8'd5, 8'd0, 8'd1,
               8'd5, 8'd2, 8'd3, 8'd4, 8'd6, 8'd7, 8'd6, 8'd6,
               8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd3, 8'd0, 8'd0,
               8'd0, 8'd0, 8'd7, 8'd7, 8'd7, 8'd7, 8'd0, 8'd0,
               8'd0, 8'd7, 8'd7, 8'd7, 8'd1, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd1, 8'd1, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2,
               8'd2, 8'd2, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3,
               8'd3, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
               8'd4, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5,
               8'd5, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6,
               8'd7, 8'd0, 8'd7, 8'd7, 8'd0, 8'd0, 8'd7, 8'd0,
               8'd0, 8'd7, 8'd0, 8'd7, 8'd0, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd1, 8'd1, 8'd1, 8'd7, 8'd2, 8'd2, 8'd2,
               8'd2, 8'd2, 8'd2, 8'd2, 8'd3, 8'd3, 8'd3, 8'd3,
               8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
               8'd4, 8'd4, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5,
               8'd0, 8'd6, 8'd7, 8'd2, 8'd0, 8'd1, 8'd3, 8'd4,
               8'd0, 8'd0, 8'd5, 8'd6, 8'd6, 8'd6, 8'd6, 8'd6,
               8'd7, 8'd7, 8'd6, 8'd6, 8'd7, 8'd7, 8'd5, 8'd2,
               8'd3, 8'd0, 8'd7, 8'd4, 8'd6, 8'd1, 8'd5, 8'd7,
               8'd7, 8'd7, 8'd7, 8'd0, 8'd0, 8'd0, 8'd0, 8'd6
    }),
    .SCAN_COL               ({
               8'd22, 8'd19, 8'd30, 8'd07, 8'd03, 8'd26, 8'd23, 8'd12,
               8'd27, 8'd04, 8'd08, 8'd31, 8'd16, 8'd12, 8'd16, 8'd27,
               8'd31, 8'd23, 8'd08, 8'd04, 8'd23, 8'd16, 8'd12, 8'd08,
               8'd04, 8'd31, 8'd27, 8'd15, 8'd07, 8'd07, 8'd12, 8'd12,
               8'd12, 8'd19, 8'd19, 8'd16, 8'd16, 8'd16, 8'd22, 8'd22,
               8'd23, 8'd23, 8'd23, 8'd26, 8'd26, 8'd27, 8'd27, 8'd27,
               8'd30, 8'd30, 8'd31, 8'd31, 8'd31, 8'd03, 8'd03, 8'd04,
               8'd04, 8'd04, 8'd08, 8'd08, 8'd08, 8'd15, 8'd15, 8'd11,
               8'd11, 8'd11, 8'd12, 8'd08, 8'd04, 8'd23, 8'd16, 8'd16,
               8'd12, 8'd08, 8'd04, 8'd31, 8'd27, 8'd27, 8'd23, 8'd31,
               8'd30, 8'd22, 8'd07, 8'd19, 8'd03, 8'd26, 8'd26, 8'd19,
               8'd03, 8'd07, 8'd22, 8'd30, 8'd11, 8'd11, 8'd00, 8'd00,
               8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00, 8'd19, 8'd03,
               8'd07, 8'd22, 8'd30, 8'd26, 8'd11, 8'd15, 8'd11, 8'd07,
               8'd22, 8'd26, 8'd19, 8'd03, 8'd07, 8'd11, 8'd19, 8'd03,
               8'd30, 8'd22, 8'd26, 8'd30, 8'd29, 8'd21, 8'd25, 8'd10,
               8'd02, 8'd06, 8'd14, 8'd14, 8'd21, 8'd29, 8'd25, 8'd10,
               8'd02, 8'd06, 8'd06, 8'd14, 8'd21, 8'd29, 8'd25, 8'd10,
               8'd02, 8'd02, 8'd10, 8'd25, 8'd21, 8'd29, 8'd14, 8'd06,
               8'd15, 8'd15, 8'd10, 8'd25, 8'd21, 8'd29, 8'd14, 8'd06,
               8'd02, 8'd02, 8'd10, 8'd25, 8'd14, 8'd29, 8'd21, 8'd06,
               8'd06, 8'd06, 8'd14, 8'd29, 8'd29, 8'd14, 8'd21, 8'd25,
               8'd10, 8'd10, 8'd02, 8'd02, 8'd21, 8'd24, 8'd28, 8'd13,
               8'd09, 8'd05, 8'd01, 8'd20, 8'd25, 8'd13, 8'd09, 8'd05,
               8'd01, 8'd24, 8'd28, 8'd20, 8'd20, 8'd13, 8'd09, 8'd05,
               8'd01, 8'd24, 8'd28, 8'd28, 8'd24, 8'd13, 8'd09, 8'd05,
               8'd01, 8'd20, 8'd13, 8'd05, 8'd01, 8'd24, 8'd28, 8'd20,
               8'd24, 8'd15, 8'd15, 8'd18, 8'd18, 8'd18, 8'd18, 8'd18,
               8'd28, 8'd20, 8'd09, 8'd13, 8'd05, 8'd24, 8'd28, 8'd09,
               8'd13, 8'd05, 8'd01, 8'd20, 8'd17, 8'd01, 8'd18, 8'd17,
               8'd17, 8'd17, 8'd18, 8'd17, 8'd18, 8'd17, 8'd17, 8'd24,
               8'd28, 8'd20, 8'd09, 8'd05, 8'd13, 8'd09, 8'd01, 8'd17
    })
  )               PATTERN4_T  (
    .data_i               (data_i),

    .data_o               (scanned[4])
  );
  TRANSFORMER #(
    .ROOT_IDX               (8'd15),
    .BASE_IDX               ({
               8'd04, 8'd07, 8'd03, 8'd11, 8'd20, 8'd07, 8'd14, 8'd15,
               8'd24, 8'd11, 8'd02, 8'd19, 8'd15, 8'd27, 8'd18, 8'd15,
               8'd24, 8'd27, 8'd19, 8'd07, 8'd28, 8'd23, 8'd18, 8'd15,
               8'd27, 8'd27, 8'd27, 8'd19, 8'd31, 8'd31, 8'd22, 8'd23
    }),
    .SHIFT_VAL              ({
                8'd0,  8'd1,  8'd0,  8'd0,  8'd0,  8'd1,  8'd0,  8'd0,
                8'd0,  8'd1,  8'd0,  8'd0,  8'd2,  8'd1,  8'd0,  8'd0,
                8'd0,  8'd1,  8'd0,  8'd0,  8'd0,  8'd1,  8'd0,  8'd0,
                8'd1,  8'd1,  8'd0,  8'd0,  8'd0,  8'd1,  8'd0,  8'd0
    }),
    .SCAN_ROW               ({
               8'd4, 8'd4, 8'd4, 8'd4, 8'd3, 8'd3, 8'd3, 8'd3,
               8'd4, 8'd3, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd4,
               8'd4, 8'd3, 8'd3, 8'd2, 8'd2, 8'd5, 8'd5, 8'd5,
               8'd5, 8'd5, 8'd5, 8'd5, 8'd6, 8'd6, 8'd6, 8'd6,
               8'd6, 8'd6, 8'd6, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1,
               8'd1, 8'd0, 8'd1, 8'd0, 8'd7, 8'd7, 8'd1, 8'd7,
               8'd0, 8'd0, 8'd7, 8'd0, 8'd0, 8'd7, 8'd7, 8'd7,
               8'd0, 8'd0, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd2,
               8'd2, 8'd2, 8'd2, 8'd3, 8'd3, 8'd2, 8'd3, 8'd3,
               8'd3, 8'd4, 8'd4, 8'd7, 8'd7, 8'd6, 8'd5, 8'd4,
               8'd7, 8'd6, 8'd7, 8'd5, 8'd6, 8'd3, 8'd3, 8'd2,
               8'd1, 8'd1, 8'd2, 8'd4, 8'd4, 8'd5, 8'd3, 8'd2,
               8'd1, 8'd0, 8'd7, 8'd7, 8'd6, 8'd6, 8'd5, 8'd5,
               8'd4, 8'd3, 8'd3, 8'd4, 8'd2, 8'd1, 8'd1, 8'd2,
               8'd0, 8'd2, 8'd2, 8'd2, 8'd4, 8'd4, 8'd5, 8'd5,
               8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd4, 8'd4, 8'd6,
               8'd5, 8'd5, 8'd6, 8'd7, 8'd7, 8'd2, 8'd4, 8'd3,
               8'd3, 8'd0, 8'd6, 8'd6, 8'd6, 8'd2, 8'd2, 8'd2,
               8'd4, 8'd5, 8'd6, 8'd7, 8'd2, 8'd2, 8'd4, 8'd0,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd6, 8'd6, 8'd7, 8'd7,
               8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd2,
               8'd1, 8'd3, 8'd3, 8'd3, 8'd3, 8'd1, 8'd1, 8'd1,
               8'd0, 8'd0, 8'd0, 8'd3, 8'd5, 8'd5, 8'd7, 8'd6,
               8'd6, 8'd1, 8'd1, 8'd1, 8'd1, 8'd6, 8'd6, 8'd6,
               8'd6, 8'd6, 8'd7, 8'd1, 8'd1, 8'd1, 8'd5, 8'd7,
               8'd6, 8'd6, 8'd1, 8'd0, 8'd2, 8'd5, 8'd3, 8'd4,
               8'd4, 8'd4, 8'd4, 8'd4, 8'd5, 8'd5, 8'd5, 8'd3,
               8'd3, 8'd5, 8'd5, 8'd4, 8'd6, 8'd5, 8'd2, 8'd3,
               8'd3, 8'd5, 8'd3, 8'd4, 8'd4, 8'd4, 8'd3, 8'd7,
               8'd0, 8'd1, 8'd5, 8'd5, 8'd5, 8'd4, 8'd7, 8'd6,
               8'd3, 8'd4, 8'd5, 8'd2, 8'd7, 8'd7, 8'd7, 8'd7,
               8'd7, 8'd7, 8'd7, 8'd7, 8'd0, 8'd1, 8'd7, 8'd6
    }),
    .SCAN_COL               ({
               8'd27, 8'd31, 8'd08, 8'd23, 8'd23, 8'd08, 8'd31, 8'd27,
               8'd19, 8'd19, 8'd31, 8'd23, 8'd08, 8'd19, 8'd04, 8'd04,
               8'd12, 8'd12, 8'd04, 8'd27, 8'd12, 8'd12, 8'd04, 8'd08,
               8'd23, 8'd31, 8'd27, 8'd19, 8'd08, 8'd23, 8'd31, 8'd27,
               8'd12, 8'd04, 8'd19, 8'd08, 8'd12, 8'd23, 8'd31, 8'd27,
               8'd04, 8'd00, 8'd19, 8'd19, 8'd27, 8'd12, 8'd00, 8'd31,
               8'd23, 8'd27, 8'd19, 8'd08, 8'd04, 8'd23, 8'd08, 8'd04,
               8'd12, 8'd31, 8'd15, 8'd22, 8'd30, 8'd07, 8'd11, 8'd22,
               8'd15, 8'd07, 8'd30, 8'd22, 8'd15, 8'd11, 8'd11, 8'd07,
               8'd30, 8'd22, 8'd15, 8'd13, 8'd05, 8'd05, 8'd05, 8'd05,
               8'd20, 8'd20, 8'd01, 8'd01, 8'd01, 8'd01, 8'd05, 8'd05,
               8'd05, 8'd01, 8'd01, 8'd01, 8'd20, 8'd20, 8'd20, 8'd20,
               8'd20, 8'd20, 8'd16, 8'd09, 8'd09, 8'd16, 8'd16, 8'd09,
               8'd09, 8'd09, 8'd16, 8'd16, 8'd16, 8'd16, 8'd09, 8'd09,
               8'd05, 8'd21, 8'd06, 8'd29, 8'd30, 8'd07, 8'd15, 8'd22,
               8'd22, 8'd30, 8'd11, 8'd02, 8'd17, 8'd18, 8'd03, 8'd30,
               8'd30, 8'd07, 8'd07, 8'd07, 8'd30, 8'd14, 8'd28, 8'd28,
               8'd24, 8'd01, 8'd06, 8'd21, 8'd29, 8'd18, 8'd26, 8'd03,
               8'd11, 8'd11, 8'd11, 8'd11, 8'd10, 8'd25, 8'd26, 8'd25,
               8'd10, 8'd29, 8'd21, 8'd06, 8'd22, 8'd15, 8'd15, 8'd22,
               8'd15, 8'd07, 8'd02, 8'd17, 8'd16, 8'd09, 8'd24, 8'd13,
               8'd13, 8'd14, 8'd21, 8'd06, 8'd29, 8'd18, 8'd26, 8'd03,
               8'd26, 8'd18, 8'd03, 8'd02, 8'd03, 8'd18, 8'd18, 8'd18,
               8'd03, 8'd29, 8'd21, 8'd06, 8'd02, 8'd02, 8'd14, 8'd25,
               8'd10, 8'd17, 8'd26, 8'd25, 8'd17, 8'd14, 8'd13, 8'd28,
               8'd24, 8'd26, 8'd10, 8'd13, 8'd28, 8'd28, 8'd13, 8'd02,
               8'd14, 8'd29, 8'd21, 8'd06, 8'd06, 8'd21, 8'd29, 8'd18,
               8'd03, 8'd02, 8'd14, 8'd13, 8'd28, 8'd24, 8'd24, 8'd25,
               8'd10, 8'd26, 8'd26, 8'd25, 8'd10, 8'd17, 8'd17, 8'd03,
               8'd14, 8'd24, 8'd25, 8'd10, 8'd17, 8'd24, 8'd00, 8'd00,
               8'd00, 8'd00, 8'd00, 8'd00, 8'd06, 8'd02, 8'd14, 8'd17,
               8'd21, 8'd29, 8'd25, 8'd10, 8'd28, 8'd28, 8'd24, 8'd13
    })
  )               PATTERN5_T  (
    .data_i               (data_i),

    .data_o               (scanned[5])
  );
  TRANSFORMER #(
    .ROOT_IDX               (8'd8),
    .BASE_IDX               ({
               8'd08, 8'd17, 8'd10, 8'd02, 8'd07, 8'd07, 8'd07, 8'd15,
               8'd08, 8'd08, 8'd18, 8'd19, 8'd15, 8'd05, 8'd06, 8'd23,
               8'd08, 8'd25, 8'd26, 8'd03, 8'd23, 8'd13, 8'd14, 8'd31,
               8'd16, 8'd09, 8'd25, 8'd11, 8'd12, 8'd21, 8'd22, 8'd24
    }),
    .SHIFT_VAL              ({
                8'd0,  8'd0,  8'd0,  8'd0,  8'd1,  8'd1,  8'd1,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd1,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd1,  8'd0,  8'd0,  8'd0,
                8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd0,  8'd6
    }),
    .SCAN_ROW               ({
               8'd3, 8'd4, 8'd3, 8'd4, 8'd5, 8'd3, 8'd5, 8'd2,
               8'd2, 8'd4, 8'd6, 8'd6, 8'd5, 8'd6, 8'd7, 8'd7,
               8'd7, 8'd2, 8'd1, 8'd1, 8'd1, 8'd0, 8'd1, 8'd0,
               8'd1, 8'd0, 8'd1, 8'd3, 8'd2, 8'd2, 8'd2, 8'd3,
               8'd3, 8'd3, 8'd4, 8'd4, 8'd4, 8'd0, 8'd0, 8'd5,
               8'd5, 8'd0, 8'd5, 8'd1, 8'd1, 8'd1, 8'd3, 8'd3,
               8'd3, 8'd7, 8'd6, 8'd6, 8'd6, 8'd5, 8'd5, 8'd7,
               8'd2, 8'd2, 8'd2, 8'd4, 8'd4, 8'd4, 8'd7, 8'd5,
               8'd5, 8'd5, 8'd4, 8'd5, 8'd4, 8'd6, 8'd6, 8'd6,
               8'd0, 8'd0, 8'd7, 8'd7, 8'd7, 8'd0, 8'd4, 8'd3,
               8'd3, 8'd3, 8'd2, 8'd2, 8'd2, 8'd1, 8'd1, 8'd0,
               8'd5, 8'd6, 8'd4, 8'd0, 8'd1, 8'd0, 8'd4, 8'd2,
               8'd2, 8'd2, 8'd4, 8'd4, 8'd4, 8'd6, 8'd6, 8'd6,
               8'd5, 8'd5, 8'd6, 8'd7, 8'd7, 8'd7, 8'd1, 8'd1,
               8'd1, 8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd5, 8'd5,
               8'd5, 8'd5, 8'd7, 8'd7, 8'd7, 8'd6, 8'd6, 8'd0,
               8'd0, 8'd0, 8'd3, 8'd3, 8'd6, 8'd6, 8'd6, 8'd0,
               8'd0, 8'd0, 8'd1, 8'd1, 8'd1, 8'd3, 8'd2, 8'd2,
               8'd7, 8'd7, 8'd7, 8'd1, 8'd5, 8'd4, 8'd0, 8'd3,
               8'd6, 8'd2, 8'd6, 8'd5, 8'd4, 8'd2, 8'd3, 8'd1,
               8'd0, 8'd7, 8'd5, 8'd6, 8'd4, 8'd0, 8'd3, 8'd4,
               8'd2, 8'd1, 8'd1, 8'd0, 8'd0, 8'd1, 8'd0, 8'd7,
               8'd7, 8'd7, 8'd7, 8'd2, 8'd2, 8'd2, 8'd5, 8'd6,
               8'd0, 8'd2, 8'd3, 8'd1, 8'd0, 8'd1, 8'd2, 8'd7,
               8'd7, 8'd7, 8'd7, 8'd6, 8'd5, 8'd4, 8'd5, 8'd5,
               8'd6, 8'd6, 8'd6, 8'd5, 8'd4, 8'd1, 8'd3, 8'd3,
               8'd3, 8'd4, 8'd4, 8'd4, 8'd3, 8'd2, 8'd0, 8'd1,
               8'd5, 8'd5, 8'd5, 8'd3, 8'd4, 8'd4, 8'd3, 8'd3,
               8'd2, 8'd2, 8'd2, 8'd7, 8'd7, 8'd7, 8'd6, 8'd6,
               8'd6, 8'd2, 8'd2, 8'd5, 8'd3, 8'd4, 8'd6, 8'd4,
               8'd3, 8'd5, 8'd6, 8'd1, 8'd0, 8'd1, 8'd1, 8'd1,
               8'd0, 8'd0, 8'd0, 8'd7, 8'd7, 8'd0, 8'd1, 8'd2
    }),
    .SCAN_COL               ({
               8'd15, 8'd08, 8'd08, 8'd15, 8'd15, 8'd23, 8'd08, 8'd23,
               8'd15, 8'd23, 8'd15, 8'd08, 8'd23, 8'd23, 8'd15, 8'd23,
               8'd08, 8'd08, 8'd22, 8'd30, 8'd23, 8'd23, 8'd15, 8'd15,
               8'd08, 8'd08, 8'd14, 8'd31, 8'd22, 8'd30, 8'd14, 8'd14,
               8'd22, 8'd30, 8'd30, 8'd22, 8'd14, 8'd30, 8'd14, 8'd22,
               8'd14, 8'd22, 8'd30, 8'd24, 8'd16, 8'd01, 8'd01, 8'd16,
               8'd24, 8'd17, 8'd02, 8'd25, 8'd17, 8'd02, 8'd25, 8'd25,
               8'd16, 8'd24, 8'd01, 8'd01, 8'd16, 8'd24, 8'd02, 8'd16,
               8'd24, 8'd01, 8'd25, 8'd17, 8'd02, 8'd16, 8'd24, 8'd01,
               8'd24, 8'd16, 8'd16, 8'd24, 8'd01, 8'd01, 8'd17, 8'd02,
               8'd25, 8'd17, 8'd02, 8'd25, 8'd17, 8'd02, 8'd25, 8'd02,
               8'd31, 8'd31, 8'd31, 8'd25, 8'd17, 8'd17, 8'd11, 8'd10,
               8'd18, 8'd03, 8'd03, 8'd10, 8'd18, 8'd18, 8'd03, 8'd10,
               8'd27, 8'd19, 8'd11, 8'd27, 8'd19, 8'd11, 8'd10, 8'd18,
               8'd03, 8'd03, 8'd10, 8'd18, 8'd27, 8'd19, 8'd11, 8'd10,
               8'd18, 8'd03, 8'd03, 8'd18, 8'd10, 8'd27, 8'd19, 8'd10,
               8'd18, 8'd03, 8'd27, 8'd19, 8'd22, 8'd30, 8'd14, 8'd29,
               8'd21, 8'd13, 8'd13, 8'd21, 8'd29, 8'd11, 8'd27, 8'd19,
               8'd00, 8'd31, 8'd09, 8'd00, 8'd00, 8'd00, 8'd00, 8'd00,
               8'd00, 8'd00, 8'd09, 8'd09, 8'd09, 8'd09, 8'd09, 8'd09,
               8'd09, 8'd26, 8'd26, 8'd26, 8'd04, 8'd26, 8'd26, 8'd26,
               8'd11, 8'd27, 8'd19, 8'd19, 8'd27, 8'd11, 8'd11, 8'd28,
               8'd22, 8'd30, 8'd14, 8'd29, 8'd21, 8'd13, 8'd04, 8'd04,
               8'd31, 8'd04, 8'd04, 8'd04, 8'd04, 8'd26, 8'd26, 8'd04,
               8'd05, 8'd20, 8'd12, 8'd28, 8'd28, 8'd28, 8'd12, 8'd05,
               8'd05, 8'd20, 8'd12, 8'd20, 8'd05, 8'd07, 8'd13, 8'd29,
               8'd21, 8'd13, 8'd29, 8'd21, 8'd28, 8'd28, 8'd28, 8'd28,
               8'd21, 8'd29, 8'd13, 8'd05, 8'd20, 8'd12, 8'd20, 8'd12,
               8'd05, 8'd20, 8'd12, 8'd21, 8'd29, 8'd13, 8'd21, 8'd29,
               8'd13, 8'd06, 8'd07, 8'd06, 8'd06, 8'd06, 8'd06, 8'd07,
               8'd07, 8'd07, 8'd07, 8'd06, 8'd06, 8'd12, 8'd20, 8'd05,
               8'd05, 8'd20, 8'd12, 8'd07, 8'd06, 8'd07, 8'd31, 8'd31
    })
  )               PATTERN6_T  (
    .data_i               (data_i),

    .data_o               (scanned[6])
  );

  wire  [255:0]           sel_scanned;
  wire  [LEN_ENCODE-1:0]  select;
  SCAN_MUX #(
    .NUM_PATTERNS           (NUM_PATTERNS),
    .NUM_FIRST_TRANSFORMER  (NUM_FIRST_TRANSFORMER),
    .NUM_LAST_TRANSFORMER   (NUM_LAST_TRANSFORMER)
  )   SCANMUX   (
    .isAllZero_i          (isAllZero),
    .isAllWordSame_i      (isAllWordSame),
    .scanned_i            ({scanned[2], scanned[3], scanned[4], scanned[5], scanned[6]}),

    .sel_scanned_o        (sel_scanned),
    .select_o             (select)
  );

  // -------------------------------------------------------------
  D_FF #(
    .BITWIDTH(1)
  ) ALLZERO_DFF (
    .d_i        (isAllZero),
    .clk        (clk),
    .rst_n      (rst_n),

    .q_o        (isAllZero_o)
  );

  D_FF #(
    .BITWIDTH(1)
  ) ALLWORDSAME_DFF (
    .d_i        (isAllWordSame),
    .clk        (clk),
    .rst_n      (rst_n),

    .q_o        (isAllWordSame_o)
  );

  D_FF #(
    .BITWIDTH(256)
  ) DATAIN_DFF (
    .d_i        (data_i),
    .clk        (clk),
    .rst_n      (rst_n),

    .q_o        (data_o)
  );

  D_FF #(
    .BITWIDTH(256)
  ) SCANNED_DFF (
    .d_i    (sel_scanned),
    .clk    (clk),
    .rst_n  (rst_n),

    .q_o    (scanned_o)
  );

  D_FF #(
    .BITWIDTH(LEN_ENCODE)
  ) SEL_DFF (
    .d_i    (select),
    .clk    (clk),
    .rst_n  (rst_n),

    .q_o    (select_o)
  );

  D_FF #(
    .BITWIDTH(1)
  ) EN1_DFF (
    .d_i      (en_i),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (en_o)
  );

endmodule

module STAGE2 #(
  parameter   NUM_PATTERNS  = 8,

  parameter   LEN_ENCODE    = 3
) (
  input   wire  [255:0]             data_i,
  input   wire                      isAllZero_i,
  input   wire                      isAllWordSame_i,
  input   wire  [255:0]             scanned_i,
  input   wire  [LEN_ENCODE-1:0]    select_i,
  input   wire                      en_i,
  input   wire                      clk,
  input   wire                      rst_n,

  output  wire  [271:0]             sel_codeword_o,
  output  wire  [119:0]             sel_startidx_o,
  output  wire  [8:0]               sel_size_o,
  output  wire  [LEN_ENCODE-1:0]    select_o,
  output  wire                      en_o
);
  // synopsys template

  wire  [  8:0]   size;
  wire  [119:0]   startidx;
  wire  [271:0]   codewords;

  ENCODER   #(
    .NUM_PATTERNS       (NUM_PATTERNS)
  ) COMMON_ENCODER (
    .scanned_i            (scanned_i),

    .size_o               (size),
    .startidx_o           (startidx),
    .codewords_o          (codewords)
  );

  // Selector
  wire  [271:0]           sel_codewords;
  wire  [119:0]           sel_startidx;
  wire  [LEN_ENCODE-1:0]  sel_select;
  wire  [  8:0]           sel_size;
  SELECTOR  #(
    .NUM_PATTERNS       (NUM_PATTERNS)
  )   SEL   (
    .original_i         (data_i),
    .isAllZero_i        (isAllZero_i),
    .isAllWordSame_i    (isAllWordSame_i),
    
    .select_i           (select_i),
    .size_i             (size),
    .startidx_i         (startidx),
    .codewords_i        (codewords),

    .codewords_o        (sel_codewords),
    .startidx_o         (sel_startidx),
    .select_o           (sel_select),
    .size_o             (sel_size)
  );

  // -------------------------------------------------------------

  D_FF #(
    .BITWIDTH (272)
  ) CODEWORD_DFF (
    .d_i      (sel_codewords),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (sel_codeword_o)
  );

  D_FF #(
    .BITWIDTH (120)
  ) STARTIDX_DFF (
    .d_i      (sel_startidx),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (sel_startidx_o)
  );
  
  D_FF #(
    .BITWIDTH (LEN_ENCODE)
  ) SELECT_DFF (
    .d_i      (sel_select),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (select_o)
  );

  D_FF #(
    .BITWIDTH (9)
  ) SIZE_DFF (
    .d_i      (sel_size),
    .clk      (clk),
    .rst_n    (rst_n),
    
    .q_o      (sel_size_o)
  );

  D_FF #(
    .BITWIDTH (1)
  ) EN2_DFF (
    .d_i      (en_i),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (en_o)
  );
endmodule

module STAGE3 #(
  parameter   NUM_PATTERNS  = 8,

  parameter   LEN_ENCODE    = 3
) (
  input   wire  [271:0]             sel_codeword_i,
  input   wire  [119:0]             sel_startidx_i,
  input   wire  [8:0]               sel_size_i,
  input   wire  [LEN_ENCODE-1:0]    select_i,
  input   wire                      en_i,
  input   wire                      clk,
  input   wire                      rst_n,

  output  wire  [255+LEN_ENCODE:0]  data_o,
  output  wire  [8:0]               size_o,
  output  wire                      en_o
);
  // synopsys template

  wire  [255+LEN_ENCODE:0]  data;
  CONCAT            CAT (
    .codewords_i          (sel_codeword_i),
    .startidx_i           (sel_startidx_i),
    .select_i             (select_i),

    .concat_o             (data)
  );
  // -------------------------------------------------------------

  D_FF #(
    .BITWIDTH (256 + LEN_ENCODE)
  ) DATA_DFF (
    .d_i      (data),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (data_o)
  );

  D_FF #(
    .BITWIDTH (9)
  ) SIZE_DFF (
    .d_i      (sel_size_i),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (size_o)
  );

  D_FF #(
    .BITWIDTH (1)
  ) EN3_DFF (
    .d_i      (en_i),
    .clk      (clk),
    .rst_n    (rst_n),

    .q_o      (en_o)
  );

endmodule
