// Design:           DDR3 PHY Write Leveling engine
// Revision:         1.0
// Date:             2019-04-25
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2019-04-25 A.Kornukhin: initial release

module ehl_ddr_wrlvl_trng
(
   input            clk,
                    reset_n,
   input            dfi_wrlvl_resp, // same as DQ @ moment of capture
   input [3:0]      rank_sel,       // TODO: route RANK controls at upper level
   input            init,           // pulse to start
   output reg       dqs,
   output reg [3:0] coef,
   output reg       done,
   output reg       status,         // 1 - OK, 0 - training FAILED
   output reg [3:0] result,         // resulted ideal coefficient
   output [15:0]    rv              // allow to read training result for debugging
);
   wire capture;
   reg capture_delay;
   wire load;

   reg [15:0] wrlvl_resp;
   assign rv = wrlvl_resp;

   wire last_run = coef == 4'hf;
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      done <= 1'b0;
   else if(init)
      done <= 1'b0;
   else if(capture_delay)
      done <= 1'b1;

   wire [3:0] first_one =
      wrlvl_resp[0] == 1'b1 ? 4'b0000 :
      wrlvl_resp[1] == 1'b1 ? 4'b0001 :
      wrlvl_resp[2] == 1'b1 ? 4'b0010 :
      wrlvl_resp[3] == 1'b1 ? 4'b0011 :
      wrlvl_resp[4] == 1'b1 ? 4'b0100 :
      wrlvl_resp[5] == 1'b1 ? 4'b0101 :
      wrlvl_resp[6] == 1'b1 ? 4'b0110 :
      wrlvl_resp[7] == 1'b1 ? 4'b0111 :
      wrlvl_resp[8] == 1'b1 ? 4'b1000 :
      wrlvl_resp[9] == 1'b1 ? 4'b1001 :
      wrlvl_resp[10] == 1'b1 ? 4'b1010 :
      wrlvl_resp[11] == 1'b1 ? 4'b1011 :
      wrlvl_resp[12] == 1'b1 ? 4'b1100 :
      wrlvl_resp[13] == 1'b1 ? 4'b1101 :
      wrlvl_resp[14] == 1'b1 ? 4'b1110 :
      wrlvl_resp[15] == 1'b1 ? 4'b1111 : 4'hx;

   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      status <= 1'b0;
   else if(init)
      status <= 1'b0;
   else if(capture_delay)
      status <= first_one != 4'h0; // TODO: report error if more than 1 0->1 transition detected!

   always@(posedge clk)
   if(capture_delay)
      result <= first_one; // TODO: analyze it better - report intermediate errors inside stable data path....

   always@(posedge clk)
   if(init)
   begin
      wrlvl_resp <= 16'h0;
      coef <= 4'h0;
   end
   else if(capture)
   begin
      wrlvl_resp[coef] <= dfi_wrlvl_resp;
      coef <= coef + 1'b1;
   end

   reg [8:0] driver;
   assign load = driver[6-1-1:0] == 5'h1;
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      driver <= 9'b0;
   else if(init)
      driver <= 9'h1ff;
   else if(driver)
      driver <= driver - 9'h1;

   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      dqs <= 1'b0;
   else if(load)
      dqs <= 1'b1;
   else
      dqs <= 1'b0;

   reg [3:0] load_delay; // TODO: define length to match tWLO
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      load_delay <= 4'h0;
   else
      load_delay <= {load_delay[2:0], load};
   assign capture = load_delay[3];

   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      capture_delay <= 1'h0;
   else
      capture_delay <= capture && last_run;

endmodule
`ifndef SYNTHESIS
module tb;
`include "test.v"

   reg reset_n = 1'b0;
   reg clk = 1'b0;
   reg ck = 1'b0;
   wire ckd;
   parameter HALF_PERIOD = 100;
   always #HALF_PERIOD clk = ~clk;
//   always #(HALF_PERIOD + ($unsigned($random % 3))) ck = ~ck;
//   always #(HALF_PERIOD + $unsigned($random % 30)+1) ck = ~ck;
   always #(HALF_PERIOD*2) ck = ~ck;
   buf #(HALF_PERIOD-30) (ckd, ck);
   reg [1:0] clock_sel = 2'b0;
   reg dfi_wrlvl_resp = 1'bx;
   reg [3:0] rank_sel = 4'hx; // TODO: use it
   reg init = 1'b0;

   wire dqs;
   wire [3:0] coef;
   reg [15:0] dqs_delay;
