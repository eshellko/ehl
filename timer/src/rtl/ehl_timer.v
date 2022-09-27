// Design:           Timer
// Revision:         2.2
// Date:             2022-06-30
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2013-04-16 A.Kornukhin: Initial release
//                   1.1 2015-03-06 A.Kornukhin: %m added
//                   1.2 2015-04-07 A.Kornukhin: PWM added
//                   1.3 2016-10-31 A.Kornukhin: prescaler added
//                   1.4 2019-11-08 A.Kornukhin: addsub module used
//                   2.1 2021-12-10 A.Kornukhin: capture/compare/pwm/counter modes
//                   2.2 2022-06-30 A.Kornukhin: added inverted PWM output

// Feature requests (not included due to limited resources):
//       - independent timer width for every timer
//       - wider than 32 timer width
//       - cascaded mode between selected timers
//       - built-in chaining timers mode
//       - SW available register dbg_check (asserted if values of counters are not correct / used for debug only (TODO: implement as 'status' bit / is enabled by user (with interrupt generation)
//       - static MUX to select clock source
//       - stop timer when debugger halts the CPU
//       - gate non-volatile CSRs

// TODO: as IRQ is async - allow IRQ generation at CLK or at TIMER_CLK via CONFIG

// hw clock gating - when enabled via SW

// Значение счетчика можно в любой момент прочитать из пары регистров TIM1_CNTRH и TIM1_CNTRL.
//       Читать надо сначала старший байт (CNTRH, при этом младший загружается во временный буфер), а потом — младший. 
// Не менять значение LOAD при работающем таймере... нет буферизации...
// UEV - Update Event - narrow bus interface writes into buffer
//       and then update event moves data from buffer to selected by UEV source
//       ... thus, no need to point which buffer to write...
// On read re-use same buffer... IRQ may break it

// TODO: check IRQ generation with 111101111 pattern - will it be detected by PLIC?

// TODO: active on start... downcount full scale...

// Q: gray counter to read register

