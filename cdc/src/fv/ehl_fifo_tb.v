// Design:           FIFO testbench
// Revision:         1.1
// Date:             2013-12-19
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0. 2011-07-11 A.Kornukhin: initial release
//                   1.1. 2013-12-19 A.Kornukhin: default directives
//                        added for regression control; tasks.v included
`timescale 1ns/100ps

// TODO: update tests with *almost*

module ehl_fifo_tb;
//DUT parameters
   parameter WIDTH_DIN  = 32,
             WIDTH_DOUT = 32,
             USE_DPRAM  = 0,
             DEPTH      = 16,
             SYNC_STAGE = 2;
//timing parameters
   parameter HALF_PERIOD_POP  = 65;
   integer   HALF_PERIOD_PUSH = 65;
   parameter delay=3;
//generated parameters
   parameter FIFO_WIDTH = WIDTH_DIN>WIDTH_DOUT ? WIDTH_DOUT : WIDTH_DIN;

   parameter FIFO_CNT = WIDTH_DIN<WIDTH_DOUT ? WIDTH_DOUT/WIDTH_DIN :
      WIDTH_DIN>WIDTH_DOUT ? WIDTH_DIN/WIDTH_DOUT : 1;
   parameter FIFO_DEPTH = WIDTH_DIN<=WIDTH_DOUT ? DEPTH/FIFO_CNT : DEPTH;

   parameter WRMX = WIDTH_DIN>WIDTH_DOUT ? FIFO_DEPTH*WIDTH_DOUT/WIDTH_DIN : DEPTH;
   parameter RDMX = DEPTH*WIDTH_DIN/WIDTH_DOUT;

   wire signed [31:0] HALF_PERIOD = HALF_PERIOD_POP>HALF_PERIOD_PUSH ? HALF_PERIOD_POP : HALF_PERIOD_PUSH;
   `include "test.v"

   reg res, wclk, rclk;
   integer i, j, fill, fill_wr, fill_rd;
   integer test_fail_toggle;

   reg wr, rd, clr_of, clr_uf;
   reg [WIDTH_DIN-1:0] d_wr;
   wire [WIDTH_DOUT-1:0] d_rd;
   wire w_full, r_full, w_empty, r_empty, overflow, underflow;
   // Note: signals that shows delay for full / empty flags for higher SYNC_STAGE
//    if(1)
//    begin
//       reg w_full, r_empty;
//       always@(posedge wclk) w_full <= dut.w_full;
//       always@(posedge rclk) r_empty <= dut.r_empty;
//       wire w_fullw, r_emptyw;
//       assign w_fullw = w_full;
//       assign r_emptyw = r_empty;
//       if(1)
//       begin
//          reg w_full, r_empty;
//          always@(posedge wclk) w_full <= w_fullw;
//          always@(posedge rclk) r_empty <= r_emptyw;
//       end
//    end
//====================================
//
// CRC calculated for Write data
// Write bit counter incremented
//
// CRC calculated for Read data
// Read bit counter incremented
//
// At the end of the test
// Read and Write CRCs and counters
// compared to make decision
// about test success
//
//====================================
   reg [31:0] WCRC32 = 32'h0;
   reg [31:0] RCRC32 = 32'h0;
   reg [31:0] WBCNT = 32'h0;
   reg [31:0] RBCNT = 32'h0;
   always@(posedge wclk)
   if(wr & !w_full)
   begin
      WBCNT <= WBCNT + WIDTH_DIN;
      for(i=0;i<WIDTH_DIN;i=i+1)
         WCRC32 = nextCRC32_D1(d_wr[i],WCRC32);
   end

   // Note: DPRAM adds extra cycle of latency
   reg rd_delayed = 1'b0;
   if(USE_DPRAM)
      always@(posedge rclk)
         rd_delayed <= rd & !r_empty;
   else
      always@*
         rd_delayed = rd & !r_empty;

   always@(posedge rclk)
   if(rd_delayed)
   begin
      RBCNT <= RBCNT + WIDTH_DOUT;
      for(j=0;j<WIDTH_DOUT;j=j+1)
         RCRC32 = nextCRC32_D1(d_rd[j],RCRC32);
   end

   always #HALF_PERIOD_PUSH wclk=~wclk;
   always #HALF_PERIOD_POP rclk=~rclk;

   wire w_afull;
   wire r_afull;
   wire r_aempty;
   wire w_aempty;
   reg w_afull_delay;
   reg r_afull_delay;
   reg r_aempty_delay;
   reg w_aempty_delay;
   reg w_full_delay;
   reg r_full_delay;
   reg r_empty_delay;
   reg w_empty_delay;
   always@(posedge wclk) w_afull_delay <= w_afull;
   always@(posedge wclk) w_aempty_delay <= w_aempty;
   always@(posedge rclk) r_afull_delay <= r_afull;
   always@(posedge rclk) r_aempty_delay <= r_aempty;
   always@(posedge wclk) w_full_delay <= w_full;
   always@(posedge wclk) w_empty_delay <= w_empty;
   always@(posedge rclk) r_full_delay <= r_full;
   always@(posedge rclk) r_empty_delay <= r_empty;

