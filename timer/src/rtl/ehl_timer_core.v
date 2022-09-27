// Design:           Timer core
// Revision:         1.0
// Date:             2021-12-10
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2021-12-10 A.Kornukhin: Initial release

module ehl_timer_core
#(
   parameter WIDTH      = 32,
             SYNC_STAGE = 3,
             TECHNOLOGY = 0,
             PWM_ENA    = 0,
             CMP_ENA    = 0,
             CPT_ENA    = 0,
   parameter [0:0] USE_CG = 1'b1,
   parameter [1:0] CPT_SYNC = 2'b11
)
(
   input wire              tmr_clk,
                           tmr_reset_n,
                           test_mode,
                           ena,
                           pause,
                           dir,
                           one_shot,
   input wire [WIDTH-1:0]  load_val,
   input wire [WIDTH-1:0]  dead_time,
   output reg              match,       // pulsed high when counter expired (one-shot or periodic mode)
   output reg              stop,        // pulsed high when counter expired (one-shot mode); or stop capture event detected
   output reg [WIDTH-1:0]  tmr_val,
   output reg [WIDTH-1:0]  tmr_cpt,
   input wire [7:0]        tmr_pre,
   input wire [2:0]        tmr_mode,
   input wire [1:0]        cpt_in,
   input wire              cpt_sel,
   input wire [1:0]        cpt_type,
   input wire [1:0]        cpt_start,
   input wire [1:0]        cpt_stop,
   input                   pwm_comp,
   output reg              capture,     // pulsed high when capture event detected
   input wire [2:0]        cmp_en,
   input wire [1:0]        cmp_type,
   output reg [2:0]        cmp_out,
                           cmp_out_n,
   output reg              compare,     // pulsed high when compare event detected
   input wire [WIDTH-1:0]  cmpa_t0,
                           cmpa_t1,
                           cmpb_t0,
                           cmpb_t1,
                           cmpc_t0,
                           cmpc_t1
);
//------------------------------------
// Prescale input clock
// TODO: synchronize with timer start...
//------------------------------------
   wire clk_en;
   wire tmr_clk_pre;
   if(USE_CG == 1'b1)
   begin : cg
      ehl_lbcd
      #(
         .DIV_WIDTH  ( 8          ),
         .TECHNOLOGY ( TECHNOLOGY ),
         .PASS_VAL   ( 0          )
      ) presc_inst
      (
         .clk          ( tmr_clk     ),
         .reset_n      ( tmr_reset_n ),
         .load         ( 1'b0        ),
         .ena          ( 1'b1        ),
         .test_mode    ( test_mode   ),
         .divider      ( tmr_pre     ),
         .clk_en       ( clk_en      ),
         .clk_out      ( tmr_clk_pre ),
         .clk_out_load (             )
      );
   end
   else
   begin : nocg
      assign tmr_clk_pre = tmr_clk;
      assign clk_en = 1'b1;
   end
//------------------------------------
// Start capture
//------------------------------------
   wire cpt_in$tmr;
   wire start_edge_det;
   wire [1:0] start_edge_mode = (cpt_start == 2'b01) ? 2'b00 : // posedge
                                 cpt_start == 2'b10  ? 2'b01 : // negedge
                                 2'b11; // any edge
   ehl_pulse
   #(
      .INIT ( 1'b0 )
   ) start_edge_det_inst
   (
      .clk      ( tmr_clk_pre     ),
      .reset_n  ( tmr_reset_n     ),
      .data_in  ( cpt_in$tmr      ),
      .mode     ( start_edge_mode ),
      .resync   ( 1'b0            ),
      .data_out ( start_edge_det  )
   );
//------------------------------------
// Stop capture
//------------------------------------
   wire stop_edge_det;
   wire [1:0] stop_edge_mode = (cpt_stop == 2'b01) ? 2'b00 : // posedge
                                cpt_stop == 2'b10  ? 2'b01 : // negedge
                                2'b11; // any edge
   ehl_pulse
   #(
      .INIT ( 1'b0 )
   ) stop_edge_det_inst
   (
      .clk      ( tmr_clk_pre    ),
      .reset_n  ( tmr_reset_n    ),
      .data_in  ( cpt_in$tmr     ),
      .mode     ( stop_edge_mode ),
      .resync   ( 1'b0           ),
      .data_out ( stop_edge_det  )
   );
//------------------------------------
// Modes decoding
//------------------------------------
   wire count_mode = tmr_mode[2];// == 3'b100;
   wire cpt_mode   = tmr_mode == 3'b001;
   wire pwm_mode   = PWM_ENA && tmr_mode == 3'b011;
   wire cmp_mode   = CMP_ENA && tmr_mode == 3'b010;
//------------------------------------
// States decoding
//------------------------------------
   reg ena_delay;
   wire tmr_active = ena & ena_delay & !pause;
   wire load_init  = ena & !ena_delay; // TODO: and not PAUSE!!!
//------------------------------------
// Counter
//------------------------------------
   wire cpt_act, cpt_ovf;
   reg cpt_ovf_r;
   reg got_cpt_r;
   reg stop_r; // copy of 'stop' at divided frequency

   wire cpt_start_event = !pause & ((CPT_ENA && cpt_mode) ? (cpt_start == 2'b00 ? 1'b1 : start_edge_det & !got_cpt_r) : 1'b0);
   wire cpt_stop_event  = !pause & ((CPT_ENA && cpt_mode) ? (cpt_stop == 2'b00  ? 1'b0 : stop_edge_det & got_cpt_r)   : 1'b0);

   wire got_cpt = got_cpt_r | (cpt_start_event & !load_init);
   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      got_cpt_r <= 1'b0;
   else if(load_init | stop_r)
      got_cpt_r <= 1'b0;
   else if(cpt_start_event)
      got_cpt_r <= 1'b1;

   reg done_cpt_r;
   wire done_cpt = done_cpt_r | (cpt_stop_event & !load_init);
   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      done_cpt_r <= 1'b0;
   else if(load_init | stop_r)
      done_cpt_r <= 1'b0;
   else if(cpt_stop_event)
      done_cpt_r <= 1'b1;

   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      ena_delay <= 1'b0;
   else
      ena_delay <= ena;

   wire match_combo = (dir ? tmr_val == load_val : tmr_val == 0) && tmr_active;
   wire one_shot_done = one_shot && match_combo;
   reg done_os;
// Note: generate internal STOP when in oneshot mode
   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      done_os <= 1'b0;
   else if(!ena) // Q: restart via !ena->ena!?
      done_os <= 1'b0;
   else if(one_shot_done)
      done_os <= 1'b1;

// Note: counter can be started via synchronized (delayed) START
//       it is active via ENA which is cleared via synchronized (delayed) STOP
//       thus ENA reflects to non-synchronized value
//       to achieve so, internal ENA masked with end-of-count flag (one_shot_done, or capture_done - TODO: others!?)
   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      tmr_val <= {WIDTH{1'b0}};
   // Note: initial load, or load by start event (do not count it)
   else if(load_init | (cpt_start_event & !got_cpt))
      tmr_val <= dir ? 0 : load_val;
   // Note: - allow to pause timer
   //       - oneshot done masks 'ena'
   else if(tmr_active && !(done_os | one_shot_done) && (count_mode ? cpt_act : cpt_mode ? got_cpt & !done_cpt & !cpt_ovf_r : 1'b1))
      tmr_val <= dir ?
                      ((tmr_val != load_val) ? tmr_val + 1 : 0) : // increment
                      (tmr_val ? (tmr_val - 1) : load_val);       // decrement

   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      stop_r <= 1'b0;
   // Note: stop counter when:
   //       - timer expired, or
   //       - capture made (i.e. stop capture event detected)
   else
      stop_r <= match_combo | done_cpt;
//------------------------------------
// Compare
// - modify output when enabled and timer matches compare registers
// - event generated when enabled and matched
//------------------------------------
   wire [2:0] cmp_match;
   assign cmp_match[0] = cmp_en[0] && ((cmpa_t0 == tmr_val) || (cmpa_t1 == tmr_val)) && tmr_active;
   assign cmp_match[1] = cmp_en[1] && ((cmpb_t0 == tmr_val) || (cmpb_t1 == tmr_val)) && tmr_active;
   assign cmp_match[2] = cmp_en[2] && ((cmpc_t0 == tmr_val) || (cmpc_t1 == tmr_val)) && tmr_active;
//------------------------------------
// PWM
// - assert output when timer inside specified range
//------------------------------------
   integer i;
   wire [2:0] pwm_inside;
   assign pwm_inside[0] = cmp_en[0] && ((tmr_val >= cmpa_t0) && (tmr_val <= cmpa_t1)) && tmr_active;
   assign pwm_inside[1] = cmp_en[1] && ((tmr_val >= cmpb_t0) && (tmr_val <= cmpb_t1)) && tmr_active;
   assign pwm_inside[2] = cmp_en[2] && ((tmr_val >= cmpc_t0) && (tmr_val <= cmpc_t1)) && tmr_active;
   wire [2:0] pwmn_inside;
   assign pwmn_inside[0] = cmp_en[0] && ((tmr_val > (cmpa_t1 + dead_time)) || (tmr_val < (cmpa_t0 - dead_time))) && tmr_active && pwm_comp;
   assign pwmn_inside[1] = cmp_en[1] && ((tmr_val > (cmpb_t1 + dead_time)) || (tmr_val < (cmpb_t0 - dead_time))) && tmr_active && pwm_comp;
   assign pwmn_inside[2] = cmp_en[2] && ((tmr_val > (cmpc_t1 + dead_time)) || (tmr_val < (cmpc_t0 - dead_time))) && tmr_active && pwm_comp;

   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
   begin
      cmp_out   <= 3'h0;
      cmp_out_n <= 3'h0;
   end
   else if(pwm_mode)
   begin
      cmp_out   <= pwm_inside;
      cmp_out_n <= pwmn_inside;
   end
   else if(cmp_mode)
   begin
      cmp_out_n <= 3'h0;
      for(i = 0; i < 3; i = i + 1)
      begin
         if(cmp_match[i])
         begin
            if(cmp_type == 2'b00)        cmp_out[i] <= 1'b1;
            else if(cmp_type == 2'b01)   cmp_out[i] <= 1'b0;
            else if(cmp_type[1] == 1'b1) cmp_out[i] <= ~cmp_out[i];
         end
      end
   end
   // Note: outputs keep their last value until leaving PWM and COMPARE modes
   else
   begin
      cmp_out   <= 3'b0;
      cmp_out_n <= 3'b0;
   end
//------------------------------------
// Capture
   // Note: resync input signal
   // Note: every signal can be configured independently for synchronizers presence
   //       when both are synchronized - single one is used
   //       when none are synchronized - bypass mode selected
   //       when 1 is selected, it is used
//------------------------------------
   if(CPT_SYNC == 2'b00)
   begin : nosync
      // Note: select single external channel before synchronizer to reduce logic size (as well as power)
      assign cpt_in$tmr = cpt_sel ? cpt_in[1] : cpt_in[0];
   end
   else if(CPT_SYNC == 2'b01)
   begin : synca
      wire cpt_sync;
      ehl_cdc
      #(
         .SYNC_STAGE   ( SYNC_STAGE ),
         .WIDTH        ( 1          ),
         .TECHNOLOGY   ( TECHNOLOGY ),
         .INIT_VAL     ( 1'b0       ),
         .SIM_ADD_META ( 1'b0       )
      ) cpt_sync_inst
      (
         .clk     ( tmr_clk_pre ),
         .reset_n ( tmr_reset_n ),
         .din     ( cpt_in[0]   ),
         .dout    ( cpt_sync    )
      );
      assign cpt_in$tmr = cpt_sel ? cpt_in[1] : cpt_sync;
   end
   else if(CPT_SYNC == 2'b10)
   begin : syncb
      wire cpt_sync;
      ehl_cdc
      #(
         .SYNC_STAGE   ( SYNC_STAGE ),
         .WIDTH        ( 1          ),
         .TECHNOLOGY   ( TECHNOLOGY ),
         .INIT_VAL     ( 1'b0       ),
         .SIM_ADD_META ( 1'b0       )
      ) cpt_sync_inst
      (
         .clk     ( tmr_clk_pre ),
         .reset_n ( tmr_reset_n ),
         .din     ( cpt_in[1]   ),
         .dout    ( cpt_sync    )
      );
      assign cpt_in$tmr = cpt_sel ? cpt_sync : cpt_in[0];
   end
   else if(CPT_SYNC == 2'b11)
   begin : sync
      wire cpt_in_sel = cpt_sel ? cpt_in[1] : cpt_in[0];
      ehl_cdc
      #(
         .SYNC_STAGE   ( SYNC_STAGE ),
         .WIDTH        ( 1          ),
         .TECHNOLOGY   ( TECHNOLOGY ),
         .INIT_VAL     ( 1'b0       ),
         .SIM_ADD_META ( 1'b0       )
      ) cpt_sync_inst
      (
         .clk     ( tmr_clk_pre ),
         .reset_n ( tmr_reset_n ),
         .din     ( cpt_in_sel  ),
         .dout    ( cpt_in$tmr  )
      );
   end

   wire edge_det;
   wire rise_4 = cpt_type == 2'b10;
   wire [1:0] edge_mode = (cpt_type == 2'b00) || (cpt_type == 2'b10) ? 2'b00 : // posedge
                          cpt_type == 2'b01 ? 2'b01 : // negedge
                          2'b10; // any edge
   ehl_pulse
   #(
      .INIT ( 1'b0 )
   ) edge_det_inst
   (
      .clk      ( tmr_clk_pre ),
      .reset_n  ( tmr_reset_n ),
      .data_in  ( cpt_in$tmr  ),
      .mode     ( edge_mode   ),
      .resync   ( 1'b0        ),
      .data_out ( edge_det    )
   );

   assign cpt_ovf = got_cpt && match_combo;
   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      cpt_ovf_r <= 1'b0;
   else if(!ena)
      cpt_ovf_r <= 1'b0;
   else if(cpt_ovf)
      cpt_ovf_r <= 1'b1;

   // Note: count active edges
   reg [1:0] edge_cnt;
   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      edge_cnt <= 2'b0;
   else if(!cpt_mode || !ena) // when timer disabled or other mode selected, counter is cleared
      edge_cnt <= 2'b0;
   else if(edge_det && rise_4 && got_cpt && ena)
      edge_cnt <= edge_cnt + 2'b1;

   assign cpt_act = !pause & (rise_4 ? edge_det && edge_cnt==2'b11 : edge_det);
   wire event_cpt = CPT_ENA && cpt_mode && cpt_act && /*done_cpt */got_cpt && ena;

   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   if(!tmr_reset_n)
      tmr_cpt <= {WIDTH{1'b0}};
   else if(event_cpt)
      tmr_cpt <= tmr_val;
//------------------------------------
// Interface to CSR
// Core works on divided clock, in synchronous mode this means
//    that output pulses have longer duration than CLK (TMR_CLK).
// Need to cut them to 1 cycle. This is achieved by clearing this pulses
//  at the next cycle after divided clock.
//------------------------------------
// Note: pulse duration is 1 non-divided clock cycle (external receiver uses undivided clock)
//   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   always@(posedge tmr_clk or negedge tmr_reset_n)
   if(!tmr_reset_n)
      match <= 1'b0;
//   else 
//      match <= match_combo; // Q: if timer stopped and preserves latest value... will we get 2-3 cycles long 'match'
   else if(clk_en)
      match <= match_combo;
   else
      match <= 1'b0;

//   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   always@(posedge tmr_clk or negedge tmr_reset_n)
   if(!tmr_reset_n)
      capture <= 1'b0;
//   else
//      capture <= event_cpt;
   else if(clk_en)
      capture <= event_cpt;
   else
      capture <= 1'b0;

//   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   always@(posedge tmr_clk or negedge tmr_reset_n)
   if(!tmr_reset_n)
      compare <= 1'b0;
//   else
//      compare <= |cmp_match;
   else if(clk_en)
      compare <= |cmp_match;
   else
      compare <= 1'b0;
// Q: is it possible to have 2 pulses in a row
//   always@(posedge tmr_clk_pre or negedge tmr_reset_n)
   always@(posedge tmr_clk or negedge tmr_reset_n) // sibling of 'stop_r'
   if(!tmr_reset_n)
      stop <= 1'b0;
//   else
//      stop <= match_combo | done_cpt;
   else if(clk_en)
      stop <= match_combo | done_cpt;
   else
      stop <= 1'b0;

endmodule
