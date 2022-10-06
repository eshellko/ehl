// Design:           Dual Clock FIFO with flags
// Revision:         2.0
// Date:             2022-10-06
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0  2011-07-10 A.Kornukhin: initial release
//                   1.1  2013-12-18 A.Kornukhin: assertions added
//                   1.2  2014-10-24 A.Kornukhin: 'sw_dram' renamed to 'sw_spram'
//                   1.3  2015-01-18 A.Kornukhin: almost_full/empty added
//                   1.4  2016-12-08 A.Kornukhin: DesignWare implementation added
//                   1.5  2016-12-12 A.Kornukhin: 'write_credit' output added
//                   1.6  2017-01-13 A.Kornukhin: 'res' for both domains changed to
//                        w_reset_n and r_reset_n synchronized externally to write and read
//                        domains respectively, parameter RES_TYPE added for backward compatibility
//                   1.7  2017-01-21 A.Kornukhin: 'RAM_ADDR' added to improve timing
//                   1.8  2017-06-19 A.Kornukhin: 'USE_DPRAM' added to allow Dual-port RAM to be used with this core
//                   1.9  2019-01-25 A.Kornukhin: Gray coding  assertions added
//                   1.10 2022-09-21 A.Kornukhin: gate output when 'r_empty' asserted
//                   2.0  2022-10-06 A.Kornukhin: remove non-classical synchronization modes

// TODO: make registered output with registered full/empty flags that use 'wr & rd' to define full/overflow logic...

// TODO: allow 2*n depth FIFO (not only 2**n)
// Q: but address of RAM should be converted to non-interrupted [0:2m) region

// TODO: provide 'valid' output that asserted combo from 'rd' for SPRAM, or delayed for DPRAM

module ehl_fifo
#(
   parameter       WIDTH_DIN      = 32'd32,
                   WIDTH_DOUT     = 32'd8,
                   DEPTH          = 32'd16,
                   SYNC_STAGE     = 2'd2,
                   TECHNOLOGY     = 0, // DPRAM/SPRAM technology
                   CDC_TECHNOLOGY = 0,
   parameter [0:0] CDC_REPORT     = 1'b1,
   parameter [0:0] USE_DPRAM      = 1'b0 // 0 - single port RAM, 1 - dual port RAM with registered output (another functionality)
)
(
   input                                                                           wclk, rclk, wr, rd,
                                                                                   w_reset_n, r_reset_n,
   input [WIDTH_DIN-1:0]                                                           wdat,
   output [WIDTH_DOUT-1:0]                                                         rdat,
   output                                                                          w_overflow, r_underflow,
   output                                                                          w_empty, r_empty, w_full, r_full,
   output                                                                          w_aempty, r_aempty, w_afull, r_afull,
   input                                                                           clr_of, clr_uf,
   output [$clog2(WIDTH_DIN<=WIDTH_DOUT ? DEPTH : DEPTH*(WIDTH_DOUT/WIDTH_DIN)):0] write_credit

);
   localparam WC_CNT = WIDTH_DIN<WIDTH_DOUT ? WIDTH_DOUT/WIDTH_DIN : 32'd1;
   localparam RC_CNT = WIDTH_DIN>WIDTH_DOUT ? WIDTH_DIN/WIDTH_DOUT : 32'd1;
   localparam FIFO_CNT = WC_CNT>1 ? WC_CNT : RC_CNT;
   localparam CS_WIDTH = FIFO_CNT==1 ? 32'd1 : $clog2(FIFO_CNT);
   localparam FIFO_WIDTH = WIDTH_DIN<=WIDTH_DOUT ? WIDTH_DIN : WIDTH_DOUT;
   localparam FIFO_DEPTH = WIDTH_DIN<=WIDTH_DOUT ? DEPTH/FIFO_CNT : DEPTH;
   localparam FIFO_ADR_WIDTH = FIFO_DEPTH<=1 ? 32'd0 : $clog2(FIFO_DEPTH);
   wire [FIFO_ADR_WIDTH:0] w_wptr, w_rptr, r_wptr, r_rptr;
   wire [FIFO_DEPTH==1 ? 0 : FIFO_ADR_WIDTH-1:0] waddr, raddr;
   wire [FIFO_CNT-1:0] w_cs;
   wire [CS_WIDTH-1:0] r_cs;
   wire [FIFO_WIDTH*FIFO_CNT-1:0] data_write, data_read;

   localparam AWIDTH = FIFO_ADR_WIDTH==0 ? 1 : FIFO_ADR_WIDTH;

   genvar gen_ram;
   ehl_fifo_rc
   #(
      .FIFO_ADR_WIDTH ( FIFO_ADR_WIDTH ),
      .FIFO_CNT       ( FIFO_CNT       ),
      .CS_WIDTH       ( CS_WIDTH       ),
      .WC_CNT         ( WC_CNT         ),
      .RC_CNT         ( RC_CNT         ),
      .FIFO_DEPTH     ( FIFO_DEPTH     )
   ) rc
   (
      .rclk        ( rclk        ),
      .reset_n     ( r_reset_n   ),
      .rd          ( rd          ),
      .clr_uf      ( clr_uf      ),
      .rptr_gray   ( r_rptr      ),
      .raddr       ( raddr       ),
      .wptr_gray   ( r_wptr      ),
      .r_full      ( r_full      ),
      .r_empty     ( r_empty     ),
      .r_aempty    ( r_aempty    ),
      .r_afull     ( r_afull     ),
      .r_underflow ( r_underflow ),
      .cs_cnt      ( r_cs        )
   );

   ehl_fifo_wc
   #(
      .FIFO_ADR_WIDTH ( FIFO_ADR_WIDTH ),
      .FIFO_CNT       ( FIFO_CNT       ),
      .CS_WIDTH       ( CS_WIDTH       ),
      .WC_CNT         ( WC_CNT         ),
      .RC_CNT         ( RC_CNT         ),
      .FIFO_DEPTH     ( FIFO_DEPTH     )
   ) wc
   (
      .wclk         ( wclk         ),
      .reset_n      ( w_reset_n    ),
      .wr           ( wr           ),
      .clr_of       ( clr_of       ),
      .wptr_gray    ( w_wptr       ),
      .waddr        ( waddr        ),
      .rptr_gray    ( w_rptr       ),
      .w_full       ( w_full       ),
      .w_empty      ( w_empty      ),
      .w_afull      ( w_afull      ),
      .w_aempty     ( w_aempty     ),
      .w_overflow   ( w_overflow   ),
      .cs           ( w_cs         ),
      .write_credit ( write_credit )
   );

