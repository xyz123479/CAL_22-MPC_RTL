module ALLZERO (
	input [255:0] data_in,

	output        isAllZero_out
);

	assign isAllZero_out = (data_in == 'd0) ? 1'b1 : 1'b0;

endmodule