// Note: delay can exceed period!?

   always@* #(0*HALF_PERIOD/8) dqs_delay[0] = dqs; // TODO: define how much PHY can move DQS
   always@* #(1*HALF_PERIOD/8) dqs_delay[1] = dqs;
   always@* #(2*HALF_PERIOD/8) dqs_delay[2] = dqs;
   always@* #(3*HALF_PERIOD/8) dqs_delay[3] = dqs;
   always@* #(4*HALF_PERIOD/8) dqs_delay[4] = dqs;
   always@* #(5*HALF_PERIOD/8) dqs_delay[5] = dqs;
   always@* #(6*HALF_PERIOD/8) dqs_delay[6] = dqs;
   always@* #(7*HALF_PERIOD/8) dqs_delay[7] = dqs;
   always@* #(8*HALF_PERIOD/8) dqs_delay[8] = dqs;
   always@* #(9*HALF_PERIOD/8) dqs_delay[9] = dqs;
   always@* #(10*HALF_PERIOD/8) dqs_delay[10] = dqs;
   always@* #(11*HALF_PERIOD/8) dqs_delay[11] = dqs;
   always@* #(12*HALF_PERIOD/8) dqs_delay[12] = dqs;
   always@* #(13*HALF_PERIOD/8) dqs_delay[13] = dqs;
   always@* #(14*HALF_PERIOD/8) dqs_delay[14] = dqs;
   always@* #(15*HALF_PERIOD/8) dqs_delay[15] = dqs;
/*
   always@* #(HALF_PERIOD/8) dqs_delay[0] = dqs;
   always@* #(HALF_PERIOD/8) dqs_delay[1] = dqs_delay[0];
   always@* #(HALF_PERIOD/8) dqs_delay[2] = dqs_delay[1];
   always@* #(HALF_PERIOD/8) dqs_delay[3] = dqs_delay[2];
   always@* #(HALF_PERIOD/8) dqs_delay[4] = dqs_delay[3];
   always@* #(HALF_PERIOD/8) dqs_delay[5] = dqs_delay[4];
   always@* #(HALF_PERIOD/8) dqs_delay[6] = dqs_delay[5];
   always@* #(HALF_PERIOD/8) dqs_delay[7] = dqs_delay[6];
   always@* #(HALF_PERIOD/8) dqs_delay[8] = dqs_delay[7];
   always@* #(HALF_PERIOD/8) dqs_delay[9] = dqs_delay[8];
   always@* #(HALF_PERIOD/8) dqs_delay[10] = dqs_delay[9];
   always@* #(HALF_PERIOD/8) dqs_delay[11] = dqs_delay[10];
   always@* #(HALF_PERIOD/8) dqs_delay[12] = dqs_delay[11];
   always@* #(HALF_PERIOD/8) dqs_delay[13] = dqs_delay[12];
   always@* #(HALF_PERIOD/8) dqs_delay[14] = dqs_delay[13];
   always@* #(HALF_PERIOD/8) dqs_delay[15] = dqs_delay[14];
*/
   wire dqs_cpt = dqs_delay[coef];

   always@(posedge dqs_cpt)
   // Note: #20 is tWLO emulation...
      dfi_wrlvl_resp <= #20 (clock_sel==2'b0 ? ck : clock_sel==2'b01 ? ckd : clock_sel==2'b10 ? ~ck : ~ckd);
   
   wire status;
   wire done;

   ehl_ddr_wrlvl_trng dut
   (
      .clk            ( clk            ),
      .reset_n        ( reset_n        ),
      .dfi_wrlvl_resp ( dfi_wrlvl_resp ),
      .rank_sel       ( rank_sel       ),
      .init           ( init           ),
      .dqs            ( dqs            ),
      .coef           ( coef           ),
      .done           ( done           ),
      .status         ( status         ),
      .result         (                ),
      .rv             (                )
   );

   initial
   begin
      TEST_TITLE("Write Leveling Check","ehl_ddr_wrlvl_trng_tb","Simple test");
      repeat(3) @(negedge clk);
      reset_n = 1'b1;
      repeat(3) @(negedge clk);
      TEST_INIT("Training");
      @(negedge clk) init = 1'b1;
      @(negedge clk) init = 1'b0;
      while(done !== 1'b1)
         @(negedge clk);
      if(status === 1'b1) test_pass = test_pass + 1;
      else $display("   Error: training completed with status FAILED at %0t.", $time);

      repeat(10) @(negedge clk);
      clock_sel = 2'b01;
      @(negedge clk) init = 1'b1;
      @(negedge clk) init = 1'b0;
      while(done !== 1'b1)
         @(negedge clk);
      if(status === 1'b1) test_pass = test_pass + 1;
      else $display("   Error: training completed with status FAILED at %0t.", $time);
      repeat(10) @(negedge clk);

      repeat(10) @(negedge clk);
      clock_sel = 2'b10;
      @(negedge clk) init = 1'b1;
      @(negedge clk) init = 1'b0;
      while(done !== 1'b1)
         @(negedge clk);
      if(status === 1'b0) test_pass = test_pass + 1;
      else $display("   Error: training completed with status PASSED at %0t.", $time);
      repeat(10) @(negedge clk);

      repeat(10) @(negedge clk);
      clock_sel = 2'b11;
      @(negedge clk) init = 1'b1;
      @(negedge clk) init = 1'b0;
      while(done !== 1'b1)
         @(negedge clk);
      if(status === 1'b0) test_pass = test_pass + 1;
      else $display("   Error: training completed with status PASSED at %0t.", $time);
      repeat(10) @(negedge clk);

      TEST_CHECK(4);
      TEST_SUMMARY;
   end

endmodule
`endif
