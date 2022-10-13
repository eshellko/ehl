// Design:           Clock Divider function check
// Revision:         1.0
// Date:             2021-01-21
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2021-01-21 A.Kornukhin: initial release

module map_clock_div_tb;

   parameter TECHNOLOGY = 1;

   reg clk_in = 1'b0;
   localparam HALF_PERIOD = 10;
   always #HALF_PERIOD clk_in = ~clk_in;

   reg reset_n = 1'b0;

   wire clk_o_rtl, clk_o_map;

   ehl_clock_div
   #(
      .TECHNOLOGY ( 0 )
   ) dut_rtl
   (
      .clk_in  ( clk_in    ),
      .reset_n ( reset_n   ),
      .clk_out ( clk_o_rtl )
   );

   ehl_clock_div
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) dut_map
   (
      .clk_in  ( clk_in    ),
      .reset_n ( reset_n   ),
      .clk_out ( clk_o_map )
   );

   integer err_cnt;
   always@(posedge clk_in or negedge clk_in)
   if(reset_n)
   begin
      #1 if(clk_o_map !== clk_o_rtl)
      begin
         $display("   Error: mismatch between RTL and MAPPED design (%b vs. %b) at time %0t", clk_o_rtl, clk_o_map, $time);
         err_cnt = err_cnt + 1;
      end
   end

   initial
   begin
//      $dumpfile("1.vcd");
//      $dumpvars(100);
      err_cnt = 0;
      #(3*HALF_PERIOD)
      if(clk_o_map !== clk_o_rtl)
      begin
         $display("   Error: mismatch between RTL and MAPPED design (%b vs. %b) under reset", clk_o_rtl, clk_o_map);
         err_cnt = err_cnt + 1;
      end

      #(11*HALF_PERIOD) reset_n = 1'b1;
      repeat(40) @(posedge clk_in);

      $display("   Info: test completed with %0d errors.", err_cnt);
      $finish;
   end

endmodule
