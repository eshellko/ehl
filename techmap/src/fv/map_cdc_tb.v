// Design:           Metastable Flip-flop function check
// Revision:         1.0
// Date:             2021-08-05
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2021-08-05 A.Kornukhin: initial release

module map_cdc_tb;
`include "test.v"

   parameter TECHNOLOGY = 4;

   reg clk = 1'b0;
   localparam HALF_PERIOD = 10;
   always #HALF_PERIOD clk = ~clk;

   parameter WIDTH = 1;
   parameter SYNC_STAGE = 2;
   parameter INIT_VAL = 0;

   reg reset_n = 1'b0;
   reg [WIDTH-1:0] din = 0;
   wire [WIDTH-1:0] dout_rtl, dout_map;

   ehl_cdc
   #(
      .TECHNOLOGY ( 0                 ),
      .SYNC_STAGE ( SYNC_STAGE        ),
      .WIDTH      ( WIDTH             ),
      .INIT_VAL   ( {WIDTH{INIT_VAL}} )
   ) dut_rtl
   (
      .clk     ( clk      ),
      .reset_n ( reset_n  ),
      .din     ( din      ),
      .dout    ( dout_rtl )
   );
   ehl_cdc
   #(
      .TECHNOLOGY ( TECHNOLOGY        ),
      .SYNC_STAGE ( SYNC_STAGE        ),
      .WIDTH      ( WIDTH             ),
      .INIT_VAL   ( {WIDTH{INIT_VAL}} )
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

   integer i;
   initial
   begin
      TEST_TITLE("CDC synchronizer mapping test", "cdc_tb.v", "Basic test");

      TEST_INIT("Reset");
         repeat(SYNC_STAGE + 1)
         begin
            @(negedge clk);
            if(dout_map !== dout_rtl) $display("   Error: mismatch between RTL and MAPPED design (%b vs. %b) under reset", dout_rtl, dout_map);
            else test_pass++;
         end
      TEST_CHECK(SYNC_STAGE + 1);

      TEST_INIT("Write");
         err_cnt = 0;
         @(negedge clk) #1 reset_n = 1'b1;
         for(i = 0; i < 2*(2**WIDTH); i++)
         begin
            @(posedge clk);
            #1 din = din + 1;
         end
         if(err_cnt === 0) test_pass++;
      TEST_CHECK(1);

      TEST_SUMMARY;
   end

endmodule
