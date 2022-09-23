// Design:           IEEE 1149.1 Boundary Scan Cell (BC_1 / BC_2)
// Revision:         1.0
// Date:             2022-06-27
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-06-27 A.Kornukhin: Initial release
// Reference:        [1] IEEE 1149.1-2001

module ehl_bsc
#(
   parameter BC_TYPE = 1 // 1 - BC_1; 2 - BC_2
)
(
   input wire  data_in,      // data from core/IO logic
               serial_in,    // data from previous scan cell
   output wire data_out,     // data to core/IO logic
   output reg  serial_out,   // data to next scan cell
   input  wire capture_dr,
               shift_dr,
               update_dr,
               xtest,        // IR == extest || IR == intest
               tck
);
`ifndef SYNTHESIS
   initial
   begin
      if(BC_TYPE != 1 &&  BC_TYPE != 2)
      begin
         $display("   Error: '%m' parameter BC_TYPE has incorrect value %x (allowed 1, 2)", BC_TYPE);
         $finish;
      end
   end
`endif
// [1 8.9.1] The INTEST instruction shall select only the boundary-scan register to be connected
//           for serial access between TDI and TDO in the Shift-DR controller state (i.e., no
//           other test data register may be connected in series with the boundary-scan register).
   always@(posedge tck)
   if(capture_dr)
      serial_out <= (BC_TYPE == 1) ? data_in : (BC_TYPE == 2) ? data_out : 1'bx;
   else if(shift_dr)
      serial_out <= serial_in;

// [1 6.1.2] Data is latched onto the parallel output of these test data registers from the shift register
//           path on the falling edge of TCK in the Update-DR controller state
   reg dneg;
   always@(negedge tck)
   if(update_dr)
      dneg <= serial_out;

   assign data_out = xtest ? dneg : data_in;

endmodule
