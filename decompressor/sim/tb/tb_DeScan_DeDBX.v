`timescale 1ns / 100ps

module TB_DESCAN_DEDBX;

  reg   [255:0]     scanned_i;
  wire  [255:0]     bpx;
  wire  [255:0]     diff_o;
  DESCAN #(
    .SCAN_ROW({
      8'd4, 8'd4, 8'd3, 8'd4, 8'd5, 8'd2, 8'd2, 8'd2,
      8'd3, 8'd5, 8'd3, 8'd5, 8'd6, 8'd6, 8'd6, 8'd4,
      8'd4, 8'd4, 8'd2, 8'd2, 8'd2, 8'd3, 8'd5, 8'd3,
      8'd5, 8'd3, 8'd5, 8'd4, 8'd3, 8'd5, 8'd6, 8'd6,
      8'd6, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd6,
      8'd4, 8'd3, 8'd5, 8'd7, 8'd7, 8'd7, 8'd0, 8'd0,
      8'd0, 8'd7, 8'd7, 8'd7, 8'd0, 8'd0, 8'd0, 8'd0,
      8'd7, 8'd1, 8'd2, 8'd2, 8'd2, 8'd1, 8'd1, 8'd1,
      8'd2, 8'd2, 8'd2, 8'd1, 8'd1, 8'd3, 8'd3, 8'd3,
      8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
      8'd4, 8'd1, 8'd2, 8'd1, 8'd1, 8'd2, 8'd3, 8'd5,
      8'd5, 8'd5, 8'd6, 8'd6, 8'd6, 8'd5, 8'd5, 8'd5,
      8'd6, 8'd6, 8'd6, 8'd7, 8'd7, 8'd7, 8'd7, 8'd7,
      8'd7, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd6,
      8'd7, 8'd0, 8'd1, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
      8'd0, 8'd4, 8'd5, 8'd6, 8'd7, 8'd1, 8'd0, 8'd2,
      8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2,
      8'd3, 8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd3, 8'd4,
      8'd5, 8'd5, 8'd5, 8'd3, 8'd3, 8'd4, 8'd4, 8'd4,
      8'd4, 8'd4, 8'd3, 8'd6, 8'd1, 8'd1, 8'd1, 8'd1,
      8'd1, 8'd1, 8'd1, 8'd2, 8'd6, 8'd6, 8'd6, 8'd7,
      8'd7, 8'd0, 8'd0, 8'd0, 8'd0, 8'd5, 8'd5, 8'd5,
      8'd5, 8'd6, 8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd2,
      8'd2, 8'd2, 8'd6, 8'd6, 8'd6, 8'd7, 8'd7, 8'd7,
      8'd7, 8'd2, 8'd7, 8'd3, 8'd4, 8'd3, 8'd3, 8'd3,
      8'd3, 8'd3, 8'd3, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
      8'd4, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd7, 8'd1,
      8'd5, 8'd6, 8'd6, 8'd6, 8'd0, 8'd0, 8'd0, 8'd0,
      8'd5, 8'd5, 8'd6, 8'd6, 8'd6, 8'd6, 8'd7, 8'd7,
      8'd7, 8'd7, 8'd7, 8'd7, 8'd7, 8'd2, 8'd0, 8'd0,
      8'd3, 8'd4, 8'd3, 8'd2, 8'd1, 8'd4, 8'd5, 8'd6,
      8'd0, 8'd0, 8'd0, 8'd6, 8'd7, 8'd7, 8'd5, 8'd0
    }),
    .SCAN_COL({
      8'd15, 8'd31, 8'd08, 8'd08, 8'd08, 8'd31, 8'd08, 8'd15,
      8'd31, 8'd31, 8'd15, 8'd15, 8'd15, 8'd31, 8'd08, 8'd19,
      8'd04, 8'd27, 8'd19, 8'd04, 8'd27, 8'd19, 8'd19, 8'd27,
      8'd27, 8'd04, 8'd04, 8'd23, 8'd23, 8'd23, 8'd19, 8'd04,
      8'd27, 8'd08, 8'd31, 8'd15, 8'd27, 8'd19, 8'd04, 8'd23,
      8'd12, 8'd12, 8'd12, 8'd31, 8'd08, 8'd15, 8'd08, 8'd31,
      8'd15, 8'd19, 8'd04, 8'd27, 8'd19, 8'd04, 8'd27, 8'd23,
      8'd23, 8'd30, 8'd30, 8'd14, 8'd07, 8'd07, 8'd14, 8'd26,
      8'd26, 8'd11, 8'd03, 8'd03, 8'd11, 8'd30, 8'd14, 8'd07,
      8'd03, 8'd11, 8'd26, 8'd26, 8'd30, 8'd14, 8'd07, 8'd03,
      8'd11, 8'd12, 8'd23, 8'd23, 8'd22, 8'd22, 8'd22, 8'd30,
      8'd14, 8'd07, 8'd07, 8'd14, 8'd30, 8'd26, 8'd11, 8'd03,
      8'd03, 8'd11, 8'd26, 8'd07, 8'd14, 8'd11, 8'd03, 8'd30,
      8'd26, 8'd25, 8'd10, 8'd21, 8'd29, 8'd13, 8'd02, 8'd12,
      8'd12, 8'd18, 8'd18, 8'd30, 8'd26, 8'd11, 8'd07, 8'd03,
      8'd14, 8'd22, 8'd22, 8'd22, 8'd22, 8'd06, 8'd22, 8'd18,
      8'd12, 8'd10, 8'd25, 8'd29, 8'd21, 8'd13, 8'd02, 8'd06,
      8'd06, 8'd13, 8'd10, 8'd25, 8'd25, 8'd10, 8'd02, 8'd02,
      8'd02, 8'd10, 8'd25, 8'd29, 8'd21, 8'd21, 8'd29, 8'd13,
      8'd06, 8'd18, 8'd18, 8'd18, 8'd09, 8'd01, 8'd24, 8'd20,
      8'd28, 8'd05, 8'd16, 8'd16, 8'd10, 8'd25, 8'd02, 8'd02,
      8'd10, 8'd13, 8'd29, 8'd25, 8'd21, 8'd21, 8'd29, 8'd13,
      8'd06, 8'd06, 8'd06, 8'd02, 8'd10, 8'd09, 8'd01, 8'd24,
      8'd20, 8'd28, 8'd29, 8'd13, 8'd21, 8'd25, 8'd21, 8'd29,
      8'd13, 8'd05, 8'd06, 8'd16, 8'd16, 8'd09, 8'd01, 8'd24,
      8'd20, 8'd28, 8'd05, 8'd09, 8'd01, 8'd24, 8'd20, 8'd28,
      8'd05, 8'd16, 8'd09, 8'd05, 8'd28, 8'd18, 8'd18, 8'd17,
      8'd01, 8'd09, 8'd05, 8'd16, 8'd16, 8'd20, 8'd24, 8'd28,
      8'd24, 8'd20, 8'd01, 8'd24, 8'd20, 8'd28, 8'd28, 8'd16,
      8'd09, 8'd05, 8'd01, 8'd24, 8'd20, 8'd17, 8'd12, 8'd00,
      8'd17, 8'd17, 8'd00, 8'd00, 8'd00, 8'd00, 8'd17, 8'd17,
      8'd09, 8'd05, 8'd01, 8'd00, 8'd00, 8'd17, 8'd00, 8'd17
    })
  ) DUT0 (
    .scanned_i      (scanned_i),

    .bpx_o          (bpx)
  );
  DEDBX DUT1 (
    .bpx_i          (bpx),

    .diff_o         (diff_o)
  );

  reg   [255:0]     diff_o_stimulus;
  reg   [255:0]     bpx_stimulus;
  reg   [255:0]     bitplane_stimulus;

  integer file_in;
  integer file_bpx, file_bitplane;
  integer file_diff_o;
  integer stat;
  integer total, cnt;
  initial begin
    total = 0;
    cnt = 0;
    file_in = $fopen("/home/jin8495/projects/contrastive_clustering_compression/verilog/decompressor/vcs/tb/stimulus/scanned_i.txt", "r");
    file_bpx = $fopen("/home/jin8495/projects/contrastive_clustering_compression/verilog/decompressor/vcs/tb/stimulus/bpx.txt", "r");
    file_bitplane = $fopen("/home/jin8495/projects/contrastive_clustering_compression/verilog/decompressor/vcs/tb/stimulus/bitplane.txt", "r");
    file_diff_o = $fopen("/home/jin8495/projects/contrastive_clustering_compression/verilog/decompressor/vcs/tb/stimulus/diff_o.txt", "r");
    if (file_in && file_bpx && file_diff_o) begin
      while (!$feof(file_in)) begin
        stat = $fscanf(file_in, "%b\n", scanned_i);
        stat = $fscanf(file_bpx, "%b\n", bpx_stimulus);
        stat = $fscanf(file_bitplane, "%b\n", bitplane_stimulus);
        stat = $fscanf(file_diff_o, "%x\n", diff_o_stimulus);

        #(1);
        if (diff_o_stimulus != diff_o) begin
          $display("scanned_i         : %b", scanned_i);
          $display("diff_o            : %x", diff_o);
          $display("diff_o_stimulus   : %x", diff_o_stimulus);
          $display("");
          cnt = cnt + 1;
        end
        total = total + 1;
        #(9);
      end
      $display("error : %d / %d", cnt, total);
      $fclose(file_in);
      $fclose(file_bpx);
      $fclose(file_bitplane);
      $fclose(file_diff_o);
    end
    else begin
      $display("File is not opened");
    end
  end
endmodule

