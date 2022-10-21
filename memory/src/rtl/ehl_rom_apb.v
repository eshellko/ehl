// Design:           ROM with APB host interface
// Revision:         1.0
// Date:             2022-10-20
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-10-20 A.Kornukhin: Initial release

module ehl_rom_apb
#(
   parameter AWIDTH = 10,
   MEM_FILE = "rom.mif",
   parameter [0:0] LOAD_MEM = 0 // set to use readmem
)
(
// AMBA APB interface
   input         pclk,
                 presetn,
   input [31:0]  paddr,
   input         pwrite,
   input         psel,
   input         penable,
   input [31:0]  pwdata,
   output        pready,
                 pslverr,
   output [31:0] prdata
);
   wire [AWIDTH-1:0] adr;
   wire wr,
   rd;
   wire [31:0] wdata;
   wire [31:0] rdata;

   ehl_apb2generic
   #(
      .DATA_WIDTH ( 32     ),
      .ADR_WIDTH  ( AWIDTH ),
      .TECHNOLOGY ( 0      )
   ) apb_inst
   (
      // AMBA APB
      .pclk      ( pclk    ),
      .presetn   ( presetn ),
      .paddr     ( paddr[AWIDTH-1:0] ),
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
      .err       ( 1'b0    ), // TODO: error on write attempt
      .wdata     ( wdata   ),
      .rdata     ( rdata   ),
      .ready     ( 1'b1    ),
      .test_mode ( 1'b0    ),
      .clk_gated ( pclk_g  )
   );

   ehl_rom
   #(
      .WIDTH    ( 32       ),
      .AWIDTH   ( AWIDTH-2 ),
      .MEM_FILE ( MEM_FILE ),
      .LOAD_MEM ( LOAD_MEM )
   ) rom_inst
   (
      .clk  ( pclk ),
      .rd,
      .addr ( adr[AWIDTH-1:2] ),
      .dout ( rdata )
   );

endmodule
