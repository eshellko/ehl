// Design:           IEEE 1149.1 Boundary Scan Cell
// Revision:         1.0
// Date:             2022-06-27
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-06-27 A.Kornukhin: Initial release
// Reference:        [1] IEEE 1149.1-2001

module ehl_bsc
#(
   parameter [0:0] TYPE = 1'b0 // 0 - input, 1 - output/output_enable
)
(
   input      data_in,        // data from core/IO logic
              serial_in,      // data from previous scan cell
   output     data_out,       // data to core/IO logic
   output reg serial_out,     // data to next scan cell
   input      capture_dr,
              shift_dr,
              update_dr,
              extest,         // IR == extest
              intest,         // IR == intest
              tck
);
   always@(posedge tck)
   if(capture_dr)
      serial_out <= (TYPE==0) ? (extest ? data_in : 1'b0) : (intest ? data_in : 1'b0);
   else if(shift_dr)
      serial_out <= serial_in;

   reg d1;
   always@(posedge tck)
   if(update_dr)
      d1 <= serial_out;

   assign data_out = (extest | intest) ? d1 : data_in;

endmodule
