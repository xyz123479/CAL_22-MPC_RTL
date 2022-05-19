module ALLWORDSAME (
  input   [255:0]     data_i,

  output              isAllWordSame_o
);

  wire  [7:0]   data      [0:31];
  genvar i;
  generate
    for (i=0; i<32; i=i+1) begin : rename_input
      assign data[i] = data_i[256-8*i-1:256-8*(i+1)];
    end
  endgenerate

  wire firstSame, secondSame, thirdSame, fourthSame;
  assign firstSame  =  (data[0] == data[4])
                     & (data[0] == data[8])
                     & (data[0] == data[12])
                     & (data[0] == data[16])
                     & (data[0] == data[20])
                     & (data[0] == data[24])
                     & (data[0] == data[28]);
  assign secondSame =  (data[1] == data[5])
                     & (data[1] == data[9])
                     & (data[1] == data[13])
                     & (data[1] == data[17])
                     & (data[1] == data[21])
                     & (data[1] == data[25])
                     & (data[1] == data[29]);
  assign thirdSame  =  (data[2] == data[6])
                     & (data[2] == data[10])
                     & (data[2] == data[14])
                     & (data[2] == data[18])
                     & (data[2] == data[22])
                     & (data[2] == data[26])
                     & (data[2] == data[30]);
  assign fourthSame =  (data[3] == data[7])
                     & (data[3] == data[11])
                     & (data[3] == data[15])
                     & (data[3] == data[19])
                     & (data[3] == data[23])
                     & (data[3] == data[27])
                     & (data[3] == data[31]);

  assign isAllWordSame_o = firstSame & secondSame & thirdSame & fourthSame;

endmodule
