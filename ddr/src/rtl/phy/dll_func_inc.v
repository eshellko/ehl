// Design:           DDR2 PHY DLL behavioral model
// Revision:         1.0
// Date:             2018-07-24
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2018-07-24 A.Kornukhin: initial release
// Description:      this file containt single source for DLL model
//                   - it is used inside ehl_ddr_phy_dll for generic TECHNOLOGY
//                   - it should be used as model of DDR2_PHY_DLL after synthesis
//                     where there is no generate scope hierarchy and no ehl_ddr_phy_dll module

// Note: define reference period
   real Tclk;
   real Tper;
   initial
   begin
      Tclk = 0.0;
      Tper = 8000.0;// 125 MHz slowest reference clock allowed, thus initial is 8
   end

   reg dll_clk_0 = 1'b0;
   reg dll_clk_90 = 1'b0;
   reg dll_clk_180 = 1'b0;
   reg dll_clk_270 = 1'b0;

   always@(posedge ref_clk)
   begin
      Tper = $realtime - Tclk;
      Tclk = $realtime;
      // Note: skip initial tied-off clock, as period can be huge...
      if(Tper > 8000.0)
         Tper = 8000.0;
// todo: report out-of-range frequency
      if(!bypass)
      begin
         dll_clk_0 = 1'b1; dll_clk_180 = 1'b0;
      end
      else
      begin
         dll_clk_0 = 1'b0; dll_clk_180 = 1'b0;
         dll_clk_90 = 1'b0; dll_clk_270 = 1'b0;
      end
   end
   always@(posedge dll_clk_0) // Note: calculation in a separate process (without races between), as in case of faster clock (200 MHz) due to Tper>PERIOD previous process will be launched at every other clock
   if(!bypass)
   begin
      #(Tper/4.0) dll_clk_90 = 1'b1; dll_clk_270 = 1'b0;
   end
   always@(posedge dll_clk_90) // Note: calculation in a separate process (without races between), as in case of faster clock (200 MHz) due to Tper>PERIOD previous process will be launched at every other clock
   if(!bypass)
   begin
      #(Tper/4.0) dll_clk_180 = 1'b1; dll_clk_0 = 1'b0;
   end
   always@(posedge dll_clk_180) // Note: calculation in a separate process (without races between), as in case of faster clock (200 MHz) due to Tper>PERIOD previous process will be launched at every other clock
   if(!bypass)
   begin
      #(Tper/4.0) dll_clk_270 = 1'b1; dll_clk_90 = 1'b0;
   end
