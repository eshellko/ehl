//===================================
// PWM test:
//         1. Set PWM mode for 3 outputs with different WIDTH
//         2. Check output waveform matches requirements
//===================================
task PWM(input integer timer);
if($test$plusargs("PWM") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("PWM");
      API_TIMER_SET_PERIOD(timer, 120); // period

   $display("   Info: 33%% PWM");
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_PWM(timer, `CHANNEL_0 | `CHANNEL_1 | `CHANNEL_2);
      API_TIMER_SET_COMPARE_A_T0(timer, 0);
      API_TIMER_SET_COMPARE_A_T1(timer, 40);
      API_TIMER_SET_COMPARE_B_T0(timer, 10);
      API_TIMER_SET_COMPARE_B_T1(timer, 50);
      API_TIMER_SET_COMPARE_C_T0(timer, 1);
      API_TIMER_SET_COMPARE_C_T1(timer, 41);

      API_TIMER_SET_DEADTIME(timer, 0);

      API_TIMER_START(timer);
      fork
         repeat(560) @(posedge dut.tmr_clk[timer]);
         begin
            repeat(4) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_A expected to be 1 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_C expected to be 1 at %0t.", $time);
            repeat(10) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_A expected to be 1 at %0t.", $time);            if(dut.cmp_out[1+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_B expected to be 1 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_C expected to be 1 at %0t.", $time);
            repeat(32) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_B expected to be 1 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_C expected to be 0 at %0t.", $time);
            repeat(10) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_C expected to be 0 at %0t.", $time);
         end
      join
      API_TIMER_STOP(timer);

   $display("   Info: 33%% PWM (decrement)");
      API_TIMER_SET_DECR(timer);
      API_TIMER_START(timer);
      fork
         repeat(560) @(posedge dut.tmr_clk[timer]);
         begin
            repeat(4) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_C expected to be 0 at %0t.", $time);
            repeat(70) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_B expected to be 1 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_C expected to be 0 at %0t.", $time);
            repeat(10) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_A expected to be 1 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_B expected to be 1 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_C expected to be 1 at %0t.", $time);
         end
      join
      API_TIMER_STOP(timer);

      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_COMPARE_A_T0(timer, 1);
      API_TIMER_SET_COMPARE_A_T1(timer, 119);
      API_TIMER_SET_COMPARE_B_T0(timer, 22);
      API_TIMER_SET_COMPARE_B_T1(timer, 118);
      API_TIMER_SET_COMPARE_C_T0(timer, 3);
      API_TIMER_SET_COMPARE_C_T1(timer, 117);
      API_TIMER_START(timer);
      repeat(560) @(posedge dut.tmr_clk[timer]);
      API_TIMER_STOP(timer);

      // inverted polarity
      API_TIMER_SET_DECR(timer);
      API_TIMER_SET_COMPARE_A_T0(timer, 0);
      API_TIMER_SET_COMPARE_A_T1(timer, 100);
      API_TIMER_SET_COMPARE_B_T0(timer, 0);
      API_TIMER_SET_COMPARE_B_T1(timer, 100);
      API_TIMER_SET_COMPARE_C_T0(timer, 0);
      API_TIMER_SET_COMPARE_C_T1(timer, 100);
      API_TIMER_START(timer);
      fork
         repeat(560) @(posedge dut.tmr_clk[timer]);
         begin
            repeat(4) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_C expected to be 0 at %0t.", $time);
            repeat(20) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_A expected to be 1 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_B expected to be 1 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_C expected to be 1 at %0t.", $time);
            repeat(100) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
            if(dut.cmp_out[2+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_C expected to be 0 at %0t.", $time);
         end
      join
      API_TIMER_STOP(timer);

   $display("   Info: inverted PWM channels");
      API_TIMER_SET_PRESCALER(timer, 8'd12);
      API_TIMER_SET_PWM(timer, `CHANNEL_0 | `CHANNEL_1);
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_COMPARE_A_T0(timer, 0);
      API_TIMER_SET_COMPARE_A_T1(timer, 40);
      API_TIMER_SET_COMPARE_B_T0(timer, 41);
      API_TIMER_SET_COMPARE_B_T1(timer, 120);
      API_TIMER_START(timer);
      fork
         repeat(5600) @(posedge dut.tmr_clk[timer]);
         begin
            repeat(4*13) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_A expected to be 1 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
            repeat(40*13) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_A expected to be 0 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_B expected to be 1 at %0t.", $time);
            repeat(80*13) @(posedge dut.tmr_clk[timer]);
            if(dut.cmp_out[0+3*timer] === 1'b1) test_pass++; else $display("   Error: PWM_A expected to be 1 at %0t.", $time);
            if(dut.cmp_out[1+3*timer] === 1'b0) test_pass++; else $display("   Error: PWM_B expected to be 0 at %0t.", $time);
         end
      join
   $display("   Info: enable channel on the fly");
      API_TIMER_SET_COMPARE_C_T0(timer, 21);
      API_TIMER_SET_COMPARE_C_T1(timer, 24);
      API_TIMER_SET_PWM(timer, `CHANNEL_0 | `CHANNEL_1 | `CHANNEL_2);
      repeat(5600) @(posedge dut.tmr_clk[timer]);
// TODO: resync to PERIOD start... and check channel is turned ON
      API_TIMER_STOP(timer);

   $display("   Info: complementary PWM"); // TODO: compare outputs
      API_TIMER_PWM_COMP_ENA(timer);
      API_TIMER_SET_CYCLIC(timer);
      API_TIMER_SET_INCR(timer); // TODO: DECR
      API_TIMER_SET_PWM(timer, `CHANNEL_0 | `CHANNEL_1 | `CHANNEL_2);
      API_TIMER_SET_DEADTIME(timer, 4); // TODO: test without deadtime...
      API_TIMER_SET_COMPARE_A_T0(timer, 10); // TODO: test at boundary
      API_TIMER_SET_COMPARE_A_T1(timer, 40);
      API_TIMER_SET_COMPARE_B_T0(timer, 20);
      API_TIMER_SET_COMPARE_B_T1(timer, 50);
      API_TIMER_SET_COMPARE_C_T0(timer, 30);
      API_TIMER_SET_COMPARE_C_T1(timer, 60);
      API_TIMER_SET_PERIOD(timer, 100); // period
      API_TIMER_SET_PRESCALER(timer, 8'd6);
      API_TIMER_START(timer);

      repeat(5600) @(posedge dut.tmr_clk[timer]);

   $display("   Info: disable complementary PWM"); // TODO: implement check...
      API_TIMER_PWM_COMP_DISA(timer); // Note: not synced write...
      repeat(5600) @(posedge dut.tmr_clk[timer]);

      API_TIMER_STOP(timer);
      API_TIMER_SET_DEADTIME(timer, 0);
      API_TIMER_SET_PRESCALER(timer, 8'd0);

   TEST_CHECK(3*4 + 3*3 + 3*3 + 3*2);
end
endtask
