// Design:           XOR function check
// Revision:         1.0
// Date:             2020-12-29
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2020-12-29 A.Kornukhin: initial release

module map_xor_tb;

   parameter TECHNOLOGY = 1;

   reg clk0 = 1'b0;
   localparam HALF_PERIOD_FAST = 10;
   always #HALF_PERIOD_FAST clk0 = ~clk0;

   reg clk1 = 1'b0;
   localparam HALF_PERIOD_SLOW = 15;
   always #HALF_PERIOD_SLOW clk1 = ~clk1;

   wire clk_o_rtl, clk_o_map;

   ehl_xor
   #(
      .TECHNOLOGY ( 0 )
   ) dut_rtl
   (
      .i_a ( clk0      ),
      .i_b ( clk1      ),
      .o_x ( clk_o_rtl )
   );

   ehl_xor
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) dut_map
   (
      .i_a ( clk0      ),
      .i_b ( clk1      ),
      .o_x ( clk_o_map )
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

      repeat(20) @(negedge clk1);
      repeat(20) @(negedge clk0);

      $display("   Info: test completed with %0d errors.", err_cnt);
      $finish;
   end

endmodule