// Buffer section
   reg [2*WIDTH_DIN*DEPTH-1:0] TX;
//   localparam WC_WIDTH = 1 + $clog2(WIDTH_DIN<=WIDTH_DOUT ? DEPTH/(WIDTH_DOUT/WIDTH_DIN) : DEPTH);
   localparam WC_WIDTH = 1 + $clog2(WIDTH_DIN<=WIDTH_DOUT ? DEPTH : DEPTH*(WIDTH_DOUT/WIDTH_DIN));
   wire [WC_WIDTH - 1:0] write_credit;


`ifdef __netlist
   ehl_fifo_WIDTH_DIN8_WIDTH_DOUT8_DEPTH8_SYNC_STAGE2
`else
   ehl_fifo #(
      .WIDTH_DIN  ( WIDTH_DIN  ),
      .WIDTH_DOUT ( WIDTH_DOUT ),
      .USE_DPRAM  ( USE_DPRAM  ),
      .DEPTH      ( DEPTH      ),
      .SYNC_STAGE ( SYNC_STAGE )
   )
`endif
   dut(
      .wclk         ( wclk         ),
      .rclk         ( rclk         ),
      .w_reset_n    ( res          ),
      .r_reset_n    ( res          ),
      .wr           ( wr           ),
      .rd           ( rd           ),
      .clr_of       ( clr_of       ),
      .clr_uf       ( clr_uf       ),
      .wdat         ( d_wr         ),
      .rdat         ( d_rd         ),
      .w_full       ( w_full       ),
      .r_full       ( r_full       ),
      .r_empty      ( r_empty      ),
      .w_empty      ( w_empty      ),
      .w_afull      ( w_afull      ),
      .r_afull      ( r_afull      ),
      .r_aempty     ( r_aempty     ),
      .w_aempty     ( w_aempty     ),
      .w_overflow   ( overflow     ),
      .r_underflow  ( underflow    ),
      .write_credit ( write_credit )
   );

// Note: this assertion should be false all the time
`ifdef __ehl_assert__
   always@(posedge wclk) assert property(write_credit <= {1'b1, {WC_WIDTH-1{1'b0}}});
