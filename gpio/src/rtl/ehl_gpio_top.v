// Design:           General Purpose Input/Output
// Revision:         1.4
// Date:             2022-04-16
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2011-12-24 A.Kornukhin: inital release
//                   1.1 2015-03-06 A.Kornukhin: %m added
//                   1.2 2019-06-13 A.Kornukhin: bit_sel combined with addr
//                   1.3 2020-09-18 A.Kornukhin: register map changed
//                   1.4 2022-04-16 A.Kornukhin: ungated clock added

module ehl_gpio_top
#(
   parameter WIDTH = 32,
   CDC_TECHNOLOGY = 0,
   META_ENA = 32'hFFFFFFFF,
   IFG_POLARITY = 1,
   // GPIO data output register (GDOR)
   GDOR_ENA = 5'b11111,
   GDOR_INIT = 0,
   // GPIO output enable register (GOER)
   GOER_ENA = 5'b11111,
   GOER_INIT = 0,
   // GPIO alternative function register (GAFR)
   GAFR_ENA = 5'b11111,
   GAFR_INIT = 0,
   // GPIO pull enable register (GPER)
   GPER_ENA = 5'b11111,
   GPER_INIT = 0,
   // GPIO pull type register (GPTR)
   GPTR_ENA = 5'b11111,
   GPTR_INIT = 0,
   // GPIO interrupt enable register (GIER)
   GIER_ENA = 5'b11111,
   GIER_INIT = 0,
   // GPIO interrupt source register (GISR)
   GISR_ENA = 5'b11111,
   GISR_INIT = 0,
   // GPIO interrupt flag register (GIFR)
   READ_GIFR_ENA = 1,
   CLR_GIFR_ENA = 1,
   GIFR_INIT = 0,
   // GPIO Data input register (GDIR)
   READ_GDIR_ENA = 1,
   // GPIO capture mode register (GCMR)
   GCMR_ENA = 5'b11111,
   GCMR_INIT = 0,
   // GPIO filter mode register (GFMR)
   GFMR_ENA = 5'b11111,
   GFMR_INIT = 0,
   REGISTERED_OUTPUT = 0 // enable register at 'dout' multiplexor
)
(
   input              clk,    // core clock, may be pulsed only when access to CSRs is required
                      clk_ug, // ungated clock - should run all the time, device is active
                      reset_n,
                      wr,
                      rd,
   input [WIDTH-1:0]  data_in,
                      gpio_in,
   input [5:0]        addr,
   output [WIDTH-1:0] data_out,
                      gpio_out,
                      gpio_oe,
                      gpio_pd,
                      gpio_pu,
                      gpio_en,
   output             ifg
);
`ifndef SYNTHESIS
   initial $display("   Info: instantiate EHL GPIO IP Core (%m).");
`endif

   wire [WIDTH-1:0]
   set_gdor, set_goer, set_gafr, set_gper, set_gptr, set_gier, set_gisr,           set_gcmr, set_gfmr,
   clr_gdor, clr_goer, clr_gafr, clr_gper, clr_gptr, clr_gier, clr_gisr, clr_gifr, clr_gcmr, clr_gfmr,
   inv_gdor, inv_goer, inv_gafr, inv_gper, inv_gptr, inv_gier, inv_gisr,           inv_gcmr, inv_gfmr;
   wire write_gdor, write_goer, write_gafr, write_gper, write_gptr, write_gier, write_gisr,                       write_gcmr, write_gfmr,
        read_gdor,  read_goer,  read_gafr,  read_gper,  read_gptr,  read_gier,  read_gisr,  read_gifr, read_gdir, read_gcmr,  read_gfmr;

   ehl_gpio_core
   #(
      .WIDTH             ( WIDTH             ),
      .CDC_TECHNOLOGY    ( CDC_TECHNOLOGY    ),
      .GDOR_INIT         ( GDOR_INIT         ),
      .GOER_INIT         ( GOER_INIT         ),
      .GAFR_INIT         ( GAFR_INIT         ),
      .GPER_INIT         ( GPER_INIT         ),
      .GPTR_INIT         ( GPTR_INIT         ),
      .GIER_INIT         ( GIER_INIT         ),
      .GISR_INIT         ( GISR_INIT         ),
      .GIFR_INIT         ( GIFR_INIT         ),
      .GCMR_INIT         ( GCMR_INIT         ),
      .GFMR_INIT         ( GFMR_INIT         ),
      .META_ENA          ( META_ENA          ),
      .IFG_POLARITY      ( IFG_POLARITY      ),
      .REGISTERED_OUTPUT ( REGISTERED_OUTPUT )
   ) core_inst
   (
      .reset_n    ( reset_n    ),
      .clk        ( clk        ),
      .clk_ug     ( clk_ug     ),
      .data_out   ( data_out   ),
      .goer       ( gpio_oe    ),
      .gafr       ( gpio_en    ),
      .pull_up    ( gpio_pu    ),
      .pull_down  ( gpio_pd    ),
      .gpio_in    ( gpio_in    ),
      .gdor       ( gpio_out   ),
      .data_in    ( data_in    ),
      .write_gdor ( write_gdor ),
      .write_goer ( write_goer ),
      .write_gafr ( write_gafr ),
      .write_gper ( write_gper ),
      .write_gptr ( write_gptr ),
      .write_gier ( write_gier ),
      .write_gisr ( write_gisr ),
      .write_gcmr ( write_gcmr ),
      .write_gfmr ( write_gfmr ),
      .read_gdor  ( read_gdor  ),
      .read_goer  ( read_goer  ),
      .read_gafr  ( read_gafr  ),
      .read_gper  ( read_gper  ),
      .read_gptr  ( read_gptr  ),
      .read_gier  ( read_gier  ),
      .read_gisr  ( read_gisr  ),
      .read_gifr  ( read_gifr  ),
      .read_gdir  ( read_gdir  ),
      .read_gcmr  ( read_gcmr  ),
      .read_gfmr  ( read_gfmr  ),
      .set_gdor   ( set_gdor   ),
      .set_goer   ( set_goer   ),
      .set_gafr   ( set_gafr   ),
      .set_gper   ( set_gper   ),
      .set_gptr   ( set_gptr   ),
      .set_gier   ( set_gier   ),
      .set_gisr   ( set_gisr   ),
      .set_gcmr   ( set_gcmr   ),
      .set_gfmr   ( set_gfmr   ),
      .clr_gdor   ( clr_gdor   ),
      .clr_goer   ( clr_goer   ),
      .clr_gafr   ( clr_gafr   ),
      .clr_gper   ( clr_gper   ),
      .clr_gptr   ( clr_gptr   ),
      .clr_gier   ( clr_gier   ),
      .clr_gisr   ( clr_gisr   ),
      .clr_gifr   ( clr_gifr   ),
      .clr_gcmr   ( clr_gcmr   ),
      .clr_gfmr   ( clr_gfmr   ),
      .inv_gdor   ( inv_gdor   ),
      .inv_goer   ( inv_goer   ),
      .inv_gafr   ( inv_gafr   ),
      .inv_gper   ( inv_gper   ),
      .inv_gptr   ( inv_gptr   ),
      .inv_gier   ( inv_gier   ),
      .inv_gisr   ( inv_gisr   ),
      .inv_gcmr   ( inv_gcmr   ),
      .inv_gfmr   ( inv_gfmr   ),
      .ifg        ( ifg        )
   );

   ehl_gpio_decoder
   #(
      .WIDTH         ( WIDTH         ),
      .GDOR_ENA      ( GDOR_ENA      ),
      .GOER_ENA      ( GOER_ENA      ),
      .GAFR_ENA      ( GAFR_ENA      ),
      .GPER_ENA      ( GPER_ENA      ),
      .GPTR_ENA      ( GPTR_ENA      ),
      .GIER_ENA      ( GIER_ENA      ),
      .GISR_ENA      ( GISR_ENA      ),
      .GCMR_ENA      ( GCMR_ENA      ),
      .GFMR_ENA      ( GFMR_ENA      ),
      .READ_GIFR_ENA ( READ_GIFR_ENA ),
      .CLR_GIFR_ENA  ( CLR_GIFR_ENA  ),
      .READ_GDIR_ENA ( READ_GDIR_ENA )
   ) decoder_inst
   (
      .wr         ( wr         ),
      .rd         ( rd         ),
      .addr       ( addr       ),
      .data_in    ( data_in    ),
      .set_gdor   ( set_gdor   ),
      .set_goer   ( set_goer   ),
      .set_gafr   ( set_gafr   ),
      .set_gper   ( set_gper   ),
      .set_gptr   ( set_gptr   ),
      .set_gier   ( set_gier   ),
      .set_gisr   ( set_gisr   ),
      .set_gcmr   ( set_gcmr   ),
      .set_gfmr   ( set_gfmr   ),
      .clr_gdor   ( clr_gdor   ),
      .clr_goer   ( clr_goer   ),
      .clr_gafr   ( clr_gafr   ),
      .clr_gper   ( clr_gper   ),
      .clr_gptr   ( clr_gptr   ),
      .clr_gier   ( clr_gier   ),
      .clr_gisr   ( clr_gisr   ),
      .clr_gifr   ( clr_gifr   ),
      .clr_gcmr   ( clr_gcmr   ),
      .clr_gfmr   ( clr_gfmr   ),
      .inv_gdor   ( inv_gdor   ),
      .inv_goer   ( inv_goer   ),
      .inv_gafr   ( inv_gafr   ),
      .inv_gper   ( inv_gper   ),
      .inv_gptr   ( inv_gptr   ),
      .inv_gier   ( inv_gier   ),
      .inv_gisr   ( inv_gisr   ),
      .inv_gcmr   ( inv_gcmr   ),
      .inv_gfmr   ( inv_gfmr   ),
      .write_gdor ( write_gdor ),
      .write_goer ( write_goer ),
      .write_gafr ( write_gafr ),
      .write_gper ( write_gper ),
      .write_gptr ( write_gptr ),
      .write_gier ( write_gier ),
      .write_gisr ( write_gisr ),
      .write_gcmr ( write_gcmr ),
      .write_gfmr ( write_gfmr ),
      .read_gdor  ( read_gdor  ),
      .read_goer  ( read_goer  ),
      .read_gafr  ( read_gafr  ),
      .read_gper  ( read_gper  ),
      .read_gptr  ( read_gptr  ),
      .read_gier  ( read_gier  ),
      .read_gisr  ( read_gisr  ),
      .read_gifr  ( read_gifr  ),
      .read_gdir  ( read_gdir  ),
      .read_gcmr  ( read_gcmr  ),
      .read_gfmr  ( read_gfmr  )
   );

endmodule
