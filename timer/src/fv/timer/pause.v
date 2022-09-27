//===================================
// PAUSE test:
//         1.1. Launch timer
//         1.2. Pause, check timer is stable
//         1.3. Continue
//         1.4. Stop and check timer is stop
//
//         2.1. Pause timer at the same time as compare should toggle output - check no series of toggles generated
//
//         3.1. Pause timer and generate few CAPTURE pulses
//         3.2. Check no Captures made during this pause
//===================================
task PAUSE(input integer timer);
reg toggles;
begin
if($test$plusargs("PAUSE") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("PAUSE");
   $display("   Info: pause timer.");
      API_TIMER_SET_PERIOD(timer, 141);
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_TIMER(timer);
      API_TIMER_START(timer);
      // Note: expected value (here and after) is test dependent
      API_TIMER_GET_VALUE(timer, 1);
      API_TIMER_PAUSE(timer);
      API_TIMER_GET_VALUE(timer, 9);
      API_TIMER_GET_VALUE(timer, 9);
      API_TIMER_START(timer);
      API_TIMER_GET_VALUE(timer, 11);
      API_TIMER_STOP(timer);
      API_TIMER_GET_VALUE(timer, 19);
   $display("   Info: pause during COMPARE.");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_COMPARE(timer, `CHANNEL_0, `MATCH_INVERT);
      API_TIMER_SET_COMPARE_A_T0(timer, 100);
      API_TIMER_SET_COMPARE_A_T1(timer, 110);
      API_TIMER_START(timer);
      repeat(100-2) @(posedge dut.tmr_clk[timer]);
      if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #1 CMP_A expected to be 0 at %0t.", $time);
// TODO: be sure PAUSE and COMPARE are matched at this cycle
      toggles = 0;
      repeat(2) @(posedge dut.tmr_clk[timer]);
      fork
         begin
            API_TIMER_PAUSE(timer);
            repeat(4) @(posedge dut.tmr_clk[timer]);
         end
         begin
            repeat(5) @(posedge dut.tmr_clk[timer]) if(dut.cmp_out[0 + 3*timer] === 1'b1) toggles = 1;
         end
      join
      API_TIMER_START(timer);
      if(toggles === 1'b0) test_pass++; else $display("   Error: CMP_A toggles during pause.");
      repeat(8) @(posedge dut.tmr_clk[timer]);
      if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #2 CMP_A expected to be 1 at %0t.", $time);
      repeat(10) @(posedge dut.tmr_clk[timer]);
      if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #3 CMP_A expected to be 0 at %0t.", $time);
      repeat(84+1) @(posedge dut.tmr_clk[timer]);
      API_TIMER_STOP(timer);

      if(CPT_ENA[timer])
      begin
         $display("   Info: pause during CAPTURE.");
         cpt_in = 0;
         API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE, `CPT_START_NOW, `CPT_STOP_NONE);
         API_TIMER_START(timer);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         cpt_in = 1 << (1 + 2*timer);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         // Note: captured value
         API_TIMER_GET_CAPTURE(timer, 5);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         API_TIMER_PAUSE(timer);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         cpt_in = 0;
         repeat(4) @(posedge dut.tmr_clk[timer]);
         cpt_in = 1 << (1 + 2*timer);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         // Note: previous captured value expected, as "no capture during pause"
         API_TIMER_GET_CAPTURE(timer, 5);

         API_TIMER_START(timer);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         cpt_in = 0;
         repeat(4) @(posedge dut.tmr_clk[timer]);
         cpt_in = 1 << (1 + 2*timer);
         repeat(4) @(posedge dut.tmr_clk[timer]);
         API_TIMER_GET_CAPTURE(timer, 29);

         API_TIMER_STOP(timer);
         cpt_in = 0;
      end

   TEST_CHECK(5*(BUS_WIDTH==32 ? 1 : 4) + 4 + (CPT_ENA[timer] ? 3*(BUS_WIDTH==32 ? 1 : 4) : 0));
end
end
endtask
