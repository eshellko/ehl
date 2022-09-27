//===================================
// IRQ test:
//         1.1. Setup IRQ on COMPARE event
//         1.2. Launch timer
//         1.3. get IRQ
//
//         2.1. divide clock
//         2.2. generate IRQ and clear it on faster clock domain
//         2.3. check IRQ is not re-assigned
//===================================
task IRQ(input integer timer);
if($test$plusargs("IRQ") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("IRQ");
   $display("   Info: IRQ generation on compare.");
      API_TIMER_SET_PERIOD(timer, 80);
      API_TIMER_SET_COMPARE_A_T0(timer, 40);
      API_TIMER_SET_COMPARE_A_T1(timer, 70);
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_COMPARE(timer, `CHANNEL_0, `MATCH_INVERT); // TODO: cross with event type, cross with all output channels
      API_TIMER_ENABLE_IRQ(1 << (8+timer));
      API_TIMER_START(timer);

      repeat(35) @(posedge dut.tmr_clk[timer]);
      API_TIMER_GET_IRQ(0);

      repeat(10) @(posedge dut.tmr_clk[timer]);
      API_TIMER_GET_IRQ(1 << (8+timer));
      API_TIMER_CLEAR_IRQ(1 << (8+timer));
      API_TIMER_GET_IRQ(0);

      repeat(30) @(posedge dut.tmr_clk[timer]);
      API_TIMER_GET_IRQ(1 << (8+timer));
      API_TIMER_CLEAR_IRQ(1 << (8+timer));
      API_TIMER_GET_IRQ(0);

      API_TIMER_STOP(timer);
      API_TIMER_DISABLE_IRQ;

// TODO: assert IRQ on slow clock -- clear it, while there is no next cycle - i.e. IRQ source is still active at slow clock
   $display("   Info: IRQ clear on divided clock.");
      API_TIMER_SET_PRESCALER(timer, 100);
      API_TIMER_ENABLE_IRQ(1 << timer);
      API_TIMER_SET_PERIOD(timer, 10);
      API_TIMER_SET_TIMER(timer);
      API_TIMER_START(timer);

      repeat(101*11+100) @(posedge dut.tmr_clk[timer]);
      API_TIMER_GET_IRQ(1 << timer);
      API_TIMER_CLEAR_IRQ(1 << timer);
      API_TIMER_GET_IRQ(0);

      API_TIMER_SET_PRESCALER(timer, 0);
      API_TIMER_DISABLE_IRQ;

   TEST_CHECK(7 * (BUS_WIDTH==32 ? 1 : 2));
end
endtask
