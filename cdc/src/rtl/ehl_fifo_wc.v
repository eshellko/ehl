// Design:           FIFO write controller
// Revision:         2.0
// Date:             2022-10-06
// Company:          Eshell
// Designer:         A.Kornukhin(kornukhin@mail.ru)
// Last modified by: 1.0 2011-07-11 A.Kornukhin: Initial release
//                   1.1 2014-05-19 A.Kornukhin: generate begin-end fixed
//                   1.2 2015-01-18 A.Kornukhin: almost_full/empty added
//                   1.3 2016-12-08 A.Kornukhin: bug fixed in chip select generation
//                                               when ratio WC/RC is not power of 2
//                   1.4 2016-12-12 A.Kornukhin: 'write_credit' added to report how
//                                               many empty cells left in FIFO
//                   1.5 2017-01-21 A.Kornukhin: 'onehot' pointer added
//                   1.6 2017-12-28 A.Kornukhin: fixed error in 'w_almost_full' generation
//                       bug was due to incorrect checking of cs_cnt (when WC_CNT > 1)
//                   1.7 2020-05-30 A.Kornukhin: 'write_credit' overflow fixed
//                   2.0 2022-10-06 A.Kornukhin: functionality completely rewritten
module ehl_fifo_wc
#(
   parameter FIFO_ADR_WIDTH = 32'd5,
             FIFO_CNT       = 32'd1,
             WC_CNT         = 32'd1,
             RC_CNT         = 32'd1,
             FIFO_DEPTH     = 32'd3
)
(  input wire                                           wclk, reset_n, wr, clr_of,
   output wire [FIFO_ADR_WIDTH:0]                       wptr_gray,
   output wire [FIFO_DEPTH==1 ? 0 : FIFO_ADR_WIDTH-1:0] waddr,
   input wire [FIFO_ADR_WIDTH:0]                        rptr_gray,
   output wire                                          w_full, w_empty, w_afull, w_aempty,
   output reg                                           w_overflow,
   output wire [FIFO_CNT-1:0]                           cs,
   output [$clog2(FIFO_CNT*FIFO_DEPTH):0]               write_credit
);
// write part consist of FIFO_CNT x FIFO_DEPTH cells
//    write can be made either to FIFO_CNT entries at one time,        assert FIFO_CNT chip selects, and adds cs_cnt to write address
//    or 1 entry at time                                               assert single chip select (pointed by write address LSB) and increment write address
// flags generated based on write credit, which calculated as function of write address, and received synchroniaed read address

//--------------------------------------------------------------------
//   SIZES     | FIFO_CNT | FIFO_DEPTH | ADDR_WIDTH      | ADDR_LSB  |
//-------------+----------+------------+-----------------+-----------+
// DIN == DOUT |    1     |   DEPTH    | log2(DEPTH)     |     0     |
// DIN >  DOUT |   O/I    |   DEPTH    | log2(DEPTH*O/I) | log2(O/I) |
// DIN <  DOUT |   I/O    |   DEPTH    | log2(DEPTH*I/O) | log2(I/O) |
//-------------+----------+------------+-----------------+-----------+

   localparam FULL_AWIDTH = $clog2(FIFO_DEPTH*FIFO_CNT);
   reg [FULL_AWIDTH:0] waddr_bin;
   localparam INCR = RC_CNT>1 ? RC_CNT : 1;

   always@(posedge wclk or negedge reset_n)
   if(!reset_n)
      waddr_bin <= 0;
   else if(wr & !w_full)
      waddr_bin <= waddr_bin + INCR;

   localparam GRAY_AWIDTH = $clog2(FIFO_DEPTH); // a.k.a. FIFO_ADR_WIDTH
   localparam LSB_AWIDTH = $clog2(FIFO_CNT);
   localparam MSB_AWIDTH = $clog2(FIFO_DEPTH);

   wire [FIFO_CNT-1:0] fptr = (FIFO_CNT==1) ? 1'b1 : (FIFO_CNT == WC_CNT) ? 1 << waddr_bin[(LSB_AWIDTH==0)?0:LSB_AWIDTH-1:0] : {FIFO_CNT{1'b1}}; // Note: integer used with gap at the moment
   assign cs = (wr & !w_full) ? fptr : {FIFO_CNT{1'b0}};

   wire [GRAY_AWIDTH:0] rptr_bin;
   assign write_credit = (FIFO_DEPTH*FIFO_CNT) - (waddr_bin[FULL_AWIDTH:0] - (rptr_bin << LSB_AWIDTH));

   ehl_gray_cnt
   #(
      .DEPTH ( GRAY_AWIDTH+1      ),
      .RANGE ( 1<<(GRAY_AWIDTH+1) )
   ) addr_inst
   (
      .clk       ( wclk                            ),
      .res       ( reset_n                         ),
      .ena       ( wr & !w_full & fptr[FIFO_CNT-1] ),
      .gcnt      ( wptr_gray                       ),
      .bcnt      (                                 ),
      .gcnt_next (                                 ),
      .bcnt_next (                                 )
   );

   assign w_empty  = write_credit == FIFO_DEPTH*FIFO_CNT;
   assign w_aempty = write_credit == (FIFO_DEPTH*FIFO_CNT - INCR);
   assign w_afull  = write_credit == INCR;
   assign w_full   = write_credit == 0;

   // Note: single entry depth FIFO ties address to 0
   assign waddr = (MSB_AWIDTH==0) ? 1'b0 : waddr_bin[LSB_AWIDTH +: (MSB_AWIDTH ? MSB_AWIDTH : 1)];

   ehl_gray2bin
   #(
      .WIDTH ( FIFO_ADR_WIDTH+1 )
   ) g2b_conv_inst (
      .data_gray ( rptr_gray ),
      .data_bin  ( rptr_bin  )
   );

   always@(posedge wclk or negedge reset_n)
   if(!reset_n)
      w_overflow <= 1'b0;
   else if(clr_of)
      w_overflow <= 1'b0;
   else if(wr && w_full)
   begin
      w_overflow <= 1'b1;
`ifndef SYNTHESIS
      $display("   Error: '%m' FIFO overflow detected at time %0t.", $time);
`endif
   end

endmodule