`else
   always@(posedge wclk)
   if(write_credit > {1'b1, {WC_WIDTH-1{1'b0}}})
      $display("   Error: write credit value %d exceed allowed limit %d.", write_credit, {1'b1, {WC_WIDTH-1{1'b0}}});
`endif

   initial
   begin
      repeat(2000000) @(posedge wclk); // Note: wait for long time and stops the test
      TEST_INIT("SIMULATION-HANG");
      TEST_CHECK(1);
      TEST_SUMMARY;
   end

   initial
   begin
      TEST_TITLE("EHL FIFO IP Core","global test","global test");
      #0 res=0; wclk=0; rclk=0; test_pass=0; tests_success=0; tests_num=0;
      clr_of=0; clr_uf=0; test_fail_toggle=0;   d_wr=0; wr=0; rd=0;
      $display("FIFO TEST STARTED WITH FOLLOWING PARAMETERS:");
      $display("WIDTH_DIN        = %0d",WIDTH_DIN);
      $display("WIDTH_DOUT       = %0d",WIDTH_DOUT);
      $display("DEPTH            = %0d",DEPTH);
      $display("DPRAM            = %0d",USE_DPRAM);
      $display("SYNC_STAGE       = %0d",SYNC_STAGE);
      $display("delay            = %0d",delay);

      TEST_1;//TEST 1. Initial outputs test.
      #delay res=1;

      TEST_PROGRAM(4*HALF_PERIOD_POP+3);
      TEST_PROGRAM(2*HALF_PERIOD_POP);
      TEST_PROGRAM(HALF_PERIOD_POP+1);
      TEST_PROGRAM(HALF_PERIOD_POP);
      TEST_PROGRAM(HALF_PERIOD_POP-1);
      TEST_PROGRAM(HALF_PERIOD_POP/2);
      TEST_PROGRAM(HALF_PERIOD_POP/3);

      #(2*HALF_PERIOD) res=0;
      TEST_1;//TEST 8. Reset test.
      TEST_SUMMARY;
   end

   task TEST_PROGRAM(input integer push);
   begin
      HALF_PERIOD_PUSH = push;
      $display("   Info: run test with PUSH(%0d) and POP(%0d).", HALF_PERIOD_PUSH, HALF_PERIOD_POP);

      TEST_BURST_RW;
      TEST_SINGLE_RW;
      TEST_4;//TEST 4. Simultaneously Write/Read FIFO.
      TEST_OVERFLOW;//TEST 5. Overflow test.
      TEST_UNDERFLOW;//TEST 6. Underflow test.
      TEST_ALMOST;
      TOGGLE_AT_EMPTY;
      TEST_7;//TEST 7. CRC final check.
   end
   endtask

   task TEST_1;
   begin
      TEST_INIT("TEST-1");
      if(
         //We don't use RESET at the buffer because routing is expensive
         //dut.d_rd==={WIDTH_DOUT{1'b0}} &&
         dut.w_full===1'b0 &&
         dut.r_full===1'b0 &&
         dut.w_empty===1'b1 &&
         dut.r_empty===1'b1 &&
         dut.w_overflow===1'b0 &&
         dut.r_underflow===1'b0
      )
         test_pass=test_pass+1;
      TEST_CHECK(1);
   end
   endtask

   task TEST_BURST_RW;
   begin
      TEST_INIT("Burst RW");
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd5); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd1); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd2); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd3); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd4); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd0); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd6); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd7); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd8); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      #(2*HALF_PERIOD_POP) FillTXBuffer(4'd9); WriteBurst; CheckFull(1'b1); ReadBurst; CheckEmpty(1'b1); CheckFull(1'b0);
      TEST_CHECK(10*3);
   end
   endtask

   task TEST_SINGLE_RW;
   integer y, u;
   begin
      TEST_INIT("Single RW");
      for(y=0;y<6;y=y+1)
      begin
         repeat(WRMX)
         begin
            FillTXBuffer(y[3:0]);
            WriteSingle;
         end
         #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
         while(!r_empty)
            ReadSingle;
         #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
         for(u=10;u<16;u=u+1)
         begin
            while(!w_full)
            begin
               FillTXBuffer(u[3:0]);
               WriteSingle;
            end
            #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
            while(!r_empty)
               ReadSingle;
            #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
         end
      end
      TEST_CHECK(0);
   end
   endtask

/////////TEST 4. Simultaneously access for Read and Write.
   integer random;

   task TEST_4;
   begin
      TEST_INIT("Mixed Read/Write");
      fork
         begin
            @(negedge wclk);// #delay;
            repeat(FIFO_DEPTH*4)
            begin
               if(!w_full)
               begin
                  wr <= 1;
                  random = $time;
                  d_wr <= random;
                  @(negedge wclk) wr<=0;
               end
            end
         end
         begin
            repeat(FIFO_DEPTH*4)
            begin
               @(posedge rclk);
               if(!r_empty)
               begin
                  rd<=1;
                  @(posedge rclk) rd<=0;
                  @(posedge rclk);
               end
            end
         end
      join
      TEST_CHECK(0);
   end
   endtask