module ehl_timer
#(
   parameter TECHNOLOGY = 0,          // technology for rtl mapping
             CDC_SYNC_STAGE = 2,      // number of CDC stages
   parameter BUS_WIDTH = 32,          // bus interface width (8, or 32)
             NTIMERS   = 1,           // number of timers (1-4) to be used as single bus slave device
             TIMER_WIDTH = 32,        // timer width
             SYNC_MODE = 0,           // 1 - clk and tmr_clk are driven by the same signal, 0 - asynchronous (internal synchronizers implemented)
   parameter [3:0] PWM_ENA = 4'b000,  // enables PWM for selected timer
   parameter [3:0] CPT_ENA = 4'b000,  // enables Capture for selected timer
   parameter [3:0] CMP_ENA = 4'b000,  // enables Compare for selected timer
   parameter [7:0] CPT_SYNC = 8'hff,  // enable synchronizer on cpt_in
   parameter [0:0] USE_CG = 1'b1      // enable clock gaters
)
(
   input wire                  clk,         // bus clock
                               reset_n,     // bus reset
                               wr,          // bus write
   input wire [7:0]            addr,        // bus address
   input wire [BUS_WIDTH-1:0]  din,         // bus data in
   output reg [BUS_WIDTH-1:0]  dout,        // bus data out
   output wire                 irq,         // active high level interrupt request

   input wire [NTIMERS-1:0]    tmr_clk,     // timers core clock
   input wire [NTIMERS-1:0]    tmr_reset_n, // timers reset (should be externally synchronized to respective 'tmr_clk')

   input wire                  test_mode,   // DFT control

   input wire  [2*NTIMERS-1:0] cpt_in,      // Capture inputs
   output wire [NTIMERS-1:0]   cmp_oe_n,    // Active low COMPARE output enable
   output wire [3*NTIMERS-1:0] cmp_out,     // Compare / PWM outputs
   output wire [3*NTIMERS-1:0] cmp_out_n    // inverted PWM outputs
);
`ifndef SYNTHESIS
// pragma coverage block = off
//   initial $display("   Info: instantiate EHL Timer IP Core (%m).");
   initial // TODO: also check other parameters...
   begin
      if(NTIMERS < 1 || NTIMERS > 4)
      begin
         $display("   Error: '%m' incorrect value %0d for parameter NTIMERS (1-4).", NTIMERS);
         $finish;
      end
      if(TIMER_WIDTH != 8 && TIMER_WIDTH != 16 && TIMER_WIDTH != 24 && TIMER_WIDTH != 32)
      begin
         $display("   Error: '%m' incorrect value %0d for parameter TIMER_WIDTH (8, 16, 24, 32).", TIMER_WIDTH);
         $finish;
      end
      if(BUS_WIDTH != 8 && BUS_WIDTH != 32)
      begin
         $display("   Error: '%m' incorrect value %0d for parameter BUS_WIDTH (8, 32).", BUS_WIDTH);
         $finish;
      end
   end
// pragma coverage block = on
`endif
//--------------------------------------------
// Registers
//--------------------------------------------
   // Note: bus access (BUS_WIDTH = 8 or 32) is marked for each of 4 bytes, either 0001,0010,0100,1000, or 1111
   wire [3:0] wr_strb;
   if(BUS_WIDTH == 8)
      assign wr_strb = wr ? (4'b1 << addr[1:0]) : 4'b0000;
   if(BUS_WIDTH == 32)
      assign wr_strb = wr ? 4'b1111 : 4'b0000;

   // CFG
   wire [NTIMERS-1:0] oneshot;
   wire [NTIMERS-1:0] pwm_comp;
   wire [2:0]         tmr_mode  [NTIMERS-1:0];
   wire [2:0]         cmp_en    [NTIMERS-1:0];
   wire [1:0]         cmp_type  [NTIMERS-1:0];
   wire [NTIMERS-1:0] cpt_sel;
   wire [1:0]         cpt_type  [NTIMERS-1:0];
   wire [NTIMERS-1:0] dir;
   wire [1:0]         cpt_start [NTIMERS-1:0];
   wire [1:0]         cpt_stop  [NTIMERS-1:0];
   // CMD
   wire [NTIMERS-1:0] ena;
   wire [NTIMERS-1:0] pause;
   // DEAD
   wire [TIMER_WIDTH-1:0] tmr_dead [NTIMERS-1:0];
   // LOAD
   wire [TIMER_WIDTH-1:0] tmr_load [NTIMERS-1:0];
   // PRE
   wire [7:0] tmr_pre [NTIMERS-1:0];
   // VALUE
   wire [TIMER_WIDTH-1:0] tmr_val [NTIMERS-1:0];
   // CPT
   wire [TIMER_WIDTH-1:0] tmr_cpt [NTIMERS-1:0];
   // CMP
   wire [TIMER_WIDTH-1:0] cmpa_t0 [NTIMERS-1:0];
   wire [TIMER_WIDTH-1:0] cmpa_t1 [NTIMERS-1:0];
   wire [TIMER_WIDTH-1:0] cmpb_t0 [NTIMERS-1:0];
   wire [TIMER_WIDTH-1:0] cmpb_t1 [NTIMERS-1:0];
   wire [TIMER_WIDTH-1:0] cmpc_t0 [NTIMERS-1:0];
   wire [TIMER_WIDTH-1:0] cmpc_t1 [NTIMERS-1:0];

   wire [BUS_WIDTH-1:0] tmr_dout [NTIMERS-1:0];

   wire [NTIMERS-1:0] match$clk;
   wire [NTIMERS-1:0] tmr_stop, tmr_stop$clk;

   wire [31:0] csr_din = BUS_WIDTH==32 ? din : {4{din}};
   genvar gen_k;
   for(gen_k = 0; gen_k < NTIMERS; gen_k = gen_k + 1)
   begin : xs
      ehl_timer_csr
      #(
         .BUS_WIDTH   ( BUS_WIDTH      ),
         .INDEX       ( gen_k          ),
         .TIMER_WIDTH ( TIMER_WIDTH    ),
         .PWM_ENA     ( PWM_ENA[gen_k] ),
         .CMP_ENA     ( CMP_ENA[gen_k] ),
         .CPT_ENA     ( CPT_ENA[gen_k] ),
         .USE_CG      ( USE_CG         )
      ) csr_inst
      (
         .clk,
         .reset_n,
         .wr_strb,
         .addr,
         .din       ( csr_din             ),
         .dout      ( tmr_dout[gen_k]     ),
         .tmr_dead  ( tmr_dead[gen_k]     ),
         .tmr_load  ( tmr_load[gen_k]     ),
         .tmr_pre   ( tmr_pre[gen_k]      ),
         .tmr_val   ( tmr_val[gen_k]      ),
         .tmr_cpt   ( tmr_cpt[gen_k]      ),
         .stop_tmr  ( tmr_stop$clk[gen_k] ),
         .oneshot   ( oneshot [gen_k]     ),
         .pwm_comp  ( pwm_comp[gen_k]     ),
         .ena       ( ena [gen_k]         ),
         .dir       ( dir [gen_k]         ),
         .pause     ( pause [gen_k]       ),
         .tmr_mode  ( tmr_mode[gen_k]     ),
         .cmp_en    ( cmp_en[gen_k]       ),
         .cmp_type  ( cmp_type[gen_k]     ),
         .cpt_sel   ( cpt_sel[gen_k]      ),
         .cpt_type  ( cpt_type[gen_k]     ),
         .cpt_start ( cpt_start[gen_k]    ),
         .cpt_stop  ( cpt_stop[gen_k]     ),
         .cmpa_t0   ( cmpa_t0[gen_k]      ),
         .cmpa_t1   ( cmpa_t1[gen_k]      ),
         .cmpb_t0   ( cmpb_t0[gen_k]      ),
         .cmpb_t1   ( cmpb_t1[gen_k]      ),
         .cmpc_t0   ( cmpc_t0[gen_k]      ),
         .cmpc_t1   ( cmpc_t1[gen_k]      )
      );
   end

   reg [11:0] ie;
   reg [11:0] ifl;

   always@(posedge clk or negedge reset_n)
   begin : tie
      integer i;
      if(!reset_n)
         ie <= 12'h0;
      else if(addr[7:2] == {2'b0, 4'h8})
      begin
         if(wr_strb[0])
            ie[7:0] <= csr_din[7:0];
         if(wr_strb[1])
            ie[11:8] <= csr_din[11:8];
      end
   end