// todo: add up to 100ps jitter
   assign clk_0   = bypass ? ref_clk : (locked ? dll_clk_0 : 1'b0); // Note: no signal propagated when DLL not locked... Q: others?
   assign clk_90  = dll_clk_90;
   assign clk_180 = dll_clk_180;
   assign clk_270 = dll_clk_270;

   wire dqs_gated;
   wire dqs_n_gated;

// Note: SDRAM_FREQ is 90 degree
//       step is 45 degree - SDRAM_FREQ/2
   // Note: irun didn't propagate Tper through single array, but propagate through scalars
   reg a1,a2,a3,a4,a5,a6,a7;
   wire [7:0] dqs_gate_delay_array = {a7, a6, a5, a4, a3, a2, a1, dqs_gate};
   always@* #(Tper/8) a1 = dqs_gate;
   always@* #(Tper/8) a2 = a1;
   always@* #(Tper/8) a3 = a2;
   always@* #(Tper/8) a4 = a3;
   always@* #(Tper/8) a5 = a4;
   always@* #(Tper/8) a6 = a5;
   always@* #(Tper/8) a7 = a6;

   wire dqs_gate_delayed = dqs_gate_delay_array[dfi_rdlvl_gate_delay];

   reg dfi_rdlvl_resp_r;
   // Note: if DQS stucked after last test, no update will be on 'dfi_rdlvl_resp'
   assign dfi_rdlvl_resp = dfi_rdlvl_resp_r;
   always@(posedge dqs_gate_delayed)
`define __no_x__
`ifdef __no_x__
      begin
         if(dqs === 1'b1)
            dfi_rdlvl_resp_r <= 1'b1;
         else // X -> 0 
            dfi_rdlvl_resp_r <= 1'b0;
      end
`else
         dfi_rdlvl_resp_r <= dqs;
`endif

   assign dqs_gated = dqs_gate_delayed & dqs & !dfi_rdlvl_gate_en; // todo: can be blocked in another place if it gives better QoR (in DLL it is blocked at output)
   assign dqs_n_gated = ~dqs_gate_delayed | dqs_n | dfi_rdlvl_gate_en;

// Note: this is simple DLL emulator, it is not function like real DLL module right now
// Note: lock time is about 2 us
   integer lock_period;
   initial lock_period = 0;
   reg bypass_delay;
   always@(posedge ref_clk or negedge reset_n)
   if(!reset_n)
      bypass_delay <= 1'b1;
   else
      bypass_delay <= bypass;
   assign locked = lock_period >= 40; // todo: ~ 1000 cycles

   always@(posedge ref_clk or negedge reset_n)
   if(!reset_n)
      lock_period <= 0;
// Note: real model will detect frequency change, while here bypass->0 used to show that frequency will be changed
   else if(bypass & !bypass_delay)
      lock_period <= 0;
   else if(lock_period < 41)
      lock_period <= lock_period + 1;
// Note: SDRAM_FREQ is a 1/4 of period - 90 degree
//       DQS offset step is 18 degrees - SDRAM_FREQ/5
   // Note: every stage has fixed 1 unit delay, as opposed to array with increased delays; as in some cases where delay > 1/2 period, signal toggle lost as new one already assigned
   reg b0,b1,b2,b3,b4,b5,b6,b7;
   wire [7:0] dqs_90_array = {b7, b6, b5, b4, b3, b2, b1, b0};
   always@* #(Tper/20) b0 = dqs_gated;
   always@* #(Tper/20) b1 = b0;
   always@* #(Tper/20) b2 = b1;
   always@* #(Tper/20) b3 = b2;
   always@* #(Tper/20) b4 = b3;
   always@* #(Tper/20) b5 = b4;
   always@* #(Tper/20) b6 = b5;
   always@* #(Tper/20) b7 = b6;
// todo: add up to 100ps jitter
   assign dqs_90 = dqs_90_array[dfi_rdlvl_delay];

   reg d0,d1,d2,d3,d4,d5,d6,d7;
   wire [7:0] dqs_n_90_array = {d7, d6, d5, d4, d3, d2, d1, d0};
   always@* #(Tper/20) d0 = dqs_n_gated;
   always@* #(Tper/20) d1 = d0;
   always@* #(Tper/20) d2 = d1;
   always@* #(Tper/20) d3 = d2;
   always@* #(Tper/20) d4 = d3;
   always@* #(Tper/20) d5 = d4;
   always@* #(Tper/20) d6 = d5;
   always@* #(Tper/20) d7 = d6;
// Note: seems like RANDOM_OUT_DELAY (meet spec) cause last data captured by DQS_N after switched to 'Z'. (-2 solves issue on one test)
//       it looks like separate parameters for DQ and DQS are must, it also seems that software tuning of this parameters can be useful
// todo: need to run testchip and check this case...
// todo: add up to 100ps jitter
   assign dqs_n_90 = dqs_n_90_array[dfi_rdlvl_delay_n];
//=========================
// 2x clock multiplier
//=========================
   wire clk_1 = clk_0 & clk_270;
   wire clk_2 = clk_90 & clk_180;
   assign clk_2x = clk_1 | clk_2;
//=========================
// todo: also detect nominal clock period change more than by 25 MHz, as another report will not be issued
   always@(hf) // todo: avoid during initial X->0/1 transition with bypass = X too
   if(bypass !== 1'b1)
      $display("   Error: '%m' DLL frequency changed while not in bypass mode at time %0t.", $time);
   always@*
   if(dfi_rdlvl_delay === 3'bx)
      $display("   Error: '%m' incorrect value of DDR2 PHY DLL settings dfi_rdlvl_delay at time %0t.", $time);
   always@*
   if(dfi_rdlvl_delay_n === 3'bx)
      $display("   Error: '%m' incorrect value of DDR2 PHY DLL settings dfi_rdlvl_delay_n at time %0t.", $time);
   always@*
   if(dfi_rdlvl_gate_delay === 3'bx)
      $display("   Error: '%m' incorrect value of DDR2 PHY DLL settings dfi_rdlvl_gate_delay at time %0t.", $time);
