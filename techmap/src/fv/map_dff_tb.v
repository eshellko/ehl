// Design:           Flip-flop function check
// Revision:         1.0
// Date:             2021-01-22
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2021-01-22 A.Kornukhin: initial release

module map_dff_tb;

   parameter TECHNOLOGY = 1;

   reg clk = 1'b0;
   localparam HALF_PERIOD = 10;
   always #HALF_PERIOD clk = ~clk;

   reg reset_n = 1'b0;
   reg din = 1'b0;

   wire dout_rtl, dout_map;

   ehl_dff
   #(
      .TECHNOLOGY ( 0 )
   ) dut_rtl
   (
      .clk     ( clk      ),
      .reset_n ( reset_n  ),
      .din     ( din      ),
      .dout    ( dout_rtl )
   );

   ehl_dff
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) dut_map
   (
      .clk     ( clk      ),
      .reset_n ( reset_n  ),
      .din     ( din      ),
      .dout    ( dout_map )
   );

   integer err_cnt;
   always@(posedge clk or negedge clk)
   if(reset_n)
   begin
      #1 if(dout_map !== dout_rtl)
      begin
         $display("   Error: mismatch between RTL and MAPPED design (%b vs. %b) at time %0t", dout_rtl, dout_map, $time);
         err_cnt = err_cnt + 1;
      end
   end

   initial
   begin
//      $dumpfile("1.vcd");
//      $dumpvars(100);
      err_cnt = 0;
      #(3*HALF_PERIOD)
      if(dout_map !== dout_rtl)
      begin
         $display("   Error: mismatch between RTL and MAPPED design (%b vs. %b) under reset", dout_rtl, dout_map);
         err_cnt = err_cnt + 1;
      end

      #(11*HALF_PERIOD) reset_n = 1'b1;
      repeat(20)
      begin
         @(posedge clk);
         #1 din = !din;
      end
      repeat(20)
      begin
         @(negedge clk);
         #1 din = !din;
      end

      $display("   Info: test completed with %0d errors.", err_cnt);
      $finish;
   end

endmodule