`ifdef ALTERA
generate
`endif
   if(USE_DPRAM)
   begin : dpram
      ehl_dpram
      #(
         .WIDTH      ( FIFO_WIDTH ),
         .AWIDTH     ( AWIDTH     ),
         .TECHNOLOGY ( TECHNOLOGY )
      ) dpram_inst [FIFO_CNT-1:0]
      (
         .wclk   ( wclk       ),
         .rclk   ( rclk       ),
         .wr     ( w_cs       ),
         .rd     ( rd         ),
         .res    ( r_reset_n  ),
         .adr_wr ( waddr      ),
         .adr_rd ( raddr      ),
         .din    ( data_write ),
         .dout   ( data_read  )
      );
   end
   else
   begin : ram
      wire [FIFO_WIDTH*FIFO_CNT-1:0] xread;
      ehl_spram
      #(
         .WIDTH      ( FIFO_WIDTH ),
         .AWIDTH     ( AWIDTH     ),
         .REG_OUT    ( 0          ),
         .TECHNOLOGY ( TECHNOLOGY )
      ) spram_inst [FIFO_CNT-1:0]
      (
         .clk     ( wclk       ),
         .reset_n ( w_reset_n  ),
         .wr      ( w_cs       ),
         .oe      ( 1'b1       ),
         .adr_wr  ( waddr      ),
         .adr_rd  ( raddr      ),
         .din     ( data_write ),
         .dout    ( xread      ),
         .mem_cfg ( 3'h0       )
      );
      // Note: protect data against asynchronous output change when 'r_empty'
      //       tie to 0
      assign data_read = r_empty ? {FIFO_CNT*FIFO_WIDTH{1'b0}} : xread;
   end

   if(USE_DPRAM)
   begin : dpram_rd
      reg [CS_WIDTH-1:0] r_cs_delay;
      always@(posedge rclk or negedge r_reset_n)
      if(!r_reset_n)
         r_cs_delay <= {CS_WIDTH{1'b0}};
      else
         r_cs_delay <= r_cs;

      assign rdat = data_read[r_cs_delay * WIDTH_DOUT +:WIDTH_DOUT];
   end
   else
   begin : reg_rd
      assign rdat = data_read[r_cs * WIDTH_DOUT +:WIDTH_DOUT];
   end
`ifdef ALTERA
endgenerate
`endif

   assign data_write = {WC_CNT{wdat}};

   ehl_cdc
   #(
      .SYNC_STAGE ( SYNC_STAGE       ),
      .WIDTH      ( FIFO_ADR_WIDTH+1 ),
      .TECHNOLOGY ( CDC_TECHNOLOGY   ),
      .REPORT     ( CDC_REPORT       )
   ) rptr_cdc (
      .clk     ( wclk      ),
      .reset_n ( w_reset_n ),
      .din     ( r_rptr    ),
      .dout    ( w_rptr    )
   );

   ehl_cdc
   #(
      .SYNC_STAGE ( SYNC_STAGE       ),
      .WIDTH      ( FIFO_ADR_WIDTH+1 ),
      .TECHNOLOGY ( CDC_TECHNOLOGY   ),
      .REPORT     ( CDC_REPORT       )
   ) wptr_cdc (
      .clk     ( rclk      ),
      .reset_n ( r_reset_n ),
      .din     ( w_wptr    ),
      .dout    ( r_wptr    )
   );
// Assertions
`ifndef SYNTHESIS
   initial
   begin
      if(DEPTH > 65536 || DEPTH < 1)
      begin
         $display("   Error: '%m' incorrect value %0d for parameter DEPTH (1 to 8192).", DEPTH);
         $finish;
      end
      if(DEPTH * WIDTH_DIN < WIDTH_DOUT)
      begin
         $display("   Error: '%m' DEPTH * WIDTH_DIN >= WIDTH_DOUT violation.");
         $finish;
      end
// TODO: add support for another parameters
//   parameter WIDTH_DIN = 32'd32,
//   WIDTH_DOUT = 32'd8,
//   SYNC_STAGE = 2'd2,
//   TECHNOLOGY = 0, // SPRAM technology
   end
`endif
`ifdef __ehl_cover__
// Gray coding assertions - SV only
// Counters can be changed by more than 1 bit, but only between clock domains, where sampling can be made rare than modification
//   But moidification still made 1 bit at time at source clock
// thus CDC assertions are not valid
   always@(posedge wclk) if(w_reset_n === 1'b1) if($countones(w_wptr ^ $past(w_wptr)) > 1) $display("   Error: '%m' FIFO write pointers (@wclk) are not Gray coded at time %0t.", $time);
   always@(posedge rclk) if(r_reset_n === 1'b1) if($countones(r_rptr ^ $past(r_rptr)) > 1) $display("   Error: '%m' FIFO read pointers (@rclk) are not Gray coded at time %0t.", $time);

   `define prop_name w_fifo_flags
   property `prop_name;
      @(posedge wclk) (w_empty | w_full | w_aempty | w_afull) |-> ($countones({w_empty, w_full, w_aempty, w_afull}) < 2);
   endproperty
   assert property (`prop_name) else $warning(" wFIFO [Almost] Full and [Almost] Empty flags shouldn't be asserted simultaneously @wclk");
   `undef prop_name

   `define prop_name r_fifo_flags
   property `prop_name;
      @(posedge rclk) (r_empty | r_full | r_aempty | r_afull) |-> ($countones({r_empty, r_full, r_aempty, r_afull}) < 2);
   endproperty
   assert property (`prop_name) else $warning(" rFIFO [Almost] Full and [Almost] Empty flags shouldn't be asserted simultaneously @rclk");
   `undef prop_name

   `define prop_name w_level_decrease
   // Note: skip
   property `prop_name;
      @(posedge wclk) disable iff(!w_reset_n) (!wr && !$isunknown($past(write_credit))) |-> ##1 (write_credit >= $past(write_credit));
   endproperty
   assert property (`prop_name) else $warning(" wFIFO level can't go down without a push");
   `undef prop_name
/*
// Note: 'write_credit' clocked at 'wclk' but assertion at 'rclk' - assume no CDC issues -- 'rd' should be synchronized to 'wclk' which consumes few cycles...
   `define prop_name w_level_increase
   property `prop_name;
      @(posedge rclk) disable iff(!r_reset_n) (!rd) |-> ##1 (write_credit <= $past(write_credit));
   endproperty
   assert property (`prop_name) else $warning(" wFIFO level can't go up without a pop");
   `undef prop_name
*/
   if(WC_CNT > 1)
   begin
      `define prop_name w_afull_seq
      property `prop_name;
         @(posedge wclk) ($stable(w_reset_n) & $rose(w_full)) |-> $past(w_afull) & $past(wr);
      endproperty
      assert property (`prop_name) else $warning(" FIFO Full must be set after w_afull");
     `undef prop_name
   end

   if(RC_CNT > 1)
   begin
      `define prop_name r_aempty_seq
      property `prop_name;
         @(posedge rclk) ($stable(r_reset_n) & $rose(r_empty)) |-> $past(r_aempty) & $past(rd);
      endproperty
      assert property (`prop_name) else $warning(" FIFO Empty must be set after r_aempty");
   `undef prop_name
   end
   //always@(posedge wclk) if(w_empty && w_full) $display("   Error: FIFO Write ctrl - Full and Empty shouldn't be asserted simultaneously at time %0t.", $time);
   //always@(posedge rclk) if(r_empty && r_full) $display("   Error: FIFO Read ctrl - Full and Empty shouldn't be asserted simultaneously at time %0t.", $time);
`endif

endmodule
