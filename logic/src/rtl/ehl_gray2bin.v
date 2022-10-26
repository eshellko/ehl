// Design:           Gray to Binary code converter
// Revision:         1.2
// Date:             2016-11-16
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2013-10-19 A.Kornukhin Initial release
//                   1.1 2016-07-12 A.Kornukhin code changed to avoid false Yosys combo loopback report
//                   1.2 2016-11-16 A.Kornukhin rewritten to avoid initial X during RTL simulation
module ehl_gray2bin
#(
   parameter WIDTH = 5
)
(
   input wire [WIDTH-1:0] data_gray,
   output reg [WIDTH-1:0] data_bin
);
//   wire [WIDTH:0] data_bin_ext;
//   assign data_bin_ext = {1'b0, data_gray ^ (data_bin_ext>>1)};
//   assign data_bin = data_bin_ext[WIDTH-1:0];
// bin[i] = gray[i] ^ bin[i+1];
// bin[msb] = gray[msb];
   integer i;
   always@*
   begin
      data_bin[WIDTH-1] = data_gray[WIDTH-1];
      for(i=WIDTH-2; i>=0; i=i-1)
         data_bin[i] = data_gray[i] ^ data_bin[i+1];
   end

endmodule
