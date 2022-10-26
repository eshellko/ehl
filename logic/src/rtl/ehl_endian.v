// Design:           Big-endian to Little-endian converter (and vice-versa)
// Revision:         1.0
// Date:             2014-03-24
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2014-03-24 A.Kornukhin: initial release
// Description:      During implementation this module should be
//                   fully optimized away as it is only makes
//                   bytes swap using reassignment

module ehl_endian
#(
   parameter BYTE_CNT = 1
)
(
   input [BYTE_CNT*8 - 1:0]  data_in,   // Input data stream (Big or Little endian)
   output [BYTE_CNT*8 - 1:0] data_out   // Output data stream (Little or Big endian respectively)
);
   reg [BYTE_CNT*8 - 1:0] data_int;
   integer i, j;
   always@(data_in)
   for(i=0; i<BYTE_CNT; i=i+1)
      for(j=0; j<8; j=j+1)
         data_int[i*8 + j] = data_in[(BYTE_CNT-i-1)*8+j];

   assign data_out = data_int;

endmodule
