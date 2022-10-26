// Design:           GPIO Core
// Revision:         1.2
// Date:             2022-04-16
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2011-12-24 A.Kornukhin: Initial release
//                   1.1 2014-05-19 A.Kornukhin: generate begin-end fixed
//                   1.2 2022-04-16 A.Kornukhin: ungated clock added

module ehl_gpio_core
#(
   parameter WIDTH = 32,
   parameter CDC_TECHNOLOGY = 0,
   parameter GDOR_INIT = 0,
   GOER_INIT = 0,
   GAFR_INIT = 0,
   GPER_INIT = 0,
   GPTR_INIT = 0,
   GIER_INIT = 0,
   GISR_INIT = 0,
   GIFR_INIT = 0,
   GCMR_INIT = 0,
   GFMR_INIT = 0,
   META_ENA = 32'hFFFFFFFF,
   parameter IFG_POLARITY = 1,
   REGISTERED_OUTPUT = 0
)
(
   input wire reset_n, clk, clk_ug,
   write_gdor, write_goer, write_gafr, write_gper,
   write_gptr, write_gier, write_gisr, write_gcmr, write_gfmr,
   read_gdor, read_goer, read_gafr, read_gper,
   read_gptr, read_gier, read_gisr, read_gifr, read_gdir, read_gcmr, read_gfmr,
   input wire [WIDTH-1:0] gpio_in, data_in,
   set_gdor, set_goer, set_gafr, set_gper,
   set_gptr, set_gier, set_gisr, set_gcmr, set_gfmr,
   clr_gdor, clr_goer, clr_gafr, clr_gper,
   clr_gptr, clr_gier, clr_gisr, clr_gifr, clr_gcmr, clr_gfmr,
   inv_gdor, inv_goer, inv_gafr, inv_gper,
   inv_gptr, inv_gier, inv_gisr, inv_gcmr, inv_gfmr,
   output wire [WIDTH-1:0] gdor, goer, gafr,
   data_out,   // Register's Output Data
   pull_up,    // Pull Up Resistor Enable
   pull_down,  // Pull Down Resistor Enable
   output reg ifg
);

   wire [WIDTH-1:0] gdir;
   wire [WIDTH-1:0] data_out_mux;
   wire [WIDTH-1:0] gptr, gper, gier, gisr, gcmr, gfmr;
   reg [WIDTH-1:0] gifr, gpio_in_prev;

   assign pull_up = gptr & gper;
   assign pull_down = (~gptr) & gper;

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GDOR_INIT )
   ) gdor_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gdor ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gdor   ),
      .clr_reg       ( clr_gdor   ),
      .inv_reg       ( inv_gdor   ),
      .gpio_register ( gdor       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GOER_INIT )
   ) goer_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_goer ),
      .data_in       ( data_in    ),
      .set_reg       ( set_goer   ),
      .clr_reg       ( clr_goer   ),
      .inv_reg       ( inv_goer   ),
      .gpio_register ( goer       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GAFR_INIT )
   ) gafr_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gafr ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gafr   ),
      .clr_reg       ( clr_gafr   ),
      .inv_reg       ( inv_gafr   ),
      .gpio_register ( gafr       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GPER_INIT )
   ) gper_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gper ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gper   ),
      .clr_reg       ( clr_gper   ),
      .inv_reg       ( inv_gper   ),
      .gpio_register ( gper       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GPTR_INIT )
   ) gptr_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gptr ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gptr   ),
      .clr_reg       ( clr_gptr   ),
      .inv_reg       ( inv_gptr   ),
      .gpio_register ( gptr       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GIER_INIT )
   ) gier_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gier ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gier   ),
      .clr_reg       ( clr_gier   ),
      .inv_reg       ( inv_gier   ),
      .gpio_register ( gier       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GISR_INIT )
   ) gisr_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gisr ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gisr   ),
      .clr_reg       ( clr_gisr   ),
      .inv_reg       ( inv_gisr   ),
      .gpio_register ( gisr       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GCMR_INIT )
   ) gcmr_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gcmr ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gcmr   ),
      .clr_reg       ( clr_gcmr   ),
      .inv_reg       ( inv_gcmr   ),
      .gpio_register ( gcmr       )
   );

   ehl_gpio_reg
   #(
      .WIDTH    ( WIDTH     ),
      .REG_INIT ( GFMR_INIT )
   ) gfmr_reg
   (
      .clk           ( clk        ),
      .reset_n       ( reset_n    ),
      .write_reg     ( write_gfmr ),
      .data_in       ( data_in    ),
      .set_reg       ( set_gfmr   ),
      .clr_reg       ( clr_gfmr   ),
      .inv_reg       ( inv_gfmr   ),
      .gpio_register ( gfmr       )
   );

   ehl_gpio_filter
   #(
      .WIDTH          ( WIDTH          ),
      .CDC_TECHNOLOGY ( CDC_TECHNOLOGY ),
      .META_ENA       ( META_ENA       )
   ) filt_inst
   (
      .clk      ( clk_ug  ),
      .reset_n  ( reset_n ),
      .gfmr     ( gfmr    ),
      .data_in  ( gpio_in ),
      .data_out ( gdir    )
   );

   always@(posedge clk_ug or negedge reset_n)
   if(!reset_n)
      gpio_in_prev <= {WIDTH{1'b0}};
   else
      gpio_in_prev <= gdir;

   wire [WIDTH-1:0] next_gifr;
   assign next_gifr =
      gier &                                           // Interrupt enabled
      (~goer) &                                        // Port as Input
      (~gafr) &                                        // Main Port Function enabled
      (
         (gcmr & (gdir^gpio_in_prev)) |                // Any switch occurs
         (gisr & (~gcmr) & gdir & (~gpio_in_prev)) |   // Positive Edge on Input occurs and enabled
         ((~gisr) & (~gcmr) & (~gdir) & gpio_in_prev)  // Negative Edge on input occurs and enabled
      );

   wire [WIDTH-1:0] gifr_load; // value of GIFR to be loaded at the next cycle

   always@(posedge clk_ug or negedge reset_n)
   if(!reset_n)
      gifr <= GIFR_INIT;
   else
      gifr <= gifr_load;

   always@(posedge clk_ug or negedge reset_n)
   if(!reset_n)
      ifg <= !IFG_POLARITY[0];
   else
      ifg <= (|gifr_load) ^ !IFG_POLARITY[0];

   // flags cleared via explicit clear command with asserted bits
   assign gifr_load = next_gifr | (gifr & ~clr_gifr);

   ehl_cdc
   #(
      .SYNC_STAGE ( REGISTERED_OUTPUT ),
      .TECHNOLOGY ( 0                 ),
      .WIDTH      ( WIDTH             ),
      .REPORT     ( 1'b0              )
   ) dout_mux
   (
      .clk     ( clk_ug       ),
      .reset_n ( reset_n      ),
      .din     ( data_out_mux ),
      .dout    ( data_out     )
   );

   assign data_out_mux =
      ({WIDTH{read_gdor}} & gdor) |
      ({WIDTH{read_goer}} & goer) |
      ({WIDTH{read_gafr}} & gafr) |
      ({WIDTH{read_gper}} & gper) |
      ({WIDTH{read_gptr}} & gptr) |
      ({WIDTH{read_gier}} & gier) |
      ({WIDTH{read_gisr}} & gisr) |
      ({WIDTH{read_gifr}} & gifr) |
      ({WIDTH{read_gdir}} & gdir) |
      ({WIDTH{read_gcmr}} & gcmr) |
      ({WIDTH{read_gfmr}} & gfmr);

`ifdef __ehl_assert__
// Assertions to check writing to IFG sensitive registers while interrupt enabled
   property ChangeGAFR;
      @(posedge clk) !(|(gier & ($past(gafr)^gafr)));
   endproperty
   property ChangeGOER;
      @(posedge clk) !(|(gier & ($past(goer)^goer)));
   endproperty
   property ChangeGISR;
      @(posedge clk) !(|(gier & ($past(gisr)^gisr)));
   endproperty
   property ChangeGCMR;
      @(posedge clk) !(|(gier & ($past(gcmr)^gcmr)));
   endproperty
   property ChangeGFMR;
      @(posedge clk) !(|(gier & ($past(gfmr)^gfmr)));
   endproperty
   assert property(ChangeGAFR) else $warning("   GPIO_TB: '%m' shouldn't change GAFR while GIER asserted to avoid false interrupt generation.\n");
   assert property(ChangeGOER) else $warning("   GPIO_TB: '%m' shouldn't change GOER while GIER asserted to avoid false interrupt generation.\n");
   assert property(ChangeGISR) else $warning("   GPIO_TB: '%m' shouldn't change GISR while GIER asserted to avoid false interrupt generation.\n");
   assert property(ChangeGCMR) else $warning("   GPIO_TB: '%m' shouldn't change GCMR while GIER asserted to avoid false interrupt generation.\n");
   assert property(ChangeGFMR) else $warning("   GPIO_TB: '%m' shouldn't change GFMR while GIER asserted to avoid false interrupt generation.\n");
`endif

endmodule
