//===================================
// ONESHOT test:
//         1. LOAD different count values (0, 1, 18, MAX, MAX-18)
//         2.1. run in INCR / DECR modes
//         2.2. run in CYCLIC / ONESHOT modes
//         3. checks that counter stops after 1 round if in ONESHOT mode, and continues when in CYCLE mode
//===================================
// TODO: add few runs with random values of interval... get some kind of coverage...
task ONESHOT(input integer timer);
if($test$plusargs("ONESHOT") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("ONESHOT");
   //----------------------------------
   // decrementor
   //----------------------------------
   API_TIMER_SET_DECR(timer);
   $display("   Info: run decrement timer in one-shot mode (value 0x0).");
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, 0); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h0);

   $display("   Info: run decrement timer in cyclic mode (value 0x0).");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_PERIOD(timer, 0); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 0, 32'h1);
      CHECK_CTRL_VAL(timer, 4, 32'h1);
      API_TIMER_STOP(timer);
      CHECK_CTRL_VAL(timer, 4, 32'h0);

   $display("   Info: run decrement timer in one-shot mode (value 0x1).");
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, 1); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 0, 32'h1);
      CHECK_CTRL_VAL(timer, 4, 32'h0);

   $display("   Info: run decrement timer in cyclic mode (value 0x1).");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_PERIOD(timer, 1); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 0, 32'h1);
      API_TIMER_STOP(timer);
      CHECK_CTRL_VAL(timer, 4, 32'h0);

   $display("   Info: run decrement timer in one-shot mode (value 0x12).");
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, 18); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 0, 32'h1);
      CHECK_CTRL_VAL(timer, 18+4, 32'h0);

   $display("   Info: run decrement timer in cyclic mode (value 0x12).");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_PERIOD(timer, 18); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 18+4, 32'h1);
      API_TIMER_STOP(timer);
      CHECK_CTRL_VAL(timer, 18+4, 32'h0);
   //----------------------------------
   // incremetor
   //----------------------------------
   API_TIMER_SET_INCR(timer);
   $display("   Info: run increment timer in one-shot mode (value 0x0).");
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, 0); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h0);

   $display("   Info: run increment timer in cyclic mode (value 0x0).");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_PERIOD(timer, 0); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h1);
      API_TIMER_STOP(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h0);

   $display("   Info: run increment timer in one-shot mode (value -0x1).");
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, {TIMER_WIDTH{1'b1}}); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h1);
`ifndef ICARUS
// Note: too long run on Icarus
      CHECK_CTRL_VAL(timer, {TIMER_WIDTH{1'b1}}, 32'h0);
`else
      API_TIMER_STOP(timer); // stop timer to not wait too much
`endif

   $display("   Info: run increment timer in cyclic mode (value -0x1).");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_PERIOD(timer, {TIMER_WIDTH{1'b1}}); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h1);
`ifndef ICARUS
// Note: too long run on Icarus
      CHECK_CTRL_VAL(timer, {TIMER_WIDTH{1'b1}}, 32'h1);
`endif
      API_TIMER_STOP(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h0);

   $display("   Info: run increment timer in one-shot mode (value -0x12).");
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, {TIMER_WIDTH{1'b1}} - 18); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h1);
`ifndef ICARUS
// Note: too long run on Icarus
      CHECK_CTRL_VAL(timer, {TIMER_WIDTH{1'b1}}-10, 32'h0);
`else
      API_TIMER_STOP(timer); // stop timer to not wait too much
`endif

   $display("   Info: run increment timer in cyclic mode (value -0x12).");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_PERIOD(timer, {TIMER_WIDTH{1'b1}} - 18); // write data
      API_TIMER_START(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h1);
`ifndef ICARUS
// Note: too long run on Icarus
      CHECK_CTRL_VAL(timer, {TIMER_WIDTH{1'b1}}-10, 32'h0);
`endif
      API_TIMER_STOP(timer);
      CHECK_CTRL_VAL(timer, 5, 32'h0);

`ifdef ICARUS
   TEST_CHECK(1 + 3 + 2*2 + 2*2   + 1+2+1+2+1+2);
`else
   TEST_CHECK(1 + 3 + 2*2 + 2*2   + 1+2+2+3+2+3);
`endif
end
endtask

task CHECK_CTRL_VAL(input integer timer, input integer unsigned dly, input integer exp);
reg [31:0] unsigned_dly;
begin
   unsigned_dly = dly; // Note: signed input can be resolved as negative, so convert it into negative
   if(unsigned_dly[31])
   begin
      repeat(unsigned_dly[30:0]) @(posedge dut.tmr_clk[timer]);
      repeat(32'h80000000) @(posedge dut.tmr_clk[timer]);
   end
   else
      repeat(unsigned_dly) @(posedge dut.tmr_clk[timer]);
   API_TIMER_GET_CTRL(timer);
   if(rdata_cpt/*[0]*/ === exp) test_pass = test_pass + 1;
   else $display("   Error: incorrect CTRL value 0x%x (exp 0x%x) at time %0t.", rdata_cpt, exp, $time);
end
endtask
