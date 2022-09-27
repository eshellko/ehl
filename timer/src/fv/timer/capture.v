//===================================
// CAPTURE test:
//         1. for capture mode check that no capture event generated and timer waits for start when timer expired with no START event
//
//         2. for capture mode check that no capture event generated and timer stop when timer expired with START event, but no capture event
//
//         3. For every supported capture mode (rise, fall, edge) run capture check
//         3.1. enable interrupt, generate event
//         3.2.1. check event captured inside register
//         3.2.2. check interrupt generated
//===================================
task CAPTURE(input integer timer);
if($test$plusargs("CAPTURE") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("CAPTURE");
      $display("   Info: [CAPTURE.1]");
      cpt_in = 0;
      API_TIMER_SET_PERIOD(timer, 4); // write data
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE, `CPT_START_RISE, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(500) @(posedge clk); // no START event, timer should be inactive (ENA + TMR_VAL = 0, TMR_CPT = previous)
      // Note: timer still enabled (CTRL.ENA=1)
      API_TIMER_GET_CTRL(timer); if(rdata_cpt[0] === 1'b1) test_pass++; else $display("   Error: CTRL.ENA expected to be 1.");
      // Note: timer value = 0
      API_TIMER_GET_VALUE(timer, 0);
      API_TIMER_STOP(timer);

      $display("   Info: [CAPTURE.2]");
      cpt_in = 0;
      API_TIMER_SET_PERIOD(timer, 4); // write data
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE, `CPT_START_RISE, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(20)@(negedge clk); cpt_in = 2 << (2*timer); // START
      repeat(20)@(negedge clk); cpt_in = 0;
      repeat(100) @(posedge clk); // no CAPTURE event, timer should be inactive (!ENA + TMR_VAL = 0, TMR_CPT = previous)
      // Note: timer disabled (CTRL.ENA=0) due to expiration
      API_TIMER_GET_CTRL(timer); if(rdata_cpt[0] === 1'b0) test_pass++; else $display("   Error: CTRL.ENA expected to be 0.");
      // Note: timer value = 0
      API_TIMER_GET_VALUE(timer, 0);
      // Note: stop timer just in case -- it should be already stop
      API_TIMER_STOP(timer);


      API_TIMER_SET_PERIOD(timer, 40000); // write data
      API_TIMER_SET_INCR(timer);
      $display("   Info: capture rise->rise starting from rise");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE, `CPT_START_RISE, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(20)@(negedge clk); cpt_in = 2 << (2*timer); // START
      repeat(20)@(negedge clk); cpt_in = 0;
      repeat(300)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(20)@(negedge clk); cpt_in = 0;
      repeat(20)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE - ignored
      repeat(20)@(negedge clk); cpt_in = 0;
      // Note: captured value = 20 + 300 -- BUG: timer will overflown for 8-bit mode...
      API_TIMER_GET_CAPTURE(timer, 320);
      API_TIMER_STOP(timer);

      $display("   Info: capture rise->rise starting from now");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE, `CPT_START_NOW, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(20)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(30)@(posedge clk);
      API_TIMER_STOP(timer);
      // Note: captured value = 20 + 1 CDC cycle
      API_TIMER_GET_CAPTURE(timer, 21);

      $display("   Info: capture any starting from fall stop at any");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_ANY, `CPT_START_FALL, `CPT_STOP_ANY);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(14)@(negedge clk); cpt_in = 0; // START
      repeat(15)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(16)@(negedge clk); cpt_in = 0; // CAPTURE
      repeat(17)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(18)@(posedge clk);
      // Note: captured value = 15
      API_TIMER_GET_CAPTURE(timer, 15);
      API_TIMER_STOP(timer);

      $display("   Info: capture RISE starting from fall stop at RISE");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE, `CPT_START_FALL, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(14)@(negedge clk); cpt_in = 0; // START
      repeat(7)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(21)@(negedge clk); cpt_in = 0;
      repeat(44)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(18)@(posedge clk);
      // Note: captured value = 7
      API_TIMER_GET_CAPTURE(timer, 7);
      API_TIMER_STOP(timer);

      $display("   Info: capture FALL starting from fall stop at FALL");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_FALL, `CPT_START_FALL, `CPT_STOP_FALL);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(14)@(negedge clk); cpt_in = 0; // START
      repeat(15)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(16)@(negedge clk); cpt_in = 0; // CAPTURE
      repeat(17)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(18)@(posedge clk);
      // Note: captured value = 15 + 16
      API_TIMER_GET_CAPTURE(timer, 31);
      API_TIMER_STOP(timer);

      $display("   Info: capture 4-th RISE starting from fall stop at RISE - stopped before capture...");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE4, `CPT_START_FALL, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(14)@(negedge clk); cpt_in = 0; // START
      repeat(15)@(negedge clk); cpt_in = 2 << (2*timer); // STOP
      repeat(16)@(negedge clk); cpt_in = 0;
      repeat(17)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(18)@(posedge clk);
      // Note: captured value from previous subtest
      API_TIMER_GET_CAPTURE(timer, 31);
      API_TIMER_STOP(timer);

      $display("   Info: capture 4-th RISE starting from fall");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE4, `CPT_START_FALL, `CPT_STOP_NONE);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer);
      repeat(14)@(negedge clk); cpt_in = 0; // START
      repeat(15)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
      repeat(16)@(negedge clk); cpt_in = 0;
      repeat(17)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
      repeat(18)@(negedge clk); cpt_in = 0;
      repeat(21)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
      repeat(22)@(negedge clk); cpt_in = 0;
      repeat(23)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(24)@(negedge clk); cpt_in = 0;
      fork
         begin
            repeat(25)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
            repeat(26)@(negedge clk); cpt_in = 0;
            repeat(27)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
            repeat(28)@(negedge clk); cpt_in = 0;
            repeat(29)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
            repeat(30)@(negedge clk); cpt_in = 0;
            repeat(31)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
            repeat(32)@(negedge clk); cpt_in = 0;
            repeat(33)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE (filtered)
            repeat(34)@(negedge clk); cpt_in = 0;
            repeat(35)@(posedge clk);
         end
         // Note: captured value = 15 + 16 + 17 + 18 + 21 + 22 + 23
         API_TIMER_GET_CAPTURE(timer, 132);
      join
      // Note: captured value = 15 + 16 + 17 + 18 + 21 + 22 + 23 + 24 + 25 + 26 + 27 + 28 + 29 + 30 + 31
      API_TIMER_GET_CAPTURE(timer, 352);
      API_TIMER_STOP(timer);

      $display("   Info: get signal period - Start and Stop at RISE, and capture at RISE-4 - no capture expected and result in CUR_VAL");
      cpt_in = 0;
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE4, `CPT_START_RISE, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer); // START
      repeat(14)@(negedge clk); cpt_in = 0;
      repeat(15)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(16)@(negedge clk); cpt_in = 0;
      repeat(18)@(posedge clk);
      API_TIMER_GET_VALUE(timer, 29);
      API_TIMER_STOP(timer);

      $display("   Info: period calculation - overflow timer");
      cpt_in = 0;
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_ENABLE_IRQ(12'h1 << timer); // enable IRQ on timer expired
      API_TIMER_SET_PERIOD(timer, 141);
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_RISE4, `CPT_START_RISE, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer); // START
      repeat(14)@(negedge clk); cpt_in = 0;
      // TIMER overflown here
      repeat(150)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(18)@(posedge clk);
      API_TIMER_STOP(0);
      API_TIMER_GET_VALUE(timer, 141);
      if(dut.irq === 1'b1) test_pass++; else $display("   Error: IRQ should be asserted.");
      API_TIMER_CLEAR_IRQ(12'h1 << timer);
      if(dut.irq === 1'b0) test_pass++; else $display("   Error: IRQ should be cleared.");
      API_TIMER_DISABLE_IRQ;

      $display("   Info: porosity calculation");
      cpt_in = 0;
      API_TIMER_SET_ONESHOT(timer);
      API_TIMER_SET_PERIOD(timer, 255);
      API_TIMER_SET_CAPTURE(timer, 1, `CPT_FALL, `CPT_START_RISE, `CPT_STOP_RISE);
      API_TIMER_START(timer);
      repeat(13)@(negedge clk); cpt_in = 2 << (2*timer); // START
      repeat(14)@(negedge clk); cpt_in = 0; // period...
      repeat(150)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(18)@(posedge clk);
      API_TIMER_GET_VALUE(timer, 164); // PERIOD
      API_TIMER_GET_CAPTURE(timer, 14); // HIGH
      API_TIMER_STOP(timer);

// STARTED with active 1 - initial 1->0 filtered and not captured into TMRx_CPT
      API_TIMER_START(timer);
      repeat(21)@(negedge clk); cpt_in = 0;
      repeat(12)@(negedge clk); cpt_in = 2 << (2*timer); // START
      repeat(53)@(negedge clk); cpt_in = 0; // period...
      repeat(70)@(negedge clk); cpt_in = 2 << (2*timer); // CAPTURE
      repeat(18)@(posedge clk);
      API_TIMER_STOP(timer);
      API_TIMER_GET_VALUE(timer, 123); // PERIOD
      API_TIMER_GET_CAPTURE(timer, 53); // HIGH

   TEST_CHECK(2 * (1 + (BUS_WIDTH==8 ? 4 : 1)) + 13 * (BUS_WIDTH==8 ? 4 : 1) + (2 + (BUS_WIDTH==8 ? 4 : 1)));
end
endtask