//--------------------------------------------
// direction control to allow shared I/O configuration
//--------------------------------------------
   genvar gen_m;
   for(gen_m=0; gen_m<NTIMERS; gen_m=gen_m+1)
   begin : io_ctrl
      assign cmp_oe_n [gen_m] = !(tmr_mode[gen_m][2:1] == 2'b01); // Compare | PWM mode
   end
//--------------------------------------------
// Synchronize controls to core clock
// Synchronize logic to bus clock
//--------------------------------------------
   wire [NTIMERS-1:0] ena$tmr;
   wire [NTIMERS-1:0] pause$tmr;
   wire [NTIMERS-1:0] dir$tmr;
   wire [NTIMERS-1:0] oneshot$tmr;
   // Note: the following signals not allowed to be modified when timer is active
   //       no synchronizers are implemented
   //      .cmpa_t0
   //      .cmpa_t1
   //      .cmpb_t0
   //      .cmpb_t1
   //      .cmpc_t0
   //      .cmpc_t1
   //      .tmr_dead
   //      .tmr_load
   //      .tmr_pre
   //      .pwm_comp

   wire [2:0]         tmr_mode$tmr  [NTIMERS-1:0];
   wire [2:0]         cmp_en$tmr    [NTIMERS-1:0];
   wire [1:0]         cmp_type$tmr  [NTIMERS-1:0];
   wire [NTIMERS-1:0] cpt_sel$tmr;
   wire [1:0]         cpt_type$tmr  [NTIMERS-1:0];
   wire [1:0]         cpt_start$tmr [NTIMERS-1:0];
   wire [1:0]         cpt_stop$tmr  [NTIMERS-1:0];
/*
   // VALUE
   wire [TIMER_WIDTH-1:0] tmr_val [NTIMERS-1:0];
   // CPT
   wire [TIMER_WIDTH-1:0] tmr_cpt [NTIMERS-1:0];
*/

/*
// TODO: place SYNCHRONIZERS when in ASYNC mode...
         .tmr_val     ( tmr_val [gen_j]     ),
         .tmr_cpt     ( tmr_cpt[gen_j]      ),
*/
   genvar gen_i;
   if(SYNC_MODE)
   begin : csync
      assign ena$tmr      = ena;
      assign pause$tmr    = pause;
      assign dir$tmr      = dir;
      assign oneshot$tmr  = oneshot;
      assign cpt_sel$tmr  = cpt_sel;
      for(gen_i=0; gen_i < NTIMERS; gen_i = gen_i+1)
      begin : cax
         assign tmr_mode$tmr  [gen_i] = tmr_mode [gen_i];
         assign cmp_en$tmr    [gen_i] = cmp_en   [gen_i];
         assign cmp_type$tmr  [gen_i] = cmp_type [gen_i];
         assign cpt_type$tmr  [gen_i] = cpt_type [gen_i];
         assign cpt_start$tmr [gen_i] = cpt_start[gen_i];
         assign cpt_stop$tmr  [gen_i] = cpt_stop [gen_i];
      end
   end
   else
   begin : casync
      for(gen_i=0; gen_i < NTIMERS; gen_i = gen_i+1)
      begin : cax
         ehl_cdc
         #(
            .SYNC_STAGE   ( CDC_SYNC_STAGE ),
            .WIDTH        ( 19             ),
            .TECHNOLOGY   ( TECHNOLOGY     ),
            //.parameter [WIDTH-1:0] INIT_VAL = {WIDTH{1'b0}}, // Note: initial value programmed as in some cases polarity of source signal is 1
            //.parameter [0:0]       REPORT = 1'b1,            // set to report CDC information; for non-CDC usage clear this parameter
            .SIM_ADD_META ( 1'b1           )
         ) cdct_inst
         (
            .clk     ( tmr_clk[gen_i]     ),
            .reset_n ( tmr_reset_n[gen_i] ),
            .din     ( {
                        tmr_mode  [gen_i],
                        cmp_en    [gen_i],
                        cmp_type  [gen_i],
                        cpt_sel   [gen_i],
                        cpt_type  [gen_i],
                        cpt_start [gen_i],
                        cpt_stop  [gen_i],
                        oneshot   [gen_i],
                        dir       [gen_i],
                        pause     [gen_i],
                        ena       [gen_i]} ),
            .dout    ( {
                        tmr_mode$tmr  [gen_i],
                        cmp_en$tmr    [gen_i],
                        cmp_type$tmr  [gen_i],
                        cpt_sel$tmr   [gen_i],
                        cpt_type$tmr  [gen_i],
                        cpt_start$tmr [gen_i],
                        cpt_stop$tmr  [gen_i],
                        oneshot$tmr   [gen_i],
                        dir$tmr       [gen_i],
                        pause$tmr     [gen_i],
                        ena$tmr       [gen_i]} )
         );
      end
   end
//--------------------------------------------
// Cores
//--------------------------------------------
   wire [NTIMERS-1:0] match;
   wire [NTIMERS-1:0] capture;
   wire [NTIMERS-1:0] compare;
   genvar gen_j;
   for(gen_j = 0; gen_j < NTIMERS; gen_j = gen_j + 1)
   begin : xc
      ehl_timer_core
      #(
         .WIDTH      ( TIMER_WIDTH          ),
         .SYNC_STAGE ( CDC_SYNC_STAGE       ),
         .TECHNOLOGY ( TECHNOLOGY           ),
         .PWM_ENA    ( PWM_ENA[gen_j]       ),
         .CMP_ENA    ( CMP_ENA[gen_j]       ),
         .CPT_ENA    ( CPT_ENA[gen_j]       ),
         .CPT_SYNC   ( CPT_SYNC[2*gen_j+:2] ),
         .USE_CG     ( USE_CG               )
      ) core_inst
      (
         .tmr_clk     ( tmr_clk[gen_j]        ),
         .tmr_reset_n ( tmr_reset_n[gen_j]    ),
         .test_mode   ( test_mode             ),
         .ena         ( ena$tmr[gen_j]        ),
         .pause       ( pause$tmr[gen_j]      ),
         .dir         ( dir$tmr[gen_j]        ),
         .one_shot    ( oneshot$tmr[gen_j]    ),
         .pwm_comp    ( pwm_comp[gen_j]       ),
         .dead_time   ( tmr_dead[gen_j]       ),
         .load_val    ( tmr_load[gen_j]       ),
         .match       ( match[gen_j]          ),
         .stop        ( tmr_stop[gen_j]       ),
         .tmr_mode    ( tmr_mode$tmr[gen_j]   ),
         .tmr_val     ( tmr_val[gen_j]        ),
         .tmr_pre     ( tmr_pre[gen_j]        ),
         .cpt_in      ( cpt_in[gen_j*2+:2]    ),
         .cpt_sel     ( cpt_sel$tmr[gen_j]    ),
         .cpt_type    ( cpt_type$tmr[gen_j]   ),
         .cpt_start   ( cpt_start$tmr[gen_j]  ),
         .cpt_stop    ( cpt_stop$tmr[gen_j]   ),
         .cmp_en      ( cmp_en$tmr[gen_j]     ),
         .cmp_type    ( cmp_type$tmr[gen_j]   ),
         .cmp_out     ( cmp_out[gen_j*3+:3]   ),
         .cmp_out_n   ( cmp_out_n[gen_j*3+:3] ),
         .tmr_cpt     ( tmr_cpt[gen_j]        ),
         .capture     ( capture[gen_j]        ),
         .compare     ( compare[gen_j]        ),
         .cmpa_t0     ( cmpa_t0[gen_j]        ),
         .cmpa_t1     ( cmpa_t1[gen_j]        ),
         .cmpb_t0     ( cmpb_t0[gen_j]        ),
         .cmpb_t1     ( cmpb_t1[gen_j]        ),
         .cmpc_t0     ( cmpc_t0[gen_j]        ),
         .cmpc_t1     ( cmpc_t1[gen_j]        )
      );
   end
