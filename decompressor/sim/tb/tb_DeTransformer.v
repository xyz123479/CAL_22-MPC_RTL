`timescale 1ns/100ps

module TB_DETRANSFORMER;
  reg   [255:0]   data_i;
  wire  [255:0]   data_o;

  DETRANSFORMER DUT (
    .data_i       (data_i),

    .data_o       (data_o)
  );

  reg   [255:0]   data_o_stimulus;
  reg   [255:0]   pred_o_stimulus;

  integer file_in;
  integer file_out;
  integer file_pred;
  integer stat;
  integer total, cnt;
  initial begin
    total = 0;
    cnt = 0;
    file_in = $fopen("/home/jin8495/projects/filter_compression/data_type/verilog/decompressor/sim/tb/stimulus/stimulus_detransformer/diff_i.txt", "r");
    file_out = $fopen("/home/jin8495/projects/filter_compression/data_type/verilog/decompressor/sim/tb/stimulus/stimulus_detransformer/data_o.txt", "r");
    file_pred = $fopen("/home/jin8495/projects/filter_compression/data_type/verilog/decompressor/sim/tb/stimulus/stimulus_detransformer/pred.txt", "r");
    if (file_in && file_out) begin
      while (!$feof(file_in)) begin
        stat = $fscanf(file_in, "%x\n", data_i);
        stat = $fscanf(file_out, "%x\n", data_o_stimulus);
        stat = $fscanf(file_pred, "%x\n", pred_o_stimulus);
        
        #(1);
        if (data_o_stimulus != data_o) begin
          $display("data_i            : %x", data_i);
          $display("data_o            : %x", data_o);
          $display("data_o_stimulus   : %x", data_o_stimulus);
          $display("");
          cnt = cnt + 1;
        end
        total = total + 1;
        #(9);
      end
      $display("error : %d / %d", cnt, total);
      $fclose(file_in);
      $fclose(file_out);
      $fclose(file_pred);
    end
    else begin
      $display("File is not opened");
    end
  end
endmodule
