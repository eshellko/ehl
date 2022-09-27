// Design:           WDT
// Revision:         1.0
// Date:             2022-07-11
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: -

`timescale 1ns/100ps
module ehl_wdt_tb;
`include "test.v"

// 32-bit mode registers
`define LOAD32           (5'b000_00)
`define VAL32            (5'b001_00)
`define LOCK32           (5'b010_00)
`define IRQ_CTRL32       (5'b011_00)
`define IRQ_FLAG32       (5'b100_00)
// 16-bit mode registers
`define LOAD16(WORD)     (5'b000_00 + WORD*2)
`define VAL16(WORD)      (5'b001_00 + WORD*2)
`define LOCK16(WORD)     (5'b010_00 + WORD*2)
`define IRQ_CTRL16(WORD) (5'b011_00 + WORD*2)
`define IRQ_FLAG16(WORD) (5'b100_00 + WORD*2)
// 8-bit mode registers
`define LOAD8(BIT)       (5'b000_00 + BIT)
`define VAL8(BIT)        (5'b001_00 + BIT)
`define LOCK8(BIT)       (5'b010_00 + BIT)
`define IRQ_CTRL8(BIT)   (5'b011_00 + BIT)
`define IRQ_FLAG8(BIT)   (5'b100_00 + BIT)

`define IRQ_ENA   32'h1
`define RST_ENA   32'h2

   parameter WIDTH = 32;
   reg [31:0] rv; // 32-bit value read from WDT; each byte written separately
`include "api.v"

   reg clk;
   reg reset_n, wr, rd;
   reg [4:0] addr;
   reg [WIDTH-1:0] wdata;
   wire [WIDTH-1:0] rdata;
   reg [WIDTH-1:0] rdata_cpt;

   wire irq;
   wire rst_req;
   reg wdt_reset_n;
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      wdt_reset_n <= 1'b0;
   else if(rst_req)
      wdt_reset_n <= 1'b0;
   else
      wdt_reset_n <= 1'b1;

   parameter HALF_PERIOD=10;
   always #HALF_PERIOD clk=~clk;

   ehl_wdt
   #(
      .WIDTH ( WIDTH )
   ) dut
   (
      .clk         ( clk         ),
      .reset_n     ( reset_n     ),
      .wdt_reset_n ( wdt_reset_n ),
      .irq         ( irq         ),
      .rst_req     ( rst_req     ),
      .wr          ( wr          ),
      .rd          ( rd          ),
      .addr        ( addr        ),
      .wdata       ( wdata       ),
      .rdata       ( rdata       )
   );

   initial
   begin
      TEST_TITLE("Check watchdog functionality", "ehl_wdt_tb.v", "basic test");
      #0 reset_n = 0; clk = 0; rd = 0; wr = 0; addr = 0; wdata = 0;
      @(negedge clk);
      reset_n = 1;

      // Note: check LOCK registers access functionality
      TEST_INIT("LOCK");
      //
      // 1. read initial registers values
         API_WDT_GET_TIMEOUT;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x00 (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         API_WDT_GET_INTERVAL;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x04 (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         if(WIDTH == 8) begin READ_REG(`LOCK8(0)); READ_REG(`LOCK8(1)); READ_REG(`LOCK8(2)); READ_REG(`LOCK8(3)); end
         if(WIDTH == 16) begin READ_REG(`LOCK16(0)); READ_REG(`LOCK16(1)); end
         if(WIDTH == 32) READ_REG(`LOCK32);
         if(rv === 32'h00_00_00_01) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x08 (exp. 0x%x) at %0t.", rv, 32'h1, $time);

         if(WIDTH == 8) begin READ_REG(`IRQ_CTRL8(0)); READ_REG(`IRQ_CTRL8(1)); READ_REG(`IRQ_CTRL8(2)); READ_REG(`IRQ_CTRL8(3)); end
         if(WIDTH == 16) begin READ_REG(`IRQ_CTRL16(0)); READ_REG(`IRQ_CTRL16(1)); end
         if(WIDTH == 32) READ_REG(`IRQ_CTRL32);
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x0C (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         API_WDT_GET_IRQ;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x10 (exp. 0x%x) at %0t.", rv, 32'h0, $time);
      //
      // 2. write into locked registers - read back
         if(WIDTH == 8) begin WRITE_REG(`LOAD8(0), 8'h11); WRITE_REG(`LOAD8(1), 8'h11); WRITE_REG(`LOAD8(2), 8'h11); WRITE_REG(`LOAD8(3), 8'h11); end
         if(WIDTH == 16) begin WRITE_REG(`LOAD16(0), 16'h1111); WRITE_REG(`LOAD16(1), 16'h1111); end
         if(WIDTH == 32) WRITE_REG(`LOAD32, 32'h11111111);

         if(WIDTH == 8) begin WRITE_REG(`VAL8(0), 8'h22); WRITE_REG(`VAL8(1), 8'h22); WRITE_REG(`VAL8(2), 8'h22); WRITE_REG(`VAL8(3), 8'h22); end
         if(WIDTH == 16) begin WRITE_REG(`VAL16(0), 16'h2222); WRITE_REG(`VAL16(1), 16'h2222); end
         if(WIDTH == 32) WRITE_REG(`VAL32, 32'h22222222);

         if(WIDTH == 8) begin WRITE_REG(`IRQ_CTRL8(0), 8'h33); WRITE_REG(`IRQ_CTRL8(1), 8'h33); WRITE_REG(`IRQ_CTRL8(2), 8'h33); WRITE_REG(`IRQ_CTRL8(3), 8'h33); end
         if(WIDTH == 16) begin WRITE_REG(`IRQ_CTRL16(0), 16'h3333); WRITE_REG(`IRQ_CTRL16(1), 16'h3333); end
         if(WIDTH == 32) WRITE_REG(`IRQ_CTRL32, 32'h33333333);

         if(WIDTH == 8) begin WRITE_REG(`IRQ_FLAG8(0), 8'h44); WRITE_REG(`IRQ_FLAG8(1), 8'h44); WRITE_REG(`IRQ_FLAG8(2), 8'h44); WRITE_REG(`IRQ_FLAG8(3), 8'h44); end
         if(WIDTH == 16) begin WRITE_REG(`IRQ_FLAG16(0), 16'h4444); WRITE_REG(`IRQ_FLAG16(1), 16'h4444); end
         if(WIDTH == 32) WRITE_REG(`IRQ_FLAG32, 32'h44444444);

         API_WDT_GET_TIMEOUT;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x00 (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         API_WDT_GET_INTERVAL;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x04 (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         if(WIDTH == 8) begin READ_REG(`LOCK8(0)); READ_REG(`LOCK8(1)); READ_REG(`LOCK8(2)); READ_REG(`LOCK8(3)); end
         if(WIDTH == 16) begin READ_REG(`LOCK16(0)); READ_REG(`LOCK16(1)); end
         if(WIDTH == 32) READ_REG(`LOCK32);
         if(rv === 32'h00_00_00_01) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x08 (exp. 0x%x) at %0t.", rv, 32'h1, $time);

         if(WIDTH == 8) begin READ_REG(`IRQ_CTRL8(0)); READ_REG(`IRQ_CTRL8(1)); READ_REG(`IRQ_CTRL8(2)); READ_REG(`IRQ_CTRL8(3)); end
         if(WIDTH == 16) begin READ_REG(`IRQ_CTRL16(0)); READ_REG(`IRQ_CTRL16(1)); end
         if(WIDTH == 32) READ_REG(`IRQ_CTRL32);
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x0C (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         API_WDT_GET_IRQ;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x10 (exp. 0x%x) at %0t.", rv, 32'h0, $time);
      //
      // 3. write unlocked registers - read back
         WRITE_REG(`LOCK8(0), 8'hD9); // unlock registers

         if(WIDTH == 8) begin WRITE_REG(`LOAD8(0), 8'h16); WRITE_REG(`LOAD8(1), 8'h13); WRITE_REG(`LOAD8(2), 8'h14); WRITE_REG(`LOAD8(3), 8'h15); end
         if(WIDTH == 16) begin WRITE_REG(`LOAD16(0), 16'h1316); WRITE_REG(`LOAD16(1), 16'h1514); end
         if(WIDTH == 32) WRITE_REG(`LOAD32, 32'h15141316);

         if(WIDTH == 8) begin WRITE_REG(`IRQ_CTRL8(0), 8'h3); WRITE_REG(`IRQ_CTRL8(1), 8'h33); WRITE_REG(`IRQ_CTRL8(2), 8'h34); WRITE_REG(`IRQ_CTRL8(3), 8'h35); end
         if(WIDTH == 16) begin WRITE_REG(`IRQ_CTRL16(0), 16'h3303); WRITE_REG(`IRQ_CTRL16(1), 16'h3534); end
         if(WIDTH == 32) WRITE_REG(`IRQ_CTRL32, 32'h35343303);

         API_WDT_GET_TIMEOUT;
         if(rv === 32'h15_14_13_16) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x00 (exp. 0x%x) at %0t.", rv, 32'h15_14_13_16, $time);

         API_WDT_GET_INTERVAL;
         // Note: LSB moved relative to initial (laoded) value
         if(WIDTH == 8) if(rv === 32'h15_14_13_04) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x04 (exp. 0x%x) at %0t.", rv, 32'h15_14_13_04, $time);
         if(WIDTH == 16) if(rv === 32'h15_14_13_0C) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x04 (exp. 0x%x) at %0t.", rv, 32'h15_14_13_0C, $time);
         if(WIDTH == 32) if(rv === 32'h15_14_13_10) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x04 (exp. 0x%x) at %0t.", rv, 32'h15_14_13_10, $time);

         if(WIDTH == 8) begin READ_REG(`LOCK8(0)); READ_REG(`LOCK8(1)); READ_REG(`LOCK8(2)); READ_REG(`LOCK8(3)); end
         if(WIDTH == 16) begin READ_REG(`LOCK16(0)); READ_REG(`LOCK16(1)); end
         if(WIDTH == 32) READ_REG(`LOCK32);
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x08 (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         if(WIDTH == 8) begin READ_REG(`IRQ_CTRL8(0)); READ_REG(`IRQ_CTRL8(1)); READ_REG(`IRQ_CTRL8(2)); READ_REG(`IRQ_CTRL8(3)); end
         if(WIDTH == 16) begin READ_REG(`IRQ_CTRL16(0)); READ_REG(`IRQ_CTRL16(1)); end
         if(WIDTH == 32) READ_REG(`IRQ_CTRL32);
         if(rv === 32'h00_00_00_03) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x0C (exp. 0x%x) at %0t.", rv, 32'h3, $time);

         API_WDT_GET_IRQ;
         if(rv === 32'h00_00_00_00) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x10 (exp. 0x%x) at %0t.", rv, 32'h0, $time);

         // Note: readd non exist register - 0 expected
         READ_REG(5'h1f); if(rdata_cpt === 8'h0) test_pass++; else $display("   Error: incorrect value 0x%x read from 0x1F (exp. 0x%x) at %0t.", rdata_cpt, 8'h0, $time);

         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(3*5+1);

      TEST_INIT("STOP");
      // Note: timer expected to be active after previous test
// Q: is timer cleared when STOPPED?
// A: yes, as STOP is write 0 into LOAD -> VAL.
         API_WDT_ACTIVE;
         if(rv === 32'h1) test_pass++; else $display("   Error: timer not active at %0t.", $time);

         API_WDT_STOP(1'b1);

         repeat(3) begin API_WDT_ACTIVE; if(rv === 32'h0) test_pass++; else $display("   Error: timer active after stop at %0t.", $time); end
         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(3+1);

      TEST_INIT("START");
         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(0);

      TEST_INIT("CYCLE_IRQ");
         API_WDT_ENABLE_IRQ(`IRQ_ENA, 1'b1);
         API_WDT_START(32'h100, 1'b1);
         repeat(300) @(posedge clk);
         if(irq === 1'b1) test_pass++; else $display("   Error: no IRQ asserted at %0t.", $time);
         repeat(300) @(posedge clk);
         if(irq === 1'b1) test_pass++; else $display("   Error: no IRQ asserted at %0t.", $time);
         API_WDT_GET_IRQ;
         if(rv === 1) test_pass++; else $display("   Error: no IRQ_FLAG asserted at %0t.", $time); // or RST_FLAG=1
         repeat(256*2) @(posedge clk);
         API_WDT_STOP(1'b1);
         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(3);

      TEST_INIT("DISABLED_IRQ");
         API_WDT_DISABLE_IRQ(1'b1);
         API_WDT_START(32'h100, 1'b1);
         repeat(256*4) @(posedge clk);
         // Note: IRQ_FLAG asserted, but there is no IRQ
         API_WDT_GET_IRQ;
         if(irq === 1'b0) test_pass++; else $display("   Error: IRQ asserted at %0t.", $time);
         if(rv === 1) test_pass++; else $display("   Error: no IRQ_FLAG asserted at %0t.", $time);
         API_WDT_STOP(1'b1);
         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(2);

      TEST_INIT("IRQ+RESET");
         API_WDT_ENABLE_IRQ(`IRQ_ENA | `RST_ENA, 1'b1);
         API_WDT_START(32'h100, 1'b1);
         repeat(300) @(posedge clk);

         // Note: clear IRQ at first appearance
         API_WDT_GET_IRQ; if(rv === 1) test_pass++; else $display("   Error: no IRQ_FLAG asserted at %0t.", $time);
         if(irq === 1'b1) test_pass++; else $display("   Error: no IRQ asserted at %0t.", $time);
         API_WDT_CLEAR_IRQ(32'h0, 1'b1);
         API_WDT_CLEAR_IRQ(32'h1, 1'b1);

         repeat(256*4) @(posedge clk);

         // Note: reset should be detected, and then cleared by SW
         API_WDT_GET_IRQ; if(rv === 2) test_pass++; else $display("   Error: no RST_FLAG asserted at %0t.", $time);
         API_WDT_STOP(1'b1);
         API_WDT_CLEAR_IRQ(32'h2, 1'b1);
         API_WDT_GET_IRQ; if(rv === 0) test_pass++; else $display("   Error: RST_FLAG not cleared at %0t.", $time);

         WRITE_REG(`LOCK8(0), 8'hD9); // unlock registers (after self-reset) for further tests
         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(4);

      TEST_INIT("MAX_INTERVAL");
         API_WDT_START(32'hFFFFFFFF, 1'b1);
`ifndef ICARUS
         repeat(32) repeat(32'hFFFFFFF) @(posedge clk);
`endif
         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(0);

      TEST_INIT("MIN_INTERVAL");
         API_WDT_ENABLE_IRQ(`IRQ_ENA | `RST_ENA, 1'b1);

      // Note: START with 0 == STOP
         API_WDT_START(32'h0, 1'b1);
         repeat(32) @(posedge clk);

         API_WDT_START(32'h1, 1'b1);
         repeat(8) @(posedge clk);
         API_WDT_GET_IRQ; if(rv === 2) test_pass++; else $display("   Error: no RST_FLAG asserted at %0t.", $time);

         API_WDT_CLEAR_IRQ(32'h3, 1'b1);
      TEST_CHECK(1);

      TEST_INIT("RELOAD_ON_THE_FLY");
         API_WDT_ENABLE_IRQ(`RST_ENA, 1'b1);
         API_WDT_START(32'h200, 1'b1);
         repeat(60) @(posedge clk);
         API_WDT_START(32'h10, 1'b1);
         repeat(20) @(posedge clk);
         if(irq === 1'b0) test_pass++; else $display("   Error: IRQ asserted at %0t.", $time);
         repeat(2*16) @(posedge clk);

         API_WDT_GET_IRQ; if(rv === 2) test_pass++; else $display("   Error: no RST_FLAG asserted at %0t.", $time);

         API_WDT_CLEAR_IRQ(32'hFFFFFFFF, 1'b1);
      TEST_CHECK(2);

      TEST_SUMMARY;
   end

   task WRITE_REG(input reg [4:0] tadr, input reg [WIDTH-1:0] tdata);
   begin
      @(negedge clk) wr = 1; wdata = tdata; addr = tadr;
      @(negedge clk) wr = 0;
   end
   endtask

   task READ_REG(input reg [4:0] tadr);
   begin
      @(negedge clk) addr = tadr; rd = 1;
      @(negedge clk) rdata_cpt = rdata; rd = 0;
      if(WIDTH == 8)
      begin
         if(tadr[1:0] == 2'b00) rv[7:0] = rdata_cpt;
         else if(tadr[1:0] == 2'b01) rv[15:8] = rdata_cpt;
         else if(tadr[1:0] == 2'b10) rv[23:16] = rdata_cpt;
         else if(tadr[1:0] == 2'b11) rv[31:24] = rdata_cpt;
      end
      else if(WIDTH == 16)
      begin
         if(tadr[1] == 1'b0) rv[15:0] = rdata_cpt;
         else if(tadr[1] == 1'b1) rv[31:16] = rdata_cpt;
      end
      else if(WIDTH == 32)
         rv = rdata_cpt;
   end
   endtask

endmodule
