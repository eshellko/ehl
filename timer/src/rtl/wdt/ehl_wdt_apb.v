// Design:           Watchdog Timer with APB host interface
// Revision:         1.0
// Date:             2022-09-05
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0. 2022-09-05 A.Kornukhin: Initial release

module ehl_wdt_apb
#(
   parameter WIDTH = 32
)
(
   input  pclk,
   input  presetn,
   input  wdt_reset_n,

   output irq,
   output rst_req,
// AMBA APB interface
   input [4:0] paddr,
   input pwrite,
   input psel,
   input penable,
   input [WIDTH-1:0] pwdata,
   output pready,
   pslverr,
   output [WIDTH-1:0] prdata
);
   wire [4:0] addr;
   wire [WIDTH-1:0] wdata, rdata;
   ehl_apb2generic
   #(
      .DATA_WIDTH ( WIDTH ),
      .ADR_WIDTH  ( 5     ),
      .TECHNOLOGY ( 0     )
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
      .adr       ( addr    ),
      .wr        ( wr      ),
      .rd        ( rd      ),
      .wdata     ( wdata   ),
      .rdata     ( rdata   ),
      .ready     ( 1'b1    ),
      .test_mode ( 1'b0    ),
      .clk_gated (         )
   );

   ehl_wdt
   #(
      .WIDTH ( WIDTH )
   ) wdt_inst
   (
      .clk         ( pclk    ),
      .reset_n     ( presetn ),
      .wdt_reset_n,
      .irq,
      .rst_req,

      .wr,
      .rd,
      .addr,
      .wdata,
      .rdata
   );

endmodule
