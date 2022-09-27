//===================================
// SYNC_RUN test:
//         1. Prepare timers to be run; enable IRQ on completion
//         1.1. Punch timers one after another and check IRQ generated one after another
//         2. Repeat same, but punch all timers at the same time
//         2.1. Check IRQs generated at the same time (i.e. timers started synchronously)
//===================================
task SYNC_RUN;
if($test$plusargs("SYNC_RUN") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("SYNC_RUN");
   //----------------------------------
   // initialize timers
   //----------------------------------
      API_TIMER_ENABLE_IRQ(12'hf);

      API_TIMER_SET_PERIOD(0, 60);
      API_TIMER_SET_INCR(0);
      API_TIMER_SET_ONESHOT(0);

      if(NTIMERS > 1)
      begin
         API_TIMER_SET_PERIOD(1, 60);
         API_TIMER_SET_INCR(1);
         API_TIMER_SET_ONESHOT(1);
      end
      if(NTIMERS > 2)
      begin
         API_TIMER_SET_PERIOD(2, 60);
         API_TIMER_SET_INCR(2);
         API_TIMER_SET_ONESHOT(2);
      end
      if(NTIMERS > 3)
      begin
         API_TIMER_SET_PERIOD(3, 60);
         API_TIMER_SET_INCR(3);
         API_TIMER_SET_ONESHOT(3);
      end
   //----------------------------------
   // start
   // Note: add delay between PUNCH to have time to read IRQ back
   //----------------------------------
      API_TIMER_START(0);
      if(NTIMERS > 1) API_TIMER_START(1);
      if(NTIMERS > 2) API_TIMER_START(2);
      if(NTIMERS > 3) API_TIMER_START(3);
   //----------------------------------
   // collect IRQs
   //----------------------------------
      wait(dut.irq === 1'b1);
      API_TIMER_GET_IRQ(1);
      if(NTIMERS > 1) API_TIMER_GET_IRQ(3);
      if(NTIMERS > 2) API_TIMER_GET_IRQ(7);
      if(NTIMERS > 3) API_TIMER_GET_IRQ(15);
      repeat(10)@(negedge clk);
      API_TIMER_CLEAR_IRQ(15);
      repeat(10)@(negedge clk);
   //----------------------------------
   // start all timers
   //----------------------------------
      API_TIMER_CTRL_ALL('h55);
      wait(dut.irq === 1'b1);
      API_TIMER_GET_IRQ(3);

      API_TIMER_DISABLE_IRQ;
      API_TIMER_CLEAR_IRQ(15);
      repeat(100) @(negedge clk);

   TEST_CHECK((NTIMERS+1)*(BUS_WIDTH==32 ? 1 : 2));
end
endtask