//=============================================
   task TEST_OVERFLOW;
   begin
      TEST_INIT("Overflow");
      while(!r_empty)//flush_buffer
         ReadSingle;
      #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to syncronize
      FillTXBuffer(4'd4);
      repeat(DEPTH)//write UNIQUE data to FIFO until full asserted
         WriteSingle;
      #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
      #(2*HALF_PERIOD*SYNC_STAGE); CheckFull(1'b1); CheckEmpty(1'b0); CheckOverflow(1'b0);
      //write some extra data and check overflow asserted   (if you write much data than RX_gold can held error detected)
      @(negedge wclk) wr<=1; d_wr<=TX[WIDTH_DIN-1:0]; TX<=TX>>WIDTH_DIN;
      @(negedge wclk) wr<=0;
      #(2*HALF_PERIOD*SYNC_STAGE); CheckFull(1'b1); CheckEmpty(1'b0); CheckOverflow(1'b1);
      //clear overflow
      @(negedge wclk) clr_of<=1;
      @(negedge wclk) clr_of<=0;
      CheckFull(1'b1); CheckEmpty(1'b0); CheckOverflow(1'b0);
      //read data - check UNIQUE data without loss and not extra data
      repeat(RDMX)//guarantee empty buffer
      begin
         if(!r_empty)
            ReadSingle;
      end
      #(2*HALF_PERIOD*SYNC_STAGE); CheckFull(1'b0); CheckEmpty(1'b1); CheckOverflow(1'b0);
// Note: when frequencies are equal determined test can be run, otherwise next test hard to predict - but it should work for all frequencies
// TODO: this test need to know when will be next READ, while this is only detected using rptr_cur and rptr_next comparision which already combinatorial
/*
      if(HALF_PERIOD_POP == HALF_PERIOD_PUSH)
      begin
         FillTXBuffer(4'd6);
         repeat(DEPTH) // write UNIQUE data to FIFO until full asserted
            WriteSingle;
         #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
         #(2*HALF_PERIOD*SYNC_STAGE); CheckFull(1'b1); CheckEmpty(1'b0); CheckOverflow(1'b0);
         // set READ request, and wait SYNC_STAGE cycles before set WRITE request - no overflow should be
         @(negedge rclk);
         fork
            begin
               rd <= 1'b1;
               @(negedge rclk) rd <= 1'b0;
            end
            begin
               repeat(SYNC_STAGE)
                  @(negedge wclk);
               wr <= 1'b1; d_wr<={WIDTH_DIN/2{2'b01}};
               @(negedge wclk) wr <= 1'b0;
            end
         join
         #(2*HALF_PERIOD*SYNC_STAGE);//wait flags to update
         #(2*HALF_PERIOD*SYNC_STAGE); CheckFull(1'b1); CheckEmpty(1'b0); CheckOverflow(1'b0);
         repeat(RDMX)//guarantee empty buffer
         begin
            if(!r_empty)
               ReadSingle;
         end
      end
*/
      TEST_CHECK(3*4 /*+ (HALF_PERIOD_POP == HALF_PERIOD_PUSH ? 6 : 0)*/);
   end
   endtask

   task TEST_UNDERFLOW;
   begin
      TEST_INIT("Underflow");
      while(!r_empty)
         ReadSingle;//empty buffer
      #(2*HALF_PERIOD*SYNC_STAGE); CheckEmpty(1'b1); CheckUnderflow(1'b0);
      //assert underflow
      @(negedge rclk) rd<=1;
      @(negedge rclk) rd<=0;
      #(2*HALF_PERIOD*SYNC_STAGE); CheckEmpty(1'b1); CheckUnderflow(1'b1);
      //clear underflow
      @(negedge rclk) clr_uf<=1;
      @(negedge rclk) clr_uf<=0;
      #(2*HALF_PERIOD*SYNC_STAGE); CheckEmpty(1'b1); CheckUnderflow(1'b0);
      TEST_CHECK(3*2);
   end
   endtask

   task TEST_ALMOST;
   reg flag_err_detected;
   begin
      TEST_INIT("TEST_ALMOST");
      // Note: tested flags must be set in sequence W_FULL only after W_ALMOST_FULL and R_EMPTY only after R_ALMOST_EMPTY
      // TODO: same for other flags in different order!? if so - add assertions!!!
      flag_err_detected = 1'b0;
      if(WIDTH_DIN < WIDTH_DOUT) // WC > 1
      fork
         begin // write data
            d_wr <= $random;
            repeat(DEPTH)
               @(posedge wclk) wr <= 1'b1;
            @(posedge wclk) wr <= 1'b0;
            repeat(10) @(posedge rclk); // Note: wait POINTER moved from WCLK to RCLK domain
            while(!r_empty)
               ReadSingle;
         end
         begin // Note: monitor if FULL asserted right after ALMOST_FULL
            repeat(2*DEPTH)
               @(posedge wclk)
                  if(w_full & !w_afull_delay & !w_full_delay)
                  begin
                     flag_err_detected = 1'b1;
                     $display("   Error: w_full asserted without w_afull at %0t.", $time);
                  end
         end
      join
      else if(WIDTH_DIN > WIDTH_DOUT) // RC > 1
      begin
         while(!w_full)
            WriteSingle;
         repeat(10) @(posedge rclk); // Note: wait POINTER moved from WCLk to RCLK domain
         fork
            while(!r_empty)
               ReadSingle;
            begin // Note: monitor if FULL asserted right after ALMOST_FULL
               repeat(20*DEPTH)
                  @(posedge rclk)
                     if(r_empty & !r_aempty_delay & !r_empty_delay)
                     begin
                        flag_err_detected = 1'b1;
                        $display("   Error: r_empty asserted without r_aempty at %0t.", $time);
                     end
            end
         join
      end
      TEST_CHECK(flag_err_detected ? 1 : 0);
   end
   endtask

   task TEST_7;
   begin
      TEST_INIT("TEST-7");
      if(RCRC32===WCRC32 && RBCNT===WBCNT) test_pass=test_pass+1;
      TEST_CHECK(1);
   end
   endtask
//
// Check that output will not be modified if data written into empty FIFO
// i.e. output asycnrhonously stable.
// As without defend, read part points to next entry, which is written at asynchronous clock
//    and toggle may propagate to receiver domain asynchronously.
// TO protect against:
// 1. use hard macro DPRAM with read enable gater @ output flop; -- non MACRO may produce glitchse
// 2. gate 'rdat' with r_empty flag                              -- logic optimization may move gater up to logic cone cause glitchse
//
   task TOGGLE_AT_EMPTY;
      reg err;
   begin
      if((SYNC_STAGE > 1) && (HALF_PERIOD_PUSH < HALF_PERIOD_POP)) // Note: check requires different data and flag path; write clock faster than read one required for this test)
      begin
         TEST_INIT("TOGGLE_AT_EMPTY");
            err = 0;
         // prepare buffer - fill FIFO with zero for easier testing
            FillTXBuffer(4'd0); WriteBurst;
            ReadBurst;
            FillTXBuffer(4'd3);
         // check while output is empty, data should eb stable (Q: add assertion?)
            fork
               begin : drive
                  repeat(3) @(negedge wclk);
                  repeat(WIDTH_DOUT>=WIDTH_DIN ? WIDTH_DOUT/WIDTH_DIN : 1) WriteSingle;
               end
               begin : check
                  while(r_empty)
                  begin
                     if(d_rd !== 0) err = 1;
                     @(negedge rclk);
                  end
               end
            join
            ReadBurst; // flush
            if(err == 0) test_pass++; else $display("   Error: read data changed while 'r_empty' asserted.");
         TEST_CHECK(1);
      end
   end
   endtask

   task CheckUnderflow(input reg cmp);
   begin
      if(underflow==cmp) test_pass=test_pass+1;
      else test_fail_toggle=!test_fail_toggle;
   end
   endtask

   task CheckOverflow(input reg cmp);
   begin
      if(overflow==cmp) test_pass=test_pass+1;
      else test_fail_toggle=!test_fail_toggle;
   end
   endtask

   task CheckFull(input reg cmp);
   begin
      if(w_full==cmp) test_pass=test_pass+1;
      else test_fail_toggle=!test_fail_toggle;
   end
   endtask

   task CheckEmpty(input reg cmp);
   begin
      if(r_empty==cmp) test_pass=test_pass+1;
      else test_fail_toggle=!test_fail_toggle;
   end
   endtask

   task FillTXBuffer(input reg [3:0] test_type);
   reg [WIDTH_DIN-1:0] counter;
   reg [WIDTH_DIN-1:0] walking_one;//2013-01-31
   integer y;
   begin
      counter=0; TX={(2*WIDTH_DIN*DEPTH){1'b0}}; #(2*HALF_PERIOD_PUSH);
      case(test_type)
         0://0x0
            TX<={(2*WIDTH_DIN*DEPTH){1'b0}};
         1://0x3
            for(y=0;y<2*WIDTH_DIN*DEPTH;y=y+1)
               TX={TX[2*WIDTH_DIN*DEPTH-2:0],y[1]};
         2://0x5
            for(y=0;y<2*WIDTH_DIN*DEPTH;y=y+1)
               TX={TX[2*WIDTH_DIN*DEPTH-2:0],~y[0]};
         3://0xA
            for(y=0;y<2*WIDTH_DIN*DEPTH;y=y+1)
               TX={TX[2*WIDTH_DIN*DEPTH-2:0],y[0]};
         4://0xC
            for(y=0;y<2*WIDTH_DIN*DEPTH;y=y+1)
               TX={TX[2*WIDTH_DIN*DEPTH-2:0],y[1:0]<2};
         5://0xF
            TX={(2*WIDTH_DIN*DEPTH){1'b1}};
         6://ADR - counter
            repeat(DEPTH)
            begin
               counter=counter+1;
               TX={TX[2*WIDTH_DIN*DEPTH-1-WIDTH_DIN:0],counter[WIDTH_DIN-1:0]};
            end
         7://~ADR - ~counter
            repeat(DEPTH)
            begin
               counter=counter+1;
               TX={TX[2*WIDTH_DIN*DEPTH-1-WIDTH_DIN:0],~counter[WIDTH_DIN-1:0]};
            end
         8://walking 0
            repeat(DEPTH)
            begin
               counter=counter+1;
               walking_one = 1<<counter;
               TX={TX[2*WIDTH_DIN*DEPTH-1-WIDTH_DIN:0],~walking_one};//2013-01-31
            end
         9://walking 1
            repeat(DEPTH)
            begin
               counter=counter+1;
               walking_one = 1<<counter;
               TX={TX[2*WIDTH_DIN*DEPTH-1-WIDTH_DIN:0],walking_one};//2013-01-31
            end
      endcase
   end
   endtask

   task WriteBurst;
   begin
      @(negedge wclk);
      while(!w_full)
      begin
         @(negedge wclk) wr <= 1; d_wr <= TX[WIDTH_DIN-1:0]; TX <= TX>>WIDTH_DIN;
      end
      wr<=0;
      //wait synchronizer to reset EMPTY flag
      while(!r_full) #(2*HALF_PERIOD);
      while(r_empty) #(2*HALF_PERIOD);
      #(2*HALF_PERIOD);
   end
   endtask

   task ReadBurst;
   begin
      @(negedge rclk);
      while(!r_empty)
      begin
         rd <= 1;
         @(negedge rclk);
      end
      rd <= 0;
      //wait synchronizer to reset FULL flag
      while(!w_empty) @(negedge rclk); // Q: why RCLK reads W_flags!?
      while(w_full) @(negedge rclk);
      #(2*HALF_PERIOD);
   end
   endtask

   task WriteSingle;
   begin
      if(!w_full)
      begin
         @(negedge wclk) wr <= 1; d_wr <= TX[WIDTH_DIN-1:0]; TX <= TX>>WIDTH_DIN;
         @(negedge wclk) wr <= 0;
      end
   end
   endtask

   task ReadSingle;
   begin
      if(!r_empty)
      begin
         @(negedge rclk) rd <= 1;
         @(negedge rclk) rd <= 0;
      end
   end
   endtask

endmodule
