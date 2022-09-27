//===================================
// CHAIN test:
//         1.1. Timer 1 set as compare generator on overflow
//         1.2. Timer 0 set in edge counting mode
//         1.3. Timer 0 generates IRQ when 10 input toggles detected
//         1.4. Timer 1 generates 10 IRQs during run

// TODO: make for capture as well !!! this one is for COUNTER!!!
//         1.1. Timer 1 set as compare generator on overflow
//         1.2. Timer 0 set as capture receiver of edges
//         1.3. Timer 0 generates IRQ when 10 input toggles detected
//         1.4. Timer 1 generates 10 IRQs during run
//===================================
task CHAIN/*(input integer timer)*/;
if($test$plusargs("CHAIN") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("CHAIN");
      API_TIMER_SET_TIMER(`TIMER_1);
      API_TIMER_SET_TIMER(`TIMER_0);
   $display("   Info: chain TIMER-1 to drive TIMER-0 in counting mode.");
   // setup compare generator - cyclic up to 255
      API_TIMER_SET_CYCLIC(`TIMER_1);
      API_TIMER_SET_INCR(`TIMER_1);
      API_TIMER_SET_PERIOD(`TIMER_1, 255);
      API_TIMER_SET_COMPARE(`TIMER_1, `CHANNEL_0, `MATCH_INVERT);
      API_TIMER_SET_COMPARE_A_T0(`TIMER_1, 255);
      API_TIMER_SET_COMPARE_A_T1(`TIMER_1, 255);
   // setup counter - oneshot up to 10
      API_TIMER_SET_ONESHOT(`TIMER_0);
      API_TIMER_SET_INCR(`TIMER_0);
      API_TIMER_SET_PERIOD(`TIMER_0, 10);
      API_TIMER_SET_COUNTER(`TIMER_0, 0, `CPT_ANY);
      API_TIMER_ENABLE_IRQ(3); // enable IRQ on counter overflow for both timers

      API_TIMER_START(`TIMER_1);
      API_TIMER_START(`TIMER_0);

      repeat(9)
      begin
         // Note: more cycles to include IRQ latency
         repeat(256+4) @(posedge dut.tmr_clk[`TIMER_0]);
         if(dut.irq === 1'b1) test_pass++; else $display("   Error: IRQ should be asserted at time %0t.", $time);
         API_TIMER_GET_IRQ(2);
         API_TIMER_CLEAR_IRQ(2); // timer 1 overflown
      end
      repeat(256) @(posedge dut.tmr_clk[`TIMER_0]);
      if(dut.irq === 1'b1) test_pass++; else $display("   Error: IRQ should be asserted at time %0t.", $time);
      API_TIMER_GET_IRQ(3);
      API_TIMER_CLEAR_IRQ(3); // timers 1,0 overflown
      API_TIMER_STOP(`TIMER_1);
      API_TIMER_STOP(`TIMER_0);

   $display("   Info: chain TIMER-1 to drive TIMER-0 to detect frequency ratio.");
   // setup compare generator - cyclic up to 16
      API_TIMER_SET_CYCLIC(`TIMER_1);
      API_TIMER_SET_INCR(`TIMER_1);
      API_TIMER_SET_PERIOD(`TIMER_1, 16);
      API_TIMER_SET_COMPARE(`TIMER_1, `CHANNEL_0, `MATCH_INVERT);
      API_TIMER_SET_COMPARE_A_T0(`TIMER_1, 16);
      API_TIMER_SET_COMPARE_A_T1(`TIMER_1, 255); // unused
   // setup capture receiver - oneshot up to 200, count 4 rising edges
      API_TIMER_SET_ONESHOT(`TIMER_0);
      API_TIMER_SET_INCR(`TIMER_0);
      API_TIMER_SET_PERIOD(`TIMER_0, 200);
      API_TIMER_SET_CAPTURE(`TIMER_0, 0, `CPT_RISE4, `CPT_START_RISE, `CPT_STOP_NONE);
      API_TIMER_ENABLE_IRQ(1 << 4); // enable IRQ on capture of timer 0

      API_TIMER_START(`TIMER_1);
      API_TIMER_START(`TIMER_0);

      repeat(200) @(posedge dut.tmr_clk[`TIMER_0]);
      API_TIMER_STOP(`TIMER_1);
      API_TIMER_STOP(`TIMER_0);

      if(dut.irq === 1'b1) test_pass++; else $display("   Error: IRQ should be asserted at time %0t.", $time);
      API_TIMER_GET_IRQ(16);
      API_TIMER_CLEAR_IRQ(16); // timer 0 capture overflown

      // Note: captured value = 100 + some gap
      API_TIMER_GET_CAPTURE(`TIMER_0, 102); // TODO: value can be not stable

   TEST_CHECK(10 + 10*(BUS_WIDTH==32 ? 1 : 2)  + 3 + (BUS_WIDTH==32 ? 1 : 4));
end
endtask
