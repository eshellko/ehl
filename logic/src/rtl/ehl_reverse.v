// Design:           Reverse order of bits in input data
// Revision:         1.0
// Date:             2013-11-28
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: -
module ehl_reverse
#(
   parameter WIDTH = 1
)
(
   input [WIDTH-1:0] din,
   output reg [WIDTH-1:0] dout
);
   integer i;
   always@*
   for(i=0;i<WIDTH;i=i+1)
      dout[i] = din[WIDTH-1-i];

endmodule
