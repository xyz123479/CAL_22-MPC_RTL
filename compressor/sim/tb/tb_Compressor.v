`timescale 1ns/100ps
module TB_COMPRESSOR;
  localparam  ENDCOUNT      = 10000;

  localparam  NUM_PATTERNS  = 8;
  localparam  LEN_ENCODE    = $clog2(NUM_PATTERNS);

  reg   [255:0]               data_i;
  reg                         clk;
  reg                         rst_n;
  reg                         en_i;

  wire  [255 + LEN_ENCODE:0]  data_o;
  wire  [8:0]                 size_o;
  wire                        en_o;

  wire  [LEN_ENCODE-1:0]      sel;
  reg   [LEN_ENCODE-1:0]      sel_ref;

  COMPRESSOR DUT (
    .data_i     (data_i),
    .en_i       (en_i),
    .clk        (clk),
    .rst_n      (rst_n),

    .data_o     (data_o),
    .size_o     (size_o),
    .en_o       (en_o)
  );

  assign sel = data_o[255+LEN_ENCODE:256];

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
    rst_n <= 1'b1;
    en_i  <= 1'b1;
  end

  integer file_stat_i;
  integer file_stat_o;

  // input vector gen
  reg   [255:0]   data;
  reg   [255:0]   data_i_list   [0:ENDCOUNT-1];
  integer list_i;

  integer file_data_i;
  initial begin
    list_i = 0;
    data = 'd0;
    data_i = data;

    file_data_i = $fopen("../tb/stimulus/stimulus_compressor/data_i.txt", "r");
    if (file_data_i) begin
      while (!$feof(file_data_i)) begin
        repeat (ENDCOUNT) @(posedge clk) begin
          if (rst_n) begin
            file_stat_i = $fscanf(file_data_i, "%x\n", data);
            data_i <= data;
            
            data_i_list[list_i] <= data;
            list_i = list_i + 1;
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

  // output vector
  integer file_data_o;
  reg   [255 + LEN_ENCODE:0]  data_o_stimulus;
  initial begin
    data_o_stimulus = 'd0;

    file_data_o = $fopen("../tb/stimulus/stimulus_compressor/data_o.txt", "r");
    if (file_data_o) begin
      while (!$feof(file_data_o)) begin
        repeat (ENDCOUNT) @(posedge clk) begin
          if (rst_n && en_o) begin
            file_stat_o = $fscanf(file_data_o, "%b\n", data_o_stimulus);
            sel_ref = data_o_stimulus[255+LEN_ENCODE:256];
          end
        end
      end
      $fclose(file_data_o);
    end
    else begin
      $display("ERROR: Output file is not opened");
      $finish;
    end
  end

  // output vector
  integer file_size_o;
  reg   [255 + LEN_ENCODE:0]  size_o_stimulus;
  initial begin
    size_o_stimulus = 'd0;

    file_size_o = $fopen("../tb/stimulus/stimulus_compressor/size_o.txt", "r");
    if (file_size_o) begin
      while (!$feof(file_size_o)) begin
        repeat (ENDCOUNT) @(posedge clk) begin
          if (rst_n && en_o) begin
            file_stat_o = $fscanf(file_size_o, "%x\n", size_o_stimulus);
          end
        end
      end
      $fclose(file_size_o);
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
        if (data_o != data_o_stimulus || size_o != size_o_stimulus) begin
          cnt = cnt + 1;
          $display("Failed at %0d\t=>\tinput  >>\t%0x", total, data_i_list[total]);
          $display("                 \toutput >>\t%0d:%0x, %0d:%0x\n", sel, data_o[255:0], sel_ref, data_o_stimulus[255:0]);
        end
        total = total + 1;
      end
    end
    $display("Total error: %d / %d", cnt, total);
    $finish;
  end
endmodule
