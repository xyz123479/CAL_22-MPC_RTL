`timescale 1ns / 100ps

module TB_DECONCAT;
  localparam  ENDCOUNT      = 10000;

  localparam  NUM_PATTERNS  = 8;
  localparam  LEN_ENCODE    = $clog2(NUM_PATTERNS);

  reg   [255+LEN_ENCODE:0]  data_i;
  reg                       clk, rst_n, en_i;

  wire  [255:0]             scanned_o;
  wire                      en_o;

  DECONCAT #(
    .NUM_PATTERNS     (NUM_PATTERNS)
  )   DUT   (
    .data_i           (data_i[255:0]),
    .clk              (clk),
    .rst_n            (rst_n),
    .en_i             (en_i),

    .scanned_o        (scanned_o),
    .en_o             (en_o)
  );

  // clock gen
  initial begin
    clk = 1'b0;
    forever #10 clk = !clk;
  end

  // reset and en_i gen
  initial begin
    rst_n = 1'b0;
    en_i  = 1'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    en_i  = 1'b1;
  end

  // input vector gen
  reg   [255 + LEN_ENCODE:0]  data;
  reg   [255 + LEN_ENCODE:0]  data_list   [0:ENDCOUNT-1];
  integer list_idx;
  integer file_data_i;
  integer file_stat_i;
  initial begin
    list_idx = 0;
    data = 'd0;

    file_data_i = $fopen("../tb/stimulus/stimulus_deconcat/data_i.txt", "r");
    if (file_data_i) begin
      while (!$feof(file_data_i)) begin
        repeat (ENDCOUNT) @(posedge clk) begin
          if (rst_n) begin
            $fscanf(file_data_i, "%b\n", data);
            data_i <= data;
            data_list[list_idx] <= data;
            list_idx = list_idx + 1;
          end
        end
      end
      $fclose(file_data_i);
    end
    else begin
      $display("ERROR: Input file is not opened");
      $finish;
    end
  end

  // output vector gen [scanned]
  integer file_scanned_o;
  reg   [255:0]  scanned_o_stimulus;
  initial begin
    scanned_o_stimulus = 'd0;
    file_scanned_o = $fopen("../tb/stimulus/stimulus_deconcat/scanned_o.txt", "r");
    if (file_scanned_o) begin
      while (!$feof(file_scanned_o)) begin
        repeat (ENDCOUNT) @(posedge clk) begin
          if (rst_n && en_o) begin
            $fscanf(file_scanned_o, "%b\n", scanned_o_stimulus);
          end
        end
      end
      $fclose(file_scanned_o);
    end
    else begin
      $display("ERROR: Output file is not opened");
      $finish;
    end
  end

  // self-check
  integer total, cnt;
  initial begin
    total = 0;
    cnt = 0;
    repeat (ENDCOUNT) @(posedge clk) begin
      if (en_o) begin
        #(1);
        if (scanned_o != scanned_o_stimulus) begin
          cnt = cnt + 1;
          $display("Failed at %05d => data_i : %0d, %0x", total, data_list[total][255+LEN_ENCODE:256], data_list[total][255:0]);
          $display("                scanned_o :    %0x | ref : %0x\n", scanned_o, scanned_o_stimulus);
        end
      end
      total = total + 1;
    end
    $display("Total error: %d / %d", cnt, total);
    $finish;
  end
endmodule
