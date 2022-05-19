module SUBTRACTOR	(
	input [247:0] data_i,
	input [247:0] pred_i,

	output [247:0] diff_o
);

	// renaming input
	wire[7:0] pred[0:30];
	wire[7:0] orig[0:30];

	genvar i;
	generate
		for (i = 0; i < 31; i = i + 1) begin : input_rename
			assign pred[i] = pred_i[(31 - i) * 8 - 1 : (30 - i) * 8];
			assign orig[i] = data_i[(31 - i) * 8 - 1 : (30 - i) * 8];
		end
	endgenerate

	// subtract
	wire[7:0] diff[0:30];

	genvar j;
	generate
		for (j = 0; j < 31; j = j + 1) begin : subtract
			assign diff[j] = orig[j] - pred[j];
		end
	endgenerate

	// renaming diff to contiguous diff_o
	genvar k;
	generate
		for (k = 0; k < 31; k = k + 1) begin : output_rename
			assign diff_o[(31 - k) * 8 - 1 : (30 - k) * 8] = diff[k];
		end
	endgenerate

endmodule

