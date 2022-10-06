// Design:           General Purpose Input/Output with APB host interface
// Revision:         1.2
// Date:             2020-09-18
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2013-02-27 A.Kornukhin: Initial release
//                   1.1 2014-10-17 A.Kornukhin: updated ehl_apb2generic
//                   1.2 2020-09-18 A.Kornukhin: register map changed

// Silicon history:
//   FPGA: Xilinx's ML605
//   FPGA: Xilinx's Zedboard

module ehl_gpio_apb
#(
   parameter WIDTH = 32,
   CDC_TECHNOLOGY  = 0,
   META_ENA        = 32'hFFFFFFFF,
   IFG_POLARITY    = 1,
   // GPIO data output register (GDOR)
   GDOR_ENA        = 5'b11111, // {set, clear, invert, read, write}
   GDOR_INIT       = 0,
   // GPIO output enable register (GOER)
   GOER_ENA        = 5'b11111,
   GOER_INIT       = 0,
   // GPIO alternative function register (GAFR)
   GAFR_ENA        = 5'b11111,
   GAFR_INIT       = 0,
   // GPIO pull enable register (GPER)
   GPER_ENA        = 5'b11111,
   GPER_INIT       = 0,
   // GPIO pull type register (GPTR)
   GPTR_ENA        = 5'b11111,
   GPTR_INIT       = 0,
   // GPIO interrupt enable register (GIER)
   GIER_ENA        = 5'b11111,
   GIER_INIT       = 0,
   // GPIO interrupt source register (GISR)
   GISR_ENA        = 5'b11111,
   GISR_INIT       = 0,
   // GPIO interrupt flag register (GIFR)
   READ_GIFR_ENA   = 1,
   CLR_GIFR_ENA    = 1,
   GIFR_INIT       = 0,
   // GPIO Data input register (GDIR)
   READ_GDIR_ENA   = 1,
   // GPIO capture mode register (GCMR)
   GCMR_ENA        = 5'b11111,
   GCMR_INIT       = 0,
   // GPIO filter mode register (GFMR)
   GFMR_ENA        = 5'b11111,
   GFMR_INIT       = 0
)
(
// AMBA APB interface
   input              pclk,
                      presetn,
   input [5:0]        paddr,
   input              pwrite,
   input              psel,
   input              penable,
   input [WIDTH-1:0]  pwdata,
   output             pready,
                      pslverr,
   output [WIDTH-1:0] prdata,
// GPIO interface
   input [WIDTH-1:0]  gpio_in,
   output [WIDTH-1:0] gpio_out,
                      gpio_oe,
                      gpio_pd,
                      gpio_pu,
                      gpio_en,
   output             ifg
);
   wire [5:0] adr;
   wire wr,
   rd;
   wire [WIDTH-1:0] wdata;
   wire [WIDTH-1:0] rdata;

   ehl_apb2generic
   #(
      .DATA_WIDTH ( WIDTH          ),
      .ADR_WIDTH  ( 6              ),
      .TECHNOLOGY ( CDC_TECHNOLOGY )
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
      .clk_gated ( pclk_g  )
   );

   ehl_gpio_top
   #(
      .WIDTH             ( WIDTH          ),
      .CDC_TECHNOLOGY    ( CDC_TECHNOLOGY ),
      .META_ENA          ( META_ENA       ),
      .IFG_POLARITY      ( IFG_POLARITY   ),
   // GPIO data output register (GDOR)
      .GDOR_ENA          ( GDOR_ENA       ),
      .GDOR_INIT         ( GDOR_INIT      ),
   // GPIO output enable register (GOER)
      .GOER_ENA          ( GOER_ENA       ),
      .GOER_INIT         ( GOER_INIT      ),
   // GPIO alternative function register (GAFR)
      .GAFR_ENA          ( GAFR_ENA       ),
      .GAFR_INIT         ( GAFR_INIT      ),
   // GPIO pull enable register (GPER)
      .GPER_ENA          ( GPER_ENA       ),
      .GPER_INIT         ( GPER_INIT      ),
   // GPIO pull type register (GPTR)
      .GPTR_ENA          ( GPTR_ENA       ),
      .GPTR_INIT         ( GPTR_INIT      ),
   // GPIO interrupt enable register (GIER)
      .GIER_ENA          ( GIER_ENA       ),
      .GIER_INIT         ( GIER_INIT      ),
   // GPIO interrupt source register (GISR)
      .GISR_ENA          ( GISR_ENA       ),
      .GISR_INIT         ( GISR_INIT      ),
   // GPIO interrupt flag register (GIFR)
      .READ_GIFR_ENA     ( READ_GIFR_ENA  ),
      .CLR_GIFR_ENA      ( CLR_GIFR_ENA   ),
      .GIFR_INIT         ( GIFR_INIT      ),
   // GPIO Data input register (GDIR)
      .READ_GDIR_ENA     ( READ_GDIR_ENA  ),
   // GPIO capture mode register (GCMR)
      .GCMR_ENA          ( GCMR_ENA       ),
      .GCMR_INIT         ( GCMR_INIT      ),
   // GPIO filter mode register (GFMR)
      .GFMR_ENA          ( GFMR_ENA       ),
      .GFMR_INIT         ( GFMR_INIT      ),
      .REGISTERED_OUTPUT ( 2'h0           )
   ) gpio_inst
   (
      .clk      ( pclk_g   ),
      .clk_ug   ( pclk     ),
      .reset_n  ( presetn  ),
      .wr       ( wr       ),
      .rd       ( rd       ),
      .data_in  ( wdata    ),
      .gpio_in  ( gpio_in  ),
      .addr     ( adr      ),
      .data_out ( rdata    ),
      .gpio_out ( gpio_out ),
      .gpio_oe  ( gpio_oe  ),
      .gpio_pd  ( gpio_pd  ),
      .gpio_pu  ( gpio_pu  ),
      .gpio_en  ( gpio_en  ),
      .ifg      ( ifg      )
   );

endmodule
