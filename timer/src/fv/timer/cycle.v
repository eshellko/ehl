//===================================
// CYCLE test:
//         1. run timer in cyclic mode + enable interrupts on completion
//         2. check interrupts generated periodically
//===================================
task CYCLE(input integer timer);
if($test$plusargs("CYCLE") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("CYCLE");
   $display("   Info: run timer in a cyclic mode with periodically generated interrupts.");
// TODO: run same for few timers at the same time...
      API_TIMER_SET_TIMER(timer);
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_PERIOD(timer, 250);

      API_TIMER_ENABLE_IRQ(1 << timer);

      API_TIMER_START(timer);
      fork
         repeat(4000) @(posedge dut.tmr_clk[timer]);

         begin
            repeat(4) @(posedge dut.tmr_clk[timer]); // initial offset
            repeat(15)
            begin
               // Note: IRQ handling creates offset at every cycle. Thus IRQs became longer and longer.
               repeat(250) @(posedge dut.tmr_clk[timer]);
               if(dut.irq === 1'b1) test_pass++; else $display("   Error: interrupt expected at time %0t.", $time);
               API_TIMER_CLEAR_IRQ(1 << timer);
            end
         end
      join
      API_TIMER_STOP(timer);

   TEST_CHECK(15);
end
endtask
