// Design:           Integrated Clock Gating (ICG) function check
// Revision:         1.0
// Date:             2020-12-28
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2020-12-28 A.Kornukhin: initial release
module ehl_clock_gate_tb;

   parameter TECHNOLOGY = 1;

   reg clk = 1'b0;
   localparam HALF_PERIOD = 10;
   always #HALF_PERIOD clk = ~clk;

   reg en = 1'b0;

   wire clk_o_rtl;
   wire clk_o_map;

   ehl_clock_gate
   #(
      .TECHNOLOGY ( 0 )
   ) dut_rtl
   (
      .clk_in    ( clk       ),
      .test_mode ( 1'b0      ),
      .enable    ( en        ),
      .clk_out   ( clk_o_rtl )
   );

   ehl_clock_gate
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) dut_map
   (
      .clk_in    ( clk       ),
      .test_mode ( 1'b0      ),
      .enable    ( en        ),
      .clk_out   ( clk_o_map )
   );

   integer err_cnt;
   always@(posedge clk or negedge clk)
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

      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b0;

      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b0;

      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b0;
      @(negedge clk) en <= 1'b0;

      @(negedge clk) en <= 1'b0;
      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b0;

      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b1;
      @(negedge clk) en <= 1'b0;
      @(negedge clk) en <= 1'b0;



      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b0;

      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b0;

      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b0;
      @(posedge clk) en <= 1'b0;

      @(posedge clk) en <= 1'b0;
      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b0;

      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b1;
      @(posedge clk) en <= 1'b0;
      @(posedge clk) en <= 1'b0;



      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b0;

      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b0;

      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b0;
      @(negedge clk) #2 en <= 1'b0;

      @(negedge clk) #2 en <= 1'b0;
      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b0;

      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b1;
      @(negedge clk) #2 en <= 1'b0;
      @(negedge clk) #2 en <= 1'b0;



      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b0;

      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b0;

      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b0;
      @(posedge clk) #2 en <= 1'b0;

      @(posedge clk) #2 en <= 1'b0;
      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b0;

      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b1;
      @(posedge clk) #2 en <= 1'b0;
      @(posedge clk) #2 en <= 1'b0;

      $display("   Info: test completed with %0d errors.", err_cnt);
      $finish;
   end

endmodule
