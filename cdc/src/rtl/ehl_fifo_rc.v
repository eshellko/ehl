// Design:           FIFO read controller
// Revision:         2.0
// Date:             2022-10-06
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2011-07-10 A.Kornukhin: Initial release
//                   1.1 2014-05-19 A.Kornukhin: generate begin-end fixed
//                   1.2 2015-01-18 A.Kornukhin: almost_full/empty added
//                   1.3 2017-01-21 A.Kornukhin: 'onehot' pointer added
//                   1.4 2017-12-28 A.Kornukhin: fixed error in 'r_almost_empty' generation
//                       bug was due to incorrect checking of cs_cnt (when RC_CNT > 1)
//                   2.0 2022-10-06 A.Kornukhin: functionality completely rewritten
module ehl_fifo_rc
#(
   parameter FIFO_ADR_WIDTH = 32'd5,
             FIFO_CNT       = 32'd1,
             CS_WIDTH       = 32'd1,
             WC_CNT         = 32'd1,
             RC_CNT         = 32'd1,
             FIFO_DEPTH     = 32'd3
)
(  input wire                                           rclk, reset_n, rd, clr_uf,
   output wire [FIFO_ADR_WIDTH:0]                       rptr_gray,
   output wire [FIFO_DEPTH==1 ? 0 : FIFO_ADR_WIDTH-1:0] raddr,
   input wire [FIFO_ADR_WIDTH:0]                        wptr_gray,
   output wire                                          r_full, r_empty, r_aempty, r_afull,
   output reg                                           r_underflow,
   output wire [CS_WIDTH-1:0]                           cs_cnt
);
   localparam FULL_AWIDTH = $clog2(FIFO_DEPTH*FIFO_CNT);
   reg [FULL_AWIDTH:0] raddr_bin;
   localparam INCR = WC_CNT>1 ? WC_CNT : 1;

   always@(posedge rclk or negedge reset_n)
   if(!reset_n)
      raddr_bin <= 0;
   else if(rd & !r_empty)
      raddr_bin <= raddr_bin + INCR;

   localparam GRAY_AWIDTH = $clog2(FIFO_DEPTH); // a.k.a. FIFO_ADR_WIDTH
   localparam LSB_AWIDTH = $clog2(FIFO_CNT);
   localparam MSB_AWIDTH = $clog2(FIFO_DEPTH);

   wire [FIFO_CNT-1:0] fptr = (FIFO_CNT==1) ? 1'b1 : (FIFO_CNT == RC_CNT) ? 1 << raddr_bin[(LSB_AWIDTH==0)?0:LSB_AWIDTH-1:0] : {FIFO_CNT{1'b1}}; // Note: integer used with gap at the moment
   assign cs_cnt = LSB_AWIDTH==0 ? 1'b0 : raddr_bin[(LSB_AWIDTH==0)?0:LSB_AWIDTH-1:0];

   wire [GRAY_AWIDTH:0] wptr_bin;
   wire [$clog2(FIFO_CNT*FIFO_DEPTH):0] read_credit;
   assign read_credit = (wptr_bin << LSB_AWIDTH) - raddr_bin[FULL_AWIDTH:0];

   ehl_gray_cnt
   #(
      .DEPTH ( GRAY_AWIDTH+1      ),
      .RANGE ( 1<<(GRAY_AWIDTH+1) )
   ) addr_inst
   (
      .clk       ( rclk                             ),
      .res       ( reset_n                          ),
      .ena       ( rd & !r_empty & fptr[FIFO_CNT-1] ),
      .gcnt      ( rptr_gray                        ),
      .bcnt      (                                  ),
      .gcnt_next (                                  ),
      .bcnt_next (                                  )
   );

   assign r_empty  = read_credit == 0;
   assign r_aempty = read_credit == INCR;
   assign r_afull  = read_credit == (FIFO_DEPTH*FIFO_CNT - INCR);
   assign r_full   = read_credit == FIFO_DEPTH*FIFO_CNT;

   // Note: single entry depth FIFO ties address to 0
   assign raddr = (MSB_AWIDTH==0) ? 1'b0 : raddr_bin[LSB_AWIDTH +: (MSB_AWIDTH ? MSB_AWIDTH : 1)];

   ehl_gray2bin
   #(
      .WIDTH ( FIFO_ADR_WIDTH+1 )
   ) g2b_conv_inst (
      .data_gray ( wptr_gray ),
      .data_bin  ( wptr_bin  )
   );

   always@(posedge rclk or negedge reset_n)
   if(!reset_n)
      r_underflow <= 1'b0;
   else if(clr_uf)
      r_underflow <= 1'b0;
   else if(rd && r_empty)
   begin
      r_underflow <= 1'b1;
`ifndef SYNTHESIS
      $display("   Error: '%m' FIFO underflow detected at time %0t.", $time);
`endif
   end

endmodule
