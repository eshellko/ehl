// Design:           Clock Mux function check
// Revision:         1.0
// Date:             2020-12-28
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2020-12-28 A.Kornukhin: initial release

module map_clock_mux_tb;

   parameter TECHNOLOGY = 1;

   reg clk0 = 1'b0;
   localparam HALF_PERIOD_FAST = 10;
   always #HALF_PERIOD_FAST clk0 = ~clk0;

   reg clk1 = 1'b0;
   localparam HALF_PERIOD_SLOW = 15;
   always #HALF_PERIOD_SLOW clk1 = ~clk1;

   reg sel = 1'b0;

   wire clk_o_rtl, clk_o_map;

   ehl_clock_mux
   #(
      .TECHNOLOGY ( 0 )
   ) dut_rtl
   (
      .clk_0   ( clk0      ),
      .clk_1   ( clk1      ),
      .sel     ( sel       ),
      .clk_out ( clk_o_rtl )
   );

   ehl_clock_mux
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) dut_map
   (
      .clk_0   ( clk0      ),
      .clk_1   ( clk1      ),
      .sel     ( sel       ),
      .clk_out ( clk_o_map )
   );

   integer err_cnt;
   always@(posedge clk0 or negedge clk0 or posedge clk1 or negedge clk1)
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
      #(13*HALF_PERIOD_FAST);

      @(negedge clk0) sel <= 1'b1; repeat(20) @(negedge clk1);
      @(negedge clk1) sel <= 1'b0; repeat(20) @(negedge clk0);

      $display("   Info: test completed with %0d errors.", err_cnt);
      $finish;
   end

endmodule
