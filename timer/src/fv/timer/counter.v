//===================================
// COUNTER test:
//         1. Set timer in counter mode for channel 0
//         2. Externally generate few impulses and stop
//         3. Check counter value
//===================================
task COUNTER(input integer timer);
if($test$plusargs("COUNTER") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("COUNTER");
// TODO: do we need input filter on capture?
// TODO: test overflow of counters...

   $display("   Info: count rising edges @ channel 0.");
      @(negedge clk) cpt_in = 0;
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_PERIOD(timer, 255);

      API_TIMER_SET_COUNTER(timer, 0, `CPT_RISE); // channel 0
      API_TIMER_START(timer);

      @(negedge clk) cpt_in[0 + 2*timer] = 1;
      repeat(4) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 0;
      repeat(4) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 1;
      repeat(4) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 0;
      repeat(14) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 1;
      repeat(3) @(posedge clk);

      API_TIMER_STOP(timer);
      // Note: timer value = 3
      API_TIMER_GET_VALUE(timer, 3);
   $display("   Info: count rising edges @ channel 0.");
      API_TIMER_SET_COUNTER(timer, 0, `CPT_FALL); // channel 0
      API_TIMER_START(timer);

      @(negedge clk) cpt_in[0 + 2*timer] = 0;
      repeat(4) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 1;
      repeat(4) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 0;
      repeat(14) @(posedge clk);
      @(negedge clk) cpt_in[0 + 2*timer] = 1;
      repeat(3) @(posedge clk);
      API_TIMER_STOP(timer);
      // Note: timer value = 2
      API_TIMER_GET_VALUE(timer, 2);

   $display("   Info: count any edges @ channel 1.");
      API_TIMER_SET_COUNTER(timer, 1, `CPT_ANY); // channel 1
      API_TIMER_START(timer);

      repeat(4) @(posedge clk);
      // Note: data changed at negedge few cycles in a row - in reality such pulses will be asynchronous and can be filtered away - limitation to pulse duration is required
      @(negedge clk) cpt_in[1 + 2*timer] = 1;
      @(negedge clk) cpt_in[1 + 2*timer] = 0;
      @(negedge clk) cpt_in[1 + 2*timer] = 1;
      @(negedge clk) cpt_in[1 + 2*timer] = 0;
      repeat(14) @(posedge clk);
      @(negedge clk) cpt_in[1 + 2*timer] = 1;
      repeat(3) @(posedge clk);
      API_TIMER_STOP(timer);
      // Note: timer value = 5
      API_TIMER_GET_VALUE(timer, 5);

      cpt_in = 0;
   TEST_CHECK(3*(BUS_WIDTH==8 ? 4 : 1));
end
endtask
