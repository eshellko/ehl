//===================================
// COMPARE test:
//         1. Set period and ranges (2 of them, or only T0)
//         2. Run comparison
//         3.1. Observe compare output
//===================================
task COMPARE(input integer timer);
reg toggles;
begin
if($test$plusargs("COMPARE") || $test$plusargs("EHLTIMER_ALL"))
begin
   TEST_INIT("COMPARE");
      API_TIMER_SET_INCR(timer);
      API_TIMER_SET_CYCLIC(timer);
// TODO: compare waveform for ASYNC mode...
// TODO: check with prescaler
// TODO: check LOAD=40 and COMPARE=40 but timer not enabled -- will output toggle only when enabled timer...?

   $display("   Info: compare match at inactive timer.");

   $display("   Info: invert output inside cycle twice.");
      API_TIMER_SET_PERIOD(timer, 200);
      API_TIMER_SET_COMPARE(timer, `CHANNEL_0, `MATCH_INVERT);
      API_TIMER_SET_COMPARE_A_T0(timer, 100);
      // Note: COMPARE register value 0 matches inactive timer value - check there is no toggles at the output
      toggles = 0;
      fork
         begin
            API_TIMER_SET_COMPARE_A_T0(timer, 0);
            repeat(40) @(posedge dut.tmr_clk[timer]);
         end
         begin
            repeat(5) @(posedge dut.tmr_clk[timer]) if(dut.cmp_out[0 + 3*timer] === 1'b1) toggles = 1;
         end
      join
      if(toggles === 1'b0) test_pass++; else $display("   Error: CMP_A toggles during pause.");

      API_TIMER_SET_COMPARE_A_T1(timer, 110);
      API_TIMER_SET_COMPARE_A_T0(timer, 100);
      fork
         begin
            API_TIMER_START(timer);
            repeat(1000) @(posedge dut.tmr_clk[timer]);
         end
         begin
         // Note: start can be run different number of cycles, so use gap for check - 4 cycles
            repeat(5)
            begin
               repeat(100-2) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #1 CMP_A expected to be 0 at %0t.", $time);
               repeat(8) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #2 CMP_A expected to be 1 at %0t.", $time);
               repeat(10) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #3 CMP_A expected to be 0 at %0t.", $time);
               repeat(84+1) @(posedge dut.tmr_clk[timer]);
            end
         end
      join
      API_TIMER_STOP(timer);

   $display("   Info: invert output once inside cycle.");
      API_TIMER_SET_COMPARE_A_T1(timer, 201);
      fork
         begin
            API_TIMER_START(timer);
            repeat(1200) @(posedge dut.tmr_clk[timer]);
         end
         begin
            repeat(3)
            begin
               repeat(100-2) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #4 CMP_A expected to be 0 at %0t.", $time);
               repeat(8) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #5 CMP_A expected to be 1 at %0t.", $time);
               repeat(94+1) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #6 CMP_A expected to be 1 at %0t.", $time);

               repeat(100-2) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #7 CMP_A expected to be 1 at %0t.", $time);
               repeat(8) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #8 CMP_A expected to be 0 at %0t.", $time);
               repeat(94+1) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #9 CMP_A expected to be 0 at %0t.", $time);
            end
         end
      join
      API_TIMER_STOP(timer);

   for(j=0; j<2; j=j+1)
   begin
      API_TIMER_SET_ONESHOT(timer);

      $display("   Info: set outputs on match.");
      API_TIMER_SET_COMPARE(timer, `CHANNEL_0 | `CHANNEL_1 | `CHANNEL_2, `MATCH_SET);
      API_TIMER_SET_PERIOD(timer, 40);
      API_TIMER_SET_COMPARE_A_T0(timer, 17);
      API_TIMER_SET_COMPARE_A_T1(timer, 18);
      API_TIMER_SET_COMPARE_B_T0(timer, 22);
      API_TIMER_SET_COMPARE_B_T1(timer, 23);
      API_TIMER_SET_COMPARE_C_T0(timer, 39);
      API_TIMER_SET_COMPARE_C_T1(timer, 39);
      fork
         begin
            API_TIMER_START(timer);
            repeat(300) @(posedge dut.tmr_clk[timer]);
         end
         begin
         // Note: 1-st run in incremental mode; 2-nd run in decremental mode - thus order of events is changed
            if(j == 0)
            begin
               repeat(16) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #10 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #11 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #12 CMP_C expected to be 0 at %0t.", $time);
               repeat(6) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #13 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #14 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #15 CMP_C expected to be 0 at %0t.", $time);
               repeat(5) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #16 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #17 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #18 CMP_C expected to be 0 at %0t.", $time);
               repeat(17) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #19 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #20 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #21 CMP_C expected to be 1 at %0t.", $time);
               repeat(100) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #22 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #23 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #24 CMP_C expected to be 1 at %0t.", $time);
            end
            else
            begin
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #25 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #26 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #27 CMP_C expected to be 0 at %0t.", $time);
               repeat(6) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #28 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #29 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #30 CMP_C expected to be 1 at %0t.", $time);
               repeat(16) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #31 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #32 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #33 CMP_C expected to be 1 at %0t.", $time);
               repeat(5) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #34 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #35 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #36 CMP_C expected to be 1 at %0t.", $time);
               repeat(100) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #37 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #38 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #39 CMP_C expected to be 1 at %0t.", $time);
            end
         end
      join

      $display("   Info: clear outputs on match.");
      API_TIMER_SET_COMPARE(timer, `CHANNEL_0 | `CHANNEL_1 | `CHANNEL_2, `MATCH_CLEAR);
      API_TIMER_SET_PERIOD(timer, 40);
      API_TIMER_SET_COMPARE_A_T0(timer, 35);
      API_TIMER_SET_COMPARE_A_T1(timer, 35);
      API_TIMER_SET_COMPARE_B_T0(timer, 12);
      API_TIMER_SET_COMPARE_B_T1(timer, 12);
      API_TIMER_SET_COMPARE_C_T0(timer, 34);
      API_TIMER_SET_COMPARE_C_T1(timer, 33);
      fork
         begin
            API_TIMER_START(timer);
            repeat(300) @(posedge dut.tmr_clk[timer]);
         end
         begin
         // Note: 1-st run in incremental mode; 2-nd run in decremental mode - thus order of events is changed
            if(j == 0)
            begin
               repeat(12) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #40 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #41 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #42 CMP_C expected to be 1 at %0t.", $time);
               repeat(6) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #43 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #44 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #45 CMP_C expected to be 1 at %0t.", $time);
               repeat(21) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #46 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #47 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #48 CMP_C expected to be 0 at %0t.", $time);
               repeat(2) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #49 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #50 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #51 CMP_C expected to be 0 at %0t.", $time);
               repeat(100) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #52 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #53 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #54 CMP_C expected to be 0 at %0t.", $time);
            end
            else
            begin
               if(dut.cmp_out[0 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #55 CMP_A expected to be 1 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #56 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #57 CMP_C expected to be 1 at %0t.", $time);
               repeat(10) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #58 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #59 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #60 CMP_C expected to be 1 at %0t.", $time);
               repeat(11) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #61 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b1) test_pass++; else $display("   Error: #62 CMP_B expected to be 1 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #63 CMP_C expected to be 0 at %0t.", $time);
               repeat(22) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #64 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #65 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #66 CMP_C expected to be 0 at %0t.", $time);
               repeat(100) @(posedge dut.tmr_clk[timer]);
               if(dut.cmp_out[0 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #67 CMP_A expected to be 0 at %0t.", $time);
               if(dut.cmp_out[1 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #68 CMP_B expected to be 0 at %0t.", $time);
               if(dut.cmp_out[2 + 3*timer] === 1'b0) test_pass++; else $display("   Error: #69 CMP_C expected to be 0 at %0t.", $time);
            end
         end
      join

      API_TIMER_SET_DECR(timer); // Note: 2nd iteration on DECR mode
   end

   TEST_CHECK(1 + 5*3 + 6*3 + 2*5*3*2);
end
end
endtask
