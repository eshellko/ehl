// Design:           Timer with APB host interface
// Revision:         1.0
// Date:             2014-11-20
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0. 2014-11-20 A.Kornukhin: Initial release

module ehl_timer_apb
#(
   parameter WIDTH = 32,
   parameter [0:0] USE_CG = 1'b1,
   parameter TECHNOLOGY = 0,          // technology for rtl mapping
             CDC_SYNC_STAGE = 2,      // number of CDC stages
             NTIMERS   = 1,           // number of timers (1-4) to be used as single bus slave device
             TIMER_WIDTH = 32,        // timer width
   parameter [3:0] PWM_ENA = 4'b000,  // enables PWM for selected timer
   parameter [3:0] CPT_ENA = 4'b000,  // enables Capture for selected timer
   parameter [3:0] CMP_ENA = 4'b000,  // enables Compare for selected timer
   parameter [7:0] CPT_SYNC = 8'hff   // enable synchronizer on cpt_in
)
(
// AMBA APB interface
   input pclk,
   presetn,
   input [7:0] paddr,
   input pwrite,
   input psel,
   input penable,
   input [WIDTH-1:0] pwdata,
   output pready,
   pslverr,
   output [WIDTH-1:0] prdata,
// Timer interface
   output ifg,
   input wire  [2*NTIMERS-1:0] cpt_in,      // Capture inputs
   output wire [NTIMERS-1:0]   cmp_oe_n,    // Active low COMPARE output enable
   output wire [3*NTIMERS-1:0] cmp_out,     // Compare / PWM outputs
   output wire [3*NTIMERS-1:0] cmp_out_n    // inverted PWM outputs
);
   wire [7:0] adr;
   wire wr,
   rd;
   wire [WIDTH-1:0] wdata;
   wire [WIDTH-1:0] rdata;

   ehl_apb2generic
   #(
      .DATA_WIDTH ( WIDTH ),
      .ADR_WIDTH  ( 8     ),
      .TECHNOLOGY ( 0     ) // TODO: drive and use CG, when enabled
   ) apb_inst
   (
      // AMBA APB
      .pclk      ( pclk    ),
      .presetn   ( presetn ),
      .paddr     ( paddr   ),
      .pwrite    ( pwrite  ),
      .psel      ( psel    ),
      .penable   ( penable ),
      .pwdata    ( pwdata  ),
      .pready    ( pready  ),
      .pslverr   ( pslverr ),
      .prdata    ( prdata  ),
      // Generic
      .adr       ( adr     ),
      .wr        ( wr      ),
      .rd        ( rd      ),
      .wdata     ( wdata   ),
      .rdata     ( rdata   ),
      .ready     ( 1'b1    ),
      .test_mode ( 1'b0    ),
      .clk_gated (         )
   );

   ehl_timer
   #(
      .BUS_WIDTH      ( WIDTH          ),
      .USE_CG         ( USE_CG         ),
      .TECHNOLOGY     ( TECHNOLOGY     ),
      .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
      .NTIMERS        ( NTIMERS        ),
      .TIMER_WIDTH    ( TIMER_WIDTH    ),
      .PWM_ENA        ( PWM_ENA        ),
      .CPT_ENA        ( CPT_ENA        ),
      .CMP_ENA        ( CMP_ENA        ),
      .CPT_SYNC       ( CPT_SYNC       )
   ) timer_inst
   (
      .clk         ( pclk               ),
      .reset_n     ( presetn            ),
      .wr          ( wr                 ),
      .addr        ( adr                ),
      .din         ( wdata              ),
      .dout        ( rdata              ),
      .tmr_clk     ( {NTIMERS{pclk}}    ),
      .tmr_reset_n ( {NTIMERS{presetn}} ),
      .irq         ( ifg                ),
      .test_mode   ( 1'b0               ), // TODO: propagate
      .cpt_in,
      .cmp_oe_n,
      .cmp_out,
      .cmp_out_n
   );

endmodule
