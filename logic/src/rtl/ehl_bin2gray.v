// Design:           Binary to Gray code converter
// Revision:         1.0
// Date:             2013-10-18
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: -
module ehl_bin2gray
#(
   parameter WIDTH = 5
)
(
   input [WIDTH-1:0] data_bin,
   output [WIDTH-1:0] data_gray
);

   assign data_gray = (data_bin>>1) ^ data_bin;

endmodule
