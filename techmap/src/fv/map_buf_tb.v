// Design:           Buffer function check
// Revision:         1.0
// Date:             2021-01-27
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2021-01-27 A.Kornukhin: initial release

module map_buf_tb;

   parameter TECHNOLOGY = 1;

   reg clk0 = 1'b0;
   localparam HALF_PERIOD = 10;
   always #HALF_PERIOD clk0 = ~clk0;

   wire clk_o_rtl, clk_o_map;

   ehl_buf
   #(
      .TECHNOLOGY ( 0 )
   ) dut_rtl
   (
      .data_i ( clk0      ),
      .data_o ( clk_o_rtl )
   );

   ehl_buf
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) dut_map
   (
      .data_i ( clk0      ),
      .data_o ( clk_o_map )
   );

   integer err_cnt;
   always@(posedge clk0 or negedge clk0)
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
      #(13*HALF_PERIOD);

      repeat(20) @(negedge clk0);

      $display("   Info: test completed with %0d errors.", err_cnt);
      $finish;
   end

endmodule

