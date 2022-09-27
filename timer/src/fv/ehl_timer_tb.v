// Design:           Timer
// Revision:         1.0
// Date:             2013-04-16
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: -

// Test plan:
//   - for every bus 8 and 32
//   - for every timer independently, and cumulatively (1-4 configurations)
//   - for every timer width (8, 16, 24, 32, 64, 80) -- at least 16, 32 at the moment...

`timescale 1ns/100ps
module ehl_timer_tb;
`include "test.v"
// 32-bit mode registers
`define CFG(IDX)      (IDX*64 + 6'b0000_00)
`define CTRL(IDX)     (IDX*64 + 6'b0001_00)
`define CTRL_ALL(IDX) (IDX*64 + 6'b0010_00)
`define DEAD(IDX)     (IDX*64 + 6'b0011_00)
`define LOAD(IDX)     (IDX*64 + 6'b0100_00)
`define PRE(IDX)      (IDX*64 + 6'b0101_00)
`define VALUE(IDX)    (IDX*64 + 6'b0110_00)
`define CPT(IDX)      (IDX*64 + 6'b0111_00)
`define IRQ_CTRL(IDX) (IDX*64 + 6'b1000_00)
`define IRQ_FLAG(IDX) (IDX*64 + 6'b1001_00)
`define CMPA_T0(IDX)  (IDX*64 + 6'b1010_00)
`define CMPA_T1(IDX)  (IDX*64 + 6'b1011_00)
`define CMPB_T0(IDX)  (IDX*64 + 6'b1100_00)
`define CMPB_T1(IDX)  (IDX*64 + 6'b1101_00)
`define CMPC_T0(IDX)  (IDX*64 + 6'b1110_00)
`define CMPC_T1(IDX)  (IDX*64 + 6'b1111_00)
// 8-bit mode registers
`define CFG8(IDX,BIT)      (IDX*64 + 6'b0000_00 + BIT)
`define CTRL8(IDX,BIT)     (IDX*64 + 6'b0001_00 + BIT)
`define CTRL_ALL8(IDX,BIT) (IDX*64 + 6'b0010_00 + BIT)
`define DEAD8(IDX,BIT)     (IDX*64 + 6'b0011_00 + BIT)
`define LOAD8(IDX,BIT)     (IDX*64 + 6'b0100_00 + BIT)
`define PRE8(IDX,BIT)      (IDX*64 + 6'b0101_00 + BIT)
`define VALUE8(IDX,BIT)    (IDX*64 + 6'b0110_00 + BIT)
`define CPT8(IDX,BIT)      (IDX*64 + 6'b0111_00 + BIT)
`define IRQ_CTRL8(IDX,BIT) (IDX*64 + 6'b1000_00 + BIT)
`define IRQ_FLAG8(IDX,BIT) (IDX*64 + 6'b1001_00 + BIT)
`define CMPA_T08(IDX,BIT)  (IDX*64 + 6'b1010_00 + BIT)
`define CMPA_T18(IDX,BIT)  (IDX*64 + 6'b1011_00 + BIT)
`define CMPB_T08(IDX,BIT)  (IDX*64 + 6'b1100_00 + BIT)
`define CMPB_T18(IDX,BIT)  (IDX*64 + 6'b1101_00 + BIT)
`define CMPC_T08(IDX,BIT)  (IDX*64 + 6'b1110_00 + BIT)
`define CMPC_T18(IDX,BIT)  (IDX*64 + 6'b1111_00 + BIT)

`define TIMER_0 0
`define TIMER_1 1
`define TIMER_2 2
`define TIMER_3 3
//
// compare
//
`define CHANNEL_0 3'b001
`define CHANNEL_1 3'b010
`define CHANNEL_2 3'b100

`define MATCH_SET 2'b00
`define MATCH_CLEAR 2'b01
`define MATCH_INVERT 2'b10
//
// capture
//
`define CPT_RISE   0
`define CPT_FALL   1
`define CPT_RISE4  2
`define CPT_ANY    3

`define CPT_START_NOW    0
`define CPT_START_RISE   1
`define CPT_START_FALL   2
`define CPT_START_ANY    3

`define CPT_STOP_NONE   0
`define CPT_STOP_RISE   1
`define CPT_STOP_FALL   2
`define CPT_STOP_ANY    3

   parameter BUS_WIDTH = 32;
   parameter TIMER_WIDTH = 32;
   parameter NTIMERS = 1*2;
   parameter CPT_ENA = 4'b000_1;
   parameter CMP_ENA = 4'b0001 | 4'b0010;
   parameter PWM_ENA = 4'b0001;

   parameter half_period=10;
   parameter delay=3;
   reg reset_n, clk, wr;
   reg [7:0] addr;
   reg [BUS_WIDTH-1:0] din;

   reg [BUS_WIDTH-1:0] rdata_cpt;

   integer i, j;

   reg  [2*NTIMERS-1:0] cpt_in = 0;
   wire [3*NTIMERS-1:0] cmp_out;

   always #half_period clk=~clk;

   ehl_timer
   #(
      .BUS_WIDTH   ( BUS_WIDTH   ),
      .TIMER_WIDTH ( TIMER_WIDTH ),
      .NTIMERS     ( NTIMERS     ),
.SYNC_MODE(1),
      .PWM_ENA     ( PWM_ENA     ),
      .CPT_ENA     ( CPT_ENA     ),
      .CMP_ENA     ( CMP_ENA     )
   ) dut
   (
      .clk       ( clk     ),
      .reset_n   ( reset_n ),
.tmr_clk     ( {NTIMERS{clk}}     ),
.tmr_reset_n ( {NTIMERS{reset_n}} ),
      .wr        ( wr      ),
      .addr      ( addr    ),
      .din       ( din     ),
      .dout      (         ),
      .irq       (         ),
      .test_mode ( 1'b0    ),
      .cpt_in    ( cpt_in  ),
      .cmp_out   (         ),
      .cmp_out_n (         )
   );

always@* cpt_in[0] = dut.cmp_out[3];

   `include "oneshot.v"
   `include "capture.v"
   `include "compare.v"
//    `include "csr_access.v"
   `include "cycle.v"
   `include "counter.v"
   `include "chain.v"
   `include "pwm.v"
   `include "pause.v"
   `include "irq.v"
   `include "sync_run.v"

   initial
   begin
      TEST_TITLE("Check timer functionality", "ehl_timer_tb.v", "basic test");
      #0 reset_n=0; clk=0; test_pass=0; tests_success=0; tests_num=0;
      wr=0; addr=0; din=0;
      #3 TEST_REPORT_NON_INIT;
//       CSR_ACCESS;

      ONESHOT(`TIMER_0);
      if(NTIMERS > 1) ONESHOT(`TIMER_1);
      if(NTIMERS > 2) ONESHOT(`TIMER_2);
      if(NTIMERS > 3) ONESHOT(`TIMER_3);

      if(CPT_ENA[0]) CAPTURE(`TIMER_0);
      if(NTIMERS > 1 && CPT_ENA[1]) CAPTURE(`TIMER_1);
      if(NTIMERS > 2 && CPT_ENA[2]) CAPTURE(`TIMER_2);
      if(NTIMERS > 3 && CPT_ENA[3]) CAPTURE(`TIMER_3);

      if(CMP_ENA[0]) COMPARE(`TIMER_0);
      if(NTIMERS > 1 && CMP_ENA[1]) COMPARE(`TIMER_1);
      if(NTIMERS > 2 && CMP_ENA[2]) COMPARE(`TIMER_2);
      if(NTIMERS > 3 && CMP_ENA[3]) COMPARE(`TIMER_3);

      if(CPT_ENA[0]) COUNTER(`TIMER_0);
      if(NTIMERS > 1 && CPT_ENA[1]) COUNTER(`TIMER_1);
      if(NTIMERS > 2 && CPT_ENA[2]) COUNTER(`TIMER_2);
      if(NTIMERS > 3 && CPT_ENA[3]) COUNTER(`TIMER_3);

      CYCLE(`TIMER_0);
      if(NTIMERS > 1) CYCLE(`TIMER_1);
      if(NTIMERS > 2) CYCLE(`TIMER_2);
      if(NTIMERS > 3) CYCLE(`TIMER_3);

      CHAIN;

      if(PWM_ENA[0]) PWM(`TIMER_0);
      if(NTIMERS > 1 && PWM_ENA[1]) PWM(`TIMER_1);
      if(NTIMERS > 2 && PWM_ENA[2]) PWM(`TIMER_2);
      if(NTIMERS > 3 && PWM_ENA[3]) PWM(`TIMER_3);

      if(CMP_ENA[0]) IRQ(`TIMER_0);
      if(NTIMERS > 1 && CMP_ENA[1]) IRQ(`TIMER_1);
      if(NTIMERS > 2 && CMP_ENA[2]) IRQ(`TIMER_2);
      if(NTIMERS > 3 && CMP_ENA[3]) IRQ(`TIMER_3);

      PAUSE(`TIMER_0);
      if(NTIMERS > 1) PAUSE(`TIMER_1);
      if(NTIMERS > 2) PAUSE(`TIMER_2);
      if(NTIMERS > 3) PAUSE(`TIMER_3);

      SYNC_RUN;

      #3 TEST_REPORT_NON_INIT;
      TEST_SUMMARY;
   end

   task TEST_REPORT_NON_INIT;
   begin
   TEST_INIT("REPORT_NON_INIT");
      reset_n = 0;
      #delay;
      if(dut.irq === 1'b0) test_pass++; else $display("   Error: IRQ should be cleared after reset.");
      if(dut.cmp_out === 0) test_pass++; else $display("   Error: CMP_OUT should be cleared after reset.");
`ifdef __none__
      $ehl_report_uninitialized(ehl_timer_tb.dut);
`endif
      #delay reset_n = 1;
   TEST_CHECK(2);
   end
   endtask

   task WRITE_REG(input reg [7:0] tadr, input reg [BUS_WIDTH-1:0] tdata);
   begin
      @(negedge clk) wr = 1; din = tdata; addr = tadr;
      @(negedge clk) wr = 0;
   end
   endtask

   task READ_REG(input reg [7:0] tadr);
   begin
      @(negedge clk) addr = tadr;
      @(negedge clk) rdata_cpt = dut.dout; // BUG: TODO: align to specified byte position in 32-bit mode
   end
   endtask

//--------------------------------------------
// APIs
//--------------------------------------------
   `include "api.v"

endmodule