//--------------------------------------------
// Interrupt generation logic
//--------------------------------------------
   wire [NTIMERS-1:0] capture$clk;
   wire [NTIMERS-1:0] compare$clk;
   if(SYNC_MODE)
   begin : isync
      assign match$clk = match;
      assign capture$clk = capture;
      assign compare$clk = compare;
      assign tmr_stop$clk = tmr_stop;
   end
   else
   begin : iasync
      ehl_cdc_pulse
      #(
         .SYNC_STAGE ( CDC_SYNC_STAGE ),
         .TECHNOLOGY ( TECHNOLOGY     )
      ) ev_sync [4*NTIMERS-1:0]
      (
         .src_clk     ( {4{tmr_clk}}     ),
         .src_reset_n ( {4{tmr_reset_n}} ),
         .src         ( {tmr_stop,
                         compare,
                         capture,
                         match}          ),
         .dst_clk     ( clk              ),
         .dst_reset_n ( reset_n          ),
         .dst         ( {tmr_stop$clk,
                         compare$clk,
                         capture$clk,
                         match$clk}      )
      );
   end

   integer i;
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      ifl <= 12'h0;
   else
   begin
      for(i = 0; i < NTIMERS; i = i + 1)
      begin
         // Note: new event asserts Interrupt Flag
         if(match$clk[i] & ie[i])
            ifl[i] <= 1'b1;
         // Note: flag can be cleared by writing 1. New event has higher priority over clear.
         else if(addr[7:2] == {2'b0, 4'h9} && wr_strb[0] && csr_din[i])
            ifl[i] <= 1'b0;

         // Note: new event asserts Interrupt Flag
         if(capture$clk[i] & ie[4+i])
            ifl[4+i] <= 1'b1;
         // Note: flag can be cleared by writing 1. New event has higher priority over clear.
         else if(addr[7:2] == {2'b0, 4'h9} && wr_strb[0] && csr_din[4+i])
            ifl[4+i] <= 1'b0;

         // Note: new event asserts Interrupt Flag
         if(compare$clk[i] & ie[8+i])
            ifl[8+i] <= 1'b1;
         // Note: flag can be cleared by writing 1. New event has higher priority over clear.
         else if(addr[7:2] == {2'b0, 4'h9} && wr_strb[1] && csr_din[8+i])
            ifl[8+i] <= 1'b0;
      end
   end

   assign irq = |ifl;
//--------------------------------------------
// CSR read access
//
// Note: default address (0x0) should not point to uninitialized register
//--------------------------------------------
   integer k;
   always@*
   begin
      dout = 0;
      for(k = 0; k < NTIMERS; k = k + 1)
         if(addr[7:6] == k)
            dout = tmr_dout[k];

      if(BUS_WIDTH == 8)
      begin
         if(addr[7:0] == {2'b0, 4'h8, 2'b0})
            dout = ie[7:0];
         if(addr[7:0] == {2'b0, 4'h8, 2'b1})
            dout = ie[11:8];
         if(addr[7:0] == {2'b0, 4'h9, 2'b0})
            dout = ifl[7:0];
         if(addr[7:0] == {2'b0, 4'h9, 2'b1})
            dout = ifl[11:8];
      end
      if(BUS_WIDTH == 32)
      begin
         if(addr[7:0] == {2'b0, 4'h8, 2'b0})
            dout = ie;
         if(addr[7:0] == {2'b0, 4'h9, 2'b0})
            dout = ifl;
      end
   end

endmodule
