module sing_extender(data_in, data_out);
  input [15:0] data_in;
  output [32-1:0] data_out;

  assign data_out = (data_in[15] == 1) ? {16'b1111111111111111, data_in} : {16'b0000000000000000, data_in};
endmodule // signExtend