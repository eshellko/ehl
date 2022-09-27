//--------------------------------------------
// APIs
//--------------------------------------------
   task API_TIMER_SET_PERIOD(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`LOAD8(timer, 0), value[7:0]);
         WRITE_REG(`LOAD8(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`LOAD8(timer, 2), value[23:16]);
         WRITE_REG(`LOAD8(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`LOAD(timer), value);
      end
   end
   endtask

   task API_TIMER_SET_DEADTIME(input integer timer, input [TIMER_WIDTH-1:0] value); // TODO: register API
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`DEAD8(timer, 0), value[7:0]);
         WRITE_REG(`DEAD8(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`DEAD8(timer, 2), value[23:16]);
         WRITE_REG(`DEAD8(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`DEAD(timer), value);
      end
   end
   endtask

   task API_TIMER_SET_COMPARE_A_T0(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CMPA_T08(timer, 0), value[7:0]);
         WRITE_REG(`CMPA_T08(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`CMPA_T08(timer, 2), value[23:16]);
         WRITE_REG(`CMPA_T08(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CMPA_T0(timer), value);
      end
   end
   endtask
   task API_TIMER_SET_COMPARE_A_T1(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CMPA_T18(timer, 0), value[7:0]);
         WRITE_REG(`CMPA_T18(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`CMPA_T18(timer, 2), value[23:16]);
         WRITE_REG(`CMPA_T18(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CMPA_T1(timer), value);
      end
   end
   endtask
   task API_TIMER_SET_COMPARE_B_T0(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CMPB_T08(timer, 0), value[7:0]);
         WRITE_REG(`CMPB_T08(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`CMPB_T08(timer, 2), value[23:16]);
         WRITE_REG(`CMPB_T08(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CMPB_T0(timer), value);
      end
   end
   endtask
   task API_TIMER_SET_COMPARE_B_T1(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CMPB_T18(timer, 0), value[7:0]);
         WRITE_REG(`CMPB_T18(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`CMPB_T18(timer, 2), value[23:16]);
         WRITE_REG(`CMPB_T18(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CMPB_T1(timer), value);
      end
   end
   endtask
   task API_TIMER_SET_COMPARE_C_T0(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CMPC_T08(timer, 0), value[7:0]);
         WRITE_REG(`CMPC_T08(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`CMPC_T08(timer, 2), value[23:16]);
         WRITE_REG(`CMPC_T08(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CMPC_T0(timer), value);
      end
   end
   endtask
   task API_TIMER_SET_COMPARE_C_T1(input integer timer, input [TIMER_WIDTH-1:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CMPC_T18(timer, 0), value[7:0]);
         WRITE_REG(`CMPC_T18(timer, 1), value[15:8]); // TODO: check for narrower timers...
         WRITE_REG(`CMPC_T18(timer, 2), value[23:16]);
         WRITE_REG(`CMPC_T18(timer, 3), value[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CMPC_T1(timer), value);
      end
   end
   endtask
/*
   // Note: clear 'CMP_EN' for few cycles with TMR_MODE=COMPARE
   task API_TIMER_CLEAR_CMP(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CFG8(timer, 0), 2);
         WRITE_REG(`CFG8(timer, 0), 0);
      end
      else if(BUS_WIDTH == 32)
      begin
         WRITE_REG(`CFG(timer), 2);
         WRITE_REG(`CFG(timer), 0);
      end
   end
   endtask
*/
   task API_TIMER_SET_ONESHOT(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CFG8(timer, 2));
         WRITE_REG(`CFG8(timer, 2), rdata_cpt | 8'h2);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt | 32'h20000);
      end
   end
   endtask

   task API_TIMER_SET_CYCLIC(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CFG8(timer, 2));
         WRITE_REG(`CFG8(timer, 2), rdata_cpt & 8'hFD);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt & 32'hFFFDFFFF);
      end
   end
   endtask

   task API_TIMER_PWM_COMP_ENA(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CFG8(timer, 2));
         WRITE_REG(`CFG8(timer, 2), rdata_cpt | 8'h4);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt | 32'h40000);
      end
   end
   endtask

   task API_TIMER_PWM_COMP_DISA(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CFG8(timer, 2));
         WRITE_REG(`CFG8(timer, 2), rdata_cpt & 8'hFB);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt & 32'hFFFBFFFF);
      end
   end
   endtask

   task API_TIMER_SET_INCR(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CFG8(timer, 2));
         WRITE_REG(`CFG8(timer, 2), rdata_cpt | 8'h1);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt | 32'h10000);
      end
   end
   endtask

   task API_TIMER_SET_DECR(input integer timer);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CFG8(timer, 2));
         WRITE_REG(`CFG8(timer, 2), rdata_cpt & 8'hFE);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt & 32'hFFFEFFFF);
      end
   end
   endtask

   task API_TIMER_SET_COMPARE(input integer timer, input [2:0] channel_en, input [1:0] cmp_mode);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CFG8(timer, 0), 2 | (channel_en << 3) | (cmp_mode << 6));
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), (rdata_cpt & 32'hFFFFFF00) | 2 | (channel_en << 3) | (cmp_mode << 6));
      end
   end
   endtask

   task API_TIMER_SET_PWM(input integer timer, input [2:0] channel_en);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CFG8(timer, 0), 3 | (channel_en << 3));
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), (rdata_cpt & 32'hFFFFFF00) | 3 | (channel_en << 3));
      end
   end
   endtask

   task API_TIMER_SET_COUNTER(input integer timer, input channel, input [1:0] ttype);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CFG8(timer, 0), 4);
         WRITE_REG(`CFG8(timer, 1), channel | (ttype << 1));
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), (rdata_cpt & 32'hFFFFF800) | 4 | (channel << 8) | (ttype << 9));
      end
   end
   endtask

   task API_TIMER_SET_CAPTURE(input integer timer, input channel, input [1:0] ttype, input [1:0] start, input [1:0] stop);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`CFG8(timer, 0), 1);
         WRITE_REG(`CFG8(timer, 1), channel | (ttype << 1) | (start << 3) | (stop << 5));
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), (rdata_cpt & 32'hFFFF00F8) | 1 | (channel << 8) | (ttype << 9) | (start << 11) | (stop << 13));
      end
   end
   endtask

   task API_TIMER_SET_TIMER(input integer timer);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CFG8(timer, 0), 0);
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CFG(timer));
         WRITE_REG(`CFG(timer), rdata_cpt & 32'hFFFFFF00);
      end
   end
   endtask


   task API_TIMER_SET_PRESCALER(input integer timer, input [7:0] value);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`PRE8(timer, 0), value);
      else if(BUS_WIDTH == 32)
         WRITE_REG(`PRE(timer), value);
   end
   endtask


   task API_TIMER_GET_VALUE(input integer timer, input integer exp);
   begin
      if(BUS_WIDTH == 8) // TODO: if timer == 32...
      begin
         READ_REG(`VALUE8(timer, 0));
         if(rdata_cpt === exp[7:0]) test_pass++; else $display("   Error: incorrect value %d read from VALUE (exp. %d).", rdata_cpt, exp[7:0]);
         READ_REG(`VALUE8(timer, 1));
         if(rdata_cpt === exp[15:8]) test_pass++; else $display("   Error: incorrect value %d read from VALUE (exp. %d).", rdata_cpt, exp[15:8]);
         READ_REG(`VALUE8(timer, 2));
         if(rdata_cpt === exp[23:16]) test_pass++; else $display("   Error: incorrect value %d read from VALUE (exp. %d).", rdata_cpt, exp[23:16]);
         READ_REG(`VALUE8(timer, 3));
         if(rdata_cpt === exp[31:24]) test_pass++; else $display("   Error: incorrect value %d read from VALUE (exp. %d).", rdata_cpt, exp[31:24]);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`VALUE(timer));
         if(rdata_cpt === exp) test_pass++; else $display("   Error: incorrect value %d read from VALUE (exp. %d).", rdata_cpt, exp);
      end
   end
   endtask

   task API_TIMER_GET_CAPTURE(input integer timer, input integer exp);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`CPT8(timer, 0));
         if(rdata_cpt === exp[7:0]) test_pass++; else $display("   Error: incorrect value %d read from CPT (exp. %d) at %0t.", rdata_cpt, exp[7:0], $time);
         READ_REG(`CPT8(timer, 1));
         if(rdata_cpt === exp[15:8]) test_pass++; else $display("   Error: incorrect value %d read from CPT (exp. %d) at %0t.", rdata_cpt, exp[15:8], $time);
         READ_REG(`CPT8(timer, 2));
         if(rdata_cpt === exp[23:16]) test_pass++; else $display("   Error: incorrect value %d read from CPT (exp. %d) at %0t.", rdata_cpt, exp[23:16], $time);
         READ_REG(`CPT8(timer, 3));
         if(rdata_cpt === exp[31:24]) test_pass++; else $display("   Error: incorrect value %d read from CPT (exp. %d) at %0t.", rdata_cpt, exp[31:24], $time);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`CPT(timer));
         if(rdata_cpt === exp) test_pass++; else $display("   Error: incorrect value %d read from CPT (exp. %d).", rdata_cpt, exp);
      end
   end
   endtask


   task API_TIMER_GET_CTRL(input integer timer);
   begin
      if(BUS_WIDTH == 8)
         READ_REG(`CTRL8(timer, 0)); // TODO: all 4 bytes...
      else if(BUS_WIDTH == 32)
         READ_REG(`CTRL(timer));
   end
   endtask

   task API_TIMER_START(input integer timer);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CTRL8(timer,0), 1);
      else if(BUS_WIDTH == 32)
         WRITE_REG(`CTRL(timer), 1);
   end
   endtask

   task API_TIMER_STOP(input integer timer);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CTRL8(timer,0), 0);
      else if(BUS_WIDTH == 32)
         WRITE_REG(`CTRL(timer), 0);
   end
   endtask

   task API_TIMER_PAUSE(input integer timer);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CTRL8(timer,0), 3);
      else if(BUS_WIDTH == 32)
         WRITE_REG(`CTRL(timer), 3);
   end
   endtask

   task API_TIMER_CTRL_ALL(input [7:0] value);
   begin
      if(BUS_WIDTH == 8)
         WRITE_REG(`CTRL_ALL8(0,0), value);
      else if(BUS_WIDTH == 32)
         WRITE_REG(`CTRL_ALL(0), value);
   end
   endtask
//
// Interrupt routines
//
   task API_TIMER_DISABLE_IRQ;
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`IRQ_CTRL8(0,0), 0);
         WRITE_REG(`IRQ_CTRL8(0,1), 0);
      end
      else if(BUS_WIDTH == 32)
         WRITE_REG(`IRQ_CTRL(0), 0);
   end
   endtask

   task API_TIMER_ENABLE_IRQ(input [11:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`IRQ_CTRL8(0,0), value[7:0]);
         WRITE_REG(`IRQ_CTRL8(0,1), value[11:8]);
      end
      else if(BUS_WIDTH == 32)
         WRITE_REG(`IRQ_CTRL(0), value);
   end
   endtask

   task API_TIMER_CLEAR_IRQ(input [11:0] value);
   begin
      if(BUS_WIDTH == 8)
      begin
         WRITE_REG(`IRQ_FLAG8(0,0), value[7:0]);
         WRITE_REG(`IRQ_FLAG8(0,1), value[11:8]);
      end
      else if(BUS_WIDTH == 32)
         WRITE_REG(`IRQ_FLAG(0), value);
   end
   endtask

   task API_TIMER_GET_IRQ(input integer exp);
   begin
      if(BUS_WIDTH == 8)
      begin
         READ_REG(`IRQ_FLAG8(0, 0));
         if(rdata_cpt === exp[7:0]) test_pass++; else $display("   Error: incorrect value %d read from IRQ_FLAG at %0t (exp. %d).", rdata_cpt, $time, exp[7:0]);
         READ_REG(`IRQ_FLAG8(0, 1));
         if(rdata_cpt === exp[15:8]) test_pass++; else $display("   Error: incorrect value %d read from IRQ_FLAG (exp. %d).", rdata_cpt, exp[15:8]);
      end
      else if(BUS_WIDTH == 32)
      begin
         READ_REG(`IRQ_FLAG(0));
         if(rdata_cpt === exp) test_pass++; else $display("   Error: incorrect value %d read from IRQ_FLAG (exp. %d).", rdata_cpt, exp);
      end
   end
   endtask
