// Design:           Timer CSR
// Revision:         1.0
// Date:             2021-12-10
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2021-12-10 A.Kornukhin: Initial release

module ehl_timer_csr
#(
   parameter BUS_WIDTH   = 32,
             INDEX       = 0,    // timer index (0-3)
             TIMER_WIDTH = 32,
             PWM_ENA     = 0,
             CMP_ENA     = 0,
             CPT_ENA     = 0,
   parameter [0:0] USE_CG = 1'b1
)
(
   input wire                   clk,      // bus clock
                                reset_n,  // bus reset
   input wire [3:0]             wr_strb,  // write strobe
   input wire [7:0]             addr,     // bus address
   input wire [31:0]            din,      // bus data in
   output wire [BUS_WIDTH-1:0]  dout,     // bus data out
   output reg [TIMER_WIDTH-1:0] tmr_load,
   output reg [TIMER_WIDTH-1:0] tmr_dead,
   output reg [7:0]             tmr_pre,
   input wire [TIMER_WIDTH-1:0] tmr_val,
   input wire [TIMER_WIDTH-1:0] tmr_cpt,
   input wire                   stop_tmr,
   output reg                   oneshot,
   output reg                   ena,
   output reg                   pause,
   output reg                   dir,
   output reg [2:0]             tmr_mode,
   output reg [2:0]             cmp_en,
   output reg [1:0]             cmp_type,
   output reg                   cpt_sel,
   output reg [1:0]             cpt_type,
   output reg [1:0]             cpt_start,
   output reg [1:0]             cpt_stop,
   output reg                   pwm_comp,
   output reg [TIMER_WIDTH-1:0] cmpa_t0,
   output reg [TIMER_WIDTH-1:0] cmpa_t1,
   output reg [TIMER_WIDTH-1:0] cmpb_t0,
   output reg [TIMER_WIDTH-1:0] cmpb_t1,
   output reg [TIMER_WIDTH-1:0] cmpc_t0,
   output reg [TIMER_WIDTH-1:0] cmpc_t1
);
//--------------------------------------------
// Address map
//--------------------------------------------
   localparam [3:0]
      TMR_CFG      = 4'b0000,
      TMR_CTRL     = 4'b0001,
      TMR_CTRL_ALL = 4'b0010,
      TMR_DEAD     = 4'b0011,
      TMR_LOAD     = 4'b0100,
      TMR_PRE      = 4'b0101,
      TMR_VALUE    = 4'b0110,
      TMR_CPT      = 4'b0111,
      // Note: common for IRQ
//      TMR_r8 = 4'b1000,
//      TMR_r9 = 4'b1001,
      TMR_CMPA_T0  = 4'b1010,
      TMR_CMPA_T1  = 4'b1011,
      TMR_CMPB_T0  = 4'b1100,
      TMR_CMPB_T1  = 4'b1101,
      TMR_CMPC_T0  = 4'b1110,
      TMR_CMPC_T1  = 4'b1111;

   localparam NBYTES = TIMER_WIDTH / 8;
//--------------------------------------------
// Registers
//--------------------------------------------
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
   begin
      oneshot   <= 1'b0;
      tmr_mode  <= 3'h0;
      cmp_en    <= 3'b0;
      cmp_type  <= 2'h0;
      cpt_sel   <= 1'b0;
      cpt_type  <= 2'h0;
      cpt_start <= 2'b0;
      cpt_stop  <= 2'h0;
      dir       <= 1'b0;
      pwm_comp  <= 1'b0;
   end
   else if(addr[5:2] == TMR_CFG && addr[7:6] == INDEX)
   begin
      if(wr_strb[0])
      begin
         tmr_mode <= din[2:0];
         if(CMP_ENA | PWM_ENA)
            cmp_en   <= din[5:3];
         if(CMP_ENA)
            cmp_type <= din[7:6];
      end

      if(wr_strb[1])
      begin
         if(CPT_ENA)
         begin
            cpt_sel   <= din[8];
            cpt_type  <= din[10:9];
            cpt_start <= din[12:11];
            cpt_stop  <= din[14:13];
         end
      end

      if(wr_strb[2])
      begin
         oneshot <= din[17];
         dir     <= din[16];
         if(PWM_ENA)
            pwm_comp <= din[18];
      end
   end

   always@(posedge clk or negedge reset_n)
   if(!reset_n)
   begin
      ena   <= 1'b0;
      pause <= 1'b0;
   end
   else if(addr[5:2] == TMR_CTRL && addr[7:6] == INDEX && wr_strb[0])
   begin
      ena   <= din[0];
      pause <= din[1];
`ifndef SYNTHESIS
      if(din[0] && tmr_load==='hx)
         $display("   Error: '%m' timer's load value must be initialized before start timer at %0t.", $time);
//       if(din[0] && (pwma_t0==='hx || pwma_t1==='hx) && pwma_en)
//          $display("   Error: '%m' PWM A timings must be initialized before start timer at %0t.", $time);
//       if(din[0] && (pwmb_t0==='hx || pwmb_t1==='hx) && pwmb_en)
//          $display("   Error: '%m' PWM B timings must be initialized before start timer at %0t.", $time);
//       if(din[0] && (pwmc_t0==='hx || pwmc_t1==='hx) && pwmc_en)
//          $display("   Error: '%m' PWM C timings must be initialized before start timer at %0t.", $time);
`endif
   end
   else if(addr[5:2] == TMR_CTRL_ALL && wr_strb[0])
   begin
      ena   <= din[0 + 2*INDEX];
      pause <= din[1 + 2*INDEX];
   end
   // Note: clear when timer expired in 'one_shot' mode or when capture/compare timer expired
   else if(stop_tmr & (oneshot | (tmr_mode == 3'b001)))
      ena <= 1'b0;

   always@(posedge clk)
   begin : tload
      integer i;
      if(addr[5:2] == TMR_LOAD && addr[7:6] == INDEX)
         for(i = 0; i < NBYTES; i = i + 1)
            if(wr_strb[i])
               tmr_load[i*8+:8] <= din[i*8+:8];
   end

   if(PWM_ENA)
   begin : xpwmdead
      always@(posedge clk)
      begin : tdead
         integer i;
         if(addr[5:2] == TMR_DEAD && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  tmr_dead[i*8+:8] <= din[i*8+:8];
      end
   end
   else
   begin : xnopwmdead
      always_comb
         tmr_dead = 0;
   end

   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      tmr_pre <= 8'b0;
   else if(addr[5:2] == TMR_PRE && addr[7:6] == INDEX && wr_strb[0])
      tmr_pre <= USE_CG==1'b1 ? din[7:0] : 8'h0; // redundant if no clock gating supported by the technology

   if(PWM_ENA | CMP_ENA)
   begin : xpwm
      always@(posedge clk)
      begin : tpwm
         integer i;

         if(addr[5:2] == TMR_CMPA_T0 && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  cmpa_t0[i*8+:8] <= din[i*8+:8];

         if(addr[5:2] == TMR_CMPA_T1 && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  cmpa_t1[i*8+:8] <= din[i*8+:8];

         if(addr[5:2] == TMR_CMPB_T0 && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  cmpb_t0[i*8+:8] <= din[i*8+:8];

         if(addr[5:2] == TMR_CMPB_T1 && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  cmpb_t1[i*8+:8] <= din[i*8+:8];

         if(addr[5:2] == TMR_CMPC_T0 && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  cmpc_t0[i*8+:8] <= din[i*8+:8];

         if(addr[5:2] == TMR_CMPC_T1 && addr[7:6] == INDEX)
            for(i = 0; i < NBYTES; i = i + 1)
               if(wr_strb[i])
                  cmpc_t1[i*8+:8] <= din[i*8+:8];
      end
   end
   else
   begin : xnopwm
      always_comb
      begin
         cmpa_t0 = 0;
         cmpa_t1 = 0;
         cmpb_t0 = 0;
         cmpb_t1 = 0;
         cmpc_t0 = 0;
         cmpc_t1 = 0;
      end
   end
//--------------------------------------------
// output multiplexor
//--------------------------------------------
   if(BUS_WIDTH == 32)
      assign dout =
         addr[5:2] == TMR_CFG     ? {pwm_comp, oneshot, dir, 1'b0, cpt_stop, cpt_start, cpt_type, cpt_sel, cmp_type, cmp_en, tmr_mode} :
         addr[5:2] == TMR_CTRL    ? {pause, ena} :
         addr[5:2] == TMR_DEAD    ? tmr_dead :
         addr[5:2] == TMR_LOAD    ? tmr_load :
         addr[5:2] == TMR_PRE     ? tmr_pre :
         addr[5:2] == TMR_VALUE   ? tmr_val :
         addr[5:2] == TMR_CPT     ? tmr_cpt :
         addr[5:2] == TMR_CMPA_T0 ? cmpa_t0 :
         addr[5:2] == TMR_CMPA_T1 ? cmpa_t1 :
         addr[5:2] == TMR_CMPB_T0 ? cmpb_t0 :
         addr[5:2] == TMR_CMPB_T1 ? cmpb_t1 :
         addr[5:2] == TMR_CMPC_T0 ? cmpc_t0 :
         addr[5:2] == TMR_CMPC_T1 ? cmpc_t1 :
         0;
   if(BUS_WIDTH == 8)
      assign dout =
         addr[5:0] == {TMR_CFG,2'd0}  ? {cmp_type, cmp_en, tmr_mode} :
         addr[5:0] == {TMR_CFG,2'd1}  ? {cpt_stop, cpt_start, cpt_type, cpt_sel} :
         addr[5:0] == {TMR_CFG,2'd2}  ? {pwm_comp, oneshot, dir} :
         addr[5:0] == {TMR_CTRL,2'd0} ? {pause, ena} :
         addr[5:2] == TMR_DEAD        ? tmr_dead >> (8*addr[1:0]) :
         addr[5:2] == TMR_LOAD        ? tmr_load >> (8*addr[1:0]) :
         addr[5:0] == {TMR_PRE,2'd0}  ? tmr_pre :
         addr[5:2] == TMR_VALUE       ? tmr_val >> (8*addr[1:0]) :
         addr[5:2] == TMR_CPT         ? tmr_cpt >> (8*addr[1:0]) :
         addr[5:2] == TMR_CMPA_T0     ? cmpa_t0 >> (8*addr[1:0]) :
         addr[5:2] == TMR_CMPA_T1     ? cmpa_t1 >> (8*addr[1:0]) :
         addr[5:2] == TMR_CMPB_T0     ? cmpb_t0 >> (8*addr[1:0]) :
         addr[5:2] == TMR_CMPB_T1     ? cmpb_t1 >> (8*addr[1:0]) :
         addr[5:2] == TMR_CMPC_T0     ? cmpc_t0 >> (8*addr[1:0]) :
         addr[5:2] == TMR_CMPC_T1     ? cmpc_t1 >> (8*addr[1:0]) :
         0;

endmodule
